import 'package:flutter/material.dart';

import '../../../data/models/activity_completion_quality.dart';

Future<ActivityCompletionQuality?> showCompletionQualitySheet(
  BuildContext context,
) {
  return showModalBottomSheet<ActivityCompletionQuality>(
    context: context,
    showDragHandle: true,
    builder: (context) => const _CompletionQualitySheet(),
  );
}

class CompletionQualityChip extends StatelessWidget {
  const CompletionQualityChip({
    super.key,
    required this.quality,
    this.compact = false,
  });

  final ActivityCompletionQuality quality;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final palette = _paletteFor(quality);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(palette.icon, size: compact ? 14 : 16, color: palette.foreground),
          const SizedBox(width: 5),
          Text(
            quality.label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: palette.foreground,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompletionQualitySheet extends StatelessWidget {
  const _CompletionQualitySheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Como foi essa atividade hoje?',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              'A conclusão continua contando, mas a qualidade ajusta o peso no histórico e dashboard.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 14),
            for (final quality in ActivityCompletionQuality.values) ...[
              _QualityOptionTile(quality: quality),
              if (quality != ActivityCompletionQuality.values.last)
                const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class _QualityOptionTile extends StatelessWidget {
  const _QualityOptionTile({required this.quality});

  final ActivityCompletionQuality quality;

  @override
  Widget build(BuildContext context) {
    final palette = _paletteFor(quality);
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => Navigator.of(context).pop(quality),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: palette.background,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: palette.border),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: palette.foreground.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(palette.icon, color: palette.foreground),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    quality.label,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: palette.foreground,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    quality.description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: palette.foreground.withValues(alpha: 0.86),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '${quality.weight.toStringAsFixed(2)}x',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: palette.foreground,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

_CompletionQualityPalette _paletteFor(ActivityCompletionQuality quality) {
  return switch (quality) {
    ActivityCompletionQuality.low => const _CompletionQualityPalette(
      background: Color(0xFFFFF1E7),
      border: Color(0xFFF2D3B9),
      foreground: Color(0xFFB86A1A),
      icon: Icons.sentiment_dissatisfied_rounded,
    ),
    ActivityCompletionQuality.medium => const _CompletionQualityPalette(
      background: Color(0xFFEAF2FF),
      border: Color(0xFFC8DAFF),
      foreground: Color(0xFF4268D6),
      icon: Icons.sentiment_neutral_rounded,
    ),
    ActivityCompletionQuality.high => const _CompletionQualityPalette(
      background: Color(0xFFE8F8EF),
      border: Color(0xFFC8E9D7),
      foreground: Color(0xFF2E9E6E),
      icon: Icons.sentiment_very_satisfied_rounded,
    ),
  };
}

class _CompletionQualityPalette {
  const _CompletionQualityPalette({
    required this.background,
    required this.border,
    required this.foreground,
    required this.icon,
  });

  final Color background;
  final Color border;
  final Color foreground;
  final IconData icon;
}
