import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils/weekly_goal_progress_utils.dart';
import 'providers.dart';

final weeklyGoalsControllerProvider =
    AsyncNotifierProvider<WeeklyGoalsController, List<WeeklyGoalProgress>>(
      WeeklyGoalsController.new,
    );

class WeeklyGoalsController extends AsyncNotifier<List<WeeklyGoalProgress>> {
  @override
  Future<List<WeeklyGoalProgress>> build() async {
    return _load();
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }

  Future<List<WeeklyGoalProgress>> _load() async {
    final goals = await ref.read(weeklyGoalRepositoryProvider).getAll();
    final activities = await ref.read(activityRepositoryProvider).getAll();
    final dailyLogs = await ref.read(dailyLogRepositoryProvider).getAll();

    return WeeklyGoalProgressUtils.buildProgresses(
      goals: goals,
      activities: activities,
      dailyLogs: dailyLogs,
    );
  }
}
