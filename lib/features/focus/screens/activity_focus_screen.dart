import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/motivation_utils.dart';
import '../../../core/utils/time_format.dart';
import '../../../data/models/activity.dart';
import '../../../data/models/activity_status.dart';
import '../../../state/motivation_phrases_controller.dart';
import '../../../state/today_controller.dart';

class ActivityFocusScreen extends ConsumerWidget {
  const ActivityFocusScreen({super.key, required this.activity});

  final Activity activity;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final phrases = ref.watch(motivationPhrasesControllerProvider).valueOrNull;
    final phrase =
        phrases == null
            ? MotivationUtils.phraseForDay(now)
            : (phrases.isEmpty
                ? 'Sem frase motivacional definida.'
                : MotivationUtils.phraseForDay(now, phrases: phrases));

    return Scaffold(
      appBar: AppBar(title: const Text('Foco da atividade')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.name,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                Text(
                  activity.description ?? 'Sem descrição detalhada.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 14),
                Text(
                  TimeFormat.formatMinutesRange(
                    activity.startMinutes,
                    activity.endMinutes,
                  ),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 10),
                Text(phrase, style: Theme.of(context).textTheme.bodySmall),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () async {
                      await ref
                          .read(todayControllerProvider.notifier)
                          .updateStatus(
                            activityId: activity.id,
                            status: ActivityStatus.completed,
                          );
                      if (!context.mounted) return;
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.check_circle_rounded),
                    label: const Text('Concluir atividade'),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await ref
                          .read(todayControllerProvider.notifier)
                          .updateStatus(
                            activityId: activity.id,
                            status: ActivityStatus.skipped,
                          );
                      if (!context.mounted) return;
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.close_rounded),
                    label: const Text('Pular hoje'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
