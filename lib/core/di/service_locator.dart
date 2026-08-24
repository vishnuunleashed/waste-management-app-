import 'package:get_it/get_it.dart';
import '../../data/datasources/local/council_rules_datasource.dart';
import '../../data/datasources/local/local_vision_datasource.dart';
import '../../data/datasources/local/offline_prefs_datasource.dart';
import '../../data/datasources/local/onboarding_prefs_datasource.dart';
import '../../data/datasources/local/pending_scan_queue_datasource.dart';
import '../../data/datasources/local/schedule_local_cache_datasource.dart';
import '../../data/datasources/local/theme_prefs_datasource.dart';
import '../../data/datasources/remote/council_lookup_datasource.dart';
import '../../data/datasources/remote/openrouter_vision_datasource.dart';
import '../../data/datasources/remote/schedule_ai_datasource.dart';
import '../../data/repositories_impl/council_schedule_repository_impl.dart';
import '../../data/repositories_impl/scan_history_repository_impl.dart';
import '../../data/repositories_impl/waste_repository_impl.dart';
import '../../domain/repositories/council_schedule_repository.dart';
import '../../domain/repositories/scan_history_repository.dart';
import '../../domain/repositories/waste_repository.dart';
import '../../domain/usecases/classify_waste_image.dart';
import '../services/connectivity_service.dart';
import '../services/device_identity_service.dart';
import '../utils/device_capability_service.dart';

/// Global GetIt instance
final sl = GetIt.instance;

/// Initialize all GetIt service locator singletons
Future<void> setupServiceLocator() async {
  // Utilities & Device Services
  sl.registerLazySingleton<DeviceCapabilityService>(
    () => DeviceCapabilityService(),
  );
  sl.registerLazySingleton<DeviceIdentityService>(
    () => DeviceIdentityServiceImpl(),
  );
  sl.registerLazySingleton<ConnectivityService>(
    () => ConnectivityServiceImpl(),
  );

  // Data Sources
  sl.registerLazySingleton<OpenRouterVisionDataSource>(
    () => OpenRouterVisionDataSourceImpl(),
  );
  sl.registerLazySingleton<CouncilRulesDataSource>(
    () => DublinCouncilRulesDataSourceImpl(),
  );
  sl.registerLazySingleton<OnboardingPrefsDataSource>(
    () => OnboardingPrefsDataSourceImpl(),
  );
  sl.registerLazySingleton<ThemePrefsDataSource>(
    () => ThemePrefsDataSourceImpl(),
  );
  sl.registerLazySingleton<CouncilLookupDataSource>(
    () => CouncilLookupDataSourceImpl(),
  );
  sl.registerLazySingleton<ScheduleAiDataSource>(
    () => ScheduleAiDataSourceImpl(),
  );
  sl.registerLazySingleton<ScheduleLocalCacheDataSource>(
    () => ScheduleLocalCacheDataSourceImpl(),
  );
  sl.registerLazySingleton<LocalVisionDataSource>(
    () => LocalVisionDataSourceImpl(),
  );
  sl.registerLazySingleton<OfflinePrefsDataSource>(
    () => OfflinePrefsDataSourceImpl(),
  );
  sl.registerLazySingleton<PendingScanQueueDataSource>(
    () => PendingScanQueueDataSourceImpl(),
  );

  // Repositories
  sl.registerLazySingleton<WasteRepository>(
    () => WasteRepositoryImpl(
      remoteVisionDataSource: sl(),
      localVisionDataSource: sl(),
      localCouncilRulesDataSource: sl(),
      connectivityService: sl(),
      offlinePrefsDataSource: sl(),
    ),
  );
  sl.registerLazySingleton<CouncilScheduleRepository>(
    () => CouncilScheduleRepositoryImpl(
      aiDataSource: sl(),
      deviceIdentityService: sl(),
      localCache: sl(),
    ),
  );
  sl.registerLazySingleton<ScanHistoryRepository>(
    () => ScanHistoryRepositoryImpl(deviceIdentityService: sl(), pendingScanQueue: sl()),
  );

  // Use Cases
  sl.registerLazySingleton<ClassifyWasteImage>(
    () => ClassifyWasteImage(repository: sl()),
  );
}
