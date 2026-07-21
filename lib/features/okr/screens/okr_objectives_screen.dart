import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/okr_progress_utils.dart';
import '../../../data/models/okr_objective.dart';
import '../../../state/okr_workspace_controller.dart';
import 'okr_cycles_screen.dart';
import 'okr_objective_detail_screen.dart';
import 'okr_objective_form_screen.dart';

class OkrObjectivesScreen extends ConsumerWidget {
  const OkrObjectivesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspaceAsync = ref.watch(okrWorkspaceControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Objetivos'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const OkrCyclesScreen()),
              );
            },
            icon: const Icon(Icons.timeline_outlined),
            tooltip: 'Ciclos',
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: workspaceAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Erro ao carregar: $error')),
          data: (workspace) {
            final objectives = workspace.allObjectives;
            if (objectives.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.flag_circle_outlined,
                        size: 56,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Nenhum objetivo cadastrado.',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Crie um objetivo para o ciclo atual e acompanhe seus resultados-chave.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              );
            }

            return RefreshIndicator(
              onRefresh:
                  () =>
                      ref
                          .read(okrWorkspaceControllerProvider.notifier)
                          .reload(),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                children: [
                  Text(
                    'Todos os objetivos',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Acompanhe progresso, resultados-chave e iniciativas vinculadas.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 14),
                  for (int index = 0; index < objectives.length; index++) ...[
                    _ObjectiveCard(
                      progress: objectives[index],
                      code: 'OBJ-${index + 1}',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder:
                                (_) => OkrObjectiveDetailScreen(
                                  objectiveId: objectives[index].objective.id,
                                ),
                          ),
                        );
                      },
                      onEdit: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder:
                                (_) => OkrObjectiveFormScreen(
                                  objectiveId: objectives[index].objective.id,
                                ),
                          ),
                        );
                      },
                    ),
                    if (index < objectives.length - 1)
                      const SizedBox(height: 10),
                  ],
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const OkrObjectiveFormScreen()),
          );
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Novo objetivo'),
      ),
    );
  }
}

class _ObjectiveCard extends StatelessWidget {
  const _ObjectiveCard({
    required this.progress,
    required this.code,
    required this.onTap,
    required this.onEdit,
  });

  final OkrObjectiveProgress progress;
  final String code;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final percent = (progress.progress * 100).round();
    final dateFormat = DateFormat('dd/MM');
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  const _IssueTypePill(label: 'OBJETIVO'),
                  _MetaPill(
                    label: progress.cycle.name,
                    background: colorScheme.surfaceContainerHighest,
                  ),
                  _MetaPill(
                    label: progress.objective.status.label,
                    background: colorScheme.primary.withValues(alpha: 0.10),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _WorkItemIcon(
                              icon: Icons.flag_rounded,
                              tint: colorScheme.primary,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    code,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.4,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    progress.objective.title,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(fontWeight: FontWeight.w800),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Container principal do ciclo com resultados-chave e iniciativas vinculadas.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') onEdit();
                    },
                    itemBuilder:
                        (_) => const [
                          PopupMenuItem(value: 'edit', child: Text('Editar')),
                        ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _ProgressRail(
                progress: progress.progress,
                label: '$percent% concluído',
              ),
              const SizedBox(height: 14),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _MetricBlock(
                        label: 'Resultados-chave',
                        value: '${progress.keyResults.length}',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MetricBlock(
                        label: 'Iniciativas',
                        value: '${progress.initiatives.length}',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MetricBlock(
                        label: 'Período',
                        value:
                            '${dateFormat.format(progress.objective.startDate)} - ${dateFormat.format(progress.objective.endDate)}',
                      ),
                    ),
                  ],
                ),
              ),
              if (progress.keyResults.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Resultados-chave',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                for (
                  int index = 0;
                  index < progress.keyResults.take(2).length;
                  index++
                ) ...[
                  _ChildItemPreview(
                    code: 'KR-${index + 1}',
                    title: progress.keyResults[index].keyResult.title,
                    subtitle:
                        '${(progress.keyResults[index].progress * 100).round()}% concluído',
                    icon: Icons.track_changes_rounded,
                  ),
                  if (index < progress.keyResults.take(2).length - 1)
                    const SizedBox(height: 8),
                ],
              ],
              if (progress.objective.needsReview) ...[
                const SizedBox(height: 14),
                const _ReviewBanner(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _IssueTypePill extends StatelessWidget {
  const _IssueTypePill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w800,
          color: Colors.white,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.label, required this.background});

  final String label;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _ProgressRail extends StatelessWidget {
  const _ProgressRail({required this.progress, required this.label});

  final double progress;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Progresso',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: progress, minHeight: 8),
        ],
      ),
    );
  }
}

class _MetricBlock extends StatelessWidget {
  const _MetricBlock({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _ChildItemPreview extends StatelessWidget {
  const _ChildItemPreview({
    required this.code,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String code;
  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _WorkItemIcon(
          icon: icon,
          tint: Theme.of(context).colorScheme.primary,
          size: 28,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                code,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 2),
              Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReviewBanner extends StatelessWidget {
  const _ReviewBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'Revisão necessária',
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _WorkItemIcon extends StatelessWidget {
  const _WorkItemIcon({required this.icon, required this.tint, this.size = 36});

  final IconData icon;
  final Color tint;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: size * 0.5, color: tint),
    );
  }
}
