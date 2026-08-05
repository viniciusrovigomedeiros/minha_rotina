import '../../data/models/activity.dart';
import '../../data/models/activity_status.dart';
import '../../data/models/daily_activity_log.dart';

class ActivityPlanningUtils {
  const ActivityPlanningUtils._();

  static List<String> plannedActivityIdsForDay({
    required DateTime date,
    required List<Activity> activities,
    required List<DailyActivityLog> logs,
    required bool respectCurrentActiveFlag,
  }) {
    final normalizedDate = _normalize(date);

    return activities
        .where((activity) {
          if (respectCurrentActiveFlag && !activity.isActive) return false;
          if (!_isCreatedBeforeDayEnd(activity, normalizedDate)) return false;

          switch (activity.recurrence) {
            case ActivityRecurrence.daily:
              return true;
            case ActivityRecurrence.weekly:
              return shouldShowFlexibleWeeklyActivity(
                activity: activity,
                date: normalizedDate,
                logs: logs,
              );
            case ActivityRecurrence.weeklyFixed:
              return activity.weekdays.contains(normalizedDate.weekday);
            case ActivityRecurrence.oneOff:
              return _isSameDay(activity.scheduledDate, normalizedDate);
            case ActivityRecurrence.monthly:
              return activity.scheduledDate?.day == normalizedDate.day;
            case ActivityRecurrence.flexible:
              return false;
          }
        })
        .map((activity) => activity.id)
        .toList();
  }

  static bool shouldShowFlexibleWeeklyActivity({
    required Activity activity,
    required DateTime date,
    required List<DailyActivityLog> logs,
  }) {
    if (activity.recurrence != ActivityRecurrence.weekly) return false;
    if (!_isCreatedBeforeDayEnd(activity, date)) return false;

    final normalizedDate = _normalize(date);
    final weekStart = startOfWeek(normalizedDate);
    final previousDay = normalizedDate.subtract(const Duration(days: 1));
    final completedBeforeToday = completedCountForWeekUntilDate(
      activityId: activity.id,
      logs: logs,
      weekStart: weekStart,
      weekEnd: weekStart.add(const Duration(days: 6)),
      endDate: previousDay,
    );
    final dayKey = _toDayKey(normalizedDate);
    final hasLogForDay = logs.any(
      (log) => log.activityId == activity.id && log.dayKey == dayKey,
    );

    return hasLogForDay ||
        completedBeforeToday < activity.effectiveWeeklyTargetCount;
  }

  static int completedCountForWeekUntilDate({
    required String activityId,
    required List<DailyActivityLog> logs,
    required DateTime weekStart,
    required DateTime weekEnd,
    required DateTime endDate,
  }) {
    final normalizedWeekStart = _normalize(weekStart);
    final normalizedWeekEnd = _normalize(weekEnd);
    final normalizedEndDate = _normalize(endDate);

    return logs.where((log) {
      if (log.activityId != activityId ||
          log.status != ActivityStatus.completed) {
        return false;
      }
      final logDate = _fromDayKey(log.dayKey);
      return !logDate.isBefore(normalizedWeekStart) &&
          !logDate.isAfter(normalizedWeekEnd) &&
          !logDate.isAfter(normalizedEndDate);
    }).length;
  }

  static DateTime startOfWeek(DateTime date) {
    final normalized = _normalize(date);
    return normalized.subtract(Duration(days: normalized.weekday - 1));
  }

  static bool isCreatedBeforeDayEnd(Activity activity, DateTime date) {
    return _isCreatedBeforeDayEnd(activity, date);
  }

  static DateTime _normalize(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static bool _isCreatedBeforeDayEnd(Activity activity, DateTime date) {
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
    return !activity.createdAt.isAfter(endOfDay);
  }

  static bool _isSameDay(DateTime? a, DateTime b) {
    if (a == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static String _toDayKey(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  static DateTime _fromDayKey(String key) {
    final parts = key.split('-');
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }
}
