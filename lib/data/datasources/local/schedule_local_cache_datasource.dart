import 'dart:convert';

import 'package:hive/hive.dart';

import '../../../domain/entities/collection_schedule.dart';

/// Local (on-device) mirror of the shared Firestore schedule cache, so the
/// Collection Schedule screen can render instantly and work offline
/// without waiting on a network round-trip on every app start.
abstract class ScheduleLocalCacheDataSource {
  CollectionSchedule? getCached(String councilId);
  Future<void> cache(CollectionSchedule schedule);
  Future<void> clear(String councilId);
}

class ScheduleLocalCacheDataSourceImpl implements ScheduleLocalCacheDataSource {
  static const boxName = 'collection_schedule_cache';

  Box<String> get _box => Hive.box<String>(boxName);

  @override
  CollectionSchedule? getCached(String councilId) {
    final raw = _box.get(councilId);
    if (raw == null) return null;
    try {
      return CollectionSchedule.fromJson(councilId, jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> cache(CollectionSchedule schedule) async {
    await _box.put(schedule.councilId, jsonEncode(schedule.toJson()));
  }

  @override
  Future<void> clear(String councilId) async {
    await _box.delete(councilId);
  }
}
