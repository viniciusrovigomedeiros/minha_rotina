import 'package:flutter/material.dart';

import '../../../data/models/activity_status.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});

  final ActivityStatus status;

  @override
  Widget build(BuildContext context) {
    final palette = _paletteFor(context, status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: palette.foreground,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  _Palette _paletteFor(BuildContext context, ActivityStatus status) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (status) {
      case ActivityStatus.pending:
        return _Palette(
          background: colorScheme.primary.withValues(alpha: 0.14),
          foreground: colorScheme.primary,
        );
      case ActivityStatus.completed:
        return _Palette(
          background: colorScheme.secondaryContainer,
          foreground: colorScheme.onSecondaryContainer,
        );
      case ActivityStatus.skipped:
        return _Palette(
          background: colorScheme.tertiaryContainer,
          foreground: colorScheme.onTertiaryContainer,
        );
    }
  }
}

class _Palette {
  const _Palette({required this.background, required this.foreground});

  final Color background;
  final Color foreground;
}
