import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/di/service_locator.dart';
import 'core/services/connectivity_service.dart';
import 'core/services/device_identity_service.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/app_logger.dart';
import 'data/datasources/local/pending_scan_queue_datasource.dart';
import 'data/datasources/local/schedule_local_cache_datasource.dart';
import 'domain/repositories/scan_history_repository.dart';
import 'firebase_options.dart';
import 'presentation/app_root.dart';
import 'presentation/common/theme_notifier.dart';

const _tag = 'Main';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  AppLogger.info(_tag, 'Initializing Firebase...');
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  AppLogger.info(_tag, 'Initializing Hive...');
  await Hive.initFlutter();
  await Hive.openBox<String>(ScheduleLocalCacheDataSourceImpl.boxName);
  await Hive.openBox<String>(PendingScanQueueDataSourceImpl.boxName);

  // Load environment configuration (.env)
  try {
    await dotenv.load(fileName: '.env');
    AppLogger.info(_tag, '.env loaded');
  } catch (e, stackTrace) {
    AppLogger.error(_tag, '.env file not loaded or empty', e, stackTrace);
  }

  // Initialize GetIt service locator
  await setupServiceLocator();
  AppLogger.info(_tag, 'Service locator ready');

  // Sign in anonymously (if not already) so this install has a stable,
  // unique device identity without requiring any login UI.
  try {
    final uid = await sl<DeviceIdentityService>().ensureDeviceId();
    AppLogger.info(_tag, 'Device identity ready: $uid');
  } catch (e, stackTrace) {
    AppLogger.error(_tag, 'Anonymous sign-in failed', e, stackTrace);
  }

  // Flush any scans queued while offline as soon as the app starts, and
  // again every time connectivity comes back.
  sl<ScanHistoryRepository>().flushPendingScans();
  sl<ConnectivityService>().onConnectivityChanged.listen((hasConnectivity) {
    AppLogger.info(_tag, 'Connectivity changed: $hasConnectivity');
    if (hasConnectivity) sl<ScanHistoryRepository>().flushPendingScans();
  });

  AppLogger.info(_tag, 'Starting app UI');
  runApp(
    const ProviderScope(
      child: WasteClassifierApp(),
    ),
  );
}

class WasteClassifierApp extends ConsumerWidget {
  const WasteClassifierApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      title: 'Waste Classifier App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: const AppRoot(),
    );
  }
}

