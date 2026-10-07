import '../../../data/models/activity.dart';
import '../../../data/models/activity_completion_quality.dart';
import '../../../data/models/activity_status.dart';

class TodayActivityItem {
  const TodayActivityItem({
    required this.activity,
    required this.status,
    required this.completionQuality,
    required this.qualityScore,
    this.weeklyCompletedCount,
    this.weeklyTargetCount,
    this.isSuggestedToday = false,
    this.countsTowardDailyProgress = true,
    this.weeklyDeadlineLabel,
    this.isDueTodayInWeeklyGoals = false,
    this.okrCompletedCount,
    this.okrPlannedCount,
  });

  final Activity activity;
  final ActivityStatus status;
  final ActivityCompletionQuality? completionQuality;
  final int? qualityScore;
  final int? weeklyCompletedCount;
  final int? weeklyTargetCount;
  final bool isSuggestedToday;
  final bool countsTowardDailyProgress;
  final String? weeklyDeadlineLabel;
  final bool isDueTodayInWeeklyGoals;
  final int? okrCompletedCount;
  final int? okrPlannedCount;

  TodayActivityItem copyWith({
    ActivityStatus? status,
    ActivityCompletionQuality? completionQuality,
    int? qualityScore,
    int? weeklyCompletedCount,
    int? weeklyTargetCount,
    bool? isSuggestedToday,
    bool? countsTowardDailyProgress,
    String? weeklyDeadlineLabel,
    bool? isDueTodayInWeeklyGoals,
    int? okrCompletedCount,
    int? okrPlannedCount,
    bool clearCompletionQuality = false,
    bool clearQualityScore = false,
  }) {
    return TodayActivityItem(
      activity: activity,
      status: status ?? this.status,
      completionQuality:
          clearCompletionQuality
              ? null
              : completionQuality ?? this.completionQuality,
      qualityScore:
          clearQualityScore ? null : qualityScore ?? this.qualityScore,
      weeklyCompletedCount: weeklyCompletedCount ?? this.weeklyCompletedCount,
      weeklyTargetCount: weeklyTargetCount ?? this.weeklyTargetCount,
      isSuggestedToday: isSuggestedToday ?? this.isSuggestedToday,
      countsTowardDailyProgress:
          countsTowardDailyProgress ?? this.countsTowardDailyProgress,
      weeklyDeadlineLabel: weeklyDeadlineLabel ?? this.weeklyDeadlineLabel,
      isDueTodayInWeeklyGoals:
          isDueTodayInWeeklyGoals ?? this.isDueTodayInWeeklyGoals,
      okrCompletedCount: okrCompletedCount ?? this.okrCompletedCount,
      okrPlannedCount: okrPlannedCount ?? this.okrPlannedCount,
    );
  }
}

class TodayState {
  const TodayState({
    required this.date,
    required this.items,
    required this.weeklyGoalItems,
  });

  final DateTime date;
  final List<TodayActivityItem> items;
  final List<TodayActivityItem> weeklyGoalItems;

  Iterable<TodayActivityItem> get countedItems => [
    ...items,
    ...weeklyGoalItems.where((item) => item.countsTowardDailyProgress),
  ];

  int get total => countedItems.length;

  int get completedCount =>
      countedItems
          .where((item) => item.status == ActivityStatus.completed)
          .length;

  int get skippedCount =>
      countedItems
          .where((item) => item.status == ActivityStatus.skipped)
          .length;

  int get pendingCount =>
      countedItems
          .where((item) => item.status == ActivityStatus.pending)
          .length;

  double get completionRate => total == 0 ? 0 : completedCount / total;

  TodayActivityItem? get nextPendingItem {
    for (final item in countedItems) {
      if (item.status == ActivityStatus.pending) {
        return item;
      }
    }
    return null;
  }
}
