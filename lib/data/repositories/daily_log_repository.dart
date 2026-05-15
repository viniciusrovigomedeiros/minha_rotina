import 'package:uuid/uuid.dart';

import '../models/activity_status.dart';
import '../models/daily_activity_log.dart';
import '../services/local_storage_service.dart';

class DailyLogRepository {
  DailyLogRepository({Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final Uuid _uuid;

  Future<List<DailyActivityLog>> getAll() async {
    final values = LocalStorageService.dailyLogsBox.values;
    return values
        .map(
          (entry) => DailyActivityLog.fromMap(Map<String, dynamic>.from(entry)),
        )
        .toList()
      ..sort((a, b) => b.dayKey.compareTo(a.dayKey));
  }

  Future<List<DailyActivityLog>> findByDayKey(String dayKey) async {
    final all = await getAll();
    return all.where((log) => log.dayKey == dayKey).toList();
  }

  Future<DailyActivityLog?> findByActivityAndDay({
    required String activityId,
    required String dayKey,
  }) async {
    final logs = await findByDayKey(dayKey);
    for (final log in logs) {
      if (log.activityId == activityId) return log;
    }
    return null;
  }

  Future<void> saveLog(DailyActivityLog log) async {
    await LocalStorageService.dailyLogsBox.put(log.id, log.toMap());
  }

  Future<DailyActivityLog> upsertStatus({
    required String activityId,
    required String dayKey,
    required ActivityStatus status,
  }) async {
    final existing = await findByActivityAndDay(
      activityId: activityId,
      dayKey: dayKey,
    );

    final now = DateTime.now();
    if (existing != null) {
      final updated = existing.copyWith(status: status, updatedAt: now);
      await saveLog(updated);
      return updated;
    }

    final created = DailyActivityLog(
      id: _uuid.v4(),
      activityId: activityId,
      dayKey: dayKey,
      status: status,
      updatedAt: now,
    );
    await saveLog(created);
    return created;
  }

  Future<void> deleteByActivity(String activityId) async {
    final all = await getAll();
    final ids =
        all
            .where((log) => log.activityId == activityId)
            .map((log) => log.id)
            .toList();

    if (ids.isEmpty) return;
    await LocalStorageService.dailyLogsBox.deleteAll(ids);
  }

  Future<void> clear() async {
    await LocalStorageService.dailyLogsBox.clear();
  }
}
