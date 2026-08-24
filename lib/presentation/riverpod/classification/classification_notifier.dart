import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/di/service_locator.dart';
import '../../../domain/usecases/classify_waste_image.dart';
import '../onboarding/onboarding_notifier.dart';
import 'classification_state.dart';

class ClassificationNotifier extends FamilyNotifier<ClassificationState, String> {
  @override
  ClassificationState build(String arg) {
    _runClassification(arg);
    return const ClassificationState(
      isLoading: true,
      statusMessage: 'Scanning item...',
    );
  }

  Future<void> _runClassification(String imagePath) async {
    final classifyUseCase = sl<ClassifyWasteImage>();
    final councilName = ref.read(onboardingProvider).selectedCouncil.name;
    final result = await classifyUseCase(imagePath, councilName: councilName);

    result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: failure.message,
        );
      },
      (wasteItem) {
        state = state.copyWith(
          isLoading: false,
          wasteItem: wasteItem,
        );
      },
    );
  }
}

final classificationProvider =
    NotifierProvider.family<ClassificationNotifier, ClassificationState, String>(() {
  return ClassificationNotifier();
});
