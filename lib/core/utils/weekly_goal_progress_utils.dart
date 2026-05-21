import '../../data/models/activity.dart';
import '../../data/models/activity_completion_quality.dart';
import '../../data/models/activity_status.dart';
import '../../data/models/daily_activity_log.dart';
import '../../data/models/weekly_goal.dart';
import 'date_utils.dart';

class GoalDateRange {
  const GoalDateRange({required this.start, required this.end});

  final DateTime start;
  final DateTime end;
}

class WeeklyGoalProgress {
  const WeeklyGoalProgress({
    required this.goal,
    required this.currentValue,
    required this.targetValue,
    required this.rangeStart,
    required this.rangeEnd,
  });

  final WeeklyGoal goal;
  final double currentValue;
  final double targetValue;
  final DateTime rangeStart;
  final DateTime rangeEnd;

  bool get isCompleted => currentValue >= targetValue;
  double get ratio =>
      targetValue <= 0 ? 0 : (currentValue / targetValue).clamp(0, 1);
  double get remainingValue => isCompleted ? 0 : (targetValue - currentValue);

  String get progressLabel =>
      '${formatGoalNumber(currentValue)}/${formatGoalNumber(targetValue)}';

  static String formatGoalNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(1);
  }
}

class WeeklyGoalProgressUtils {
  const WeeklyGoalProgressUtils._();

  static List<WeeklyGoalProgress> buildProgresses({
    required List<WeeklyGoal> goals,
    required List<Activity> activities,
    required List<DailyActivityLog> dailyLogs,
    DateTime? referenceDate,
  }) {
    final baseDate = referenceDate ?? DateTime.now();
    final activitiesById = {
      for (final activity in activities) activity.id: activity,
    };

    return goals.map((goal) {
        final range = resolveRange(goal: goal, referenceDate: baseDate);
        final currentValue =
            goal.isManual
                ? goal.currentValue
                : _automaticCurrentValueForGoal(
                  goal: goal,
                  range: range,
                  activitiesById: activitiesById,
                  dailyLogs: dailyLogs,
                );

        return WeeklyGoalProgress(
          goal: goal,
          currentValue: currentValue,
          targetValue: goal.targetValue,
          rangeStart: range.start,
          rangeEnd: range.end,
        );
      }).toList()
      ..sort((a, b) {
        if (a.goal.isActive != b.goal.isActive) {
          return a.goal.isActive ? -1 : 1;
        }
        if (a.goal.trackingMode != b.goal.trackingMode) {
          return a.goal.trackingMode == GoalTrackingMode.manual ? -1 : 1;
        }
        if (a.isCompleted != b.isCompleted) {
          return a.isCompleted ? 1 : -1;
        }
        return a.goal.name.compareTo(b.goal.name);
      });
  }

  static GoalDateRange resolveRange({
    required WeeklyGoal goal,
    DateTime? referenceDate,
  }) {
    final base = _normalize(referenceDate ?? DateTime.now());
    final explicitStart = goal.startDate;
    final explicitEnd = goal.endDate;

    if (explicitStart != null || explicitEnd != null) {
      final start = _normalize(explicitStart ?? explicitEnd ?? goal.createdAt);
      final end = _normalize(explicitEnd ?? explicitStart ?? goal.createdAt);
      return GoalDateRange(
        start: start,
        end: end.isBefore(start) ? start : end,
      );
    }

    switch (goal.period) {
      case GoalPeriod.week:
        final start = base.subtract(Duration(days: base.weekday - 1));
        return GoalDateRange(
          start: start,
          end: start.add(const Duration(days: 6)),
        );
      case GoalPeriod.month:
        final start = DateTime(base.year, base.month, 1);
        final end = DateTime(base.year, base.month + 1, 0);
        return GoalDateRange(start: start, end: end);
      case GoalPeriod.quarter:
        final quarterStartMonth = (((base.month - 1) ~/ 3) * 3) + 1;
        final start = DateTime(base.year, quarterStartMonth, 1);
        final end = DateTime(base.year, quarterStartMonth + 3, 0);
        return GoalDateRange(start: start, end: end);
      case GoalPeriod.year:
        return GoalDateRange(
          start: DateTime(base.year, 1, 1),
          end: DateTime(base.year, 12, 31),
        );
      case GoalPeriod.custom:
        final start = _normalize(goal.startDate ?? goal.createdAt);
        final end = _normalize(goal.endDate ?? goal.createdAt);
        return GoalDateRange(
          start: start,
          end: end.isBefore(start) ? start : end,
        );
    }
  }

  static double _automaticCurrentValueForGoal({
    required WeeklyGoal goal,
    required GoalDateRange range,
    required Map<String, Activity> activitiesById,
    required List<DailyActivityLog> dailyLogs,
  }) {
    final startKey = DateUtilsX.toDayKey(range.start);
    final endKey = DateUtilsX.toDayKey(range.end);
    final completedLogs =
        dailyLogs.where((log) {
          return log.status == ActivityStatus.completed &&
              log.dayKey.compareTo(startKey) >= 0 &&
              log.dayKey.compareTo(endKey) <= 0;
        }).toList();

    final matchedLogs =
        completedLogs.where((log) {
          switch (goal.scope ?? WeeklyGoalScope.overall) {
            case WeeklyGoalScope.overall:
              return true;
            case WeeklyGoalScope.activity:
              return log.activityId == goal.activityId;
            case WeeklyGoalScope.category:
              final activity = activitiesById[log.activityId];
              return activity?.categoryId == goal.categoryId;
          }
        }).toList();

    switch (goal.type ?? WeeklyGoalType.completions) {
      case WeeklyGoalType.completions:
        return matchedLogs.length.toDouble();
      case WeeklyGoalType.activeDays:
        return matchedLogs.map((log) => log.dayKey).toSet().length.toDouble();
      case WeeklyGoalType.qualityPoints:
        return matchedLogs.fold<double>(0, (sum, log) {
          final quality =
              log.completionQuality ?? ActivityCompletionQuality.medium;
          return sum + quality.weight;
        });
    }
  }

  static DateTime _normalize(DateTime date) =>
      DateTime(date.year, date.month, date.day);
}
