import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../data/models/activity.dart';
import 'providers.dart';

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
  }

  Future<void> create({
    required String name,
    String? description,
    required String categoryId,
    required List<int> weekdays,
    int? startMinutes,
    int? endMinutes,
    int? colorHex,
    String? iconKey,
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
    await ref
        .read(notificationServiceProvider)
        .syncNotifications(
          activities: activities,
          settings: settings,
          motivationPhrases: phrases,
        );
  }
}
