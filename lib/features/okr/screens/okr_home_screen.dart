import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/okr_progress_utils.dart';
import '../../../core/utils/time_format.dart';
import '../../../data/models/activity.dart';
import '../../../state/okr_management_controller.dart';
import '../../../state/okr_workspace_controller.dart';
import '../widgets/okr_check_in_sheet.dart';
import 'okr_cycles_screen.dart';
import 'okr_objective_detail_screen.dart';
import 'okr_objectives_screen.dart';

class OkrHomeScreen extends ConsumerWidget {
  const OkrHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspaceAsync = ref.watch(okrWorkspaceControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('OKRs'),
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
            final currentCycle = workspace.currentCycle;
            return RefreshIndicator(
              onRefresh:
                  () =>
                      ref
                          .read(okrWorkspaceControllerProvider.notifier)
                          .reload(),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ciclo atual',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            currentCycle?.cycle.name ?? 'Nenhum ciclo ativo',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          if (currentCycle != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              '${DateFormat('dd/MM/yyyy').format(currentCycle.cycle.startDate)} - ${DateFormat('dd/MM/yyyy').format(currentCycle.cycle.endDate)}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 12),
                            LinearProgressIndicator(
                              value: currentCycle.progress,
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _StatPill(
                                  label: 'Progresso geral',
                                  value:
                                      '${(currentCycle.progress * 100).round()}%',
                                ),
                                _StatPill(
                                  label: 'Objetivos ativos',
                                  value: '${workspace.activeObjectives.length}',
                                ),
                                _StatPill(
                                  label: 'Próximo check-in',
                                  value:
                                      workspace.nextCheckInDate == null
                                          ? 'Sem data'
                                          : DateFormat(
                                            'dd/MM',
                                          ).format(workspace.nextCheckInDate!),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SectionHeader(
                    title: 'Objetivos ativos',
                    actionLabel: 'Ver todos',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const OkrObjectivesScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  if (workspace.activeObjectives.isEmpty)
                    const _EmptyCard(
                      text:
                          'Crie seu primeiro objetivo para começar este ciclo.',
                    )
                  else
                    for (
                      int index = 0;
                      index < workspace.activeObjectives.take(3).length;
                      index++
                    ) ...[
                      _ObjectivePreviewCard(
                        progress: workspace.activeObjectives[index],
                      ),
                      if (index < workspace.activeObjectives.take(3).length - 1)
                        const SizedBox(height: 10),
                    ],
                  const SizedBox(height: 12),
                  _SectionHeader(
                    title: 'Resultados-chave pendentes de check-in',
                  ),
                  const SizedBox(height: 8),
                  if (workspace.staleKeyResults.isEmpty)
                    const _EmptyCard(
                      text:
                          'Nenhum resultado-chave está precisando de atualização agora.',
                    )
                  else
                    Card(
                      child: Column(
                        children: [
                          for (
                            int index = 0;
                            index < workspace.staleKeyResults.take(5).length;
                            index++
                          ) ...[
                            Builder(
                              builder: (context) {
                                final stale = workspace.staleKeyResults[index];
                                final objectiveProgress =
                                    _findObjectiveForKeyResult(
                                      workspace.activeObjectives,
                                      stale.keyResult.id,
                                    );
                                final lastCheckInAt =
                                    stale.keyResult.lastCheckInAt;
                                final updateLabel =
                                    lastCheckInAt == null
                                        ? 'Nunca atualizado'
                                        : 'Último check-in em ${DateFormat('dd/MM/yyyy').format(lastCheckInAt)}';

                                return _HomeHierarchyTile(
                                  icon: Icons.track_changes_rounded,
                                  code: 'KR-${index + 1}',
                                  title: stale.keyResult.title,
                                  subtitle:
                                      objectiveProgress == null
                                          ? updateLabel
                                          : '${objectiveProgress.objective.title} • $updateLabel',
                                  trailing:
                                      objectiveProgress == null
                                          ? null
                                          : const Icon(
                                            Icons.chevron_right_rounded,
                                          ),
                                  onTap:
                                      objectiveProgress == null
                                          ? null
                                          : () {
                                            _openObjectiveCheckInSheet(
                                              context: context,
                                              ref: ref,
                                              progress: objectiveProgress,
                                              focusKeyResultId:
                                                  stale.keyResult.id,
                                            );
                                          },
                                );
                              },
                            ),
                            if (index <
                                workspace.staleKeyResults.take(5).length - 1)
                              const Divider(height: 1),
                          ],
                        ],
                      ),
                    ),
                  const SizedBox(height: 12),
                  _SectionHeader(title: 'Iniciativas da semana'),
                  const SizedBox(height: 8),
                  if (workspace.weekInitiatives.isEmpty)
                    const _EmptyCard(
                      text:
                          'Nenhuma iniciativa vinculada a objetivos por enquanto.',
                    )
                  else
                    _ActivityCardList(activities: workspace.weekInitiatives),
                  const SizedBox(height: 12),
                  _SectionHeader(title: 'Tarefas independentes'),
                  const SizedBox(height: 8),
                  if (workspace.independentActivities.isEmpty)
                    const _EmptyCard(
                      text:
                          'As tarefas sem OKR continuam disponíveis aqui como apoio secundário.',
                    )
                  else
                    _ActivityCardList(
                      activities: workspace.independentActivities,
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.actionLabel, this.onTap});

  final String title;
  final String? actionLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
        if (actionLabel != null && onTap != null)
          TextButton(onPressed: onTap, child: Text(actionLabel!)),
      ],
    );
  }
}

