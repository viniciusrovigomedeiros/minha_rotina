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
            case ActivityRecurrence.weeklyFixed:
              return shouldCountFlexibleWeeklyActivityForDay(
                activity: activity,
                date: normalizedDate,
                logs: logs,
              );
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

  static bool shouldShowInWeeklyGoalsSection({
    required Activity activity,
    required DateTime date,
    required List<DailyActivityLog> logs,
  }) {
    final normalizedDate = _normalize(date);
    final weekStart = startOfWeek(normalizedDate);
    final weekEnd = weekStart.add(const Duration(days: 6));

    if (!activity.isActive || !_isCreatedBeforeDayEnd(activity, weekEnd)) {
      return false;
    }

    final targetCount = weeklyTargetCountForActivity(
      activity: activity,
      date: normalizedDate,
    );
    if (targetCount <= 0) return false;

    final completedUntilToday = completedCountForWeekUntilDate(
      activityId: activity.id,
      logs: logs,
      weekStart: weekStart,
      weekEnd: weekEnd,
      endDate: normalizedDate,
    );

    return completedUntilToday < targetCount ||
        _hasCompletedOnDay(
          activityId: activity.id,
          date: normalizedDate,
          logs: logs,
        );
  }

  static int weeklyTargetCountForActivity({
    required Activity activity,
    required DateTime date,
  }) {
    final normalizedDate = _normalize(date);
    final weekStart = startOfWeek(normalizedDate);
    final weekEnd = weekStart.add(const Duration(days: 6));

    switch (activity.recurrence) {
      case ActivityRecurrence.daily:
        final createdStart = _normalize(activity.createdAt);
        final effectiveStart =
            createdStart.isAfter(weekStart) ? createdStart : weekStart;
        if (effectiveStart.isAfter(weekEnd)) return 0;
        return weekEnd.difference(effectiveStart).inDays + 1;
      case ActivityRecurrence.weekly:
        return activity.effectiveWeeklyTargetCount;
      case ActivityRecurrence.weeklyFixed:
        int count = 0;
        for (
          DateTime cursor = weekStart;
          !cursor.isAfter(weekEnd);
          cursor = cursor.add(const Duration(days: 1))
        ) {
          if (activity.weekdays.contains(cursor.weekday) &&
              _isCreatedBeforeDayEnd(activity, cursor)) {
            count++;
          }
        }
        return count;
      case ActivityRecurrence.oneOff:
        final scheduledDate = activity.scheduledDate;
        if (scheduledDate == null) return 0;
        final normalizedScheduled = _normalize(scheduledDate);
        if (normalizedScheduled.isBefore(weekStart) ||
            normalizedScheduled.isAfter(weekEnd) ||
            !_isCreatedBeforeDayEnd(activity, normalizedScheduled)) {
          return 0;
        }
        return 1;
      case ActivityRecurrence.monthly:
        final occurrenceDate = _monthlyOccurrenceDateInWeek(
          activity: activity,
          weekStart: weekStart,
          weekEnd: weekEnd,
        );
        if (occurrenceDate == null ||
            !_isCreatedBeforeDayEnd(activity, occurrenceDate)) {
          return 0;
        }
        return 1;
      case ActivityRecurrence.flexible:
        return 0;
    }
  }

  static bool countsTowardDailyProgressInWeeklyGoals({
    required Activity activity,
    required DateTime date,
    required List<DailyActivityLog> logs,
  }) {
    final normalizedDate = _normalize(date);

    switch (activity.recurrence) {
      case ActivityRecurrence.weekly:
        return shouldCountFlexibleWeeklyActivityForDay(
          activity: activity,
          date: normalizedDate,
          logs: logs,
        );
      case ActivityRecurrence.daily:
        return true;
      case ActivityRecurrence.weeklyFixed:
        return activity.weekdays.contains(normalizedDate.weekday);
      case ActivityRecurrence.oneOff:
        return _isSameDay(activity.scheduledDate, normalizedDate);
      case ActivityRecurrence.monthly:
        return activity.scheduledDate?.day == normalizedDate.day;
      case ActivityRecurrence.flexible:
        return false;
    }
  }

  static String? deadlineLabelForWeeklyGoalActivity({
    required Activity activity,
    required DateTime date,
    required List<DailyActivityLog> logs,
  }) {
    final normalizedDate = _normalize(date);

    if (!shouldShowInWeeklyGoalsSection(
      activity: activity,
      date: normalizedDate,
      logs: logs,
    )) {
      return null;
    }

    if (activity.recurrence == ActivityRecurrence.weekly) {
      return deadlineLabelForFlexibleWeeklyActivity(
        activity: activity,
        date: normalizedDate,
        logs: logs,
      );
    }

    if (countsTowardDailyProgressInWeeklyGoals(
      activity: activity,
      date: normalizedDate,
      logs: logs,
    )) {
      return 'Faça hoje';
    }

    final latestRelevantDate = _latestRelevantDateInWeek(
      activity: activity,
      date: normalizedDate,
    );
    if (latestRelevantDate == null || latestRelevantDate.isBefore(normalizedDate)) {
      return null;
    }

    return 'Faça até ${_weekdayShortLabel(latestRelevantDate.weekday)}';
  }

  static DateTime? relevantDateForWeeklyGoalsSection({
    required Activity activity,
    required DateTime date,
  }) {
    return _latestRelevantDateInWeek(
      activity: activity,
      date: _normalize(date),
    );
  }

  static bool isDueTodayInWeeklyGoals({
    required Activity activity,
    required DateTime date,
    required List<DailyActivityLog> logs,
  }) {
    final normalizedDate = _normalize(date);

    switch (activity.recurrence) {
      case ActivityRecurrence.daily:
        return true;
      case ActivityRecurrence.weekly:
        return shouldCountFlexibleWeeklyActivityForDay(
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
  }

  static bool shouldCountFlexibleWeeklyActivityForDay({
    required Activity activity,
    required DateTime date,
    required List<DailyActivityLog> logs,
  }) {
    if (activity.recurrence != ActivityRecurrence.weekly &&
        activity.recurrence != ActivityRecurrence.weeklyFixed) {
      return false;
    }
    if (!_isCreatedBeforeDayEnd(activity, date)) return false;

    final normalizedDate = _normalize(date);
    final weekStart = startOfWeek(normalizedDate);
    final weekEnd = weekStart.add(const Duration(days: 6));
    final previousDay = normalizedDate.subtract(const Duration(days: 1));
    final completedBeforeToday = completedCountForWeekUntilDate(
      activityId: activity.id,
      logs: logs,
      weekStart: weekStart,
      weekEnd: weekEnd,
      endDate: previousDay,
    );
    final remainingNeeded =
        activity.effectiveWeeklyTargetCount - completedBeforeToday;

    if (remainingNeeded <= 0) return false;
    if (_hasCompletedOnDay(
      activityId: activity.id,
      date: normalizedDate,
      logs: logs,
    )) {
      return true;
    }

    final remainingDaysIncludingToday =
        weekEnd.difference(normalizedDate).inDays + 1;
    return remainingNeeded >= remainingDaysIncludingToday;
  }

  static String? deadlineLabelForFlexibleWeeklyActivity({
    required Activity activity,
    required DateTime date,
    required List<DailyActivityLog> logs,
  }) {
    if (activity.recurrence != ActivityRecurrence.weekly &&
        activity.recurrence != ActivityRecurrence.weeklyFixed) {
      return null;
    }
    if (!_isCreatedBeforeDayEnd(activity, date)) return null;

    if (shouldCountFlexibleWeeklyActivityForDay(
      activity: activity,
      date: date,
      logs: logs,
    )) {
      return 'Faça hoje';
    }

    final normalizedDate = _normalize(date);
    final weekStart = startOfWeek(normalizedDate);
    final weekEnd = weekStart.add(const Duration(days: 6));
    final completedUntilToday = completedCountForWeekUntilDate(
      activityId: activity.id,
      logs: logs,
      weekStart: weekStart,
      weekEnd: weekEnd,
      endDate: normalizedDate,
    );
    final remainingNeeded =
        activity.effectiveWeeklyTargetCount - completedUntilToday;

    if (remainingNeeded <= 0) return null;

    final latestStartDate = weekEnd.subtract(
      Duration(days: remainingNeeded - 1),
    );
    return 'Faça até ${_weekdayShortLabel(latestStartDate.weekday)}';
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

  static bool _hasCompletedOnDay({
    required String activityId,
    required DateTime date,
    required List<DailyActivityLog> logs,
  }) {
    final dayKey = _toDayKey(date);
    return logs.any(
      (log) =>
          log.activityId == activityId &&
          log.dayKey == dayKey &&
          log.status == ActivityStatus.completed,
    );
  }

  static bool _isCreatedBeforeDayEnd(Activity activity, DateTime date) {
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
    return !activity.createdAt.isAfter(endOfDay);
  }

  static bool _isSameDay(DateTime? a, DateTime b) {
    if (a == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static DateTime? _latestRelevantDateInWeek({
    required Activity activity,
    required DateTime date,
  }) {
    final normalizedDate = _normalize(date);
    final weekStart = startOfWeek(normalizedDate);
    final weekEnd = weekStart.add(const Duration(days: 6));

    switch (activity.recurrence) {
      case ActivityRecurrence.daily:
        return weekEnd;
      case ActivityRecurrence.weekly:
        return weekEnd;
      case ActivityRecurrence.weeklyFixed:
        DateTime? latest;
        for (
          DateTime cursor = weekStart;
          !cursor.isAfter(weekEnd);
          cursor = cursor.add(const Duration(days: 1))
        ) {
          if (activity.weekdays.contains(cursor.weekday) &&
              _isCreatedBeforeDayEnd(activity, cursor)) {
            latest = cursor;
          }
        }
        return latest;
      case ActivityRecurrence.oneOff:
        final scheduledDate = activity.scheduledDate;
        if (scheduledDate == null) return null;
        final normalizedScheduled = _normalize(scheduledDate);
        if (normalizedScheduled.isBefore(weekStart) ||
            normalizedScheduled.isAfter(weekEnd)) {
          return null;
        }
        return normalizedScheduled;
      case ActivityRecurrence.monthly:
        return _monthlyOccurrenceDateInWeek(
          activity: activity,
          weekStart: weekStart,
          weekEnd: weekEnd,
        );
      case ActivityRecurrence.flexible:
        return null;
    }
  }

  static DateTime? _monthlyOccurrenceDateInWeek({
    required Activity activity,
    required DateTime weekStart,
    required DateTime weekEnd,
  }) {
    final scheduledDate = activity.scheduledDate;
    if (scheduledDate == null) return null;

    for (
      DateTime cursor = weekStart;
      !cursor.isAfter(weekEnd);
      cursor = cursor.add(const Duration(days: 1))
    ) {
      if (cursor.day == scheduledDate.day) return cursor;
    }
    return null;
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

  static String _weekdayShortLabel(int weekday) {
    const labels = ['seg', 'ter', 'qua', 'qui', 'sex', 'sab', 'dom'];
    if (weekday < 1 || weekday > 7) return 'dia';
    return labels[weekday - 1];
  }
}
