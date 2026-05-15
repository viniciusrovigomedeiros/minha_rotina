import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/date_utils.dart';
import '../../../data/models/activity_status.dart';
import '../../../state/activities_controller.dart';
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
    final activitiesAsync = ref.watch(activitiesControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Histórico')),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Erro ao carregar: $error')),
        data: (days) {
          return activitiesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error:
                (error, _) => Center(child: Text('Erro ao carregar: $error')),
            data: (activities) {
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

              final plannedForSelectedDay =
                  activities
                      .where(
                        (activity) =>
                            activity.isActive &&
                            activity.weekdays.contains(selectedDate.weekday),
                      )
                      .length;

              final completedOnSelected = summary?.completed ?? 0;
              final skippedOnSelected =
                  summary?.items
                      .where((item) => item.status == ActivityStatus.skipped)
                      .length ??
                  0;
              final completionRate =
                  plannedForSelectedDay == 0
                      ? 0.0
                      : completedOnSelected / plannedForSelectedDay;

              final totalCompletedHistory = days.fold<int>(
                0,
                (sum, day) => sum + day.completed,
              );
              final totalSkippedHistory = days.fold<int>(
                0,
                (sum, day) =>
                    sum +
                    day.items
                        .where((item) => item.status == ActivityStatus.skipped)
                        .length,
              );

              return RefreshIndicator(
                onRefresh:
                    () => ref.read(historyControllerProvider.notifier).reload(),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  children: [
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
                              _formatDate(selectedDate),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '$completedOnSelected concluídas de $plannedForSelectedDay planejadas',
                            ),
                            const SizedBox(height: 6),
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
                            if (summary == null || summary.items.isEmpty)
                              const Text(
                                'Sem registros neste dia. Marque atividades no painel Hoje para aparecer aqui.',
                              )
                            else
                              ...summary.items.map(
                                (item) => Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Row(
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
                                      Expanded(child: Text(item.activityName)),
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
                            Text(
                              'Totalizador',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _MetricTag(
                                  label: 'Concluídas (dia)',
                                  value: '$completedOnSelected',
                                ),
                                _MetricTag(
                                  label: 'Puladas (dia)',
                                  value: '$skippedOnSelected',
                                ),
                                _MetricTag(
                                  label: 'Planejadas (dia)',
                                  value: '$plannedForSelectedDay',
                                ),
                                _MetricTag(
                                  label: 'Concluídas (histórico)',
                                  value: '$totalCompletedHistory',
                                ),
                                _MetricTag(
                                  label: 'Puladas (histórico)',
                                  value: '$totalSkippedHistory',
                                ),
                                _MetricTag(
                                  label: 'Dias com registro',
                                  value: '${days.length}',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
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
      case 'skipped':
        return Icons.skip_next_rounded;
      default:
        return Icons.radio_button_unchecked_rounded;
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
                    'Calendário  $rangeLabel',
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

class _MetricTag extends StatelessWidget {
  const _MetricTag({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
