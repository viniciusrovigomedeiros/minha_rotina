import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils/date_utils.dart';
import '../data/models/activity.dart';
import '../data/models/activity_completion_quality.dart';
import '../data/models/activity_status.dart';
import '../data/models/daily_activity_log.dart';
import 'providers.dart';

class HistoryActivitySummary {
  const HistoryActivitySummary({
    required this.activityName,
    required this.status,
    required this.completionQuality,
  });

  final String activityName;
  final ActivityStatus status;
  final ActivityCompletionQuality? completionQuality;
}

class HistoryDaySummary {
  const HistoryDaySummary({
    required this.dayKey,
    required this.completed,
    required this.totalPlanned,
    required this.qualityScore,
    required this.averageQualityRank,
    required this.items,
  });

  final String dayKey;
  final int completed;
  final int totalPlanned;
  final double qualityScore;
  final double averageQualityRank;
  final List<HistoryActivitySummary> items;

  double get completionRate => totalPlanned == 0 ? 0 : completed / totalPlanned;
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

    final logsByDay = <String, List<DailyActivityLog>>{};
    for (final log in logs) {
      logsByDay.putIfAbsent(log.dayKey, () => []).add(log);
    }

    final firstDate = _firstRelevantDate(activities: activities, logs: logs);
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
      );

      final dayLogs = logsByDay[dayKey] ?? const [];
      final completed =
          dayLogs
              .where((entry) => entry.status == ActivityStatus.completed)
              .length;
      final completedQualities =
          dayLogs
              .where((entry) => entry.status == ActivityStatus.completed)
              .map(
                (entry) =>
                    entry.completionQuality ?? ActivityCompletionQuality.medium,
              )
              .toList();
      final qualityScore = completedQualities.fold<double>(
        0,
        (sum, quality) => sum + quality.weight,
      );
      final averageQualityRank = ActivityCompletionQualityX.averageRank(
        completedQualities,
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
            );
          }).toList();

      result.add(
        HistoryDaySummary(
          dayKey: dayKey,
          completed: completed,
          totalPlanned: planSnapshot.totalPlanned,
          qualityScore: qualityScore,
          averageQualityRank: averageQualityRank,
          items: summaries,
        ),
      );
    }

    return result;
  }

  DateTime _firstRelevantDate({
    required List<Activity> activities,
    required List<DailyActivityLog> logs,
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

    return first;
  }
}
