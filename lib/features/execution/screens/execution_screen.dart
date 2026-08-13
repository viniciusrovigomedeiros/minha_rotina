import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/time_format.dart';
import '../../../state/history_controller.dart';
import '../../../state/today_controller.dart';
import '../../../state/weekly_dashboard_controller.dart';
import '../../activities/screens/activities_screen.dart';
import '../../activities/screens/activity_form_screen.dart';
import '../../shared/widgets/settings_action_button.dart';
import '../../today/screens/today_screen.dart';

enum _ExecutionView { today, week, month }

class ExecutionScreen extends ConsumerStatefulWidget {
  const ExecutionScreen({super.key});

  @override
  ConsumerState<ExecutionScreen> createState() => _ExecutionScreenState();
}

class _ExecutionScreenState extends ConsumerState<ExecutionScreen> {
  _ExecutionView _selectedView = _ExecutionView.today;

  @override
  Widget build(BuildContext context) {
    final todayAsync = ref.watch(todayControllerProvider);
    final selectedDate = todayAsync.valueOrNull?.date ?? DateTime.now();
    final isViewingToday = _isSameDay(selectedDate, DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Iniciativas'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ActivitiesScreen()),
              );
            },
            child: const Text('Todas as iniciativas'),
          ),
          const SettingsActionButton(),
        ],
      ),
      body: Column(
        children: [
          if (_selectedView == _ExecutionView.today)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      TimeFormat.dateLabel(selectedDate),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        height: 1.15,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
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
                        onPressed: () => _pickDate(context, ref, selectedDate),
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
                                  .selectDate(DateTime.now()),
                          child: const Text('Hoje'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              _selectedView == _ExecutionView.today ? 12 : 8,
              16,
              0,
            ),
            child: _ExecutionViewSwitcher(
              selectedView: _selectedView,
              onChanged: (view) {
                setState(() => _selectedView = view);
              },
            ),
          ),
          Expanded(
            child: IndexedStack(
              index: _ExecutionView.values.indexOf(_selectedView),
              children: const [
                TodayScreen(),
                _ExecutionWeekView(),
                _ExecutionMonthView(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const ActivityFormScreen()));
        },
        icon: const Icon(Icons.add_task_rounded),
        label: const Text('Nova iniciativa'),
      ),
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
}

class _ExecutionWeekView extends ConsumerWidget {
  const _ExecutionWeekView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(historyControllerProvider);
    final dashboardAsync = ref.watch(weeklyDashboardControllerProvider);

