import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_utils.dart';
import '../../../core/utils/motivation_utils.dart';
import '../../../core/utils/time_format.dart';
import '../../../data/models/activity_completion_payload.dart';
import '../../../data/models/activity_completion_quality.dart';
import '../../../data/models/daily_closure_entry.dart';
import '../../../data/models/activity_status.dart';
import '../../../state/categories_controller.dart';
import '../../../state/daily_closures_controller.dart';
import '../../../state/motivation_phrases_controller.dart';
import '../../../state/today_controller.dart';
import '../../../state/user_settings_controller.dart';
import '../../focus/screens/activity_focus_screen.dart';
import '../../shared/widgets/daily_closure_sheet.dart';
import '../widgets/empty_today_state.dart';
import '../widgets/motivation_carousel_card.dart';
import '../widgets/today_activity_card.dart';
import '../widgets/today_progress_card.dart';

class TodayScreen extends ConsumerStatefulWidget {
  const TodayScreen({super.key});

  @override
  ConsumerState<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends ConsumerState<TodayScreen> {
  bool _showTopCards = true;

  @override
  Widget build(BuildContext context) {
    final todayAsync = ref.watch(todayControllerProvider);
    final categoriesAsync = ref.watch(categoriesControllerProvider);
    final settingsAsync = ref.watch(userSettingsControllerProvider);
    final phrasesAsync = ref.watch(motivationPhrasesControllerProvider);
    final dailyClosuresAsync = ref.watch(dailyClosuresControllerProvider);

    return todayAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Erro ao carregar: $error')),
      data: (todayState) {
        final now = DateTime.now();
        final selectedDate = todayState.date;
        final selectedDayKey = DateUtilsX.toDayKey(selectedDate);
        final isViewingToday = _isSameDay(selectedDate, now);
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
        final dailyClosure = dailyClosuresAsync.valueOrNull?[selectedDayKey];

        return SafeArea(
          bottom: false,
          child: RefreshIndicator(
            onRefresh:
                () => ref.read(todayControllerProvider.notifier).reload(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(14, 16, 14, 24),
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            greeting,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            TimeFormat.dateLabel(selectedDate),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _showTopCards = !_showTopCards;
                            });
                          },
                          icon: Icon(
                            _showTopCards
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                            size: 18,
                          ),
                          label: Text(
                            _showTopCards ? 'Ocultar cards' : 'Mostrar cards',
                          ),
                        ),
                        const SizedBox(height: 2),
                        Wrap(
                          spacing: 6,
                          children: [
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                minimumSize: const Size(0, 34),
                              ),
                              onPressed:
                                  () => _pickDate(context, ref, selectedDate),
                              icon: const Icon(
                                Icons.calendar_month_rounded,
                                size: 14,
                              ),
                              label: const Text('Escolher dia'),
                            ),
                            if (!isViewingToday)
                              OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                  minimumSize: const Size(0, 34),
                                ),
                                onPressed:
                                    () => ref
                                        .read(todayControllerProvider.notifier)
                                        .selectDate(now),
                                child: const Text('Hoje'),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                if (_showTopCards) ...[
                  const SizedBox(height: 10),
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
                ],
                const SizedBox(height: 18),
                Text(
                  isViewingToday ? 'Atividades de hoje' : 'Atividades do dia',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Conclua cada tarefa com checklist e nota de qualidade.',
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
                    'Metas flexíveis da semana',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Aparecem até você bater a meta semanal, mesmo fora dos dias sugeridos.',
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
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Fechamento diário',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            TextButton(
                              onPressed:
                                  () => _openDailyClosureSheet(
                                    context: context,
                                    ref: ref,
                                    dayKey: selectedDayKey,
                                    existing: dailyClosure,
                                  ),
                              child: Text(
                                dailyClosure == null ? 'Registrar' : 'Editar',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (dailyClosure == null)
                          const Text(
                            'No final do dia, registre sua reflexão para manter o padrão de execução.',
                          )
                        else ...[
                          Text(
                            'Reflexão registrada para este dia.',
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _DailyClosureRow(
                            label: 'O que ficou excelente?',
                            value: dailyClosure.bestWork,
                          ),
                          const SizedBox(height: 8),
                          _DailyClosureRow(
                            label: 'Perda de padrão',
                            value: dailyClosure.lostStandard,
                          ),
                          const SizedBox(height: 8),
                          _DailyClosureRow(
                            label: 'O que melhorar amanhã?',
                            value: dailyClosure.improvementForTomorrow,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickDate(
    BuildContext context,
    WidgetRef ref,
    DateTime selectedDate,
  ) async {
    final today = DateTime.now();
    final lastDate = DateTime(today.year, today.month, today.day);
    final firstDate = DateTime(2000);

    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate.isAfter(lastDate) ? lastDate : selectedDate,
      firstDate: firstDate,
      lastDate: lastDate,
      locale: const Locale('pt', 'BR'),
    );

    if (picked == null) return;
    await ref.read(todayControllerProvider.notifier).selectDate(picked);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<void> _openDailyClosureSheet({
    required BuildContext context,
    required WidgetRef ref,
    required String dayKey,
    required DailyClosureEntry? existing,
  }) async {
    final result = await showDailyClosureSheet(
      context: context,
      existing: existing,
    );
    if (result == null) return;

    await ref
        .read(dailyClosuresControllerProvider.notifier)
        .saveForDay(
          dayKey: dayKey,
          bestWork: result.bestWork,
          lostStandard: result.lostStandard,
          improvementForTomorrow: result.improvementForTomorrow,
        );

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fechamento diário salvo.'),
        duration: Duration(milliseconds: 1200),
      ),
    );
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

class _DailyClosureRow extends StatelessWidget {
  const _DailyClosureRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 2),
        Text(value, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}
