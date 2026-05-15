import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../state/weekly_dashboard_controller.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(weeklyDashboardControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard semanal')),
      body: dashboardAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Erro ao carregar: $error')),
        data: (state) {
          final weekPercent = (state.weekProgress * 100).round();

          return RefreshIndicator(
            onRefresh:
                () =>
                    ref
                        .read(weeklyDashboardControllerProvider.notifier)
                        .reload(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _MetricCard(
                      title: 'Progresso semana',
                      value: '$weekPercent%',
                      subtitle: '${state.totalCompleted}/${state.totalPlanned}',
                    ),
                    _MetricCard(
                      title: 'Concluídas',
                      value: '${state.totalCompleted}',
                      subtitle: 'Últimos 7 dias',
                    ),
                    _MetricCard(
                      title: 'Melhor dia',
                      value: _capitalize(state.bestDayLabel),
                      subtitle: 'Maior percentual',
                    ),
                    _MetricCard(
                      title: 'Sequência atual',
                      value: '${state.currentStreak} dia(s)',
                      subtitle: 'Com pelo menos 1 concluída',
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
                                              completedPortion + pendingPortion,
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
    );
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text.substring(0, 1).toUpperCase() + text.substring(1);
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
