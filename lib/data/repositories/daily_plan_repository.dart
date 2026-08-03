import '../../core/utils/date_utils.dart';
import '../models/activity.dart';
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
  }) async {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);
    final dayKey = DateUtilsX.toDayKey(normalizedDate);

    if (normalizedDate.isAfter(normalizedToday)) {
      return _buildSnapshot(
        dayKey: dayKey,
        activityIds: _derivePlannedActivityIds(
          date: normalizedDate,
          activities: activities,
          respectCurrentActiveFlag: true,
        ),
      );
    }

    if (normalizedDate.isAtSameMomentAs(normalizedToday)) {
      final snapshot = _buildSnapshot(
        dayKey: dayKey,
        activityIds: _derivePlannedActivityIds(
          date: normalizedDate,
          activities: activities,
          respectCurrentActiveFlag: true,
        ),
      );
      await save(snapshot);
      return snapshot;
    }

    final existing = await findByDayKey(dayKey);
    if (existing != null) return existing;

    final snapshot = _buildSnapshot(
      dayKey: dayKey,
      activityIds: _derivePlannedActivityIds(
        date: normalizedDate,
        activities: activities,
        respectCurrentActiveFlag: false,
      ),
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

  List<String> _derivePlannedActivityIds({
    required DateTime date,
    required List<Activity> activities,
    required bool respectCurrentActiveFlag,
  }) {
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59, 999);

    return activities
        .where((activity) {
          if (respectCurrentActiveFlag && !activity.isActive) return false;
          if (activity.createdAt.isAfter(endOfDay)) return false;

          switch (activity.recurrence) {
            case ActivityRecurrence.daily:
              return true;
            case ActivityRecurrence.weeklyFixed:
              return activity.weekdays.contains(date.weekday);
            case ActivityRecurrence.oneOff:
              final scheduled = activity.scheduledDate;
              return scheduled != null &&
                  scheduled.year == date.year &&
                  scheduled.month == date.month &&
                  scheduled.day == date.day;
            case ActivityRecurrence.monthly:
              return activity.scheduledDate?.day == date.day;
            case ActivityRecurrence.weekly:
            case ActivityRecurrence.flexible:
              return false;
          }
        })
        .map((activity) => activity.id)
        .toList();
  }
}
