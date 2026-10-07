import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/activity_planning_utils.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/okr_progress_utils.dart';
import '../../../data/models/activity.dart';
import '../../../data/models/activity_status.dart';
import '../../../data/models/daily_activity_log.dart';
import '../../../data/models/okr_cycle.dart';
import '../../../data/models/okr_objective.dart';
import '../../../state/providers.dart';
import '../models/today_state.dart';

final todayStateLoaderProvider = Provider<TodayStateLoader>((ref) {
  return TodayStateLoader(ref);
});

class TodayStateLoader {
  const TodayStateLoader(this._ref);

  final Ref _ref;

  Future<TodayState> load(DateTime date) async {
    final activities = await _ref.read(activityRepositoryProvider).getAll();
    final cycles = await _ref.read(okrCycleRepositoryProvider).getAll();
    final objectives = await _ref.read(okrObjectiveRepositoryProvider).getAll();
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final dayKey = DateUtilsX.toDayKey(date);
    final allLogs = await _ref.read(dailyLogRepositoryProvider).getAll();
    final logs = allLogs.where((log) => log.dayKey == dayKey).toList();
    final currentCycle = OkrProgressUtils.resolveCurrentCycle(
      cycles,
      date: normalizedDate,
    );
    final objectivesById = {
      for (final objective in objectives) objective.id: objective,
    };

    final logsByActivityId = {for (final log in logs) log.activityId: log};
    final weekStart = ActivityPlanningUtils.startOfWeek(normalizedDate);
    final weekEnd = weekStart.add(const Duration(days: 6));

    final todayActivities =
        activities
            .where(
              (activity) =>
                  _isScheduledActivityForDate(activity, normalizedDate),
            )
            .toList()
          ..sort((a, b) {
            final aMinutes = a.startMinutes ?? 9999;
            final bMinutes = b.startMinutes ?? 9999;
            if (aMinutes == bMinutes) return a.name.compareTo(b.name);
            return aMinutes.compareTo(bMinutes);
          });

    final items =
        todayActivities.map((activity) {
          final log = logsByActivityId[activity.id];
          final okrProgress = _resolveOkrProgressForActivity(
            activity: activity,
            currentCycle: currentCycle,
            objectivesById: objectivesById,
            logs: allLogs,
            date: normalizedDate,
          );
          return TodayActivityItem(
            activity: activity,
            status: log?.status ?? ActivityStatus.pending,
            completionQuality: log?.completionQuality,
            qualityScore: log?.qualityScore,
            okrCompletedCount: okrProgress?.completedCount,
            okrPlannedCount: okrProgress?.plannedCount,
          );
        }).toList();

    final weeklyGoalItems =
        activities
            .where(
              (activity) =>
                  activity.isActive &&
                  activity.isWithinPeriod(normalizedDate) &&
                  ActivityPlanningUtils.shouldShowInWeeklyGoalsSection(
                    activity: activity,
                    date: normalizedDate,
                    logs: allLogs,
                  ),
            )
            .map((activity) {
              final log = logsByActivityId[activity.id];
              final okrProgress = _resolveOkrProgressForActivity(
                activity: activity,
                currentCycle: currentCycle,
                objectivesById: objectivesById,
                logs: allLogs,
                date: normalizedDate,
              );
              final completedCount =
                  ActivityPlanningUtils.completedCountForWeekUntilDate(
                    activityId: activity.id,
                    activity: activity,
                    logs: allLogs,
                    weekStart: weekStart,
                    weekEnd: weekEnd,
                    endDate: normalizedDate,
                  );

              final countsTowardDailyProgress =
                  ActivityPlanningUtils.countsTowardDailyProgressInWeeklyGoals(
                    activity: activity,
                    date: normalizedDate,
                    logs: allLogs,
                  );
              final weeklyDeadlineLabel =
                  ActivityPlanningUtils.deadlineLabelForWeeklyGoalActivity(
                    activity: activity,
                    date: normalizedDate,
                    logs: allLogs,
                  );
              final isDueTodayInWeeklyGoals =
                  ActivityPlanningUtils.isDueTodayInWeeklyGoals(
                    activity: activity,
                    date: normalizedDate,
                    logs: allLogs,
                  );
              final weeklyTargetCount =
                  ActivityPlanningUtils.weeklyTargetCountForActivity(
                    activity: activity,
                    date: normalizedDate,
                  );

              return TodayActivityItem(
                activity: activity,
                status: log?.status ?? ActivityStatus.pending,
                completionQuality: log?.completionQuality,
                qualityScore: log?.qualityScore,
                weeklyCompletedCount: completedCount,
                weeklyTargetCount: weeklyTargetCount,
                isSuggestedToday: activity.weekdays.contains(
                  normalizedDate.weekday,
                ),
                countsTowardDailyProgress: countsTowardDailyProgress,
                weeklyDeadlineLabel: weeklyDeadlineLabel,
                isDueTodayInWeeklyGoals: isDueTodayInWeeklyGoals,
                okrCompletedCount: okrProgress?.completedCount,
                okrPlannedCount: okrProgress?.plannedCount,
              );
            })
            .toList()
          ..sort((a, b) {
            if (a.countsTowardDailyProgress != b.countsTowardDailyProgress) {
              return a.countsTowardDailyProgress ? -1 : 1;
            }
            final aRelevantDate =
                ActivityPlanningUtils.relevantDateForWeeklyGoalsSection(
                  activity: a.activity,
                  date: normalizedDate,
                );
            final bRelevantDate =
                ActivityPlanningUtils.relevantDateForWeeklyGoalsSection(
                  activity: b.activity,
                  date: normalizedDate,
                );
            if (aRelevantDate != null && bRelevantDate != null) {
              final compare = aRelevantDate.compareTo(bRelevantDate);
              if (compare != 0) return compare;
            } else if (aRelevantDate != null) {
              return -1;
            } else if (bRelevantDate != null) {
              return 1;
            }
            if (a.isSuggestedToday != b.isSuggestedToday) {
              return a.isSuggestedToday ? -1 : 1;
            }
            final aMinutes = a.activity.startMinutes ?? 9999;
            final bMinutes = b.activity.startMinutes ?? 9999;
            if (aMinutes == bMinutes) {
              return a.activity.name.compareTo(b.activity.name);
            }
            return aMinutes.compareTo(bMinutes);
          });

    return TodayState(
      date: normalizedDate,
      items: items,
      weeklyGoalItems: weeklyGoalItems,
    );
  }

