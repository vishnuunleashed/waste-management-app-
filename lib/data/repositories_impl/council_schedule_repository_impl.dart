import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fpdart/fpdart.dart';

import '../../core/error/failure.dart';
import '../../core/services/device_identity_service.dart';
import '../../core/utils/app_logger.dart';
import '../../domain/entities/collection_schedule.dart';
import '../../domain/entities/council.dart';
import '../../domain/repositories/council_schedule_repository.dart';
import '../datasources/local/schedule_local_cache_datasource.dart';
import '../datasources/remote/schedule_ai_datasource.dart';

const _tag = 'CouncilSchedule';

class CouncilScheduleRepositoryImpl implements CouncilScheduleRepository {
  final FirebaseFirestore firestore;
  final ScheduleAiDataSource aiDataSource;
  final DeviceIdentityService deviceIdentityService;
  final ScheduleLocalCacheDataSource localCache;

  CouncilScheduleRepositoryImpl({
    required this.aiDataSource,
    required this.deviceIdentityService,
    required this.localCache,
    FirebaseFirestore? firestore,
  }) : firestore = firestore ?? FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _scheduleDoc(String councilId) => firestore
      .collection('councils')
      .doc(councilId)
      .collection('schedule')
      .doc('current');

  @override
  Future<Either<Failure, CollectionSchedule>> getSchedule(
    Council council, {
    bool forceRefresh = false,
  }) async {
    // 1. Fastest path: a fresh on-device mirror — no network round-trip,
    // works offline. Skipped entirely on a forced refresh.
    final onDevice = forceRefresh ? null : localCache.getCached(council.id);
    if (onDevice != null && !onDevice.isStale) {
      return Right(onDevice);
    }

    // 2. Shared cache in Firestore — same data for every device/login on
    // this council. Also skipped on a forced refresh.
    CollectionSchedule? sharedCached;
    if (!forceRefresh) {
      try {
        AppLogger.firebase(_tag, 'Reading shared schedule cache for ${council.id}...');
        final snapshot = await _scheduleDoc(council.id).get();
        if (snapshot.exists && snapshot.data() != null) {
          sharedCached = CollectionSchedule.fromJson(council.id, snapshot.data()!);
        }
      } catch (e, stackTrace) {
        AppLogger.error(_tag, 'Could not read cached schedule from Firestore', e, stackTrace);
        // Firestore unreachable — fall back to a stale on-device copy if we
        // have one rather than failing outright.
        if (onDevice != null) return Right(onDevice);
        return Left(ServerFailure('Could not read cached schedule: $e'));
      }

      if (sharedCached != null && !sharedCached.isStale) {
        await localCache.cache(sharedCached);
        return Right(sharedCached);
      }
    }

    // 3. Both caches missing or stale — refresh from the AI model and
    // write back to both cache layers.
    try {
      AppLogger.info(_tag, 'Cache stale/missing for ${council.id} — refreshing via AI...');
      final fresh = await aiDataSource.fetchSchedule(council);
      AppLogger.firebase(_tag, 'Writing refreshed schedule to Firestore for ${council.id}');
      await _scheduleDoc(council.id).set(fresh.toJson());
      await firestore.collection('councils').doc(council.id).set({
        'name': council.name,
        'country': council.country.name,
        'lastRefreshedAt': fresh.generatedAt.toIso8601String(),
      }, SetOptions(merge: true));
      await localCache.cache(fresh);
      AppLogger.info(_tag, 'Schedule refreshed and cached for ${council.id}');
      return Right(fresh);
    } catch (e, stackTrace) {
      // AI refresh failed — degrade to whichever stale cached copy we
      // have rather than erroring out.
      final fallback = sharedCached ?? onDevice;
      if (fallback != null) {
        AppLogger.error(_tag, 'Schedule refresh failed, serving stale cache', e, stackTrace);
        return Right(fallback);
      }
      AppLogger.error(_tag, 'Schedule refresh failed, no cache to fall back to', e, stackTrace);
      if (e is Failure) return Left(e);
      return Left(ServerFailure('Could not fetch collection schedule: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> reportCorrection(Council council, String note) async {
    final uid = deviceIdentityService.currentDeviceId;
    if (uid == null) {
      return const Left(UnexpectedFailure('Device is not signed in yet.'));
    }
    final trimmedNote = note.trim();
    if (trimmedNote.isEmpty) {
      return const Left(UnexpectedFailure('Correction note cannot be empty.'));
    }

    try {
      final correctionsRef =
          firestore.collection('councils').doc(council.id).collection('corrections');

      final pendingMatches = await correctionsRef
          .where('status', isEqualTo: 'pending')
          .where('note', isEqualTo: trimmedNote)
          .get();
      final fromOtherDevices =
          pendingMatches.docs.where((d) => d.data()['reportedBy'] != uid).toList();

      final batch = firestore.batch();
      if (fromOtherDevices.isNotEmpty) {
        // A second, independent device reported the same issue — treat the
        // cached schedule as disputed so it's regenerated on next read,
        // rather than trusting free-text input as ground truth directly.
        for (final doc in fromOtherDevices) {
          batch.update(doc.reference, {'status': 'applied'});
        }
        batch.set(correctionsRef.doc(), {
          'reportedBy': uid,
          'note': trimmedNote,
          'createdAt': DateTime.now().toIso8601String(),
          'status': 'applied',
        });
        batch.set(
          _scheduleDoc(council.id),
          {'generatedAt': DateTime(2000).toIso8601String()},
          SetOptions(merge: true),
        );
        // This device's own local mirror is cleared immediately; other
        // devices pick up the invalidation once their local cache's own
        // 30-day staleness window elapses or they force-refresh.
        await localCache.clear(council.id);
      } else {
        batch.set(correctionsRef.doc(), {
          'reportedBy': uid,
          'note': trimmedNote,
          'createdAt': DateTime.now().toIso8601String(),
          'status': 'pending',
        });
      }
      AppLogger.firebase(_tag, 'Committing correction batch for ${council.id}');
      await batch.commit();
      AppLogger.firebase(_tag, 'Correction submitted for ${council.id}');
      return const Right(null);
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Could not submit correction', e, stackTrace);
      if (e is Failure) return Left(e);
      return Left(ServerFailure('Could not submit correction: $e'));
    }
  }
}
