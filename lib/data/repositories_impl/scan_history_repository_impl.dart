import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fpdart/fpdart.dart';

import '../../core/error/failure.dart';
import '../../core/services/device_identity_service.dart';
import '../../core/utils/app_logger.dart';
import '../../domain/entities/bin_assignment.dart';
import '../../domain/entities/scan_record.dart';
import '../../domain/entities/waste_item.dart';
import '../../domain/repositories/scan_history_repository.dart';
import '../datasources/local/pending_scan_queue_datasource.dart';

const _tag = 'ScanHistory';

class ScanHistoryRepositoryImpl implements ScanHistoryRepository {
  final FirebaseFirestore firestore;
  final DeviceIdentityService deviceIdentityService;
  final PendingScanQueueDataSource pendingScanQueue;

  ScanHistoryRepositoryImpl({
    required this.deviceIdentityService,
    required this.pendingScanQueue,
    FirebaseFirestore? firestore,
  }) : firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>>? _historyCollection() {
    final deviceId = deviceIdentityService.currentDeviceId;
    if (deviceId == null) return null;
    return firestore.collection('devices').doc(deviceId).collection('scanHistory');
  }

  Map<String, dynamic> _toFieldMap(WasteItem item, DateTime scannedAt) {
    return {
      'objectName': item.objectName,
      'materialType': item.materialType,
      'condition': item.condition,
      'confidenceScore': item.confidenceScore,
      'binType': item.binAssignment.binType.name,
      'localBinName': item.binAssignment.localBinName,
      'binColorValue': item.binAssignment.binColor.toARGB32(),
      'primaryCategory': item.binAssignment.primaryCategory,
      'councilName': item.binAssignment.councilName,
      'disposalSteps': item.binAssignment.disposalSteps,
      'source': item.source.name,
      // Stored as an ISO string (not FieldValue.serverTimestamp()) here
      // because this same map may sit in the local pending queue for a
      // while before it ever reaches Firestore — serverTimestamp only
      // makes sense at the moment of an actual write.
      'scannedAtIso': scannedAt.toIso8601String(),
      'expireAtIso': scannedAt.add(scanHistoryRetention).toIso8601String(),
    };
  }

  @override
  Future<Either<Failure, void>> saveScan(WasteItem item) async {
    final collection = _historyCollection();
    if (collection == null) {
      return const Left(UnexpectedFailure('Device is not signed in yet.'));
    }
    final scannedAt = DateTime.now();
    final fields = _toFieldMap(item, scannedAt);

    try {
      AppLogger.firebase(_tag, 'Saving scan to Firestore: ${item.objectName}');
      await collection.add({
        ...fields,
        'scannedAt': Timestamp.fromDate(scannedAt),
        'expireAt': Timestamp.fromDate(scannedAt.add(scanHistoryRetention)),
      });
      AppLogger.firebase(_tag, 'Scan saved to Firestore');
      return const Right(null);
    } catch (e, stackTrace) {
      // Most likely offline — queue it locally instead of losing the
      // scan; it'll upload next time connectivity returns.
      AppLogger.error(_tag, 'Firestore save failed, queuing locally', e, stackTrace);
      try {
        await pendingScanQueue.enqueue(fields);
        AppLogger.info(_tag, 'Scan queued locally (offline)');
        return const Right(null);
      } catch (queueError, queueStackTrace) {
        AppLogger.error(_tag, 'Could not queue scan locally either', queueError, queueStackTrace);
        return Left(ServerFailure('Could not save scan to history: $queueError'));
      }
    }
  }

  @override
  Future<void> flushPendingScans() async {
    final collection = _historyCollection();
    if (collection == null) return;

    final queued = pendingScanQueue.getQueued();
    if (queued.isEmpty) return;
    AppLogger.firebase(_tag, 'Flushing ${queued.length} queued scan(s) to Firestore...');

    for (final entry in queued.entries) {
      try {
        final data = entry.value;
        final scannedAt = DateTime.parse(data['scannedAtIso'] as String);
        final expireAt = DateTime.parse(data['expireAtIso'] as String);
        await collection.add({
          ...data,
          'scannedAt': Timestamp.fromDate(scannedAt),
          'expireAt': Timestamp.fromDate(expireAt),
        });
        await pendingScanQueue.remove(entry.key);
        AppLogger.firebase(_tag, 'Flushed queued scan ${entry.key}');
      } catch (e) {
        AppLogger.error(_tag, 'Still offline, keeping scan queued', e);
        // Leave it queued — stop here, connectivity likely still down for
        // the rest of the batch too.
        return;
      }
    }
  }