  bool _isScheduledActivityForDate(Activity activity, DateTime date) {
    if (!activity.isActive || !activity.isWithinPeriod(date)) {
      return false;
    }

    switch (activity.recurrence) {
      case ActivityRecurrence.daily:
        return true;
      case ActivityRecurrence.weeklyFixed:
        return activity.weekdays.contains(date.weekday);
      case ActivityRecurrence.oneOff:
        return _isSameDay(activity.scheduledDate, date);
      case ActivityRecurrence.monthly:
        return activity.scheduledDate?.day == date.day;
      case ActivityRecurrence.weekly:
      case ActivityRecurrence.flexible:
        return false;
    }
  }

  ActivityPeriodProgress? _resolveOkrProgressForActivity({
    required Activity activity,
    required OkrCycle? currentCycle,
    required Map<String, OkrObjective> objectivesById,
    required List<DailyActivityLog> logs,
    required DateTime date,
  }) {
    final objectiveId = activity.objectiveId;
    if (objectiveId == null || currentCycle == null) return null;

    final objective = objectivesById[objectiveId];
    if (objective == null || objective.cycleId != currentCycle.id) return null;

    final periodStart =
        objective.startDate.isAfter(currentCycle.startDate)
            ? objective.startDate
            : currentCycle.startDate;
    final periodEnd =
        objective.endDate.isBefore(currentCycle.endDate)
            ? objective.endDate
            : currentCycle.endDate;

    final progress = ActivityPlanningUtils.progressInPeriodUntilDate(
      activity: activity,
      logs: logs,
      periodStart: periodStart,
      periodEnd: periodEnd,
      date: date,
    );

    if (progress.plannedCount <= 0 && progress.completedCount <= 0) {
      return null;
    }

    return progress;
  }

  bool _isSameDay(DateTime? a, DateTime b) {
    if (a == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
