import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/activity.dart';
import '../../../data/models/category.dart';
import '../../../data/models/weekly_goal.dart';
import '../../../state/activities_controller.dart';
import '../../../state/categories_controller.dart';
import '../../../state/goals_controller.dart';
import '../../../state/weekly_goals_controller.dart';
import '../widgets/weekly_goal_card.dart';
import 'goal_form_screen.dart';

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(weeklyGoalsControllerProvider);
    final activities =
        ref.watch(activitiesControllerProvider).valueOrNull ?? const [];
    final categories =
        ref.watch(categoriesControllerProvider).valueOrNull ?? const [];

    return Scaffold(
      appBar: AppBar(title: const Text('Metas')),
      body: SafeArea(
        top: false,
        child: goalsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Erro ao carregar: $error')),
          data: (progresses) {
            if (progresses.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.flag_outlined,
                        size: 54,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Você ainda não criou metas.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Crie metas automáticas de execução ou metas manuais de resultado.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () => _openForm(context),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Criar primeira meta'),
                      ),
                    ],
                  ),
                ),
              );
            }

            return RefreshIndicator(
              onRefresh:
                  () =>
                      ref.read(weeklyGoalsControllerProvider.notifier).reload(),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  Text(
                    'Suas metas',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Metas ativas aparecem no dashboard e podem gerar lembretes.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 14),
                  for (int index = 0; index < progresses.length; index++) ...[
                    WeeklyGoalCard(
                      progress: progresses[index],
                      scopeLabel: _scopeLabel(
                        progresses[index].goal,
                        activities,
                        categories,
                      ),
                      onTap:
                          () =>
                              _openForm(context, goal: progresses[index].goal),
                      onMore:
                          () => _openMenu(
                            context: context,
                            ref: ref,
                            goal: progresses[index].goal,
                          ),
                    ),
                    if (index < progresses.length - 1)
                      const SizedBox(height: 10),
                  ],
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nova meta'),
      ),
    );
  }

  Future<void> _openForm(BuildContext context, {WeeklyGoal? goal}) async {
    await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => GoalFormScreen(goal: goal)));
  }

  Future<void> _openMenu({
    required BuildContext context,
    required WidgetRef ref,
    required WeeklyGoal goal,
  }) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Editar meta'),
                onTap: () => Navigator.of(context).pop('edit'),
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded),
                title: const Text('Excluir meta'),
                onTap: () => Navigator.of(context).pop('delete'),
              ),
              const SizedBox(height: 6),
            ],
          ),
        );
      },
    );

    if (!context.mounted || selected == null) return;

    if (selected == 'edit') {
      await _openForm(context, goal: goal);
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Excluir meta?'),
          content: Text('A meta "${goal.name}" será removida.'),
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
    await ref.read(goalsControllerProvider.notifier).delete(goal.id);
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
