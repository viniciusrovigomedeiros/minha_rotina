import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/okr_progress_utils.dart';
import '../../../core/utils/time_format.dart';
import '../../../data/models/activity.dart';
import '../../../data/models/activity_status.dart';
import '../../../state/activities_controller.dart';
import '../../../state/okr_management_controller.dart';
import '../../../state/okr_workspace_controller.dart';
import '../../../state/today_controller.dart';
import '../../activities/screens/activity_form_screen.dart';
import '../../shared/widgets/completion_quality_sheet.dart';
import '../../shared/widgets/settings_action_button.dart';
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
          const SettingsActionButton(),
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
                        ref: ref,
                      ),
                      if (index < workspace.activeObjectives.take(3).length - 1)
                        const SizedBox(height: 10),
                    ],
                  const SizedBox(height: 12),
                  _SectionHeader(title: 'Iniciativas da semana'),
                  const SizedBox(height: 8),
                  if (workspace.weekInitiatives.isEmpty)
                    const _EmptyCard(
                      text:
                          'Nenhuma iniciativa recorrente dos objetivos está programada para esta semana.',
                    )
                  else
                    _ActivityCardList(
                      activities: workspace.weekInitiatives,
                      compact: true,
                      ref: ref,
                    ),
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
                      ref: ref,
                      dense: true,
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
  const _ObjectivePreviewCard({required this.progress, required this.ref});

  final OkrObjectiveProgress progress;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final percent = (progress.progress * 100).round();
    final pendingCount = progress.staleKeyResultsCount;
    final recurringInitiatives = _recurringActivitiesForObjective(
      progress.initiatives,
    );
    final nextActions = _nextActionsForObjective(progress.initiatives);

    return Card(
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
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        progress.objective.title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder:
                            (_) => OkrObjectiveDetailScreen(
                              objectiveId: progress.objective.id,
                            ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.chevron_right_rounded),
                  tooltip: 'Ver objetivo',
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
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
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
                  label: '${recurringInitiatives.length} iniciativas',
                ),
                if (nextActions.isNotEmpty)
                  _HomeMetricChip(
                    label: '${nextActions.length} próximas ações',
                  ),
                if (pendingCount > 0)
                  _HomeMetricChip(
                    label: '$pendingCount pendente(s) de check-in',
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (progress.keyResults.isNotEmpty)
                  OutlinedButton.icon(
                    onPressed: () {
                      _openObjectiveCheckInSheet(
                        context: context,
                        ref: ref,
                        progress: progress,
                      );
                    },
                    icon: const Icon(Icons.edit_calendar_rounded, size: 18),
                    label: Text(
                      pendingCount > 0 ? 'Fazer check-in' : 'Atualizar KRs',
                    ),
                  ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder:
                            (_) => OkrObjectiveDetailScreen(
                              objectiveId: progress.objective.id,
                            ),
                      ),
                    );
                  },
                  child: const Text('Ver detalhes'),
                ),
              ],
            ),
            if (progress.keyResults.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Divider(height: 1),
              Theme(
                data: Theme.of(
                  context,
                ).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  key: PageStorageKey(
                    'objective-home-${progress.objective.id}',
                  ),
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: EdgeInsets.zero,
                  expandedCrossAxisAlignment: CrossAxisAlignment.start,
                  title: Text(
                    'Resultados-chave',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  subtitle: Text(
                    pendingCount > 0
                        ? '$pendingCount pendente(s) para atualizar esta semana'
                        : 'Tudo em dia neste objetivo',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  children: [
                    for (
                      int index = 0;
                      index < progress.keyResults.length;
                      index++
                    )
                      _ObjectiveKeyResultTile(
                        progress: progress.keyResults[index],
                        code: 'KR-${index + 1}',
                        onTap: () {
                          _openObjectiveCheckInSheet(
                            context: context,
                            ref: ref,
                            progress: progress,
                            focusKeyResultId:
                                progress.keyResults[index].keyResult.id,
                          );
                        },
                        showDivider: index < progress.keyResults.length - 1,
                      ),
                  ],
                ),
              ),
            ],
            if (nextActions.isNotEmpty) ...[
              const Divider(height: 1),
              Theme(
                data: Theme.of(
                  context,
                ).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  key: PageStorageKey(
                    'objective-actions-home-${progress.objective.id}',
                  ),
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: EdgeInsets.zero,
                  expandedCrossAxisAlignment: CrossAxisAlignment.start,
                  title: Text(
                    'Próximas ações',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  subtitle: Text(
                    '${nextActions.length} passo(s) pontual(is) ligado(s) a este objetivo',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  children: [
                    for (int index = 0; index < nextActions.length; index++)
                      _ObjectiveActionTile(
                        activity: nextActions[index],
                        code: 'ACAO-${index + 1}',
                        ref: ref,
                        showDivider: index < nextActions.length - 1,
                      ),
                  ],
                ),
              ),
            ],
          ],
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

class _ObjectiveKeyResultTile extends StatelessWidget {
  const _ObjectiveKeyResultTile({
    required this.progress,
    required this.code,
    required this.onTap,
    required this.showDivider,
  });

  final KeyResultProgress progress;
  final String code;
  final VoidCallback onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final lastCheckInAt = progress.keyResult.lastCheckInAt;
    final updateLabel =
        lastCheckInAt == null
            ? 'Nunca atualizado'
            : 'Último check-in em ${DateFormat('dd/MM').format(lastCheckInAt)}';

    return Column(
      children: [
        _HomeHierarchyTile(
          icon: Icons.track_changes_rounded,
          code: code,
          title: progress.keyResult.title,
          subtitle:
              '${OkrProgressUtils.formatValue(progress.keyResult, progress.keyResult.currentValue)} de ${OkrProgressUtils.formatValue(progress.keyResult, progress.keyResult.targetValue)} • $updateLabel',
          trailing:
              progress.needsUpdate
                  ? const _PendingInlineBadge()
                  : const Icon(Icons.chevron_right_rounded),
          onTap: onTap,
        ),
        if (showDivider) const Divider(height: 1),
      ],
    );
  }
}