    return historyAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Erro ao carregar: $error')),
      data: (historyDays) {
        final now = _normalize(DateTime.now());
        final weekStart = _startOfWeek(now);
        final weekDays = _buildRangeDays(
          historyDays: historyDays,
          start: weekStart,
          end: weekStart.add(const Duration(days: 6)),
          today: now,
        );
        final summary = _PeriodExecutionSummary.fromDays(weekDays);
        final dashboard = dashboardAsync.valueOrNull;

        return RefreshIndicator(
          onRefresh: () => _refreshInsights(ref),
          child: SafeArea(
            top: false,
            bottom: false,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                _PeriodHeroCard(
                  eyebrow: 'Semana atual',
                  title: _formatWeekRange(weekStart),
                  subtitle:
                      'Veja rápido onde você manteve o ritmo e onde quebrou a consistência.',
                  progress: summary.progress,
                  badges: [
                    '${summary.totalCompleted}/${summary.totalPlanned} concluídas',
                    '${summary.perfectDays} dias 100%',
                    '${summary.missedDays} dias zerados',
                    '${dashboard?.currentStreak ?? summary.currentStreak} em sequência',
                  ],
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionTitle(
                          title: 'Ritmo por dia',
                          subtitle:
                              'O dia só cobra meta semanal quando ela vira necessária para fechar a semana.',
                        ),
                        const SizedBox(height: 14),
                        _WeekConsistencyGrid(days: weekDays),
                        const SizedBox(height: 14),
                        const _ExecutionLegend(),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _MetricCard(
                        title: 'Qualidade média',
                        value:
                            dashboard?.averageQualityScore == null ||
                                    (dashboard?.averageQualityScore ?? 0) == 0
                                ? 'Sem dados'
                                : '${dashboard!.averageQualityScore.toStringAsFixed(1)}/10',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MetricCard(
                        title: 'Dias ativos',
                        value: '${summary.activeDays}/7 dias',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ExecutionMonthView extends ConsumerStatefulWidget {
  const _ExecutionMonthView();

  @override
  ConsumerState<_ExecutionMonthView> createState() =>
      _ExecutionMonthViewState();
}

class _ExecutionMonthViewState extends ConsumerState<_ExecutionMonthView> {
  late DateTime _selectedMonthStart;

  @override
  void initState() {
    super.initState();
    final now = _normalize(DateTime.now());
    _selectedMonthStart = DateTime(now.year, now.month, 1);
  }

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final historyAsync = ref.watch(historyControllerProvider);

    return historyAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Erro ao carregar: $error')),
      data: (historyDays) {
        final now = _normalize(DateTime.now());
        final currentMonthStart = DateTime(now.year, now.month, 1);
        final earliestDate =
            historyDays.isEmpty
                ? currentMonthStart
                : DateUtilsX.fromDayKey(historyDays.last.dayKey);
        final earliestMonthStart = DateTime(
          earliestDate.year,
          earliestDate.month,
          1,
        );
        final monthStart = _selectedMonthStart;
        final selectedMonthEnd = DateTime(
          monthStart.year,
          monthStart.month + 1,
          0,
        );
        final monthDays = _buildRangeDays(
          historyDays: historyDays,
          start: monthStart,
          end: selectedMonthEnd,
          today: now,
        );
        final summary = _PeriodExecutionSummary.fromDays(monthDays);
        final longestStreak = _longestStreak(monthDays);
        final canGoPrevious = !monthStart.isAtSameMomentAs(earliestMonthStart);
        final canGoNext = monthStart.isBefore(currentMonthStart);

        return RefreshIndicator(
          onRefresh: () => _refreshInsights(ref),
          child: SafeArea(
            top: false,
            bottom: false,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                _PeriodHeroCard(
                  eyebrow: 'Mês selecionado',
                  title: _capitalize(
                    DateFormat("MMMM 'de' y", 'pt_BR').format(monthStart),
                  ),
                  subtitle:
                      'Uma leitura mais macro para ver consistência, sequência e dias de quebra.',
                  progress: summary.progress,
                  badges: [
                    '${summary.totalCompleted}/${summary.totalPlanned} concluídas',
                    '${summary.perfectDays} dias 100%',
                    '${summary.activeDays} dias ativos',
                    '$longestStreak dias de sequência',
                  ],
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed:
                              canGoPrevious
                                  ? () {
                                    setState(() {
                                      _selectedMonthStart = DateTime(
                                        monthStart.year,
                                        monthStart.month - 1,
                                        1,
                                      );
                                    });
                                  }
                                  : null,
                          icon: const Icon(Icons.chevron_left_rounded),
                          tooltip: 'Mês anterior',
                        ),
                        Expanded(
                          child: Center(
                            child: Text(
                              _capitalize(
                                DateFormat(
                                  "MMMM 'de' y",
                                  'pt_BR',
                                ).format(monthStart),
                              ),
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed:
                              canGoNext
                                  ? () {
                                    setState(() {
                                      _selectedMonthStart = DateTime(
                                        monthStart.year,
                                        monthStart.month + 1,
                                        1,
                                      );
                                    });
                                  }
                                  : null,
                          icon: const Icon(Icons.chevron_right_rounded),
                          tooltip: 'Próximo mês',
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
                        _SectionTitle(
                          title: 'Calendário do mês',
                          subtitle:
                              'A meta semanal só entra no dia quando já não dá mais para adiar.',
                        ),
                        const SizedBox(height: 14),
                        _MonthCalendar(days: monthDays),
                        const SizedBox(height: 14),
                        const _ExecutionLegend(),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _MetricCard(
                        title: 'Dias zerados',
                        value: '${summary.missedDays} dias',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MetricCard(
                        title: 'Dias ativos',
                        value: '${summary.activeDays} dias',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ExecutionViewSwitcher extends StatelessWidget {
  const _ExecutionViewSwitcher({
    required this.selectedView,
    required this.onChanged,
  });

  final _ExecutionView selectedView;
  final ValueChanged<_ExecutionView> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          for (final view in _ExecutionView.values)
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: view == _ExecutionView.month ? 0 : 4,
                ),
                child: _ExecutionViewButton(
                  label: _labelFor(view),
                  selected: selectedView == view,
                  onTap: () => onChanged(view),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _labelFor(_ExecutionView view) {
    switch (view) {
      case _ExecutionView.today:
        return 'Hoje';
      case _ExecutionView.week:
        return 'Semana';
      case _ExecutionView.month:
        return 'Mês';
    }
  }
}

class _ExecutionViewButton extends StatelessWidget {
  const _ExecutionViewButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: selected ? scheme.primary : Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Center(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: selected ? scheme.onPrimary : scheme.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PeriodHeroCard extends StatelessWidget {
  const _PeriodHeroCard({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.progress,
    required this.badges,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final double progress;
  final List<String> badges;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              eyebrow,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.outline),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: 8,
                value: progress.clamp(0, 1),
                backgroundColor: scheme.primary.withValues(alpha: 0.14),
                valueColor: AlwaysStoppedAnimation<Color>(scheme.primary),
              ),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (int index = 0; index < badges.length; index++) ...[
                    _SummaryBadge(label: badges[index]),
                    if (index < badges.length - 1) const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryBadge extends StatelessWidget {
  const _SummaryBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: scheme.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.outline,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeekConsistencyGrid extends StatelessWidget {
  const _WeekConsistencyGrid({required this.days});

  final List<_ExecutionDayData> days;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int index = 0; index < days.length; index++) ...[
          Expanded(child: _WeekDayColumn(day: days[index])),
          if (index < days.length - 1) const SizedBox(width: 8),
        ],
      ],
    );
  }
}

class _WeekDayColumn extends StatelessWidget {
  const _WeekDayColumn({required this.day});

  final _ExecutionDayData day;

  @override
  Widget build(BuildContext context) {
    final palette = _paletteFor(context, day.status);
    final isToday = _isSameDay(day.date, DateTime.now());
    final progressText =
        day.future
            ? '...'
            : day.planned == 0
            ? '—'
            : '${day.completed}/${day.planned}';

    return Column(
      children: [
        Text(
          _weekLabel(day.date),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.outline,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            color: palette.background,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isToday ? palette.foreground : palette.border,
              width: isToday ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color:
                      isToday
                          ? palette.foreground
                          : palette.foreground.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '${day.date.day}',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color:
                        isToday
                            ? Theme.of(context).colorScheme.onPrimary
                            : palette.foreground,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 44,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    width: 18,
                    height: day.future ? 8 : 8 + (day.progress * 28),
                    decoration: BoxDecoration(
                      color: palette.foreground,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                progressText,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: palette.foreground,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MonthCalendar extends StatelessWidget {
  const _MonthCalendar({required this.days});

  final List<_ExecutionDayData> days;

  @override
  Widget build(BuildContext context) {
    if (days.isEmpty) {
      return const SizedBox.shrink();
    }

    const weekLabels = ['S', 'T', 'Q', 'Q', 'S', 'S', 'D'];
    final firstDay = days.first.date;
    final leadingEmptyCount = firstDay.weekday - 1;

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 8.0;
        final cellWidth = (constraints.maxWidth - (spacing * 6)) / 7;

        return Column(
          children: [
            Row(
              children: [
                for (int index = 0; index < weekLabels.length; index++) ...[
                  SizedBox(
                    width: cellWidth,
                    child: Center(
                      child: Text(
                        weekLabels[index],
                        style: Theme.of(
                          context,
                        ).textTheme.labelMedium?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  if (index < weekLabels.length - 1)
                    const SizedBox(width: spacing),
                ],
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                for (int index = 0; index < leadingEmptyCount; index++)
                  SizedBox(width: cellWidth, height: 70),
                for (final day in days)
                  SizedBox(
                    width: cellWidth,
                    height: 70,
                    child: _MonthDayCell(day: day),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _MonthDayCell extends StatelessWidget {
  const _MonthDayCell({required this.day});

  final _ExecutionDayData day;

  @override
  Widget build(BuildContext context) {
    final palette = _paletteFor(context, day.status);
    final isToday = _isSameDay(day.date, DateTime.now());

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isToday ? palette.foreground : palette.border,
          width: isToday ? 1.6 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${day.date.day}',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: palette.foreground,
            ),
          ),
          const Spacer(),
          if (!day.future && day.planned > 0)
            Text(
              '${day.completed}/${day.planned}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: palette.foreground,
                fontWeight: FontWeight.w700,
              ),
            )
          else
            Text(
              day.future ? '...' : '—',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: palette.foreground.withValues(alpha: 0.72),
                fontWeight: FontWeight.w700,
              ),
            ),
          const SizedBox(height: 6),
          Container(
            height: 5,
            decoration: BoxDecoration(
              color: palette.foreground,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExecutionLegend extends StatelessWidget {
  const _ExecutionLegend();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 8,
      children: const [
        _LegendItem(label: 'Completo', status: _ExecutionDayStatus.complete),
        _LegendItem(label: 'Parcial', status: _ExecutionDayStatus.partial),
        _LegendItem(label: 'Zerado', status: _ExecutionDayStatus.missed),
        _LegendItem(
          label: 'Sem carga',
          status: _ExecutionDayStatus.nonePlanned,
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.label, required this.status});

  final String label;
  final _ExecutionDayStatus status;

  @override
  Widget build(BuildContext context) {
    final palette = _paletteFor(context, status);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: palette.foreground,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.labelMedium),
      ],
    );
  }
}

class _ExecutionDayData {
  const _ExecutionDayData({
    required this.date,
    required this.planned,
    required this.completed,
    required this.weeklyFlexibleCompleted,
    required this.weeklyFlexibleTarget,
    required this.future,
  });

  final DateTime date;
  final int planned;
  final int completed;
  final int weeklyFlexibleCompleted;
  final int weeklyFlexibleTarget;
  final bool future;

  double get progress {
    if (future || planned == 0) return 0;
    return (completed / planned).clamp(0, 1);
  }

  _ExecutionDayStatus get status {
    if (future) return _ExecutionDayStatus.future;
    if (planned == 0) return _ExecutionDayStatus.nonePlanned;
    if (completed == 0) return _ExecutionDayStatus.missed;
    if (completed >= planned) return _ExecutionDayStatus.complete;
    return _ExecutionDayStatus.partial;
  }
}

enum _ExecutionDayStatus { complete, partial, missed, nonePlanned, future }

class _PeriodExecutionSummary {
  const _PeriodExecutionSummary({
    required this.totalCompleted,
    required this.totalPlanned,
    required this.perfectDays,
    required this.missedDays,
    required this.activeDays,
    required this.currentStreak,
  });

  final int totalCompleted;
  final int totalPlanned;
  final int perfectDays;
  final int missedDays;
  final int activeDays;
  final int currentStreak;

  double get progress => totalPlanned == 0 ? 0 : totalCompleted / totalPlanned;

  factory _PeriodExecutionSummary.fromDays(List<_ExecutionDayData> days) {
    final visibleDays = days.where((day) => !day.future).toList();

    int totalCompleted = 0;
    int totalPlanned = 0;
    int perfectDays = 0;
    int missedDays = 0;
    int activeDays = 0;

    for (final day in visibleDays) {
      totalCompleted += day.completed;
      totalPlanned += day.planned;
      if (day.planned > 0 && day.completed >= day.planned) perfectDays++;
      if (day.planned > 0 && day.completed == 0) missedDays++;
      if (day.completed > 0) activeDays++;
    }

    return _PeriodExecutionSummary(
      totalCompleted: totalCompleted,
      totalPlanned: totalPlanned,
      perfectDays: perfectDays,
      missedDays: missedDays,
      activeDays: activeDays,
      currentStreak: _currentStreak(visibleDays),
    );
  }
}

class _DayPalette {
  const _DayPalette({
    required this.background,
    required this.foreground,
    required this.border,
  });

  final Color background;
  final Color foreground;
  final Color border;
}

Future<void> _refreshInsights(WidgetRef ref) async {
  await Future.wait([
    ref.read(historyControllerProvider.notifier).reload(),
    ref.read(weeklyDashboardControllerProvider.notifier).reload(),
  ]);
}

List<_ExecutionDayData> _buildRangeDays({
  required List<HistoryDaySummary> historyDays,
  required DateTime start,
  required DateTime end,
  required DateTime today,
}) {
  final historyByDay = {
    for (final summary in historyDays) summary.dayKey: summary,
  };

  final result = <_ExecutionDayData>[];

  for (
    DateTime cursor = start;
    !cursor.isAfter(end);
    cursor = cursor.add(const Duration(days: 1))
  ) {
    final normalized = _normalize(cursor);
    final summary = historyByDay[DateUtilsX.toDayKey(normalized)];

    result.add(
      _ExecutionDayData(
        date: normalized,
        planned: summary?.totalPlanned ?? 0,
        completed: summary?.completedPlanned ?? 0,
        weeklyFlexibleCompleted: summary?.weeklyFlexibleCompleted ?? 0,
        weeklyFlexibleTarget: summary?.weeklyFlexibleTarget ?? 0,
        future: normalized.isAfter(today),
      ),
    );
  }

  return result;
}

int _currentStreak(List<_ExecutionDayData> days) {
  int streak = 0;
  for (final day in days.reversed) {
    if (day.completed > 0) {
      streak++;
    } else {
      break;
    }
  }
  return streak;
}

int _longestStreak(List<_ExecutionDayData> days) {
  int longest = 0;
  int current = 0;

  for (final day in days) {
    if (!day.future && day.completed > 0) {
      current++;
      if (current > longest) longest = current;
    } else {
      current = 0;
    }
  }

  return longest;
}

DateTime _normalize(DateTime date) => DateTime(date.year, date.month, date.day);

DateTime _startOfWeek(DateTime date) {
  final normalized = _normalize(date);
  return normalized.subtract(Duration(days: normalized.weekday - 1));
}

String _formatWeekRange(DateTime weekStart) {
  final formatter = DateFormat('d MMM', 'pt_BR');
  final weekEnd = weekStart.add(const Duration(days: 6));
  return '${formatter.format(weekStart)} - ${formatter.format(weekEnd)}';
}

String _weekLabel(DateTime date) {
  const labels = ['SEG', 'TER', 'QUA', 'QUI', 'SEX', 'SAB', 'DOM'];
  return labels[date.weekday - 1];
}

String _capitalize(String value) {
  if (value.isEmpty) return value;
  return value.substring(0, 1).toUpperCase() + value.substring(1);
}

bool _isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

_DayPalette _paletteFor(BuildContext context, _ExecutionDayStatus status) {
  final palette = context.appPalette;
  final scheme = Theme.of(context).colorScheme;

  switch (status) {
    case _ExecutionDayStatus.complete:
      return _DayPalette(
        background: scheme.primary.withValues(alpha: 0.12),
        foreground: scheme.primary,
        border: scheme.primary.withValues(alpha: 0.24),
      );
    case _ExecutionDayStatus.partial:
      return _DayPalette(
        background: palette.warningFill,
        foreground: palette.warningForeground,
        border: palette.warningBorder,
      );
    case _ExecutionDayStatus.missed:
      return _DayPalette(
        background: scheme.error.withValues(alpha: 0.10),
        foreground: scheme.error,
        border: scheme.error.withValues(alpha: 0.20),
      );
    case _ExecutionDayStatus.nonePlanned:
      return _DayPalette(
        background: scheme.surface,
        foreground: scheme.outline,
        border: scheme.outlineVariant,
      );
    case _ExecutionDayStatus.future:
      return _DayPalette(
        background: scheme.surface,
        foreground: scheme.outline.withValues(alpha: 0.72),
        border: scheme.outlineVariant.withValues(alpha: 0.72),
      );
  }
}
