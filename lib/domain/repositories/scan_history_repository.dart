import 'package:fpdart/fpdart.dart';

import '../../core/error/failure.dart';
import '../entities/scan_record.dart';
import '../entities/waste_item.dart';

abstract class ScanHistoryRepository {
  /// Persists a successful classification to this device's scan history.
  Future<Either<Failure, void>> saveScan(WasteItem item);

  /// Live view of this device's scans from the last [scanHistoryRetention]
  /// window, newest first. When [councilName] is given, only scans made
  /// under that council are included — switching council hides (not
  /// deletes) scans made under a previous one.
  Stream<List<ScanRecord>> watchRecentScans({int limit = 20, String? councilName});

  /// Uploads any scans that were saved while offline (see
  /// `PendingScanQueueDataSource`) to Firestore. Safe to call whenever
  /// connectivity returns — entries that still fail stay queued for the
  /// next attempt.
  Future<void> flushPendingScans();
}
