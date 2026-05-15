import 'package:flutter/material.dart';

import '../../../core/utils/icon_mapper.dart';
import '../../../core/utils/time_format.dart';
import '../../../data/models/activity_status.dart';
import '../../../data/models/category.dart';
import '../../../state/today_controller.dart';

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
  final VoidCallback onComplete;
  final VoidCallback onSkip;
  final VoidCallback onReset;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final status = item.status;
    final categoryColor =
        item.activity.colorOrNull ??
        category?.color ??
        Theme.of(context).colorScheme.primary;
    final meta = _buildMeta();
    final description = item.activity.description?.trim();
    final hasDescription = description != null && description.isNotEmpty;

    return InkWell(
      onTap: onOpen,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                  Text(
                    item.activity.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    meta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
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
    final timeLabel = TimeFormat.formatMinutesRange(
      item.activity.startMinutes,
      item.activity.endMinutes,
    );
    if (timeLabel == 'Sem horário definido') return categoryName;
    return '$categoryName  ·  $timeLabel';
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
  final VoidCallback onComplete;
  final VoidCallback onSkip;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case ActivityStatus.completed:
        return _CircleAction(
          icon: Icons.check_rounded,
          palette: const _Palette(
            fill: Color(0xFFE3F3EA),
            border: Color(0xFFC8E7D8),
            icon: Color(0xFF2E9E6E),
          ),
          onTap: onReset,
        );
      case ActivityStatus.skipped:
        return _CircleAction(
          icon: Icons.close_rounded,
          palette: const _Palette(
            fill: Color(0xFFF6EAD9),
            border: Color(0xFFEFD9BC),
            icon: Color(0xFFB9832C),
          ),
          onTap: onReset,
        );
      case ActivityStatus.pending:
        return _CircleAction(
          icon: Icons.more_horiz_rounded,
          palette: const _Palette(
            fill: Color(0xFFF4F6FB),
            border: Color(0xFFE1E6F1),
            icon: Color(0xFF98A3BA),
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
      onComplete();
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
