import 'dart:convert';

import 'package:hive/hive.dart';

/// Local staging area for scan-history writes that couldn't reach
/// Firestore (typically because the device was offline). Each entry is
/// the same field map `ScanHistoryRepositoryImpl` would otherwise send
/// straight to Firestore, keyed by an insertion-ordered id so a flush can
/// replay them oldest-first.
abstract class PendingScanQueueDataSource {
  Future<void> enqueue(Map<String, dynamic> scanData);
  Map<String, Map<String, dynamic>> getQueued();
  Future<void> remove(String queueId);
}

class PendingScanQueueDataSourceImpl implements PendingScanQueueDataSource {
  static const boxName = 'pending_scan_queue';

  Box<String> get _box => Hive.box<String>(boxName);

  @override
  Future<void> enqueue(Map<String, dynamic> scanData) async {
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    await _box.put(id, jsonEncode(scanData));
  }

  @override
  Map<String, Map<String, dynamic>> getQueued() {
    final result = <String, Map<String, dynamic>>{};
    for (final key in _box.keys) {
      final raw = _box.get(key);
      if (raw == null) continue;
      try {
        result[key as String] = jsonDecode(raw) as Map<String, dynamic>;
      } catch (_) {
        // Corrupt entry — drop it rather than block the rest of the queue.
        _box.delete(key);
      }
    }
    return result;
  }

  @override
  Future<void> remove(String queueId) async {
    await _box.delete(queueId);
  }
}
