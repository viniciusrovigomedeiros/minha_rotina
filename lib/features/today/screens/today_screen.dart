import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/motivation_utils.dart';
import '../../../core/utils/time_format.dart';
import '../../../data/models/activity_status.dart';
import '../../../state/categories_controller.dart';
import '../../../state/motivation_phrases_controller.dart';
import '../../../state/today_controller.dart';
import '../../../state/user_settings_controller.dart';
import '../../focus/screens/activity_focus_screen.dart';
import '../widgets/empty_today_state.dart';
import '../widgets/motivation_carousel_card.dart';
import '../widgets/today_activity_card.dart';
import '../widgets/today_progress_card.dart';

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayAsync = ref.watch(todayControllerProvider);
    final categoriesAsync = ref.watch(categoriesControllerProvider);
    final settingsAsync = ref.watch(userSettingsControllerProvider);
    final phrasesAsync = ref.watch(motivationPhrasesControllerProvider);

    return todayAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Erro ao carregar: $error')),
      data: (todayState) {
        final now = DateTime.now();
        final settings = settingsAsync.valueOrNull;
        final name = settings?.userName ?? '';
        final greeting = '${MotivationUtils.greetingByTime(now)}, $name';
        final categories = categoriesAsync.valueOrNull ?? const [];
        final phrases = phrasesAsync.valueOrNull ?? const [];
        final fixedPhrase = settings?.fixedMotivationPhrase;
        final isFixedMode = settings?.motivationPhraseMode == 'fixed';
        final fixedIndex =
            fixedPhrase == null ? -1 : phrases.indexOf(fixedPhrase);
        final initialPhraseIndex =
            isFixedMode && fixedIndex >= 0
                ? fixedIndex
                : MotivationUtils.indexForDay(now, length: phrases.length);

        return RefreshIndicator(
          onRefresh: () => ref.read(todayControllerProvider.notifier).reload(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 16, 14, 24),
            children: [
              Text(
                greeting,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                TimeFormat.dateLabel(now),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 14),
              MotivationCarouselCard(
                phrases: phrases,
                initialIndex: initialPhraseIndex,
              ),
              const SizedBox(height: 18),
              TodayProgressCard(
                total: todayState.total,
                completed: todayState.completedCount,
                skipped: todayState.skippedCount,
                rate: todayState.completionRate,
              ),
              const SizedBox(height: 18),
              Text(
                'Atividades de hoje',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              if (todayState.items.isEmpty)
                const EmptyTodayState()
              else
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
                                  () => _setStatus(
                                    ref,
                                    item.activity.id,
                                    ActivityStatus.completed,
                                    context,
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
            ],
          ),
        );
      },
    );
  }

  Future<void> _setStatus(
    WidgetRef ref,
    String activityId,
    ActivityStatus status,
    BuildContext context,
  ) async {
    await ref
        .read(todayControllerProvider.notifier)
        .updateStatus(activityId: activityId, status: status);

    if (!context.mounted) return;

    final message =
        status == ActivityStatus.completed
            ? 'Boa! Atividade concluída.'
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
