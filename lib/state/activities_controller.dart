import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../data/models/activity.dart';
import 'history_controller.dart';
import 'providers.dart';
import 'weekly_dashboard_controller.dart';
import 'weekly_goals_controller.dart';

final activitiesControllerProvider =
    AsyncNotifierProvider<ActivitiesController, List<Activity>>(
      ActivitiesController.new,
    );

class ActivitiesController extends AsyncNotifier<List<Activity>> {
  final Uuid _uuid = const Uuid();

  @override
  Future<List<Activity>> build() async {
    final activities = await ref.read(activityRepositoryProvider).getAll();
    await _syncNotificationsWith(activities);
    return activities;
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      return ref.read(activityRepositoryProvider).getAll();
    });
    await _syncNotifications();
    _invalidateDerivedStates();
  }

  Future<void> create({
    required String name,
    String? description,
    required String categoryId,
    required List<int> weekdays,
    ActivityRecurrence recurrence = ActivityRecurrence.flexible,
    int? startMinutes,
    int? endMinutes,
    int? colorHex,
    String? iconKey,
    String? objectiveId,
    String? keyResultId,
    DateTime? scheduledDate,
    bool isActive = true,
    bool remindersEnabled = false,
  }) async {
    final now = DateTime.now();
    final activity = Activity(
      id: _uuid.v4(),
      name: name.trim(),
      description:
          description?.trim().isEmpty ?? true ? null : description?.trim(),
      categoryId: categoryId,
      weekdays: weekdays,
      startMinutes: startMinutes,
      endMinutes: endMinutes,
      colorHex: colorHex,
      iconKey: iconKey,
      objectiveId: objectiveId,
      keyResultId: keyResultId,
      recurrence: recurrence,
      scheduledDate: scheduledDate,
      isActive: isActive,
      remindersEnabled: remindersEnabled,
      createdAt: now,
      updatedAt: now,
    );

    await ref.read(activityRepositoryProvider).upsert(activity);
    await reload();
  }

  Future<void> updateActivity(Activity activity) async {
    await ref
        .read(activityRepositoryProvider)
        .upsert(activity.copyWith(updatedAt: DateTime.now()));
    await reload();
  }

  Future<void> delete(String id) async {
    await ref.read(activityRepositoryProvider).delete(id);
    await ref.read(dailyLogRepositoryProvider).deleteByActivity(id);
    await reload();
  }

  Future<void> _syncNotifications() async {
    final activities = state.valueOrNull;
    if (activities == null) return;
    await _syncNotificationsWith(activities);
  }

  Future<void> _syncNotificationsWith(List<Activity> activities) async {
    final settings = await ref.read(userSettingsRepositoryProvider).get();
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
    ref.invalidate(historyControllerProvider);
    ref.invalidate(weeklyDashboardControllerProvider);
    ref.invalidate(weeklyGoalsControllerProvider);
  }
}
