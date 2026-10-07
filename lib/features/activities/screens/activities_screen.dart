import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/time_format.dart';
import '../../../data/models/activity.dart';
import '../../../state/activities_controller.dart';
import '../../../state/okr_workspace_controller.dart';
import 'activity_form_screen.dart';
import '../../social/screens/social_hub_screen.dart';

class ActivitiesScreen extends ConsumerWidget {
  const ActivitiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activitiesAsync = ref.watch(activitiesControllerProvider);
    final workspace = ref.watch(okrWorkspaceControllerProvider).valueOrNull;
    final objectiveTitles = <String, String>{
      for (final item in workspace?.allObjectives ?? const <dynamic>[])
        item.objective.id: item.objective.title,
    };

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Iniciativas e tarefas'),
          bottom: const TabBar(
            tabs: [Tab(text: 'Atuais'), Tab(text: 'Passadas')],
          ),
        ),
        body: SafeArea(
          top: false,
          child: activitiesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error:
                (error, _) => Center(child: Text('Erro ao carregar: $error')),
            data: (activities) {
              final now = DateTime.now();
              final today = DateTime(now.year, now.month, now.day);
              final current = <Activity>[];
              final past = <Activity>[];
              for (final activity in activities) {
                (_isPastActivity(activity, today) ? past : current).add(
                  activity,
                );
              }
              return TabBarView(
                children: [
                  _buildList(
                    context,
                    ref,
                    current,
                    objectiveTitles,
                    emptyMessage:
                        'Nenhuma iniciativa atual.\nToque em + para cadastrar uma nova.',
                  ),
                  _buildList(
                    context,
                    ref,
                    past,
                    objectiveTitles,
                    emptyMessage: 'Nenhuma iniciativa passada.',
                  ),
                ],
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
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    WidgetRef ref,
    List<Activity> activities,
    Map<String, String> objectiveTitles, {
    required String emptyMessage,
  }) {
    return RefreshIndicator(
      onRefresh: () => ref.read(activitiesControllerProvider.notifier).reload(),
      child:
          activities.isEmpty
              ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: [Text(emptyMessage, textAlign: TextAlign.center)],
              )
              : ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
                itemCount: activities.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final activity = activities[index];
                  return Card(
                    margin: EdgeInsets.zero,
                    child: _ActivityListTile(
                      activity: activity,
                      objectiveTitle:
                          activity.objectiveId == null
                              ? null
                              : objectiveTitles[activity.objectiveId],
                      onEdit: () async {
                        await Navigator.of(context).push<bool>(
                          MaterialPageRoute(
                            builder:
                                (_) => ActivityFormScreen(activity: activity),
                          ),
                        );
                        await ref
                            .read(activitiesControllerProvider.notifier)
                            .reload();
                      },
                      onDelete: () async {
                        await ref
                            .read(activitiesControllerProvider.notifier)
                            .delete(activity.id);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Atividade excluída.')),
                        );
                      },
                      onCreateSocialChallenge:
                          activity.objectiveId == null
                              ? () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder:
                                      (_) => SocialHubScreen(
                                        initialChallengeTitle: activity.name,
                                        initialChallengeDescription:
                                            'Desafio criado a partir da iniciativa "${activity.name}".',
                                      ),
                                ),
                              )
                              : null,
                    ),
                  );
                },
              ),
    );
  }
}

bool _isPastActivity(Activity activity, DateTime today) {
  if (!activity.isActive) return true;
  final deadline =
      activity.endDate ??
      (activity.recurrence == ActivityRecurrence.oneOff
          ? activity.scheduledDate
          : null);
  if (deadline == null) return false;
  return DateTime(deadline.year, deadline.month, deadline.day).isBefore(today);
}

class _ActivityListTile extends StatelessWidget {
  const _ActivityListTile({
    required this.activity,
    required this.objectiveTitle,
    required this.onEdit,
    required this.onDelete,
    this.onCreateSocialChallenge,
  });

  final Activity activity;
  final String? objectiveTitle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onCreateSocialChallenge;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final status =
        !activity.isActive
            ? 'inativa'
            : _isPastActivity(activity, today)
            ? 'encerrada'
            : activity.effectiveStartDate.isAfter(today)
            ? 'prevista'
            : 'ativa';
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
          if (activity.endDate != null) ...[
            Text(
              'Período: ${_dateLabel(activity.effectiveStartDate)} a ${_dateLabel(activity.endDate!)}',
            ),
            const SizedBox(height: 2),
          ],
          Text('Recorrência: ${activity.recurrence.label}'),
          const SizedBox(height: 2),
          if (activity.recurrence == ActivityRecurrence.weekly) ...[
            Text('Meta: ${activity.effectiveWeeklyTargetCount}x por semana'),
            const SizedBox(height: 2),
          ],
          Text(
            'Horário: ${TimeFormat.formatMinutesRange(activity.startMinutes, activity.endMinutes)}',
          ),
          const SizedBox(height: 2),
          Text('${_daysLabel(activity)}: ${_weekdaysLabel(activity)}'),
          const SizedBox(height: 2),
          Text(
            'Status: $status',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color:
                  !_isPastActivity(activity, today)
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
          if (value == 'social') {
            onCreateSocialChallenge?.call();
          }
        },
        itemBuilder:
            (_) => [
              const PopupMenuItem(value: 'edit', child: Text('Editar')),
              if (onCreateSocialChallenge != null)
                const PopupMenuItem(
                  value: 'social',
                  child: Text('Criar desafio social'),
                ),
              const PopupMenuItem(value: 'delete', child: Text('Excluir')),
            ],
      ),
    );
  }

  String _dateLabel(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  String _daysLabel(Activity activity) {
    return switch (activity.recurrence) {
      ActivityRecurrence.weekly => 'Sugestões',
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
