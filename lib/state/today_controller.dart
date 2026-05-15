import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils/date_utils.dart';
import '../data/models/activity.dart';
import '../data/models/activity_status.dart';
import 'activities_controller.dart';
import 'history_controller.dart';
import 'providers.dart';
import 'weekly_dashboard_controller.dart';

class TodayActivityItem {
  const TodayActivityItem({required this.activity, required this.status});

  final Activity activity;
  final ActivityStatus status;

  TodayActivityItem copyWith({ActivityStatus? status}) {
    return TodayActivityItem(activity: activity, status: status ?? this.status);
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
          );
        }).toList();

    return TodayState(date: date, items: items);
  }

  Future<void> updateStatus({
    required String activityId,
    required ActivityStatus status,
  }) async {
    final current = state.value;
    if (current == null) return;

    final dayKey = DateUtilsX.toDayKey(current.date);
    await ref
        .read(dailyLogRepositoryProvider)
        .upsertStatus(activityId: activityId, dayKey: dayKey, status: status);

    final updatedItems =
        current.items.map((item) {
          if (item.activity.id != activityId) return item;
          return item.copyWith(status: status);
        }).toList();

    state = AsyncData(TodayState(date: current.date, items: updatedItems));
    ref.invalidate(historyControllerProvider);
    ref.invalidate(weeklyDashboardControllerProvider);
  }
}
