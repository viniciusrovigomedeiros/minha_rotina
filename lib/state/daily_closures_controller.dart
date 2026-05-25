import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/daily_closure_entry.dart';
import 'history_controller.dart';
import 'providers.dart';
import 'weekly_dashboard_controller.dart';

final dailyClosuresControllerProvider = AsyncNotifierProvider<
  DailyClosuresController,
  Map<String, DailyClosureEntry>
>(DailyClosuresController.new);

class DailyClosuresController
    extends AsyncNotifier<Map<String, DailyClosureEntry>> {
  @override
  Future<Map<String, DailyClosureEntry>> build() async {
    return _load();
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }

  Future<void> saveForDay({
    required String dayKey,
    required String bestWork,
    required String lostStandard,
    required String improvementForTomorrow,
  }) async {
    final saved = await ref
        .read(dailyClosureRepositoryProvider)
        .upsertForDay(
          dayKey: dayKey,
          bestWork: bestWork.trim(),
          lostStandard: lostStandard.trim(),
          improvementForTomorrow: improvementForTomorrow.trim(),
        );

    final current = Map<String, DailyClosureEntry>.from(
      state.valueOrNull ?? {},
    );
    current[saved.dayKey] = saved;
    state = AsyncData(current);

    ref.invalidate(historyControllerProvider);
    ref.invalidate(weeklyDashboardControllerProvider);
  }

  Future<Map<String, DailyClosureEntry>> _load() async {
    final entries = await ref.read(dailyClosureRepositoryProvider).getAll();
    return {for (final entry in entries) entry.dayKey: entry};
  }
}
