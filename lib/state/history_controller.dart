import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils/date_utils.dart';
import '../data/models/activity_status.dart';
import '../data/models/daily_activity_log.dart';
import 'providers.dart';

class HistoryActivitySummary {
  const HistoryActivitySummary({
    required this.activityName,
    required this.status,
  });

  final String activityName;
  final ActivityStatus status;
}

class HistoryDaySummary {
  const HistoryDaySummary({
    required this.dayKey,
    required this.completed,
    required this.totalPlanned,
    required this.items,
  });

  final String dayKey;
  final int completed;
  final int totalPlanned;
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

    final logsByDay = <String, List<DailyActivityLog>>{};
    for (final log in logs) {
      logsByDay.putIfAbsent(log.dayKey, () => []).add(log);
    }

    final days = logsByDay.keys.toList()..sort((a, b) => b.compareTo(a));

    final result = <HistoryDaySummary>[];

    for (final dayKey in days) {
      final dayDate = DateUtilsX.fromDayKey(dayKey);
      final planned =
          activities.where((activity) {
            return activity.weekdays.contains(dayDate.weekday);
          }).toList();

      final dayLogs = logsByDay[dayKey] ?? const [];
      final completed =
          dayLogs
              .where((entry) => entry.status == ActivityStatus.completed)
              .length;

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
            );
          }).toList();

      result.add(
        HistoryDaySummary(
          dayKey: dayKey,
          completed: completed,
          totalPlanned: planned.length,
          items: summaries,
        ),
      );
    }

    return result;
  }
}
