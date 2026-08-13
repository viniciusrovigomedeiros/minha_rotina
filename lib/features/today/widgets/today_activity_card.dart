import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/icon_mapper.dart';
import '../../../core/utils/time_format.dart';
import '../../../data/models/activity.dart';
import '../../../data/models/activity_completion_payload.dart';
import '../../../data/models/activity_status.dart';
import '../../../data/models/category.dart';
import '../../../state/today_controller.dart';
import '../../shared/widgets/completion_quality_sheet.dart';

class TodayActivityCard extends StatelessWidget {
  const TodayActivityCard({
    super.key,
    required this.item,
    required this.category,
    required this.onComplete,
    required this.onSkip,
    required this.onReset,
    required this.onOpen,
  });

  final TodayActivityItem item;
  final Category? category;
  final Future<void> Function(ActivityCompletionPayload completion) onComplete;
  final VoidCallback onSkip;
  final VoidCallback onReset;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final status = item.status;
    final scheme = Theme.of(context).colorScheme;
    final categoryColor =
        item.activity.colorOrNull ?? category?.color ?? scheme.primary;
    final meta = _buildMeta();
    final description = item.activity.description?.trim();
    final hasDescription = description != null && description.isNotEmpty;
    final highlightDueToday =
        item.weeklyTargetCount != null && item.isDueTodayInWeeklyGoals;

    return InkWell(
      onTap: onOpen,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: const BoxDecoration(),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              height: 36,
              width: 36,
              decoration: BoxDecoration(
                color: categoryColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                IconMapper.fromKey(item.activity.iconKey ?? category?.iconKey),
                size: 18,
                color: categoryColor,
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.activity.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      if (highlightDueToday)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(left: 6),
                          decoration: BoxDecoration(
                            color: scheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  if (item.weeklyTargetCount != null &&
                      item.weeklyCompletedCount != null)
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          meta,
                          style: Theme.of(
                            context,
                          ).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context).textTheme.bodySmall?.color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        _TypeMetaTag(
                          label: _weeklyGoalTypeLabel(item.activity),
                        ),
                        if (item.weeklyDeadlineLabel != null)
                          _MetaTag(
                            label: item.weeklyDeadlineLabel!,
                            highlighted: item.isDueTodayInWeeklyGoals,
                          ),
                      ],
                    )
                  else
                    Text(
                      meta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  if (status == ActivityStatus.completed &&
                      item.completionQuality != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        CompletionQualityChip(
                          quality: item.completionQuality!,
                          compact: true,
                        ),
                        if (item.qualityScore != null) ...[
                          const SizedBox(width: 6),
                          Text(
                            '${item.qualityScore}/10',
                            style: Theme.of(
                              context,
                            ).textTheme.labelSmall?.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                  if (hasDescription) ...[
                    const SizedBox(height: 2),
                    Text(
                      description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                        fontSize: 11,
                        height: 1.1,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            _StatusActionButton(
              status: status,
              onComplete: onComplete,
              onSkip: onSkip,
              onReset: onReset,
            ),
          ],
        ),
      ),
    );
  }

  String _buildMeta() {
    final categoryName = category?.name ?? 'Sem categoria';
    if (item.weeklyTargetCount != null && item.weeklyCompletedCount != null) {
      return '$categoryName  ·  ${item.weeklyCompletedCount}/${item.weeklyTargetCount}';
    }
    final timeLabel = TimeFormat.formatMinutesRange(
      item.activity.startMinutes,
      item.activity.endMinutes,
    );
    if (timeLabel == 'Sem horário definido') return categoryName;
    return '$categoryName  ·  $timeLabel';
  }

  String _weeklyGoalTypeLabel(Activity activity) {
    switch (activity.recurrence) {
      case ActivityRecurrence.daily:
        return 'Diaria';
      case ActivityRecurrence.weekly:
      case ActivityRecurrence.weeklyFixed:
        return 'Semanal';
      case ActivityRecurrence.monthly:
        return 'Mensal';
      case ActivityRecurrence.oneOff:
        return 'Unica';
      case ActivityRecurrence.flexible:
        return 'Flexivel';
    }
  }
}

class _MetaTag extends StatelessWidget {
  const _MetaTag({required this.label, required this.highlighted});

  final String label;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final background =
        highlighted
            ? scheme.primary.withValues(alpha: 0.14)
            : scheme.surfaceContainerHighest;
    final foreground = highlighted ? scheme.primary : scheme.outline;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color:
              highlighted
                  ? scheme.primary.withValues(alpha: 0.22)
                  : scheme.outlineVariant,
        ),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _TypeMetaTag extends StatelessWidget {
  const _TypeMetaTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: scheme.outline,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _StatusActionButton extends StatelessWidget {
  const _StatusActionButton({
    required this.status,
    required this.onComplete,
    required this.onSkip,
    required this.onReset,
  });

  final ActivityStatus status;
  final Future<void> Function(ActivityCompletionPayload completion) onComplete;
  final VoidCallback onSkip;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    switch (status) {
      case ActivityStatus.completed:
        return _CircleAction(
          icon: Icons.check_rounded,
          palette: _Palette(
            fill: palette.successFill,
            border: palette.successBorder,
            icon: palette.successForeground,
          ),
          onTap: onReset,
        );
      case ActivityStatus.skipped:
        return _CircleAction(
          icon: Icons.close_rounded,
          palette: _Palette(
            fill: palette.warningFill,
            border: palette.warningBorder,
            icon: palette.warningForeground,
          ),
          onTap: onReset,
        );
      case ActivityStatus.pending:
        return _CircleAction(
          icon: Icons.more_horiz_rounded,
          palette: _Palette(
            fill: palette.neutralFill,
            border: palette.neutralBorder,
            icon: palette.neutralForeground,
          ),
          onTap: () => _openActions(context),
        );
    }
  }

  Future<void> _openActions(BuildContext context) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.check_circle_outline_rounded),
                title: const Text('Marcar como concluída'),
                onTap: () => Navigator.of(context).pop('complete'),
              ),
              ListTile(
                leading: const Icon(Icons.close_rounded),
                title: const Text('Marcar como pulada'),
                onTap: () => Navigator.of(context).pop('skip'),
              ),
              const SizedBox(height: 6),
            ],
          ),
        );
      },
    );

    if (selected == 'complete') {
      if (!context.mounted) return;
      final quality = await showCompletionQualitySheet(context);
      if (quality == null) return;
      await onComplete(quality);
    } else if (selected == 'skip') {
      onSkip();
    }
  }
}

class _CircleAction extends StatelessWidget {
  const _CircleAction({
    required this.icon,
    required this.palette,
    required this.onTap,
  });

  final IconData icon;
  final _Palette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: palette.fill,
          border: Border.all(color: palette.border, width: 1.2),
        ),
        child: Icon(icon, size: 20, color: palette.icon),
      ),
    );
  }
}

class _Palette {
  const _Palette({
    required this.fill,
    required this.border,
    required this.icon,
  });

  final Color fill;
  final Color border;
  final Color icon;
}
