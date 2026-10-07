import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/activity_completion_payload.dart';
import '../../../data/models/activity_completion_quality.dart';

Future<ActivityCompletionPayload?> showCompletionQualitySheet(
  BuildContext context,
) {
  return showModalBottomSheet<ActivityCompletionPayload>(
    context: context,
    isScrollControlled: true,
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
    final palette = _paletteFor(context, quality);
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
          Icon(
            palette.icon,
            size: compact ? 14 : 16,
            color: palette.foreground,
          ),
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

class _CompletionQualitySheet extends StatefulWidget {
  const _CompletionQualitySheet();

  @override
  State<_CompletionQualitySheet> createState() =>
      _CompletionQualitySheetState();
}

class _CompletionQualitySheetState extends State<_CompletionQualitySheet> {
  double _score = 7;

  @override
  Widget build(BuildContext context) {
    final quality = _qualityForScore(_score.round());

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          4,
          16,
          16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Qualidade da execução',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                'Dê uma nota rápida para como essa atividade foi executada.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Nota de qualidade: ${_score.round()}/10',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              Slider(
                value: _score,
                min: 0,
                max: 10,
                divisions: 10,
                label: _score.round().toString(),
                onChanged: (value) => setState(() => _score = value),
              ),
              const SizedBox(height: 2),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [CompletionQualityChip(quality: quality)],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop(
                      ActivityCompletionPayload(
                        completionQuality: quality,
                        qualityScore: _score.round(),
                        checklistCheckedCount: 0,
                        checklistTotalCount: 0,
                      ),
                    );
                  },
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Salvar nota'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  ActivityCompletionQuality _qualityForScore(int score) {
    if (score <= 4) return ActivityCompletionQuality.low;
    if (score <= 7) return ActivityCompletionQuality.medium;
    return ActivityCompletionQuality.high;
  }
}

_CompletionQualityPalette _paletteFor(
  BuildContext context,
  ActivityCompletionQuality quality,
) {
  final palette = context.appPalette;

  return switch (quality) {
    ActivityCompletionQuality.low => _CompletionQualityPalette(
      background: palette.warningFill,
      border: palette.warningBorder,
      foreground: palette.warningForeground,
      icon: Icons.sentiment_dissatisfied_rounded,
    ),
    ActivityCompletionQuality.medium => _CompletionQualityPalette(
      background: palette.infoFill,
      border: palette.infoBorder,
      foreground: palette.infoForeground,
      icon: Icons.sentiment_neutral_rounded,
    ),
    ActivityCompletionQuality.high => _CompletionQualityPalette(
      background: palette.successFill,
      border: palette.successBorder,
      foreground: palette.successForeground,
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
