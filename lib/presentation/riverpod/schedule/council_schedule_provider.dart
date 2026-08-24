import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/service_locator.dart';
import '../../../core/error/failure.dart';
import '../../../domain/entities/collection_schedule.dart';
import '../../../domain/repositories/council_schedule_repository.dart';
import '../onboarding/onboarding_notifier.dart';

/// Loads (and, if stale, silently refreshes via AI) the collection
/// schedule for the currently selected council. Rebuilds automatically
/// whenever the selected council changes.
class CouncilScheduleNotifier extends AsyncNotifier<CollectionSchedule> {
  @override
  Future<CollectionSchedule> build() async {
    final council = ref.watch(onboardingProvider).selectedCouncil;
    final result = await sl<CouncilScheduleRepository>().getSchedule(council);
    return result.match((failure) => throw failure, (schedule) => schedule);
  }

  /// Retries after a failed load. Bypasses both cache layers, but since a
  /// failed [build] never populated them, this can't discard a valid
  /// cached schedule — there isn't one yet. Deliberately not exposed as a
  /// general "refresh" action elsewhere: since there's no real data source
  /// for UK/Ireland bin schedules, re-asking the AI for an already-cached,
  /// non-stale schedule just replaces one fabricated answer with a
  /// different one, which is exactly the inconsistency users would see.
  Future<void> refresh() async {
    final council = ref.read(onboardingProvider).selectedCouncil;
    state = const AsyncLoading<CollectionSchedule>().copyWithPrevious(state);
    state = await AsyncValue.guard(() async {
      final result =
          await sl<CouncilScheduleRepository>().getSchedule(council, forceRefresh: true);
      return result.match((failure) => throw failure, (schedule) => schedule);
    });
  }

  Future<Failure?> reportCorrection(String note) async {
    final council = ref.read(onboardingProvider).selectedCouncil;
    final result = await sl<CouncilScheduleRepository>().reportCorrection(council, note);
    return result.match((failure) => failure, (_) => null);
  }
}

final councilScheduleProvider =
    AsyncNotifierProvider<CouncilScheduleNotifier, CollectionSchedule>(() {
  return CouncilScheduleNotifier();
});
