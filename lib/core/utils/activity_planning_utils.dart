import '../../data/models/activity.dart';
import '../../data/models/activity_status.dart';
import '../../data/models/daily_activity_log.dart';

class ActivityPeriodProgress {
  const ActivityPeriodProgress({
    required this.completedCount,
    required this.plannedCount,
  });

  final int completedCount;
  final int plannedCount;
}

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
          if (!activity.isWithinPeriod(normalizedDate)) return false;

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
    if (!activity.isWithinPeriod(date)) return false;

    final normalizedDate = _normalize(date);
    final weekStart = startOfWeek(normalizedDate);
    final previousDay = normalizedDate.subtract(const Duration(days: 1));
    final completedBeforeToday = completedCountForWeekUntilDate(
      activityId: activity.id,
      activity: activity,
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
        completedBeforeToday <
            weeklyTargetCountForActivity(
              activity: activity,
              date: normalizedDate,
            );
  }

  static bool shouldShowInWeeklyGoalsSection({
    required Activity activity,
    required DateTime date,
    required List<DailyActivityLog> logs,
  }) {
    final normalizedDate = _normalize(date);
    final weekStart = startOfWeek(normalizedDate);
    final weekEnd = weekStart.add(const Duration(days: 6));

    if (!activity.isActive || !activity.isWithinPeriod(normalizedDate)) {
      return false;
    }

    final targetCount = weeklyTargetCountForActivity(
      activity: activity,
      date: normalizedDate,
    );
    if (targetCount <= 0) return false;

    final completedUntilToday = completedCountForWeekUntilDate(
      activityId: activity.id,
      activity: activity,
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

    final effectiveStart =
        activity.effectiveStartDate.isAfter(weekStart)
            ? activity.effectiveStartDate
            : weekStart;
    final effectiveEnd =
        activity.endDate != null &&
                _normalize(activity.endDate!).isBefore(weekEnd)
            ? _normalize(activity.endDate!)
            : weekEnd;
    if (effectiveEnd.isBefore(effectiveStart)) return 0;
    final availableDays = effectiveEnd.difference(effectiveStart).inDays + 1;

    switch (activity.recurrence) {
      case ActivityRecurrence.daily:
        return availableDays;
      case ActivityRecurrence.weekly:
        return activity.effectiveWeeklyTargetCount.clamp(0, availableDays);
      case ActivityRecurrence.weeklyFixed:
        int count = 0;
        for (
          DateTime cursor = weekStart;
          !cursor.isAfter(weekEnd);
          cursor = cursor.add(const Duration(days: 1))
        ) {
          if (activity.weekdays.contains(cursor.weekday) &&
              activity.isWithinPeriod(cursor)) {
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
            !activity.isWithinPeriod(normalizedScheduled)) {
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
            !activity.isWithinPeriod(occurrenceDate)) {
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
    if (!activity.isWithinPeriod(normalizedDate)) return false;

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
    if (latestRelevantDate == null ||
        latestRelevantDate.isBefore(normalizedDate)) {
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
    if (!activity.isWithinPeriod(normalizedDate)) return false;

    switch (activity.recurrence) {
      case ActivityRecurrence.daily:
        return true;
      case ActivityRecurrence.weekly:
        return isFlexibleWeeklyActivityDueToday(
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
    if (!activity.isWithinPeriod(date)) return false;

    final normalizedDate = _normalize(date);
    final weekStart = startOfWeek(normalizedDate);
    final weekEnd = weekStart.add(const Duration(days: 6));
    final previousDay = normalizedDate.subtract(const Duration(days: 1));
    final completedBeforeToday = completedCountForWeekUntilDate(
      activityId: activity.id,
      activity: activity,
      logs: logs,
      weekStart: weekStart,
      weekEnd: weekEnd,
      endDate: previousDay,
    );
    final remainingNeeded =
        weeklyTargetCountForActivity(activity: activity, date: normalizedDate) -
        completedBeforeToday;

    if (remainingNeeded <= 0) return false;
    return _hasCompletedOnDay(
          activityId: activity.id,
          date: normalizedDate,
          logs: logs,
        ) ||
        isFlexibleWeeklyActivityDueToday(
          activity: activity,
          date: normalizedDate,
          logs: logs,
        );
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
    if (!activity.isWithinPeriod(date)) return null;

    if (isFlexibleWeeklyActivityDueToday(
      activity: activity,
      date: date,
      logs: logs,
    )) {
      return 'Faça hoje';
    }

    final normalizedDate = _normalize(date);
    final weekStart = startOfWeek(normalizedDate);
    final calendarWeekEnd = weekStart.add(const Duration(days: 6));
    final weekEnd =
        activity.endDate != null &&
                _normalize(activity.endDate!).isBefore(calendarWeekEnd)
            ? _normalize(activity.endDate!)
            : calendarWeekEnd;
    final completedUntilToday = completedCountForWeekUntilDate(
      activityId: activity.id,
      activity: activity,
      logs: logs,
      weekStart: weekStart,
      weekEnd: weekEnd,
      endDate: normalizedDate,
    );
    final remainingNeeded =
        weeklyTargetCountForActivity(activity: activity, date: normalizedDate) -
        completedUntilToday;

    if (remainingNeeded <= 0) return null;

    final latestStartDate = weekEnd.subtract(
      Duration(days: remainingNeeded - 1),
    );
    return 'Faça até ${_weekdayShortLabel(latestStartDate.weekday)}';
  }

  static bool isFlexibleWeeklyActivityDueToday({
    required Activity activity,
    required DateTime date,
    required List<DailyActivityLog> logs,
  }) {
    if (activity.recurrence != ActivityRecurrence.weekly &&
        activity.recurrence != ActivityRecurrence.weeklyFixed) {
      return false;
    }
    if (!activity.isWithinPeriod(date)) return false;

    final normalizedDate = _normalize(date);
    final weekStart = startOfWeek(normalizedDate);
    final calendarWeekEnd = weekStart.add(const Duration(days: 6));
    final weekEnd =
        activity.endDate != null &&
                _normalize(activity.endDate!).isBefore(calendarWeekEnd)
            ? _normalize(activity.endDate!)
            : calendarWeekEnd;
    final previousDay = normalizedDate.subtract(const Duration(days: 1));
    final completedBeforeToday = completedCountForWeekUntilDate(
      activityId: activity.id,
      activity: activity,
      logs: logs,
      weekStart: weekStart,
      weekEnd: weekEnd,
      endDate: previousDay,
    );
    final remainingNeeded =
        weeklyTargetCountForActivity(activity: activity, date: normalizedDate) -
        completedBeforeToday;

    if (remainingNeeded <= 0) return false;

    final remainingDaysIncludingToday =
        weekEnd.difference(normalizedDate).inDays + 1;
    return remainingNeeded >= remainingDaysIncludingToday;
  }

  static int completedCountForWeekUntilDate({
    required String activityId,
    Activity? activity,
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
      if (activity != null && !activity.isWithinPeriod(logDate)) return false;
      return !logDate.isBefore(normalizedWeekStart) &&
          !logDate.isAfter(normalizedWeekEnd) &&
          !logDate.isAfter(normalizedEndDate);
    }).length;
  }

  static ActivityPeriodProgress progressInPeriodUntilDate({
    required Activity activity,
    required List<DailyActivityLog> logs,
    required DateTime periodStart,
    required DateTime periodEnd,
    required DateTime date,
  }) {
    final requestedStart = _normalize(periodStart);
    final normalizedStart =
        activity.effectiveStartDate.isAfter(requestedStart)
            ? activity.effectiveStartDate
            : requestedStart;
    final requestedEnd = _normalize(periodEnd);
    final normalizedPeriodEnd =
        activity.endDate != null &&
                _normalize(activity.endDate!).isBefore(requestedEnd)
            ? _normalize(activity.endDate!)
            : requestedEnd;
    final normalizedDate = _normalize(date);
    final cappedDate =
        normalizedDate.isAfter(normalizedPeriodEnd)
            ? normalizedPeriodEnd
            : normalizedDate;

    if (cappedDate.isBefore(normalizedStart)) {
      return const ActivityPeriodProgress(completedCount: 0, plannedCount: 0);
    }

    return ActivityPeriodProgress(
      completedCount: completedCountForActivityInRange(
        activityId: activity.id,
        logs: logs,
        startDate: normalizedStart,
        endDate: cappedDate,
      ),
      plannedCount: plannedCountForActivityInPeriodUntilDate(
        activity: activity,
        periodStart: normalizedStart,
        periodEnd: normalizedPeriodEnd,
        date: cappedDate,
      ),
    );
  }

  static int plannedCountForActivityInPeriodUntilDate({
    required Activity activity,
    required DateTime periodStart,
    required DateTime periodEnd,
    required DateTime date,
  }) {
    final requestedStart = _normalize(periodStart);
    final normalizedStart =
        activity.effectiveStartDate.isAfter(requestedStart)
            ? activity.effectiveStartDate
            : requestedStart;
    final requestedEnd = _normalize(periodEnd);
    final normalizedPeriodEnd =
        activity.endDate != null &&
                _normalize(activity.endDate!).isBefore(requestedEnd)
            ? _normalize(activity.endDate!)
            : requestedEnd;
    final normalizedDate = _normalize(date);
    final cappedDate =
        normalizedDate.isAfter(normalizedPeriodEnd)
            ? normalizedPeriodEnd
            : normalizedDate;
    final createdStart = activity.effectiveStartDate;
    final effectiveStart =
        createdStart.isAfter(normalizedStart) ? createdStart : normalizedStart;

    if (cappedDate.isBefore(effectiveStart)) return 0;

    switch (activity.recurrence) {
      case ActivityRecurrence.daily:
        return cappedDate.difference(effectiveStart).inDays + 1;
      case ActivityRecurrence.weekly:
        return _plannedFlexibleWeeklyCountInPeriodUntilDate(
          activity: activity,
          periodStart: effectiveStart,
          periodEnd: normalizedPeriodEnd,
          date: cappedDate,
        );
      case ActivityRecurrence.weeklyFixed:
        return _countMatchingDates(
          startDate: effectiveStart,
          endDate: cappedDate,
          predicate: (cursor) => activity.weekdays.contains(cursor.weekday),
        );
      case ActivityRecurrence.oneOff:
        final scheduledDate = activity.scheduledDate;
        if (scheduledDate == null) return 0;
        final normalizedScheduled = _normalize(scheduledDate);
        return !normalizedScheduled.isBefore(effectiveStart) &&
                !normalizedScheduled.isAfter(cappedDate)
            ? 1
            : 0;
      case ActivityRecurrence.monthly:
        final scheduledDate = activity.scheduledDate;
        if (scheduledDate == null) return 0;
        return _countMatchingDates(
          startDate: effectiveStart,
          endDate: cappedDate,
          predicate: (cursor) => cursor.day == scheduledDate.day,
        );
      case ActivityRecurrence.flexible:
        return 0;
    }
  }

  static int completedCountForActivityInRange({
    required String activityId,
    required List<DailyActivityLog> logs,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final normalizedStart = _normalize(startDate);
    final normalizedEnd = _normalize(endDate);
    if (normalizedEnd.isBefore(normalizedStart)) return 0;

    return logs.where((log) {
      if (log.activityId != activityId ||
          log.status != ActivityStatus.completed) {
        return false;
      }
      final logDate = _fromDayKey(log.dayKey);
      return !logDate.isBefore(normalizedStart) &&
          !logDate.isAfter(normalizedEnd);
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

    final effectiveEnd =
        activity.endDate != null &&
                _normalize(activity.endDate!).isBefore(weekEnd)
            ? _normalize(activity.endDate!)
            : weekEnd;
    if (!activity.isWithinPeriod(effectiveEnd)) return null;

    switch (activity.recurrence) {
      case ActivityRecurrence.daily:
        return effectiveEnd;
      case ActivityRecurrence.weekly:
        return effectiveEnd;
      case ActivityRecurrence.weeklyFixed:
        DateTime? latest;
        for (
          DateTime cursor = weekStart;
          !cursor.isAfter(weekEnd);
          cursor = cursor.add(const Duration(days: 1))
        ) {
          if (activity.weekdays.contains(cursor.weekday) &&
              activity.isWithinPeriod(cursor)) {
            latest = cursor;
          }
        }
        return latest;
      case ActivityRecurrence.oneOff:
        final scheduledDate = activity.scheduledDate;
        if (scheduledDate == null) return null;
        final normalizedScheduled = _normalize(scheduledDate);
        if (normalizedScheduled.isBefore(weekStart) ||
            normalizedScheduled.isAfter(weekEnd) ||
            !activity.isWithinPeriod(normalizedScheduled)) {
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
      if (cursor.day == scheduledDate.day && activity.isWithinPeriod(cursor)) {
        return cursor;
      }
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

  static int _plannedFlexibleWeeklyCountInPeriodUntilDate({
    required Activity activity,
    required DateTime periodStart,
    required DateTime periodEnd,
    required DateTime date,
  }) {
    final requestedStart = _normalize(periodStart);
    final normalizedStart =
        activity.effectiveStartDate.isAfter(requestedStart)
            ? activity.effectiveStartDate
            : requestedStart;
    final normalizedEnd = _normalize(periodEnd);
    final normalizedDate = _normalize(date);
    int total = 0;

    DateTime cursor = startOfWeek(normalizedStart);
    while (!cursor.isAfter(normalizedDate)) {
      final weekStart = cursor;
      final weekEnd = weekStart.add(const Duration(days: 6));
      final activeWeekStart =
          weekStart.isAfter(normalizedStart) ? weekStart : normalizedStart;
      final activeWeekDeadline =
          weekEnd.isBefore(normalizedEnd) ? weekEnd : normalizedEnd;

      if (!activeWeekDeadline.isBefore(activeWeekStart)) {
        final activeDaysInWeek =
            activeWeekDeadline.difference(activeWeekStart).inDays + 1;
        final weekCapacity =
            activity.effectiveWeeklyTargetCount
                .clamp(0, activeDaysInWeek)
                .toInt();

        if (!normalizedDate.isBefore(activeWeekDeadline)) {
          total += weekCapacity;
        } else if (!normalizedDate.isBefore(activeWeekStart)) {
          final remainingActiveDaysAfterDate =
              activeWeekDeadline.difference(normalizedDate).inDays;
          total +=
              (weekCapacity - remainingActiveDaysAfterDate)
                  .clamp(0, weekCapacity)
                  .toInt();
        }
      }

      cursor = cursor.add(const Duration(days: 7));
    }

    return total;
  }

  static int _countMatchingDates({
    required DateTime startDate,
    required DateTime endDate,
    required bool Function(DateTime cursor) predicate,
  }) {
    if (endDate.isBefore(startDate)) return 0;
    int count = 0;
    for (
      DateTime cursor = startDate;
      !cursor.isAfter(endDate);
      cursor = cursor.add(const Duration(days: 1))
    ) {
      if (predicate(cursor)) count++;
    }
    return count;
  }
}
