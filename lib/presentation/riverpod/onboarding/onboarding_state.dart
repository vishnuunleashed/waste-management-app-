import '../../../data/datasources/local/onboarding_prefs_datasource.dart';
import '../../../domain/entities/council.dart';

class OnboardingState {
  final bool isLoading;
  final bool isCompleted;
  final Council selectedCouncil;

  const OnboardingState({
    required this.isLoading,
    required this.isCompleted,
    required this.selectedCouncil,
  });

  factory OnboardingState.initial() => const OnboardingState(
        isLoading: true,
        isCompleted: false,
        selectedCouncil: OnboardingPrefsDataSourceImpl.defaultCouncil,
      );

  OnboardingState copyWith({
    bool? isLoading,
    bool? isCompleted,
    Council? selectedCouncil,
  }) {
    return OnboardingState(
      isLoading: isLoading ?? this.isLoading,
      isCompleted: isCompleted ?? this.isCompleted,
      selectedCouncil: selectedCouncil ?? this.selectedCouncil,
    );
  }
}