class _ObjectivePreviewCard extends StatelessWidget {
  const _ObjectivePreviewCard({required this.progress});

  final OkrObjectiveProgress progress;

  @override
  Widget build(BuildContext context) {
    final percent = (progress.progress * 100).round();

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder:
                  (_) => OkrObjectiveDetailScreen(
                    objectiveId: progress.objective.id,
                  ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  const _TypeBadge(label: 'OBJ'),
                  _HomeMetaPill(label: progress.cycle.name),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _PreviewLeadingIcon(icon: Icons.flag_rounded),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'OBJ',
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          progress.objective.title,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: progress.progress,
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '$percent%',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _HomeMetricChip(label: '${progress.keyResults.length} KRs'),
                  _HomeMetricChip(
                    label: '${progress.initiatives.length} iniciativas',
                  ),
                  if (progress.staleKeyResultsCount > 0)
                    _HomeMetricChip(
                      label:
                          '${progress.staleKeyResultsCount} pendente(s) de check-in',
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _PreviewLeadingIcon extends StatelessWidget {
  const _PreviewLeadingIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 18, color: color),
    );
  }
}

class _HomeMetaPill extends StatelessWidget {
  const _HomeMetaPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
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

class _HomeMetricChip extends StatelessWidget {
  const _HomeMetricChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
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

class _ActivityCardList extends StatelessWidget {
  const _ActivityCardList({required this.activities});

  final List<Activity> activities;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          for (int index = 0; index < activities.length; index++) ...[
            _HomeHierarchyTile(
              icon:
                  activities[index].objectiveId == null
                      ? Icons.checklist_rounded
                      : Icons.check_box_outlined,
              code:
                  activities[index].objectiveId == null
                      ? 'TASK-${index + 1}'
                      : 'INIT-${index + 1}',
              title: activities[index].name,
              subtitle:
                  '${activities[index].recurrence.label} • ${TimeFormat.formatMinutesRange(activities[index].startMinutes, activities[index].endMinutes)}',
            ),
            if (index < activities.length - 1) const Divider(height: 1),
          ],
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label: $value',
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _HomeHierarchyTile extends StatelessWidget {
  const _HomeHierarchyTile({
    required this.icon,
    required this.code,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String code;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      leading: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            code,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 2),
          Text(title),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(subtitle),
      ),
      trailing: trailing,
      horizontalTitleGap: 12,
      minVerticalPadding: 10,
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(text, style: Theme.of(context).textTheme.bodySmall),
      ),
    );
  }
}

OkrObjectiveProgress? _findObjectiveForKeyResult(
  List<OkrObjectiveProgress> objectives,
  String keyResultId,
) {
  for (final objective in objectives) {
    final hasMatch = objective.keyResults.any(
      (item) => item.keyResult.id == keyResultId,
    );
    if (hasMatch) return objective;
  }
  return null;
}

Future<void> _openObjectiveCheckInSheet({
  required BuildContext context,
  required WidgetRef ref,
  required OkrObjectiveProgress progress,
  String? focusKeyResultId,
}) async {
  final result = await showOkrCheckInSheet(
    context: context,
    objectiveTitle: progress.objective.title,
    items: [
      for (int index = 0; index < progress.keyResults.length; index++)
        OkrCheckInItem(
          keyResult: progress.keyResults[index].keyResult,
          code: 'KR-${index + 1}',
          needsUpdate: progress.keyResults[index].needsUpdate,
        ),
    ],
    focusKeyResultId: focusKeyResultId,
  );
  if (result == null) return;

  await ref
      .read(okrManagementControllerProvider.notifier)
      .submitObjectiveCheckIn(
        objectiveId: progress.objective.id,
        updates:
            result.updates
                .map(
                  (item) => KeyResultCheckInDraft(
                    keyResultId: item.keyResultId,
                    valueAfter: item.valueAfter,
                  ),
                )
                .toList(),
        note: result.note,
        confidence: result.confidence,
      );

  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Check-in salvo para "${progress.objective.title}".'),
    ),
  );
}
