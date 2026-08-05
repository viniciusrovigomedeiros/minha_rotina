import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/utils/date_utils.dart';
import '../data/models/activity_completion_quality.dart';
import '../data/models/activity_status.dart';
import '../data/models/daily_activity_log.dart';
import 'providers.dart';

class DailyCompletionPoint {
  const DailyCompletionPoint({
    required this.date,
    required this.label,
    required this.completed,
    required this.total,
  });

  final DateTime date;
  final String label;
  final int completed;
  final int total;

  double get percent => total == 0 ? 0 : completed / total;
}

class CategoryCompletionPoint {
  const CategoryCompletionPoint({
    required this.categoryName,
    required this.count,
    required this.colorHex,
  });

  final String categoryName;
  final int count;
  final int colorHex;
}

class WeeklyDashboardState {
  const WeeklyDashboardState({
    required this.dailyPoints,
    required this.categoryPoints,
    required this.totalCompleted,
    required this.totalPlanned,
    required this.totalQualityScore,
    required this.averageQualityRank,
    required this.averageQualityScore,
    required this.bestDayLabel,
    required this.currentStreak,
  });

  final List<DailyCompletionPoint> dailyPoints;
  final List<CategoryCompletionPoint> categoryPoints;
  final int totalCompleted;
  final int totalPlanned;
  final double totalQualityScore;
  final double averageQualityRank;
  final double averageQualityScore;
  final String bestDayLabel;
  final int currentStreak;

  double get weekProgress =>
      totalPlanned == 0 ? 0 : totalCompleted / totalPlanned;
}

final weeklyDashboardControllerProvider =
    AsyncNotifierProvider<WeeklyDashboardController, WeeklyDashboardState>(
      WeeklyDashboardController.new,
    );

class WeeklyDashboardController extends AsyncNotifier<WeeklyDashboardState> {
  @override
  Future<WeeklyDashboardState> build() async {
    return _load();
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }

  Future<WeeklyDashboardState> _load() async {
    final now = DateTime.now();
    final end = DateTime(now.year, now.month, now.day);
    final start = end.subtract(const Duration(days: 6));

    final activities = await ref.read(activityRepositoryProvider).getAll();
    final categories = await ref.read(categoryRepositoryProvider).getAll();
    final logs = await ref.read(dailyLogRepositoryProvider).getAll();
    final dailyPlanRepository = ref.read(dailyPlanRepositoryProvider);

    final logsByDay = <String, List<DailyActivityLog>>{};
    for (final log in logs) {
      logsByDay.putIfAbsent(log.dayKey, () => []).add(log);
    }

    final points = <DailyCompletionPoint>[];
    final categoryCompleted = <String, int>{};

    int totalCompleted = 0;
    int totalPlanned = 0;
    double totalQualityScore = 0;
    final completedQualities = <ActivityCompletionQuality>[];
    final completedScores = <int>[];

    for (int i = 0; i < 7; i++) {
      final date = start.add(Duration(days: i));
      final dayKey = DateUtilsX.toDayKey(date);
      final planSnapshot = await dailyPlanRepository.snapshotForDay(
        date: date,
        activities: activities,
        logs: logs,
      );
      final planned = planSnapshot.totalPlanned;

      final dayLogs = logsByDay[dayKey] ?? const [];
      final completedLogs =
          dayLogs
              .where((log) => log.status == ActivityStatus.completed)
              .toList();

      final completed = completedLogs.length;
      totalCompleted += completed;
      totalPlanned += planned;
      for (final completedLog in completedLogs) {
        final quality =
            completedLog.completionQuality ?? ActivityCompletionQuality.medium;
        completedQualities.add(quality);
        totalQualityScore += quality.weight;
        completedScores.add(_resolveQualityScore(completedLog));
      }

      for (final completedLog in completedLogs) {
        final activity =
            activities
                .where((item) => item.id == completedLog.activityId)
                .toList();
        if (activity.isEmpty) continue;
        final categoryId = activity.first.categoryId;
        final current = categoryCompleted[categoryId] ?? 0;
        categoryCompleted[categoryId] = current + 1;
      }

      points.add(
        DailyCompletionPoint(
          date: date,
          label: DateFormat('E', 'pt_BR').format(date).substring(0, 1),
          completed: completed,
          total: planned,
        ),
      );
    }

    final bestDay = points.fold<DailyCompletionPoint?>(null, (best, current) {
      if (best == null) return current;
      if (current.percent > best.percent) return current;
      return best;
    });

    final categoryPoints =
        categoryCompleted.entries.map((entry) {
            final category =
                categories.where((item) => item.id == entry.key).toList();
            final categoryName =
                category.isEmpty ? 'Sem categoria' : category.first.name;
            final colorHex =
                category.isEmpty ? 0xFF5A7DFA : category.first.colorHex;

            return CategoryCompletionPoint(
              categoryName: categoryName,
              count: entry.value,
              colorHex: colorHex,
            );
          }).toList()
          ..sort((a, b) => b.count.compareTo(a.count));

    int streak = 0;
    for (int i = 0; i < 60; i++) {
      final date = end.subtract(Duration(days: i));
      final dayKey = DateUtilsX.toDayKey(date);
      final dayLogs = logsByDay[dayKey] ?? const [];
      final hasCompleted = dayLogs.any(
        (log) => log.status == ActivityStatus.completed,
      );
      if (hasCompleted) {
        streak++;
      } else {
        break;
      }
    }

    return WeeklyDashboardState(
      dailyPoints: points,
      categoryPoints: categoryPoints,
      totalCompleted: totalCompleted,
      totalPlanned: totalPlanned,
      totalQualityScore: totalQualityScore,
      averageQualityRank: ActivityCompletionQualityX.averageRank(
        completedQualities,
      ),
      averageQualityScore:
          completedScores.isEmpty
              ? 0
              : completedScores.fold<int>(0, (sum, value) => sum + value) /
                  completedScores.length,
      bestDayLabel:
          bestDay == null
              ? 'Sem dados'
              : DateFormat('EEEE', 'pt_BR').format(bestDay.date),
      currentStreak: streak,
    );
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
}
