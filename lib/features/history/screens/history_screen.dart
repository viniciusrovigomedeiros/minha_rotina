import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/date_utils.dart';
import '../../../data/models/daily_closure_entry.dart';
import '../../../data/models/activity_status.dart';
import '../../shared/widgets/completion_quality_sheet.dart';
import '../../shared/widgets/daily_closure_sheet.dart';
import '../../../state/daily_closures_controller.dart';
import '../../../state/history_controller.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  DateTime _selectedDate = DateTime.now();
  late DateTime _windowStart;

  @override
  void initState() {
    super.initState();
    final weekStart = _startOfWeek(_normalize(DateTime.now()));
    _windowStart = weekStart.subtract(const Duration(days: 7));
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(historyControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Revisão')),
      body: SafeArea(
        top: false,
        child: historyAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Erro ao carregar: $error')),
          data: (days) {
            final firstDate =
                days.isEmpty
                    ? DateTime.now().subtract(const Duration(days: 365))
                    : DateUtilsX.fromDayKey(days.last.dayKey);
            final lastDate = DateTime.now();
            final selectedDate = _clampDate(
              _selectedDate,
              _normalize(firstDate),
              _normalize(lastDate),
            );
            final selectedDayKey = DateUtilsX.toDayKey(selectedDate);
            final selectedSummary =
                days.where((day) => day.dayKey == selectedDayKey).toList();

            final summary =
                selectedSummary.isEmpty ? null : selectedSummary.first;

            final plannedForSelectedDay = summary?.totalPlanned ?? 0;
            final completedOnSelected = summary?.completed ?? 0;
            final completionRate =
                plannedForSelectedDay == 0
                    ? 0.0
                    : completedOnSelected / plannedForSelectedDay;
            final selectedDayAverageQualityScore =
                summary == null || summary.completed == 0
                    ? 0.0
                    : summary.averageQualityScore;

            final weeklySummary = _buildWeeklyLearningSummary(days);

            return RefreshIndicator(
              onRefresh:
                  () => ref.read(historyControllerProvider.notifier).reload(),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  Text(
                    'Revise um dia por vez para ajustar o padrão da execução.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _CompactHistoryCalendar(
                    selectedDate: selectedDate,
                    firstDate: _normalize(firstDate),
                    lastDate: _normalize(lastDate),
                    windowStart: _windowStart,
                    onDateSelected: (date) {
                      setState(() => _selectedDate = _normalize(date));
                    },
                    onPreviousWeek: () {
                      setState(() {
                        _windowStart = _windowStart.subtract(
                          const Duration(days: 7),
                        );
                      });
                    },
                    onNextWeek: () {
                      setState(() {
                        _windowStart = _windowStart.add(
                          const Duration(days: 7),
                        );
                      });
                    },
                    onExpand: () async {
                      final picked = await showDatePicker(
                        context: context,
                        locale: const Locale('pt', 'BR'),
                        initialDate: selectedDate,
                        firstDate: _normalize(firstDate),
                        lastDate: _normalize(lastDate),
                      );
                      if (picked == null) return;
                      final normalized = _normalize(picked);
                      setState(() {
                        _selectedDate = normalized;
                        _windowStart = _startOfWeek(
                          normalized,
                        ).subtract(const Duration(days: 7));
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Aprendizados da semana',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Média de qualidade da semana: ${weeklySummary.averageQualityLabel}.',
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Dias com fechamento diário: ${weeklySummary.daysWithClosure}/7.',
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Ajuste mais recente para amanhã: ${weeklySummary.latestImprovement}.',
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Use este resumo para decidir o foco da próxima semana.',
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Execução do dia',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _formatDate(selectedDate),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$completedOnSelected concluídas de $plannedForSelectedDay planejadas',
                          ),
                          const SizedBox(height: 6),
                          Text(
                            summary == null || summary.completed == 0
                                ? 'Qualidade média do dia: sem dados'
                                : 'Qualidade média do dia: ${selectedDayAverageQualityScore.toStringAsFixed(1)}/10',
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              minHeight: 8,
                              value: completionRate.clamp(0, 1),
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primary.withValues(alpha: 0.18),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${(completionRate * 100).round()}% de conclusão',
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Tarefas do dia',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 6),
                          if (summary == null || summary.items.isEmpty)
                            const Text(
                              'Sem registros neste dia. Marque atividades no painel Hoje para aparecer aqui.',
                            )
                          else
                            ...summary.items.map(
                              (item) => Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      _iconFor(item.status.name),
                                      size: 16,
                                      color: _colorFor(
                                        context,
                                        item.status.name,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              item.activityName,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          if (item.status ==
                                                  ActivityStatus.completed &&
                                              item.completionQuality != null)
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                CompletionQualityChip(
                                                  quality:
                                                      item.completionQuality!,
                                                  compact: true,
                                                ),
                                                if (item.qualityScore !=
                                                    null) ...[
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    '${item.qualityScore}/10',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .labelSmall
                                                        ?.copyWith(
                                                          fontWeight:
                                                              FontWeight.w700,
                                                        ),
                                                  ),
                                                ],
                                              ],
                                            )
                                          else
                                            Text(
                                              '—',
                                              style: Theme.of(
                                                context,
                                              ).textTheme.labelSmall?.copyWith(
                                                color:
                                                    Theme.of(
                                                      context,
                                                    ).colorScheme.outline,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
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
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                              ),
                              TextButton(
                                onPressed:
                                    () => _openDailyClosureSheet(
                                      context: context,
                                      dayKey: selectedDayKey,
                                      existing: summary?.dailyClosure,
                                    ),
                                child: Text(
                                  summary?.dailyClosure == null
                                      ? 'Registrar'
                                      : 'Editar',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (summary?.dailyClosure == null)
                            const Text(
                              'Registre em 2 minutos: melhor entrega, onde perdeu padrão e o ajuste para amanhã.',
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
                              value: summary!.dailyClosure!.bestWork,
                            ),
                            const SizedBox(height: 8),
                            _DailyClosureRow(
                              label: 'Perda de padrão',
                              value: summary.dailyClosure!.lostStandard,
                            ),
                            const SizedBox(height: 8),
                            _DailyClosureRow(
                              label: 'O que melhorar amanhã?',
                              value:
                                  summary.dailyClosure!.improvementForTomorrow,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  DateTime _normalize(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  DateTime _startOfWeek(DateTime date) {
    return _normalize(date).subtract(Duration(days: date.weekday - 1));
  }

  DateTime _clampDate(DateTime value, DateTime min, DateTime max) {
    final normalized = _normalize(value);
    if (normalized.isBefore(min)) return min;
    if (normalized.isAfter(max)) return max;
    return normalized;
  }

  String _formatDate(DateTime date) {
    final formatter = DateFormat("EEEE, d 'de' MMMM", 'pt_BR');
    final raw = formatter.format(date);
    return raw.substring(0, 1).toUpperCase() + raw.substring(1);
  }

  IconData _iconFor(String status) {
    switch (status) {
      case 'completed':
        return Icons.check_circle_rounded;
      default:
        return Icons.close_rounded;
    }
  }

  Color _colorFor(BuildContext context, String status) {
    final scheme = Theme.of(context).colorScheme;
    switch (status) {
      case 'completed':
        return scheme.secondary;
      case 'skipped':
        return scheme.tertiary;
      default:
        return scheme.outline;
    }
  }

  Future<void> _openDailyClosureSheet({
    required BuildContext context,
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

  _WeeklyLearningSummary _buildWeeklyLearningSummary(
    List<HistoryDaySummary> days,
  ) {
    final week = days.take(7).toList();
    if (week.isEmpty) {
      return const _WeeklyLearningSummary(
        averageQualityLabel: 'sem dados',
        daysWithClosure: 0,
        latestImprovement: 'sem registros',
      );
    }

    final completedInWeek = week.fold<int>(
      0,
      (sum, day) => sum + day.completed,
    );
    final averageQuality =
        completedInWeek == 0
            ? 0.0
            : week.fold<double>(
                  0,
                  (sum, day) => sum + (day.averageQualityScore * day.completed),
                ) /
                completedInWeek;

    final closures = week.where((day) => day.dailyClosure != null).toList();
    final latestClosure =
        closures.isEmpty
            ? null
            : closures.first.dailyClosure?.improvementForTomorrow;

    return _WeeklyLearningSummary(
      averageQualityLabel:
          completedInWeek == 0
              ? 'sem dados'
              : '${averageQuality.toStringAsFixed(1)}/10',
      daysWithClosure: closures.length,
      latestImprovement:
          (latestClosure == null || latestClosure.trim().isEmpty)
              ? 'sem registros'
              : latestClosure,
    );
  }
}

class _WeeklyLearningSummary {
  const _WeeklyLearningSummary({
    required this.averageQualityLabel,
    required this.daysWithClosure,
    required this.latestImprovement,
  });

  final String averageQualityLabel;
  final int daysWithClosure;
  final String latestImprovement;
}

class _CompactHistoryCalendar extends StatelessWidget {
  const _CompactHistoryCalendar({
    required this.selectedDate,
    required this.firstDate,
    required this.lastDate,
    required this.windowStart,
    required this.onDateSelected,
    required this.onPreviousWeek,
    required this.onNextWeek,
    required this.onExpand,
  });

  final DateTime selectedDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final DateTime windowStart;
  final ValueChanged<DateTime> onDateSelected;
  final VoidCallback onPreviousWeek;
  final VoidCallback onNextWeek;
  final VoidCallback onExpand;

  @override
  Widget build(BuildContext context) {
    const weekDayLabels = ['seg', 'ter', 'qua', 'qui', 'sex', 'sáb', 'dom'];

    final dates = List.generate(
      14,
      (index) => DateTime(
        windowStart.year,
        windowStart.month,
        windowStart.day + index,
      ),
    );

    final rangeLabel =
        '${DateFormat('d MMM', 'pt_BR').format(dates.first)} - ${DateFormat('d MMM', 'pt_BR').format(dates.last)}';

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Selecione o dia  •  $rangeLabel',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Semana anterior',
                  onPressed: onPreviousWeek,
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Próxima semana',
                  onPressed: onNextWeek,
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Expandir calendário',
                  onPressed: onExpand,
                  icon: const Icon(Icons.open_in_full_rounded),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                for (final label in weekDayLabels)
                  Expanded(
                    child: Center(
                      child: Text(
                        label,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: dates.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1.8,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
              ),
              itemBuilder: (context, index) {
                final date = dates[index];
                final isEnabled =
                    !date.isBefore(firstDate) && !date.isAfter(lastDate);
                final isSelected = _isSameDate(date, selectedDate);

                return InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: isEnabled ? () => onDateSelected(date) : null,
                  child: Container(
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        date.day.toString(),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color:
                              isEnabled
                                  ? (isSelected
                                      ? Colors.white
                                      : Theme.of(context).colorScheme.onSurface)
                                  : Theme.of(context).colorScheme.outline,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
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