class _ObjectiveActionTile extends StatelessWidget {
  const _ObjectiveActionTile({
    required this.activity,
    required this.code,
    required this.ref,
    required this.showDivider,
  });

  final Activity activity;
  final String code;
  final WidgetRef ref;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final subtitle =
        activity.scheduledDate == null
            ? activity.recurrence.label
            : '${activity.recurrence.label} • ${DateFormat('dd/MM').format(activity.scheduledDate!)}';

    return Column(
      children: [
        _CompactActivityTile(
          activity: activity,
          code: code,
          title: activity.name,
          subtitle: subtitle,
          dense: true,
          onTap: () {
            _editActivity(context: context, ref: ref, activity: activity);
          },
          onSelected: (action) {
            _handleActivityAction(
              context: context,
              ref: ref,
              activity: activity,
              action: action,
            );
          },
        ),
        if (showDivider) const Divider(height: 1),
      ],
    );
  }
}

class _ActivityCardList extends StatelessWidget {
  const _ActivityCardList({
    required this.activities,
    required this.ref,
    this.compact = false,
    this.dense = false,
  });

  final List<Activity> activities;
  final WidgetRef ref;
  final bool compact;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          for (int index = 0; index < activities.length; index++) ...[
            if (compact)
              _CompactActivityTile(
                activity: activities[index],
                code: 'INIT-${index + 1}',
                title: activities[index].name,
                subtitle:
                    '${activities[index].recurrence.label} • ${TimeFormat.formatMinutesRange(activities[index].startMinutes, activities[index].endMinutes)}',
                onTap: () {
                  _editActivity(
                    context: context,
                    ref: ref,
                    activity: activities[index],
                  );
                },
                onSelected: (action) {
                  _handleActivityAction(
                    context: context,
                    ref: ref,
                    activity: activities[index],
                    action: action,
                  );
                },
              )
            else
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
                trailing: _ActivityActionsButton(
                  onSelected: (action) {
                    _handleActivityAction(
                      context: context,
                      ref: ref,
                      activity: activities[index],
                      action: action,
                    );
                  },
                ),
                dense: dense,
                onTap: () {
                  _editActivity(
                    context: context,
                    ref: ref,
                    activity: activities[index],
                  );
                },
              ),
            if (index < activities.length - 1) const Divider(height: 1),
          ],
        ],
      ),
    );
  }
}

class _CompactActivityTile extends StatelessWidget {
  const _CompactActivityTile({
    required this.activity,
    required this.code,
    required this.title,
    required this.subtitle,
    this.dense = false,
    required this.onTap,
    required this.onSelected,
  });

