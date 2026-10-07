import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/services/daily_goal_live_activity_service.dart';
import '../data/models/activity_status.dart';
import '../features/today/models/today_state.dart';
import '../features/today/services/today_state_loader.dart';

final dailyGoalLiveActivityServiceProvider =
    Provider<DailyGoalLiveActivityService>((ref) {
      return DailyGoalLiveActivityService();
    });

final dailyGoalLiveActivitySyncProvider = Provider<DailyGoalLiveActivitySync>((
  ref,
) {
  return DailyGoalLiveActivitySync(ref);
});

class DailyGoalLiveActivitySync {
  const DailyGoalLiveActivitySync(this._ref);

  final Ref _ref;

  Future<void> refresh() async {
    final state = await _ref
        .read(todayStateLoaderProvider)
        .load(DateTime.now());
    if (state.items.isEmpty && state.weeklyGoalItems.isEmpty) {
      await _ref.read(dailyGoalLiveActivityServiceProvider).end();
      return;
    }

    await _ref
        .read(dailyGoalLiveActivityServiceProvider)
        .sync(buildDailyGoalLiveActivityPayload(state));
  }
}

DailyGoalLiveActivityPayload buildDailyGoalLiveActivityPayload(
  TodayState state,
) {
  // A weekly suggestion is optional even after completing it adds it to the
  // daily progress. Only its actual deadline makes it required today.
  final requiredIds = {
    for (final item in state.items) item.activity.id,
    for (final item in state.weeklyGoalItems)
      if (item.isDueTodayInWeeklyGoals) item.activity.id,
  };
  final items =
      {
        for (final item in [...state.weeklyGoalItems, ...state.items])
          item.activity.id: item,
      }.values.toList();
  final requiredItems =
      items.where((item) => requiredIds.contains(item.activity.id)).toList();
  final requiredPending =
      requiredItems
          .where((item) => item.status == ActivityStatus.pending)
          .toList();
  final optionalPending =
      items
          .where(
            (item) =>
                !requiredIds.contains(item.activity.id) &&
                item.status == ActivityStatus.pending,
          )
          .toList();
  final completed =
      items.where((item) => item.status == ActivityStatus.completed).toList();
  final requiredCompleted =
      requiredItems
          .where((item) => item.status == ActivityStatus.completed)
          .length;
  final requiredSkipped =
      requiredItems
          .where((item) => item.status == ActivityStatus.skipped)
          .length;

  // Keep previews bounded: ActivityKit shares a 4 KB budget for all content.
  List<String> titles(List<TodayActivityItem> group) =>
      group.take(2).map((item) {
        final name = item.activity.name.replaceAll(RegExp(r'\s+'), ' ').trim();
        return name.runes.length > 40
            ? '${String.fromCharCodes(name.runes.take(39))}…'
            : name;
      }).toList();

  final statusText =
      requiredPending.isNotEmpty
          ? 'Próxima: ${titles(requiredPending).first}'
          : requiredSkipped > 0
          ? requiredSkipped == 1
              ? '1 obrigatória pulada'
              : '$requiredSkipped obrigatórias puladas'
          : requiredItems.isEmpty
          ? 'Sem obrigatórias hoje'
          : 'Obrigatórias concluídas';

  return DailyGoalLiveActivityPayload(
    title: 'Minha rotina',
    dateLabel: DateFormat('d MMM', 'pt_BR').format(state.date),
    summaryText:
        '${completed.length} feitas · '
        '${requiredPending.length} obrigatórias · '
        '${optionalPending.length} opcionais',
    statusText: statusText,
    completedCount: completed.length,
    totalCount: items.length,
    skippedCount:
        items.where((item) => item.status == ActivityStatus.skipped).length,
    pendingCount: requiredPending.length + optionalPending.length,
    progress:
        requiredItems.isEmpty ? 0 : requiredCompleted / requiredItems.length,
    requiredTotalCount: requiredItems.length,
    requiredCompletedCount: requiredCompleted,
    requiredPendingCount: requiredPending.length,
    requiredSkippedCount: requiredSkipped,
    optionalPendingCount: optionalPending.length,
    requiredPendingTitles: titles(requiredPending),
    optionalPendingTitles: titles(optionalPending),
    completedTitles: titles(completed),
  );
}
