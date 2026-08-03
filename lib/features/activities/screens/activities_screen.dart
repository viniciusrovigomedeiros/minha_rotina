import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/time_format.dart';
import '../../../data/models/activity.dart';
import '../../../state/activities_controller.dart';
import '../../../state/okr_workspace_controller.dart';
import 'activity_form_screen.dart';

class ActivitiesScreen extends ConsumerWidget {
  const ActivitiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activitiesAsync = ref.watch(activitiesControllerProvider);
    final workspace = ref.watch(okrWorkspaceControllerProvider).valueOrNull;
    final objectiveTitles = {
      for (final item in workspace?.allObjectives ?? const <dynamic>[])
        item.objective.id: item.objective.title,
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Iniciativas e tarefas')),
      body: SafeArea(
        top: false,
        child: activitiesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Erro ao carregar: $error')),
          data: (activities) {
            if (activities.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Você ainda não cadastrou iniciativas ou tarefas.\nToque em + para começar.',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            return RefreshIndicator(
              onRefresh:
                  () =>
                      ref.read(activitiesControllerProvider.notifier).reload(),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
                children: [
                  Card(
                    child: Column(
                      children: [
                        for (
                          int index = 0;
                          index < activities.length;
                          index++
                        ) ...[
                          Builder(
                            builder: (context) {
                              final activity = activities[index];

                              return _ActivityListTile(
                                activity: activity,
                                objectiveTitle:
                                    activity.objectiveId == null
                                        ? null
                                        : objectiveTitles[activity.objectiveId],
                                onEdit: () async {
                                  await Navigator.of(context).push<bool>(
                                    MaterialPageRoute(
                                      builder:
                                          (_) => ActivityFormScreen(
                                            activity: activity,
                                          ),
                                    ),
                                  );
                                  await ref
                                      .read(
                                        activitiesControllerProvider.notifier,
                                      )
                                      .reload();
                                },
                                onDelete: () async {
                                  await ref
                                      .read(
                                        activitiesControllerProvider.notifier,
                                      )
                                      .delete(activity.id);
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Atividade excluída.'),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                          if (index < activities.length - 1)
                            const Divider(height: 1, thickness: 1),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const ActivityFormScreen()),
          );
          await ref.read(activitiesControllerProvider.notifier).reload();
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nova iniciativa'),
      ),
    );
  }
}

class _ActivityListTile extends StatelessWidget {
  const _ActivityListTile({
    required this.activity,
    required this.objectiveTitle,
    required this.onEdit,
    required this.onDelete,
  });

  final Activity activity;
  final String? objectiveTitle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      leading: const Icon(Icons.task_alt_rounded),
      title: Text(activity.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 2),
          if (objectiveTitle != null) ...[
            Text('Objetivo: $objectiveTitle'),
            const SizedBox(height: 2),
          ],
          Text('Recorrência: ${activity.recurrence.label}'),
          const SizedBox(height: 2),
          if (activity.recurrence == ActivityRecurrence.weekly) ...[
            Text(
              'Meta: ${activity.effectiveWeeklyTargetCount}x por semana',
            ),
            const SizedBox(height: 2),
          ],
          Text(
            'Horário: ${TimeFormat.formatMinutesRange(activity.startMinutes, activity.endMinutes)}',
          ),
          const SizedBox(height: 2),
          Text('${_daysLabel(activity)}: ${_weekdaysLabel(activity)}'),
          const SizedBox(height: 2),
          Text(
            activity.isActive ? 'Status: ativa' : 'Status: inativa',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color:
                  activity.isActive
                      ? Theme.of(context).colorScheme.secondary
                      : Theme.of(context).colorScheme.outline,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      trailing: PopupMenuButton<String>(
        onSelected: (value) {
          if (value == 'edit') {
            onEdit();
          }
          if (value == 'delete') {
            onDelete();
          }
        },
        itemBuilder:
            (_) => const [
              PopupMenuItem(value: 'edit', child: Text('Editar')),
              PopupMenuItem(value: 'delete', child: Text('Excluir')),
            ],
      ),
    );
  }

  String _daysLabel(Activity activity) {
    return switch (activity.recurrence) {
      ActivityRecurrence.weekly => 'Sugestões',
      ActivityRecurrence.weeklyFixed => 'Dias fixos',
      _ => 'Dias',
    };
  }

  String _weekdaysLabel(Activity activity) {
    const labels = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
    final sorted = [...activity.weekdays]..sort();
    if (sorted.isEmpty) {
      return activity.recurrence == ActivityRecurrence.weekly
          ? 'Sem sugestão fixa'
          : '—';
    }
    return sorted
        .where((day) => day >= 1 && day <= 7)
        .map((day) => labels[day - 1])
        .join(', ');
  }
}