  final Activity activity;
  final String code;
  final String title;
  final String subtitle;
  final bool dense;
  final VoidCallback onTap;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: dense ? 12 : 16,
          vertical: dense ? 8 : 12,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    code,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                _ActivityActionsButton(onSelected: onSelected),
              ],
            ),
            SizedBox(height: dense ? 3 : 6),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: (dense
                      ? Theme.of(context).textTheme.titleSmall
                      : Theme.of(context).textTheme.titleMedium)
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            SizedBox(height: dense ? 2 : 4),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityActionsButton extends StatelessWidget {
  const _ActivityActionsButton({required this.onSelected});

  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Ações da iniciativa',
      onSelected: onSelected,
      itemBuilder:
          (_) => const [
            PopupMenuItem(value: 'complete', child: Text('Concluir hoje')),
            PopupMenuItem(value: 'edit', child: Text('Editar')),
            PopupMenuItem(value: 'delete', child: Text('Excluir')),
          ],
      child: const Padding(
        padding: EdgeInsets.all(4),
        child: Icon(Icons.more_horiz_rounded),
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
    this.dense = false,
    this.onTap,
  });

  final IconData icon;
  final String code;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final bool dense;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;

    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(
        horizontal: dense ? 12 : 14,
        vertical: dense ? 2 : 6,
      ),
      leading: Container(
        width: dense ? 34 : 36,
        height: dense ? 34 : 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: dense ? 17 : 18, color: color),
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
          SizedBox(height: dense ? 1 : 2),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: dense ? Theme.of(context).textTheme.titleSmall : null,
          ),
        ],
      ),
      subtitle: Padding(
        padding: EdgeInsets.only(top: dense ? 2 : 4),
        child: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      trailing: trailing,
      horizontalTitleGap: dense ? 10 : 12,
      minVerticalPadding: dense ? 6 : 10,
    );
  }
}

class _PendingInlineBadge extends StatelessWidget {
  const _PendingInlineBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'Pendente',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.error,
          fontWeight: FontWeight.w800,
        ),
      ),
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

List<Activity> _recurringActivitiesForObjective(List<Activity> activities) {
  final items =
      activities.where((item) => item.isRecurringForObjective).toList();
  items.sort(_sortActivitiesByTime);
  return items;
}

List<Activity> _nextActionsForObjective(List<Activity> activities) {
  final items =
      activities.where((item) => item.isOneOffObjectiveAction).toList();
  items.sort((a, b) {
    final aDate = a.scheduledDate;
    final bDate = b.scheduledDate;
    if (aDate != null && bDate != null) {
      final compare = aDate.compareTo(bDate);
      if (compare != 0) return compare;
    } else if (aDate != null) {
      return -1;
    } else if (bDate != null) {
      return 1;
    }
    return b.updatedAt.compareTo(a.updatedAt);
  });
  return items;
}

int _sortActivitiesByTime(Activity a, Activity b) {
  final aMinutes = a.startMinutes ?? 9999;
  final bMinutes = b.startMinutes ?? 9999;
  if (aMinutes != bMinutes) return aMinutes.compareTo(bMinutes);
  return a.name.compareTo(b.name);
}

Future<void> _editActivity({
  required BuildContext context,
  required WidgetRef ref,
  required Activity activity,
}) async {
  await Navigator.of(context).push<bool>(
    MaterialPageRoute(builder: (_) => ActivityFormScreen(activity: activity)),
  );
  await ref.read(activitiesControllerProvider.notifier).reload();
  ref.invalidate(okrWorkspaceControllerProvider);
}

Future<void> _handleActivityAction({
  required BuildContext context,
  required WidgetRef ref,
  required Activity activity,
  required String action,
}) async {
  if (action == 'edit') {
    await _editActivity(context: context, ref: ref, activity: activity);
    return;
  }

  if (action == 'delete') {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Excluir iniciativa?'),
            content: Text('A iniciativa "${activity.name}" será removida.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Excluir'),
              ),
            ],
          ),
    );
    if (confirm != true) return;

    await ref.read(activitiesControllerProvider.notifier).delete(activity.id);
    ref.invalidate(okrWorkspaceControllerProvider);
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Iniciativa excluída.')));
    return;
  }

  if (action == 'complete') {
    final completion = await showCompletionQualitySheet(context);
    if (completion == null) return;

    await ref
        .read(todayControllerProvider.notifier)
        .updateStatus(
          activityId: activity.id,
          status: ActivityStatus.completed,
          completionPayload: completion,
        );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('"${activity.name}" concluída hoje.')),
    );
  }
}
