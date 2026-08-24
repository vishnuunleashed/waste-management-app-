import 'bin_assignment.dart';

/// Which path produced a classification — surfaced to the user (Result
/// screen, scan history) so they know when they're seeing a lower-accuracy
/// on-device result vs. the cloud model.
enum ClassificationSource { cloud, local }

class WasteItem {
  final String objectName;
  final String materialType;
  final String condition;
  final double confidenceScore;
  final String? imagePath;
  final BinAssignment binAssignment;
  final ClassificationSource source;

  const WasteItem({
    required this.objectName,
    required this.materialType,
    required this.condition,
    required this.confidenceScore,
    required this.binAssignment,
    this.imagePath,
    this.source = ClassificationSource.cloud,
  });

  @override
  String toString() =>
      'WasteItem(object: $objectName, material: $materialType, condition: $condition, score: $confidenceScore, source: ${source.name})';
}
