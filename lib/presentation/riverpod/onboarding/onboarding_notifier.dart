import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/di/service_locator.dart';
import '../../../data/datasources/local/onboarding_prefs_datasource.dart';
import '../../../domain/entities/council.dart';
import 'onboarding_state.dart';

class OnboardingNotifier extends Notifier<OnboardingState> {
  @override
  OnboardingState build() {
    _load();
    return OnboardingState.initial();
  }

  Future<void> _load() async {
    final prefsDataSource = sl<OnboardingPrefsDataSource>();
    final completed = await prefsDataSource.hasCompletedOnboarding();
    final council = await prefsDataSource.getSelectedCouncil();
    state = state.copyWith(
      isLoading: false,
      isCompleted: completed,
      selectedCouncil: council,
    );
  }

  Future<void> selectCouncil(Council council) async {
    state = state.copyWith(selectedCouncil: council);
    await sl<OnboardingPrefsDataSource>().setSelectedCouncil(council);
  }

  Future<void> completeOnboarding() async {
    await sl<OnboardingPrefsDataSource>().setOnboardingCompleted();
    state = state.copyWith(isCompleted: true);
  }
}

final onboardingProvider =
    NotifierProvider<OnboardingNotifier, OnboardingState>(() {
  return OnboardingNotifier();
});
