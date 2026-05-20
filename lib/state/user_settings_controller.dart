import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/user_settings.dart';
import 'providers.dart';

final userSettingsControllerProvider =
    AsyncNotifierProvider<UserSettingsController, UserSettings>(
      UserSettingsController.new,
    );

class UserSettingsController extends AsyncNotifier<UserSettings> {
  @override
  Future<UserSettings> build() async {
    return ref.read(userSettingsRepositoryProvider).get();
  }

  Future<void> updateName(String name) async {
    final current = state.value;
    if (current == null) return;

    final updated = current.copyWith(
      userName: name.trim().isEmpty ? current.userName : name.trim(),
      updatedAt: DateTime.now(),
    );

    await _save(updated);
  }

  Future<void> updateThemeKey(String themeKey) async {
    final current = state.value;
    if (current == null) return;
    await _save(
      current.copyWith(themeKey: themeKey, updatedAt: DateTime.now()),
    );
  }

  Future<void> updateMotivationPhraseMode(String mode) async {
    final current = state.value;
    if (current == null) return;
    await _save(
      current.copyWith(
        motivationPhraseMode: mode,
        clearFixedMotivationPhrase: mode == 'daily',
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> updateFixedMotivationPhrase(String phrase) async {
    final current = state.value;
    if (current == null) return;
    await _save(
      current.copyWith(
        motivationPhraseMode: 'fixed',
        fixedMotivationPhrase: phrase,
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> updateNotificationsEnabled(bool value) async {
    final current = state.value;
    if (current == null) return;
    await _save(
      current.copyWith(notificationsEnabled: value, updatedAt: DateTime.now()),
    );
  }

  Future<void> updateActivityRemindersEnabled(bool value) async {
    final current = state.value;
    if (current == null) return;
    await _save(
      current.copyWith(
        activityReminderNotificationsEnabled: value,
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> updateGoalRemindersEnabled(bool value) async {
    final current = state.value;
    if (current == null) return;
    await _save(
      current.copyWith(
        goalReminderNotificationsEnabled: value,
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> updateBedtimeMotivationEnabled(bool value) async {
    final current = state.value;
    if (current == null) return;
    await _save(
      current.copyWith(
        bedtimeMotivationEnabled: value,
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> updateBedtimeMotivationMinutes(int minutes) async {
    final current = state.value;
    if (current == null) return;
    await _save(
      current.copyWith(
        bedtimeMotivationMinutes: minutes,
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> updateGoalReminderMinutes(int minutes) async {
    final current = state.value;
    if (current == null) return;
    await _save(
      current.copyWith(goalReminderMinutes: minutes, updatedAt: DateTime.now()),
    );
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      return ref.read(userSettingsRepositoryProvider).get();
    });
  }

  Future<void> _save(UserSettings updated) async {
    await ref.read(userSettingsRepositoryProvider).save(updated);
    state = AsyncData(updated);
    await _syncNotifications(updated);
  }

  Future<void> _syncNotifications(UserSettings settings) async {
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
