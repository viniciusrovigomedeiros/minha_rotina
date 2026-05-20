import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../data/models/weekly_goal.dart';
import 'providers.dart';
import 'weekly_dashboard_controller.dart';
import 'weekly_goals_controller.dart';

final goalsControllerProvider =
    AsyncNotifierProvider<GoalsController, List<WeeklyGoal>>(
      GoalsController.new,
    );

class GoalsController extends AsyncNotifier<List<WeeklyGoal>> {
  final Uuid _uuid = const Uuid();

  @override
  Future<List<WeeklyGoal>> build() async {
    return ref.read(weeklyGoalRepositoryProvider).getAll();
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      return ref.read(weeklyGoalRepositoryProvider).getAll();
    });
    await _syncNotifications();
    _invalidateDerivedStates();
  }

  Future<void> create({
    required String name,
    required GoalTrackingMode trackingMode,
    required GoalPeriod period,
    WeeklyGoalType? type,
    WeeklyGoalScope? scope,
    required double targetValue,
    required double currentValue,
    String? activityId,
    String? categoryId,
    String? unit,
    DateTime? startDate,
    DateTime? endDate,
    bool isActive = true,
  }) async {
    final now = DateTime.now();
    final goal = WeeklyGoal(
      id: _uuid.v4(),
      name: name.trim(),
      trackingMode: trackingMode,
      period: period,
      type: type,
      scope: scope,
      targetValue: targetValue,
      currentValue: currentValue,
      isActive: isActive,
      createdAt: now,
      updatedAt: now,
      activityId: scope == WeeklyGoalScope.activity ? activityId : null,
      categoryId: scope == WeeklyGoalScope.category ? categoryId : null,
      unit: unit,
      startDate: startDate,
      endDate: endDate,
    );

    await ref.read(weeklyGoalRepositoryProvider).upsert(goal);
    await reload();
  }

  Future<void> updateGoal(WeeklyGoal goal) async {
    await ref
        .read(weeklyGoalRepositoryProvider)
        .upsert(goal.copyWith(updatedAt: DateTime.now()));
    await reload();
  }

  Future<void> delete(String id) async {
    await ref.read(weeklyGoalRepositoryProvider).delete(id);
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

  void _invalidateDerivedStates() {
    ref.invalidate(weeklyGoalsControllerProvider);
    ref.invalidate(weeklyDashboardControllerProvider);
  }
}
