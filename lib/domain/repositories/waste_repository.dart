import 'package:fpdart/fpdart.dart';
import '../../core/error/failure.dart';
import '../entities/waste_item.dart';

abstract class WasteRepository {
  Future<Either<Failure, WasteItem>> classifyWasteImage(String imagePath, {required String councilName});
}
