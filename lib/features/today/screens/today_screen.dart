import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/activity_completion_payload.dart';
import '../../../data/models/activity_completion_quality.dart';
import '../../../data/models/activity_status.dart';
import '../../../state/categories_controller.dart';
import '../../../state/today_controller.dart';
import '../../focus/screens/activity_focus_screen.dart';
import '../widgets/empty_today_state.dart';
import '../widgets/today_activity_card.dart';
import '../widgets/today_progress_card.dart';

class TodayScreen extends ConsumerStatefulWidget {
  const TodayScreen({super.key});

  @override
  ConsumerState<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends ConsumerState<TodayScreen> {
  @override
  Widget build(BuildContext context) {
    final todayAsync = ref.watch(todayControllerProvider);
    final categoriesAsync = ref.watch(categoriesControllerProvider);

    return todayAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Erro ao carregar: $error')),
      data: (todayState) {
        final now = DateTime.now();
        final selectedDate = todayState.date;
        final isViewingToday = _isSameDay(selectedDate, now);
        final categories = categoriesAsync.valueOrNull ?? const [];
        final bottomSpacing = MediaQuery.paddingOf(context).bottom + 132;

        return SafeArea(
          bottom: false,
          child: RefreshIndicator(
            onRefresh:
                () => ref.read(todayControllerProvider.notifier).reload(),
            child: ListView(
              padding: EdgeInsets.fromLTRB(14, 16, 14, bottomSpacing),
              children: [
                TodayProgressCard(
                  total: todayState.total,
                  completed: todayState.completedCount,
                  skipped: todayState.skippedCount,
                  rate: todayState.completionRate,
                ),
                const SizedBox(height: 18),
                Text(
                  isViewingToday ? 'Atividades de hoje' : 'Atividades do dia',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Essas iniciativas contam para o progresso de hoje.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                const SizedBox(height: 10),
                if (todayState.items.isEmpty &&
                    todayState.weeklyGoalItems.isEmpty)
                  const EmptyTodayState()
                else if (todayState.items.isNotEmpty)
                  Card(
                    child: Column(
                      children: [
                        for (
                          int index = 0;
                          index < todayState.items.length;
                          index++
                        ) ...[
                          Builder(
                            builder: (context) {
                              final item = todayState.items[index];
                              final categoryMatch =
                                  categories
                                      .where(
                                        (cat) =>
                                            cat.id == item.activity.categoryId,
                                      )
                                      .toList();
                              final category =
                                  categoryMatch.isEmpty
                                      ? null
                                      : categoryMatch.first;

                              return TodayActivityCard(
                                item: item,
                                category: category,
                                onComplete:
                                    (completion) => _setStatus(
                                      ref,
                                      item.activity.id,
                                      ActivityStatus.completed,
                                      context,
                                      completionPayload: completion,
                                    ),
                                onSkip:
                                    () => _setStatus(
                                      ref,
                                      item.activity.id,
                                      ActivityStatus.skipped,
                                      context,
                                    ),
                                onReset:
                                    () => _setStatus(
                                      ref,
                                      item.activity.id,
                                      ActivityStatus.pending,
                                      context,
                                    ),
                                onOpen: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder:
                                          (_) => ActivityFocusScreen(
                                            activity: item.activity,
                                          ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                          if (index < todayState.items.length - 1)
                            const Divider(height: 1, thickness: 1),
                        ],
                      ],
                    ),
                  ),
                if (todayState.weeklyGoalItems.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Metas da semana',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'A tag mostra o último dia para começar sem perder a meta da semana.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Card(
                    child: Column(
                      children: [
                        for (
                          int index = 0;
                          index < todayState.weeklyGoalItems.length;
                          index++
                        ) ...[
                          Builder(
                            builder: (context) {
                              final item = todayState.weeklyGoalItems[index];
                              final categoryMatch =
                                  categories
                                      .where(
                                        (cat) =>
                                            cat.id == item.activity.categoryId,
                                      )
                                      .toList();
                              final category =
                                  categoryMatch.isEmpty
                                      ? null
                                      : categoryMatch.first;

                              return TodayActivityCard(
                                item: item,
                                category: category,
                                onComplete:
                                    (completion) => _setStatus(
                                      ref,
                                      item.activity.id,
                                      ActivityStatus.completed,
                                      context,
                                      completionPayload: completion,
                                    ),
                                onSkip:
                                    () => _setStatus(
                                      ref,
                                      item.activity.id,
                                      ActivityStatus.skipped,
                                      context,
                                    ),
                                onReset:
                                    () => _setStatus(
                                      ref,
                                      item.activity.id,
                                      ActivityStatus.pending,
                                      context,
                                    ),
                                onOpen: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder:
                                          (_) => ActivityFocusScreen(
                                            activity: item.activity,
                                          ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                          if (index < todayState.weeklyGoalItems.length - 1)
                            const Divider(height: 1, thickness: 1),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<void> _setStatus(
    WidgetRef ref,
    String activityId,
    ActivityStatus status,
    BuildContext context, {
    ActivityCompletionPayload? completionPayload,
  }) async {
    await ref
        .read(todayControllerProvider.notifier)
        .updateStatus(
          activityId: activityId,
          status: status,
          completionQuality: completionPayload?.completionQuality,
          completionPayload: completionPayload,
        );

    if (!context.mounted) return;

    final message =
        status == ActivityStatus.completed
            ? 'Boa! Qualidade ${completionPayload?.qualityScore ?? '-'} /10 (${completionPayload?.completionQuality.label.toLowerCase() ?? 'ok'}).'
            : status == ActivityStatus.skipped
            ? 'Tudo bem, atividade marcada como pulada.'
            : 'Atividade voltou para pendente.';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(milliseconds: 1200),
      ),
    );
  }
}
