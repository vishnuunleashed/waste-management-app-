import 'package:fpdart/fpdart.dart';

import '../../core/error/failure.dart';
import '../entities/collection_schedule.dart';
import '../entities/council.dart';

abstract class CouncilScheduleRepository {
  /// Returns the cached schedule for [council] if it's fresh (<30 days
  /// old); otherwise fetches a new one from the AI model and caches it in
  /// Firestore so every device/login sees the same data until the next
  /// refresh. Pass [forceRefresh] to bypass both cache layers (e.g. a
  /// user-triggered "Refresh" action).
  Future<Either<Failure, CollectionSchedule>> getSchedule(
    Council council, {
    bool forceRefresh = false,
  });

  /// Reports that the currently cached schedule for [council] looks wrong.
  /// A second, independent report (different device) invalidates the
  /// cache so it's regenerated on the next read.
  Future<Either<Failure, void>> reportCorrection(Council council, String note);
}
