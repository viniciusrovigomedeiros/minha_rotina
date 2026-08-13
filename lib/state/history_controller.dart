import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils/activity_planning_utils.dart';
import '../core/utils/date_utils.dart';
import '../data/models/activity.dart';
import '../data/models/activity_completion_quality.dart';
import '../data/models/activity_status.dart';
import '../data/models/daily_activity_log.dart';
import '../data/models/daily_closure_entry.dart';
import 'providers.dart';

class HistoryActivitySummary {
  const HistoryActivitySummary({
    required this.activityName,
    required this.status,
    required this.completionQuality,
    required this.qualityScore,
  });

  final String activityName;
  final ActivityStatus status;
  final ActivityCompletionQuality? completionQuality;
  final int? qualityScore;
}

class HistoryDaySummary {
  const HistoryDaySummary({
    required this.dayKey,
    required this.completed,
    required this.completedPlanned,
    required this.totalPlanned,
    required this.qualityScore,
    required this.averageQualityRank,
    required this.averageQualityScore,
    required this.weeklyFlexibleCompleted,
    required this.weeklyFlexibleTarget,
    required this.items,
    required this.dailyClosure,
  });

  final String dayKey;
  final int completed;
  final int completedPlanned;
  final int totalPlanned;
  final double qualityScore;
  final double averageQualityRank;
  final double averageQualityScore;
  final int weeklyFlexibleCompleted;
  final int weeklyFlexibleTarget;
  final List<HistoryActivitySummary> items;
  final DailyClosureEntry? dailyClosure;

  bool get hasWeeklyFlexibleProgress => weeklyFlexibleTarget > 0;

  double get completionRate =>
      totalPlanned == 0 ? 0 : completedPlanned / totalPlanned;
}

final historyControllerProvider =
    AsyncNotifierProvider<HistoryController, List<HistoryDaySummary>>(
      HistoryController.new,
    );

class HistoryController extends AsyncNotifier<List<HistoryDaySummary>> {
  @override
  Future<List<HistoryDaySummary>> build() async {
    return _load();
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }

  Future<List<HistoryDaySummary>> _load() async {
    final activities = await ref.read(activityRepositoryProvider).getAll();
    final logs = await ref.read(dailyLogRepositoryProvider).getAll();
    final dailyPlanRepository = ref.read(dailyPlanRepositoryProvider);
    final dailyClosures =
        await ref.read(dailyClosureRepositoryProvider).getAll();

    final logsByDay = <String, List<DailyActivityLog>>{};
    for (final log in logs) {
      logsByDay.putIfAbsent(log.dayKey, () => []).add(log);
    }
    final closuresByDay = {
      for (final closure in dailyClosures) closure.dayKey: closure,
    };

    final firstDate = _firstRelevantDate(
      activities: activities,
      logs: logs,
      closures: dailyClosures,
    );
    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);

    final result = <HistoryDaySummary>[];

