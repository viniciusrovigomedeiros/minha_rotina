import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils/date_utils.dart';
import '../data/models/activity_completion_payload.dart';
import '../data/models/activity_completion_quality.dart';
import '../data/models/activity.dart';
import '../data/models/activity_status.dart';
import '../data/models/daily_activity_log.dart';
import 'activities_controller.dart';
import 'history_controller.dart';
import 'providers.dart';
import 'weekly_dashboard_controller.dart';
import 'weekly_goals_controller.dart';

class TodayActivityItem {
  const TodayActivityItem({
    required this.activity,
    required this.status,
    required this.completionQuality,
    required this.qualityScore,
    this.weeklyCompletedCount,
    this.weeklyTargetCount,
    this.isSuggestedToday = false,
  });

  final Activity activity;
  final ActivityStatus status;
  final ActivityCompletionQuality? completionQuality;
  final int? qualityScore;
  final int? weeklyCompletedCount;
  final int? weeklyTargetCount;
  final bool isSuggestedToday;

  TodayActivityItem copyWith({
    ActivityStatus? status,
    ActivityCompletionQuality? completionQuality,
    int? qualityScore,
    int? weeklyCompletedCount,
    int? weeklyTargetCount,
    bool? isSuggestedToday,
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

  int get total => items.length;

  int get completedCount =>
      items.where((item) => item.status == ActivityStatus.completed).length;

  int get skippedCount =>
      items.where((item) => item.status == ActivityStatus.skipped).length;

  double get completionRate => total == 0 ? 0 : completedCount / total;
}

final todayControllerProvider =
    AsyncNotifierProvider<TodayController, TodayState>(TodayController.new);

class TodayController extends AsyncNotifier<TodayState> {
  @override
  Future<TodayState> build() async {
    ref.listen<AsyncValue<List<Activity>>>(activitiesControllerProvider, (
      _,
      __,
    ) async {
      await reload();
    });

    return _load(DateTime.now());
  }

  Future<void> reload() async {
    final selectedDate = state.value?.date ?? DateTime.now();
    state = await AsyncValue.guard(() async {
      return _load(selectedDate);
    });
  }

  Future<void> selectDate(DateTime date) async {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final currentDate = state.value?.date;
    if (currentDate != null &&
        currentDate.year == normalizedDate.year &&
        currentDate.month == normalizedDate.month &&
        currentDate.day == normalizedDate.day) {
      return;
    }

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      return _load(normalizedDate);
    });
  }

  Future<TodayState> _load(DateTime date) async {
    final activities = await ref.read(activityRepositoryProvider).getAll();
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final dayKey = DateUtilsX.toDayKey(date);
    final allLogs = await ref.read(dailyLogRepositoryProvider).getAll();
    final logs = allLogs.where((log) => log.dayKey == dayKey).toList();

    final logsByActivityId = {for (final log in logs) log.activityId: log};
    final weekStart = _startOfWeek(normalizedDate);
    final weekEnd = weekStart.add(const Duration(days: 6));

    final todayActivities =
        activities
            .where(
              (activity) => _isScheduledActivityForDate(activity, normalizedDate),
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
          return TodayActivityItem(
            activity: activity,
            status: log?.status ?? ActivityStatus.pending,
            completionQuality: log?.completionQuality,
            qualityScore: log?.qualityScore,
          );
        }).toList();

