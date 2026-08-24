import 'package:fpdart/fpdart.dart';
import '../../core/error/failure.dart';
import '../entities/waste_item.dart';
import '../repositories/waste_repository.dart';

class ClassifyWasteImage {
  final WasteRepository repository;

  ClassifyWasteImage({required this.repository});

  Future<Either<Failure, WasteItem>> call(String imagePath, {required String councilName}) {
    return repository.classifyWasteImage(imagePath, councilName: councilName);
  }
}
