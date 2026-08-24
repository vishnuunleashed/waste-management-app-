import '../../../domain/entities/waste_item.dart';

class ClassificationState {
  final bool isLoading;
  final String statusMessage;
  final WasteItem? wasteItem;
  final String? errorMessage;

  const ClassificationState({
    required this.isLoading,
    required this.statusMessage,
    this.wasteItem,
    this.errorMessage,
  });

  ClassificationState copyWith({
    bool? isLoading,
    String? statusMessage,
    WasteItem? wasteItem,
    String? errorMessage,
  }) {
    return ClassificationState(
      isLoading: isLoading ?? this.isLoading,
      statusMessage: statusMessage ?? this.statusMessage,
      wasteItem: wasteItem ?? this.wasteItem,
      errorMessage: errorMessage,
    );
  }
}
