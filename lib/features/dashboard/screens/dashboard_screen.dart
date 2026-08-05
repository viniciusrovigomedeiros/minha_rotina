import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/activity.dart';
import '../../../data/models/category.dart';
import '../../../state/activities_controller.dart';
import '../../../state/categories_controller.dart';
import '../../../state/weekly_dashboard_controller.dart';
import '../../../state/weekly_goals_controller.dart';
import '../../../data/models/weekly_goal.dart';
import '../../goals/screens/goals_screen.dart';
import '../../goals/widgets/weekly_goal_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(weeklyDashboardControllerProvider);
    final goalsAsync = ref.watch(weeklyGoalsControllerProvider);
    final activities =
        ref.watch(activitiesControllerProvider).valueOrNull ??
        const <Activity>[];
    final categories =
        ref.watch(categoriesControllerProvider).valueOrNull ??
        const <Category>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard semanal'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const GoalsScreen()));
            },
            icon: const Icon(Icons.flag_outlined),
            tooltip: 'Metas',
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: dashboardAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Erro ao carregar: $error')),
          data: (state) {
            final weekPercent = (state.weekProgress * 100).round();
            final weeklyQualityValue =
                state.totalCompleted == 0
                    ? 'Sem dados'
                    : '${state.averageQualityScore.toStringAsFixed(1)}/10';

            return RefreshIndicator(
              onRefresh: () async {
                await ref
                    .read(weeklyDashboardControllerProvider.notifier)
                    .reload();
                await ref.read(weeklyGoalsControllerProvider.notifier).reload();
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _MetricCard(
                        title: 'Média de qualidade (semana)',
                        value: weeklyQualityValue,
                        subtitle:
                            state.totalCompleted == 0
                                ? 'Conclua tarefas com nota para calcular'
                                : 'Foco na execução, não no volume',
                      ),
                      _MetricCard(
                        title: 'Sequência atual',
                        value: '${state.currentStreak} dias',
                        subtitle: 'Dias seguidos com ao menos uma conclusão',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Resultados (secundário)',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _SmallSecondaryTag(
                                label: 'Concluídas',
                                value: '${state.totalCompleted}',
                              ),
                              _SmallSecondaryTag(
                                label: 'Planejadas',
                                value: '${state.totalPlanned}',
                              ),
                              _SmallSecondaryTag(
                                label: 'Progresso',
                                value: '$weekPercent%',
                              ),
                            ],
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
                                  'Metas',
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const GoalsScreen(),
                                    ),
                                  );
                                },
                                child: const Text('Ver todas'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          goalsAsync.when(
                            loading:
                                () =>
                                    const LinearProgressIndicator(minHeight: 2),
                            error:
                                (error, _) =>
                                    Text('Erro ao carregar metas: $error'),
                            data: (progresses) {
                              if (progresses.isEmpty) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Crie metas automáticas de execução ou metas manuais de resultado.',
                                    ),
                                    const SizedBox(height: 10),
                                    FilledButton.icon(
                                      onPressed: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => const GoalsScreen(),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.add_rounded),
                                      label: const Text('Criar meta'),
                                    ),
                                  ],
                                );
                              }

                              final visible = progresses.take(3).toList();
                              return Column(
                                children: [
                                  for (
                                    int index = 0;
                                    index < visible.length;
                                    index++
                                  ) ...[
                                    WeeklyGoalCard(
                                      progress: visible[index],
                                      compact: true,
                                      scopeLabel: _scopeLabel(
                                        visible[index].goal,
                                        activities,
                                        categories,
                                      ),
                                      onTap: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => const GoalsScreen(),
                                          ),
                                        );
                                      },
                                    ),
                                    if (index < visible.length - 1)
                                      const SizedBox(height: 10),
                                  ],
                                ],
                              );
                            },
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
                            'Conclusão por dia (7 dias)',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 220,
                            child: BarChart(
                              BarChartData(
                                alignment: BarChartAlignment.spaceAround,
                                maxY: 1,
                                gridData: const FlGridData(show: false),
                                borderData: FlBorderData(show: false),
                                titlesData: FlTitlesData(
                                  leftTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  topTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  rightTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: (value, _) {
                                        final index = value.toInt();
                                        if (index < 0 ||
                                            index >= state.dailyPoints.length) {
                                          return const SizedBox.shrink();
                                        }
                                        return Text(
                                          state.dailyPoints[index].label,
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                barGroups:
                                    state.dailyPoints.asMap().entries.map((
                                      entry,
                                    ) {
                                      final index = entry.key;
                                      final point = entry.value;
                                      final hasPlanned = point.total > 0;
                                      final completedPortion =
                                          hasPlanned
                                              ? point.percent
                                                  .clamp(0, 1)
                                                  .toDouble()
                                              : 0.0;
                                      final pendingPortion =
                                          (1 - completedPortion).toDouble();
                                      final completedColor =
                                          Theme.of(context).colorScheme.primary;
                                      final pendingColor =
                                          hasPlanned
                                              ? Theme.of(context)
                                                  .colorScheme
                                                  .surfaceContainerHighest
                                              : Theme.of(
                                                context,
                                              ).colorScheme.surfaceContainer;

                                      return BarChartGroupData(
                                        x: index,
                                        barRods: [
                                          BarChartRodData(
                                            toY: 1,
                                            width: 16,
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                            color: pendingColor,
                                            rodStackItems: [
                                              BarChartRodStackItem(
                                                0,
                                                completedPortion,
                                                completedColor,
                                              ),
                                              BarChartRodStackItem(
                                                completedPortion,
                                                completedPortion +
                                                    pendingPortion,
                                                pendingColor,
                                              ),
                                            ],
                                          ),
                                        ],
                                      );
                                    }).toList(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _LegendDot(
                                color: Theme.of(context).colorScheme.primary,
                                label: 'Concluídas',
                              ),
                              const SizedBox(width: 16),
                              _LegendDot(
                                color:
                                    Theme.of(
                                      context,
                                    ).colorScheme.surfaceContainerHighest,
                                label: 'Não concluídas',
                              ),
                            ],
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
                            'Concluídas por categoria',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 16),
                          if (state.categoryPoints.isEmpty)
                            const Text('Sem atividades concluídas na semana.')
                          else
                            ...state.categoryPoints.map(
                              (point) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: Color(point.colorHex),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text(point.categoryName)),
                                    Text('${point.count}'),
                                  ],
                                ),
                              ),
                            ),
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

  String _scopeLabel(
    WeeklyGoal goal,
    List<Activity> activities,
    List<Category> categories,
  ) {
    if (goal.isManual) {
      return goal.period.label;
    }

    switch (goal.scope) {
      case WeeklyGoalScope.overall:
        return 'Geral';
      case WeeklyGoalScope.activity:
        final match =
            activities.where((item) => item.id == goal.activityId).toList();
        return match.isEmpty ? 'Atividade removida' : match.first.name;
      case WeeklyGoalScope.category:
        final match =
            categories.where((item) => item.id == goal.categoryId).toList();
        return match.isEmpty ? 'Categoria removida' : match.first.name;
      case null:
        return 'Geral';
    }
  }
}

class _SmallSecondaryTag extends StatelessWidget {
  const _SmallSecondaryTag({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label: $value',
        style: Theme.of(context).textTheme.labelSmall,
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
  });

  final String title;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final width = (MediaQuery.sizeOf(context).width - 42) / 2;

    return SizedBox(
      width: width,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 8),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
