import 'package:fpdart/fpdart.dart';

import '../../core/error/failure.dart';
import '../../core/services/connectivity_service.dart';
import '../../core/utils/app_logger.dart';
import '../../domain/entities/waste_item.dart';
import '../../domain/repositories/waste_repository.dart';
import '../datasources/local/council_rules_datasource.dart';
import '../datasources/local/local_vision_datasource.dart';
import '../datasources/local/offline_prefs_datasource.dart';
import '../datasources/remote/openrouter_vision_datasource.dart';

const _tag = 'WasteRepository';

class WasteRepositoryImpl implements WasteRepository {
  final OpenRouterVisionDataSource remoteVisionDataSource;
  final LocalVisionDataSource localVisionDataSource;
  final CouncilRulesDataSource localCouncilRulesDataSource;
  final ConnectivityService connectivityService;
  final OfflinePrefsDataSource offlinePrefsDataSource;

  WasteRepositoryImpl({
    required this.remoteVisionDataSource,
    required this.localVisionDataSource,
    required this.localCouncilRulesDataSource,
    required this.connectivityService,
    required this.offlinePrefsDataSource,
  });

  @override
  Future<Either<Failure, WasteItem>> classifyWasteImage(
    String imagePath, {
    required String councilName,
  }) async {
    try {
      final isOnline = await connectivityService.hasConnectivity();
      final offlineEnabled = await offlinePrefsDataSource.isOfflineScanEnabled();
      AppLogger.info(
          _tag, 'classifyWasteImage — online=$isOnline offlineEnabled=$offlineEnabled');

      RawVisionAnalysis rawAnalysis;
      ClassificationSource source;

      if (isOnline) {
        try {
          AppLogger.info(_tag, 'Trying cloud classification (OpenRouter)...');
          rawAnalysis = await remoteVisionDataSource.analyzeImage(imagePath);
          source = ClassificationSource.cloud;
        } catch (e) {
          AppLogger.error(_tag, 'Cloud classification failed, falling back to local if available', e);
          if (!offlineEnabled) rethrow;
          AppLogger.info(_tag, 'Falling back to on-device classification...');
          rawAnalysis = await localVisionDataSource.analyzeImage(imagePath);
          source = ClassificationSource.local;
        }
      } else {
        if (!offlineEnabled) {
          AppLogger.error(_tag, 'Offline and offline scanning is disabled — cannot classify');
          return const Left(ServerFailure(
            'No internet connection. Enable offline scanning in Settings to scan without '
            'connectivity.',
          ));
        }
        AppLogger.info(_tag, 'Offline — using on-device classification...');
        rawAnalysis = await localVisionDataSource.analyzeImage(imagePath);
        source = ClassificationSource.local;
      }

      // Map object + material + condition to a bin assignment
      final binAssignment = localCouncilRulesDataSource.resolveBin(
        objectName: rawAnalysis.objectName,
        materialType: rawAnalysis.materialType,
        condition: rawAnalysis.condition,
        binCategory: rawAnalysis.binCategory,
        councilName: councilName,
      );

      final wasteItem = WasteItem(
        objectName: rawAnalysis.objectName,
        materialType: rawAnalysis.materialType,
        condition: rawAnalysis.condition,
        confidenceScore: rawAnalysis.confidenceScore,
        imagePath: imagePath,
        binAssignment: binAssignment,
        source: source,
      );

      AppLogger.info(_tag,
          'Classification complete — source=${source.name} bin=${binAssignment.binType.name}');
      return Right(wasteItem);
    } catch (e, stackTrace) {
      if (e is Failure) {
        AppLogger.error(_tag, 'Classification failed', e, stackTrace);
        return Left(e);
      }
      AppLogger.error(_tag, 'Classification failed (unexpected)', e, stackTrace);
      return Left(ServerFailure('Classification failed: $e'));
    }
  }
}
