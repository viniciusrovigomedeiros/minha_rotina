import 'package:flutter/material.dart';

import '../../../core/utils/weekly_goal_progress_utils.dart';
import '../../../data/models/weekly_goal.dart';

class WeeklyGoalCard extends StatelessWidget {
  const WeeklyGoalCard({
    super.key,
    required this.progress,
    required this.scopeLabel,
    this.compact = false,
    this.onTap,
    this.onMore,
  });

  final WeeklyGoalProgress progress;
  final String scopeLabel;
  final bool compact;
  final VoidCallback? onTap;
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    final titleStyle =
        compact
            ? Theme.of(context).textTheme.titleSmall
            : Theme.of(context).textTheme.titleMedium;
    final statusColor =
        progress.isCompleted
            ? const Color(0xFF2E9E6E)
            : Theme.of(context).colorScheme.primary;

    final goal = progress.goal;
    final subtitle =
        goal.isAutomatic
            ? '${goal.type?.label ?? 'Execução'} · $scopeLabel'
            : 'Resultado manual · $scopeLabel';
    final valueSuffix =
        goal.isManual && (goal.unit?.trim().isNotEmpty ?? false)
            ? ' ${goal.unit!.trim()}'
            : '';

    final content = Container(
      padding: EdgeInsets.all(compact ? 14 : 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color:
              progress.isCompleted
                  ? const Color(0xFFBFE3CF)
                  : Theme.of(
                    context,
                  ).colorScheme.outline.withValues(alpha: 0.28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      progress.goal.name,
                      style: titleStyle?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (onMore != null)
                IconButton(
                  onPressed: onMore,
                  icon: const Icon(Icons.more_horiz_rounded),
                  visualDensity: VisualDensity.compact,
                )
              else
                _GoalStatusPill(progress: progress),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: compact ? 8 : 10,
              value: progress.ratio,
              backgroundColor: statusColor.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                '${progress.progressLabel}$valueSuffix',
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  progress.isCompleted
                      ? 'Meta concluída'
                      : 'Faltam ${WeeklyGoalProgress.formatGoalNumber(progress.remainingValue)}$valueSuffix',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
          if (!compact && onMore != null) ...[
            const SizedBox(height: 10),
            _GoalStatusPill(progress: progress),
          ],
        ],
      ),
    );

    if (onTap == null) return content;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: content,
    );
  }
}

class _GoalStatusPill extends StatelessWidget {
  const _GoalStatusPill({required this.progress});

  final WeeklyGoalProgress progress;

  @override
  Widget build(BuildContext context) {
    final completed = progress.isCompleted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color:
            completed
                ? const Color(0xFFE8F8EF)
                : Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        completed ? 'Concluída' : 'Em andamento',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color:
              completed
                  ? const Color(0xFF2E9E6E)
                  : Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
