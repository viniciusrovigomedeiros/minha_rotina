import '../../core/utils/activity_planning_utils.dart';
import '../../core/utils/date_utils.dart';
import '../models/activity.dart';
import '../models/daily_activity_log.dart';
import '../models/daily_plan_snapshot.dart';
import '../services/local_storage_service.dart';

class DailyPlanRepository {
  DailyPlanRepository();

  Future<List<DailyPlanSnapshot>> getAll() async {
    final values = LocalStorageService.dailyPlansBox.values;
    return values
        .map(
          (entry) =>
              DailyPlanSnapshot.fromMap(Map<String, dynamic>.from(entry)),
        )
        .toList()
      ..sort((a, b) => b.dayKey.compareTo(a.dayKey));
  }

  Future<DailyPlanSnapshot?> findByDayKey(String dayKey) async {
    final raw = LocalStorageService.dailyPlansBox.get(dayKey);
    if (raw == null) return null;
    return DailyPlanSnapshot.fromMap(Map<String, dynamic>.from(raw));
  }

  Future<void> save(DailyPlanSnapshot snapshot) async {
    await LocalStorageService.dailyPlansBox.put(
      snapshot.dayKey,
      snapshot.toMap(),
    );
  }

  Future<void> clear() async {
    await LocalStorageService.dailyPlansBox.clear();
  }

  Future<DailyPlanSnapshot> snapshotForDay({
    required DateTime date,
    required List<Activity> activities,
    required List<DailyActivityLog> logs,
  }) async {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);
    final dayKey = DateUtilsX.toDayKey(normalizedDate);

    if (normalizedDate.isAfter(normalizedToday)) {
      return _buildSnapshot(
        dayKey: dayKey,
        activityIds: ActivityPlanningUtils.plannedActivityIdsForDay(
          date: normalizedDate,
          activities: activities,
          logs: logs,
          respectCurrentActiveFlag: true,
        ),
      );
    }

    if (normalizedDate.isAtSameMomentAs(normalizedToday)) {
      final snapshot = _buildSnapshot(
        dayKey: dayKey,
        activityIds: ActivityPlanningUtils.plannedActivityIdsForDay(
          date: normalizedDate,
          activities: activities,
          logs: logs,
          respectCurrentActiveFlag: true,
        ),
      );
      await save(snapshot);
      return snapshot;
    }

    final existing = await findByDayKey(dayKey);
    final derivedActivityIds = ActivityPlanningUtils.plannedActivityIdsForDay(
      date: normalizedDate,
      activities: activities,
      logs: logs,
      respectCurrentActiveFlag: false,
    );
    if (existing != null) {
      final existingIds = [...existing.activityIds]..sort();
      final derivedIds = [...derivedActivityIds]..sort();
      if (_sameIds(existingIds, derivedIds)) return existing;

      final refreshed = _buildSnapshot(
        dayKey: dayKey,
        activityIds: derivedActivityIds,
      );
      await save(refreshed);
      return refreshed;
    }

    final snapshot = _buildSnapshot(
      dayKey: dayKey,
      activityIds: derivedActivityIds,
    );
    await save(snapshot);
    return snapshot;
  }

  DailyPlanSnapshot _buildSnapshot({
    required String dayKey,
    required List<String> activityIds,
  }) {
    return DailyPlanSnapshot(
      dayKey: dayKey,
      activityIds: activityIds,
      updatedAt: DateTime.now(),
    );
  }

  bool _sameIds(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int index = 0; index < a.length; index++) {
      if (a[index] != b[index]) return false;
    }
    return true;
  }
}
