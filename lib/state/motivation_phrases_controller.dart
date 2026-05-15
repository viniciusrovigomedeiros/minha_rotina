import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils/motivation_utils.dart';
import 'providers.dart';

final motivationPhrasesControllerProvider =
    AsyncNotifierProvider<MotivationPhrasesController, List<String>>(
      MotivationPhrasesController.new,
    );

class MotivationPhrasesController extends AsyncNotifier<List<String>> {
  @override
  Future<List<String>> build() async {
    return ref.read(motivationPhraseRepositoryProvider).getAll();
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      return ref.read(motivationPhraseRepositoryProvider).getAll();
    });
  }

  Future<void> addPhrase(String phrase) async {
    final text = phrase.trim();
    if (text.isEmpty) return;

    final current = List<String>.from(state.valueOrNull ?? const []);
    current.add(text);
    await ref.read(motivationPhraseRepositoryProvider).saveAll(current);
    state = AsyncData(current);
    await _syncNotifications(current);
  }

  Future<void> removeAt(int index) async {
    final current = List<String>.from(state.valueOrNull ?? const []);
    if (index < 0 || index >= current.length) return;

    current.removeAt(index);
    await ref.read(motivationPhraseRepositoryProvider).saveAll(current);
    state = AsyncData(current);
    await _syncNotifications(current);
  }

  Future<void> clearAll() async {
    await ref.read(motivationPhraseRepositoryProvider).clearAll();
    state = const AsyncData([]);
    await _syncNotifications(const []);
  }

  Future<void> restoreDefaults() async {
    await ref.read(motivationPhraseRepositoryProvider).restoreDefaults();
    final restored = List<String>.from(MotivationUtils.defaultPhrases);
    state = AsyncData(restored);
    await _syncNotifications(restored);
  }

  Future<void> _syncNotifications(List<String> phrases) async {
    final settings = await ref.read(userSettingsRepositoryProvider).get();
    final activities = await ref.read(activityRepositoryProvider).getAll();
    await ref
        .read(notificationServiceProvider)
        .syncNotifications(
          activities: activities,
          settings: settings,
          motivationPhrases: phrases,
        );
  }
}