    for (
      DateTime dayDate = normalizedToday;
      !dayDate.isBefore(firstDate);
      dayDate = dayDate.subtract(const Duration(days: 1))
    ) {
      final dayKey = DateUtilsX.toDayKey(dayDate);
      final planSnapshot = await dailyPlanRepository.snapshotForDay(
        date: dayDate,
        activities: activities,
        logs: logs,
      );
      final plannedActivityIds = planSnapshot.activityIds.toSet();

      final dayLogs = logsByDay[dayKey] ?? const [];
      final completedLogs =
          dayLogs
              .where((entry) => entry.status == ActivityStatus.completed)
              .toList();
      final completedPlannedLogs =
          completedLogs
              .where((entry) => plannedActivityIds.contains(entry.activityId))
              .toList();
      final completedQualities =
          completedLogs
              .map(
                (entry) =>
                    entry.completionQuality ?? ActivityCompletionQuality.medium,
              )
              .toList();
      final completedScores = completedLogs.map(_resolveQualityScore).toList();
      final qualityScore = completedQualities.fold<double>(
        0,
        (sum, quality) => sum + quality.weight,
      );
      final averageQualityRank = ActivityCompletionQualityX.averageRank(
        completedQualities,
      );
      final averageQualityScore =
          completedScores.isEmpty
              ? 0.0
              : completedScores.fold<int>(0, (sum, value) => sum + value) /
                  completedScores.length;
      final weeklyFlexibleProgress = _weeklyFlexibleProgressForDay(
        date: dayDate,
        activities: activities,
        logs: logs,
      );

      final summaries =
          dayLogs.map((entry) {
            final activity =
                activities
                    .where((item) => item.id == entry.activityId)
                    .toList();
            final name =
                activity.isEmpty ? 'Atividade removida' : activity.first.name;
            return HistoryActivitySummary(
              activityName: name,
              status: entry.status,
              completionQuality: entry.completionQuality,
              qualityScore:
                  entry.status == ActivityStatus.completed
                      ? _resolveQualityScore(entry)
                      : null,
            );
          }).toList();

      result.add(
        HistoryDaySummary(
          dayKey: dayKey,
          completed: completedLogs.length,
          completedPlanned: completedPlannedLogs.length,
          totalPlanned: planSnapshot.totalPlanned,
          qualityScore: qualityScore,
          averageQualityRank: averageQualityRank,
          averageQualityScore: averageQualityScore,
          weeklyFlexibleCompleted: weeklyFlexibleProgress.completed,
          weeklyFlexibleTarget: weeklyFlexibleProgress.target,
          items: summaries,
          dailyClosure: closuresByDay[dayKey],
        ),
      );
    }

    return result;
  }

  DateTime _firstRelevantDate({
    required List<Activity> activities,
    required List<DailyActivityLog> logs,
    required List<DailyClosureEntry> closures,
  }) {
    final today = DateTime.now();
    var first = DateTime(today.year, today.month, today.day);

    for (final activity in activities) {
      final created = DateTime(
        activity.createdAt.year,
        activity.createdAt.month,
        activity.createdAt.day,
      );
      if (created.isBefore(first)) first = created;
    }

    for (final log in logs) {
      final date = DateUtilsX.fromDayKey(log.dayKey);
      if (date.isBefore(first)) first = date;
    }

    for (final closure in closures) {
      final date = DateUtilsX.fromDayKey(closure.dayKey);
      if (date.isBefore(first)) first = date;
    }

    return first;
  }

  int _resolveQualityScore(DailyActivityLog log) {
    if (log.qualityScore != null) {
      return log.qualityScore!.clamp(0, 10).toInt();
    }
    final quality = log.completionQuality ?? ActivityCompletionQuality.medium;
    switch (quality) {
      case ActivityCompletionQuality.low:
        return 4;
      case ActivityCompletionQuality.medium:
        return 7;
      case ActivityCompletionQuality.high:
        return 9;
    }
  }

  _HistoryWeeklyFlexibleProgress _weeklyFlexibleProgressForDay({
    required DateTime date,
    required List<Activity> activities,
    required List<DailyActivityLog> logs,
  }) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final weekStart = ActivityPlanningUtils.startOfWeek(normalizedDate);
    final weekEnd = weekStart.add(const Duration(days: 6));
    int completed = 0;
    int target = 0;

    for (final activity in activities) {
      if (activity.recurrence != ActivityRecurrence.weekly) continue;
      if (!ActivityPlanningUtils.isCreatedBeforeDayEnd(
        activity,
        normalizedDate,
      )) {
        continue;
      }

      target += activity.effectiveWeeklyTargetCount;
      completed += ActivityPlanningUtils.completedCountForWeekUntilDate(
        activityId: activity.id,
        logs: logs,
        weekStart: weekStart,
        weekEnd: weekEnd,
        endDate: normalizedDate,
      );
    }

    return _HistoryWeeklyFlexibleProgress(
      completed: completed.clamp(0, target),
      target: target,
    );
  }
}

class _HistoryWeeklyFlexibleProgress {
  const _HistoryWeeklyFlexibleProgress({
    required this.completed,
    required this.target,
  });

  final int completed;
  final int target;
}
