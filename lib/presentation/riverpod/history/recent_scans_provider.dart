import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/service_locator.dart';
import '../../../domain/entities/scan_record.dart';
import '../../../domain/repositories/scan_history_repository.dart';
import '../onboarding/onboarding_notifier.dart';

/// Re-subscribes whenever the selected council changes, so switching
/// council in Settings immediately hides scans made under a different one.
final recentScansProvider = StreamProvider<List<ScanRecord>>((ref) {
  final council = ref.watch(onboardingProvider).selectedCouncil;
  return sl<ScanHistoryRepository>().watchRecentScans(councilName: council.name);
});
