import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/okr_progress_utils.dart';
import '../../../data/models/activity.dart';
import '../../../data/models/okr_objective.dart';
import '../../../state/okr_management_controller.dart';
import '../../../state/okr_workspace_controller.dart';
import '../../activities/screens/activity_form_screen.dart';
import '../widgets/okr_check_in_sheet.dart';
import 'okr_objective_form_screen.dart';

class OkrObjectiveDetailScreen extends ConsumerWidget {
  const OkrObjectiveDetailScreen({super.key, required this.objectiveId});

  final String objectiveId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(okrObjectiveProgressProvider(objectiveId));

    if (progress == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Objetivo não encontrado.')),
      );
    }

    final percent = (progress.progress * 100).round();
    final shortDateFormat = DateFormat('dd/MM');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhe do objetivo'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder:
                      (_) => OkrObjectiveFormScreen(objectiveId: objectiveId),
                ),
              );
            },
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Editar',
          ),
          IconButton(
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text('Excluir objetivo?'),
                    content: Text(
                      'O objetivo "${progress.objective.title}" será removido. As iniciativas continuarão salvas, mas serão desvinculadas.',
                    ),
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
                  );
                },
              );

              if (confirm != true) return;
              await ref
                  .read(okrManagementControllerProvider.notifier)
                  .deleteObjective(objectiveId);
              if (!context.mounted) return;
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.delete_outline_rounded),
            tooltip: 'Excluir',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder:
                  (_) => ActivityFormScreen(
                    initialObjectiveId: progress.objective.id,
                  ),
            ),
          );
        },
        icon: const Icon(Icons.add_task_rounded),
        label: const Text('Nova iniciativa'),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: [
            if (progress.objective.needsReview)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Este objetivo foi migrado automaticamente dos dados antigos em 20/07/2026 e deve ser revisado.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
            if (progress.objective.needsReview) const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        const _HeaderBadge(label: 'OBJETIVO'),
                        _HeaderMetaPill(label: progress.cycle.name),
                        _HeaderMetaPill(label: progress.objective.status.label),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _DetailWorkItemIcon(
                          icon: Icons.flag_rounded,
                          tint: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
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
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (progress.objective.description != null) ...[
                      const SizedBox(height: 10),
                      Text(progress.objective.description!),
                    ],
                    const SizedBox(height: 14),
                    _HeroProgress(
                      progress: progress.progress,
                      percentLabel: '$percent%',
                    ),
                    const SizedBox(height: 14),
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: _SummaryTile(
                              label: 'Período',
                              value:
                                  '${shortDateFormat.format(progress.objective.startDate)} - ${shortDateFormat.format(progress.objective.endDate)}',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _SummaryTile(
                              label: 'Resultados-chave',
                              value: '${progress.keyResults.length}',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _SummaryTile(
                              label: 'Iniciativas',
                              value: '${progress.initiatives.length}',
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (progress.keyResults.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () {
                            _handleObjectiveCheckIn(context, ref, progress);
                          },
                          icon: const Icon(
                            Icons.playlist_add_check_circle_rounded,
                          ),
                          label: Text(
                            progress.staleKeyResultsCount > 0
                                ? 'Fazer check-in (${progress.staleKeyResultsCount} pendente(s))'
                                : 'Fazer check-in',
                          ),
                        ),
                      ),
                    ],
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
                      'Resultados-chave',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Itens de resultado ligados ao objetivo pai.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    if (progress.keyResults.isEmpty)
                      Text(
                        'Nenhum resultado-chave configurado.',
                        style: Theme.of(context).textTheme.bodySmall,
                      )
                    else
                      for (
                        int index = 0;
                        index < progress.keyResults.length;
                        index++
                      ) ...[
                        _KeyResultTile(
                          progress: progress.keyResults[index],
                          index: index + 1,
                          onCheckIn:
                              progress.keyResults[index].needsUpdate
                                  ? () {
                                    _handleObjectiveCheckIn(
                                      context,
                                      ref,
                                      progress,
                                      focusKeyResultId:
                                          progress
                                              .keyResults[index]
                                              .keyResult
                                              .id,
                                    );
                                  }
                                  : null,
                        ),
                        if (index < progress.keyResults.length - 1)
                          const Divider(height: 20),
                      ],
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
                      'Iniciativas',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ações filhas para mover os resultados-chave.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    if (progress.initiatives.isEmpty)
                      Text(
                        'Ainda não há iniciativas vinculadas.',
                        style: Theme.of(context).textTheme.bodySmall,
                      )
                    else
                      for (
                        int index = 0;
                        index < progress.initiatives.length;
                        index++
                      ) ...[
                        _InitiativeTile(
                          activity: progress.initiatives[index],
                          code: 'TASK-${index + 1}',
                        ),
                        if (index < progress.initiatives.length - 1)
                          const Divider(height: 10),
                      ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KeyResultTile extends StatelessWidget {
  const _KeyResultTile({
    required this.progress,
    required this.index,
    this.onCheckIn,
  });

  final KeyResultProgress progress;
  final int index;
  final VoidCallback? onCheckIn;

  @override
  Widget build(BuildContext context) {
    final percent = (progress.progress * 100).round();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.28),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DetailWorkItemIcon(
            icon: Icons.track_changes_rounded,
            tint: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'KR-$index',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.primary,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  progress.keyResult.title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  '${OkrProgressUtils.formatValue(progress.keyResult, progress.keyResult.currentValue)} de ${OkrProgressUtils.formatValue(progress.keyResult, progress.keyResult.targetValue)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 10),
                LinearProgressIndicator(value: progress.progress, minHeight: 8),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '$percent% concluído',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 10),
                    if (progress.needsUpdate)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Pendente',
                          style: Theme.of(
                            context,
                          ).textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    const Spacer(),
                    if (onCheckIn != null)
                      TextButton.icon(
                        onPressed: onCheckIn,
                        icon: const Icon(Icons.edit_calendar_rounded, size: 18),
                        label: const Text('Atualizar'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderBadge extends StatelessWidget {
  const _HeaderBadge({required this.label});

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
          color: Colors.white,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _DetailWorkItemIcon extends StatelessWidget {
  const _DetailWorkItemIcon({required this.icon, required this.tint});

  final IconData icon;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, size: 22, color: tint),
    );
  }
}

class _HeaderMetaPill extends StatelessWidget {
  const _HeaderMetaPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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

class _HeroProgress extends StatelessWidget {
  const _HeroProgress({required this.progress, required this.percentLabel});

  final double progress;
  final String percentLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Progresso do objetivo',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                percentLabel,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(value: progress, minHeight: 9),
        ],
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({required this.label, required this.value});

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
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.25),
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

class _InitiativeTile extends StatelessWidget {
  const _InitiativeTile({required this.activity, required this.code});

  final Activity activity;
  final String code;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DetailWorkItemIcon(
          icon: Icons.check_box_outlined,
          tint: Theme.of(context).colorScheme.secondary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                code,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.secondary,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                activity.name,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                activity.description ?? activity.recurrence.label,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

Future<void> _handleObjectiveCheckIn(
  BuildContext context,
  WidgetRef ref,
  OkrObjectiveProgress progress, {
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
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(const SnackBar(content: Text('Check-in semanal salvo.')));
}
