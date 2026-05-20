import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils/date_utils.dart';
import '../data/models/activity_completion_quality.dart';
import '../data/models/activity.dart';
import '../data/models/activity_status.dart';
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
  });

  final Activity activity;
  final ActivityStatus status;
  final ActivityCompletionQuality? completionQuality;

  TodayActivityItem copyWith({
    ActivityStatus? status,
    ActivityCompletionQuality? completionQuality,
    bool clearCompletionQuality = false,
  }) {
    return TodayActivityItem(
      activity: activity,
      status: status ?? this.status,
      completionQuality:
          clearCompletionQuality
              ? null
              : completionQuality ?? this.completionQuality,
    );
  }
}

class TodayState {
  const TodayState({required this.date, required this.items});

  final DateTime date;
  final List<TodayActivityItem> items;

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
    state = await AsyncValue.guard(() async {
      return _load(DateTime.now());
    });
  }

  Future<TodayState> _load(DateTime date) async {
    final activities = await ref.read(activityRepositoryProvider).getAll();
    final dayWeek = date.weekday;
    final dayKey = DateUtilsX.toDayKey(date);
    final logs = await ref
        .read(dailyLogRepositoryProvider)
        .findByDayKey(dayKey);

    final logsByActivityId = {for (final log in logs) log.activityId: log};

    final todayActivities =
        activities
            .where(
              (activity) =>
                  activity.isActive && activity.weekdays.contains(dayWeek),
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
          );
        }).toList();

    return TodayState(date: date, items: items);
  }

  Future<void> updateStatus({
    required String activityId,
    required ActivityStatus status,
    ActivityCompletionQuality? completionQuality,
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
          completionQuality: completionQuality,
        );

    final updatedItems =
        current.items.map((item) {
          if (item.activity.id != activityId) return item;
          return item.copyWith(
            status: updatedLog.status,
            completionQuality: updatedLog.completionQuality,
            clearCompletionQuality:
                updatedLog.status != ActivityStatus.completed,
          );
        }).toList();

    state = AsyncData(TodayState(date: current.date, items: updatedItems));
    ref.invalidate(historyControllerProvider);
    ref.invalidate(weeklyDashboardControllerProvider);
    ref.invalidate(weeklyGoalsControllerProvider);
    await _syncNotifications();
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
}