  @override
  Stream<List<ScanRecord>> watchRecentScans({int limit = 20, String? councilName}) {
    final collection = _historyCollection();
    if (collection == null) {
      AppLogger.error(_tag, 'watchRecentScans: device not signed in yet — showing queued only');
      return Stream.value(_queuedAsRecords(councilName));
    }

    final cutoff = Timestamp.fromDate(DateTime.now().subtract(scanHistoryRetention));
    AppLogger.firebase(
        _tag, 'Watching scan history (cutoff=${cutoff.toDate()}, council=$councilName)');

    return collection
        .where('scannedAt', isGreaterThan: cutoff)
        .orderBy('scannedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      AppLogger.firebase(_tag, 'Scan history snapshot: ${snapshot.docs.length} doc(s)');
      // Filtered in Dart rather than via a Firestore `where('councilName', ...)`
      // clause — combining that with the scannedAt range+orderBy above would
      // need a composite index; retention already caps this to a small
      // window, so client-side filtering is cheap.
      final synced = snapshot.docs
          .where((doc) => doc.data()['scannedAt'] != null)
          .map((doc) => _fromDoc(doc.id, doc.data()))
          .where((record) => councilName == null || record.councilName == councilName)
          .toList();
      // Show still-queued (not-yet-synced) scans too, newest first, ahead
      // of the synced ones, so a fully-offline scan is visible immediately.
      return [..._queuedAsRecords(councilName), ...synced];
    }).handleError((Object e, StackTrace stackTrace) {
      AppLogger.error(_tag, 'watchRecentScans stream error', e, stackTrace);
      throw e;
    });
  }

  List<ScanRecord> _queuedAsRecords(String? councilName) {
    final queued = pendingScanQueue.getQueued();
    final records = queued.entries
        .map((e) => _fromDoc('pending_${e.key}', e.value))
        .where((record) => councilName == null || record.councilName == councilName)
        .toList();
    records.sort((a, b) => b.scannedAt.compareTo(a.scannedAt));
    return records;
  }

  ScanRecord _fromDoc(String id, Map<String, dynamic> data) {
    final scannedAt = data['scannedAt'] is Timestamp
        ? (data['scannedAt'] as Timestamp).toDate()
        : DateTime.parse(data['scannedAtIso'] as String);
    final expireAt = data['expireAt'] is Timestamp
        ? (data['expireAt'] as Timestamp).toDate()
        : DateTime.tryParse(data['expireAtIso'] as String? ?? '');
    return ScanRecord(
      id: id,
      objectName: data['objectName'] as String? ?? 'Unknown item',
      materialType: data['materialType'] as String? ?? '',
      condition: data['condition'] as String? ?? '',
      confidenceScore: (data['confidenceScore'] as num?)?.toDouble() ?? 0,
      binType: BinType.values.firstWhere(
        (t) => t.name == data['binType'],
        orElse: () => BinType.blackGeneral,
      ),
      localBinName: data['localBinName'] as String? ?? 'General Waste',
      binColor: Color(data['binColorValue'] as int? ?? 0xFF334155),
      primaryCategory: data['primaryCategory'] as String? ?? '',
      councilName: data['councilName'] as String? ?? '',
      disposalSteps: (data['disposalSteps'] as List?)?.cast<String>() ?? const [],
      scannedAt: scannedAt,
      expireAt: expireAt ?? scannedAt.add(scanHistoryRetention),
      source: ClassificationSource.values.firstWhere(
        (s) => s.name == data['source'],
        orElse: () => ClassificationSource.cloud,
      ),
    );
  }
}
