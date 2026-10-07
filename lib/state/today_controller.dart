import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils/date_utils.dart';
import '../data/models/activity.dart';
import '../data/models/activity_completion_payload.dart';
import '../data/models/activity_completion_quality.dart';
import '../data/models/activity_status.dart';
import 'activities_controller.dart';
import 'daily_goal_live_activity_sync.dart';
import '../features/today/models/today_state.dart';
import '../features/today/services/today_state_loader.dart';
import 'history_controller.dart';
import 'providers.dart';
import 'weekly_dashboard_controller.dart';
import 'weekly_goals_controller.dart';

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
    return ref.read(todayStateLoaderProvider).load(date);
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
    await ref.read(dailyGoalLiveActivitySyncProvider).refresh();
  }

  Future<void> _syncNotifications() async {
    final settings = await ref.read(userSettingsRepositoryProvider).get();
    final activities = await ref.read(activityRepositoryProvider).getAll();
    final goals = await ref.read(weeklyGoalRepositoryProvider).getAll();
    final dailyLogs = await ref.read(dailyLogRepositoryProvider).getAll();
    await ref
        .read(notificationServiceProvider)
        .syncNotifications(
          activities: activities,
          settings: settings,
          goals: goals,
          dailyLogs: dailyLogs,
        );
  }
}
