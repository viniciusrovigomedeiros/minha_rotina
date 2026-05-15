import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/icon_mapper.dart';
import '../../../core/utils/time_format.dart';
import '../../../data/models/activity.dart';
import '../../../state/activities_controller.dart';
import '../../../state/categories_controller.dart';
import 'activity_form_screen.dart';

class ActivitiesScreen extends ConsumerWidget {
  const ActivitiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activitiesAsync = ref.watch(activitiesControllerProvider);
    final categories =
        ref.watch(categoriesControllerProvider).valueOrNull ?? const [];

    return Scaffold(
      appBar: AppBar(title: const Text('Atividades')),
      body: activitiesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Erro ao carregar: $error')),
        data: (activities) {
          if (activities.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Você ainda não cadastrou atividades.\nToque em + para começar sua rotina.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh:
                () => ref.read(activitiesControllerProvider.notifier).reload(),
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
                            final category =
                                categories
                                    .where(
                                      (item) => item.id == activity.categoryId,
                                    )
                                    .toList();
                            final categoryName =
                                category.isEmpty
                                    ? 'Sem categoria'
                                    : category.first.name;
                            final color =
                                activity.colorOrNull ??
                                (category.isEmpty
                                    ? Theme.of(context).colorScheme.primary
                                    : category.first.color);

                            return _ActivityListTile(
                              activity: activity,
                              categoryName: categoryName,
                              color: color,
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
                                    .read(activitiesControllerProvider.notifier)
                                    .reload();
                              },
                              onDelete: () async {
                                await ref
                                    .read(activitiesControllerProvider.notifier)
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const ActivityFormScreen()),
          );
          await ref.read(activitiesControllerProvider.notifier).reload();
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nova atividade'),
      ),
    );
  }
}

class _ActivityListTile extends StatelessWidget {
  const _ActivityListTile({
    required this.activity,
    required this.categoryName,
    required this.color,
    required this.onEdit,
    required this.onDelete,
  });

  final Activity activity;
  final String categoryName;
  final Color color;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          IconMapper.fromKey(activity.iconKey),
          color: color,
          size: 20,
        ),
      ),
      title: Text(activity.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 2),
          Text(categoryName),
          const SizedBox(height: 2),
          Text(
            TimeFormat.formatMinutesRange(
              activity.startMinutes,
              activity.endMinutes,
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
}