    final weeklyGoalItems =
        activities
            .where(
              (activity) =>
                  activity.isActive &&
                  activity.recurrence == ActivityRecurrence.weekly &&
                  _isCreatedBeforeDayEnd(activity, normalizedDate) &&
                  _shouldShowFlexibleWeeklyActivity(
                    activity: activity,
                    date: normalizedDate,
                    allLogs: allLogs,
                  ),
            )
            .map((activity) {
              final log = logsByActivityId[activity.id];
              final completedCount = _completedCountForWeekUntilDate(
                activityId: activity.id,
                allLogs: allLogs,
                weekStart: weekStart,
                weekEnd: weekEnd,
                endDate: normalizedDate,
              );

              return TodayActivityItem(
                activity: activity,
                status: log?.status ?? ActivityStatus.pending,
                completionQuality: log?.completionQuality,
                qualityScore: log?.qualityScore,
                weeklyCompletedCount: completedCount,
                weeklyTargetCount: activity.effectiveWeeklyTargetCount,
                isSuggestedToday: activity.weekdays.contains(normalizedDate.weekday),
              );
            })
            .toList()
          ..sort((a, b) {
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

  Future<void> updateStatus({
    required String activityId,
    required ActivityStatus status,
    ActivityCompletionQuality? completionQuality,
    ActivityCompletionPayload? completionPayload,
  }) async {
    final current = state.value;
    if (current == null) return;

    final dayKey = DateUtilsX.toDayKey(current.date);
    final updatedLog = await ref
        .read(dailyLogRepositoryProvider)
        .upsertStatus(
          activityId: activityId,
          dayKey: dayKey,
          status: status,
          completionQuality:
              completionPayload?.completionQuality ?? completionQuality,
          qualityScore: completionPayload?.qualityScore,
          qualityChecklistCheckedCount:
              completionPayload?.checklistCheckedCount,
          qualityChecklistTotalCount: completionPayload?.checklistTotalCount,
        );

    final updatedItems =
        current.items.map((item) {
          if (item.activity.id != activityId) return item;
          return item.copyWith(
            status: updatedLog.status,
            completionQuality: updatedLog.completionQuality,
            qualityScore: updatedLog.qualityScore,
            clearCompletionQuality:
                updatedLog.status != ActivityStatus.completed,
            clearQualityScore: updatedLog.status != ActivityStatus.completed,
          );
        }).toList();
    final updatedWeeklyGoalItems =
        current.weeklyGoalItems.map((item) {
          if (item.activity.id != activityId) return item;
          final nextWeeklyCompletedCount =
              updatedLog.status == ActivityStatus.completed
                  ? ((item.weeklyCompletedCount ?? 0) +
                          (item.status == ActivityStatus.completed ? 0 : 1))
                      .clamp(0, item.weeklyTargetCount ?? 7)
                  : updatedLog.status == ActivityStatus.pending &&
                          item.status == ActivityStatus.completed
                  ? ((item.weeklyCompletedCount ?? 0) - 1).clamp(0, 7)
                  : item.weeklyCompletedCount;
          return item.copyWith(
            status: updatedLog.status,
            completionQuality: updatedLog.completionQuality,
            qualityScore: updatedLog.qualityScore,
            weeklyCompletedCount: nextWeeklyCompletedCount,
            clearCompletionQuality:
                updatedLog.status != ActivityStatus.completed,
            clearQualityScore: updatedLog.status != ActivityStatus.completed,
          );
        }).toList();

    state = AsyncData(
      TodayState(
        date: current.date,
        items: updatedItems,
        weeklyGoalItems: updatedWeeklyGoalItems,
      ),
    );
    ref.invalidate(historyControllerProvider);
    ref.invalidate(weeklyDashboardControllerProvider);
    ref.invalidate(weeklyGoalsControllerProvider);
    await _syncNotifications();
    await reload();
  }

  Future<void> _syncNotifications() async {
    final settings = await ref.read(userSettingsRepositoryProvider).get();
    final activities = await ref.read(activityRepositoryProvider).getAll();
    final phrases = await ref.read(motivationPhraseRepositoryProvider).getAll();
    final goals = await ref.read(weeklyGoalRepositoryProvider).getAll();
    final dailyLogs = await ref.read(dailyLogRepositoryProvider).getAll();
    await ref
        .read(notificationServiceProvider)
        .syncNotifications(
          activities: activities,
          settings: settings,
          motivationPhrases: phrases,
          goals: goals,
          dailyLogs: dailyLogs,
        );
  }

  bool _isScheduledActivityForDate(Activity activity, DateTime date) {
    if (!activity.isActive || !_isCreatedBeforeDayEnd(activity, date)) {
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

  bool _shouldShowFlexibleWeeklyActivity({
    required Activity activity,
    required DateTime date,
    required List<DailyActivityLog> allLogs,
  }) {
    final weekStart = _startOfWeek(date);
    final previousDay = date.subtract(const Duration(days: 1));
    final completedBeforeToday = _completedCountForWeekUntilDate(
      activityId: activity.id,
      allLogs: allLogs,
      weekStart: weekStart,
      weekEnd: weekStart.add(const Duration(days: 6)),
      endDate: previousDay,
    );
    final todayLogExists = allLogs.any(
      (log) => log.activityId == activity.id && log.dayKey == DateUtilsX.toDayKey(date),
    );

    return todayLogExists ||
        completedBeforeToday < activity.effectiveWeeklyTargetCount;
  }

  int _completedCountForWeekUntilDate({
    required String activityId,
    required List<DailyActivityLog> allLogs,
    required DateTime weekStart,
    required DateTime weekEnd,
    required DateTime endDate,
  }) {
    return allLogs.where((log) {
      if (log.activityId != activityId || log.status != ActivityStatus.completed) {
        return false;
      }
      final logDate = DateUtilsX.fromDayKey(log.dayKey);
      return !logDate.isBefore(weekStart) &&
          !logDate.isAfter(weekEnd) &&
          !logDate.isAfter(endDate);
    }).length;
  }

  DateTime _startOfWeek(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  bool _isCreatedBeforeDayEnd(Activity activity, DateTime date) {
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
    return !activity.createdAt.isAfter(endOfDay);
  }

  bool _isSameDay(DateTime? a, DateTime b) {
    if (a == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
