import 'package:flutter/material.dart';

class TodayProgressCard extends StatelessWidget {
  const TodayProgressCard({
    super.key,
    required this.total,
    required this.completed,
    required this.skipped,
    required this.rate,
  });

  final int total;
  final int completed;
  final int skipped;
  final double rate;

  @override
  Widget build(BuildContext context) {
    final percent = (rate * 100).round();
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final foreground = isDark ? scheme.onSurface : scheme.onPrimary;
    final background = isDark ? scheme.surfaceContainerHigh : scheme.primary;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
        border:
            isDark
                ? Border.all(color: scheme.outline.withValues(alpha: 0.65))
                : null,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Progresso de hoje',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  '$percent%',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: 6,
                value: rate,
                backgroundColor:
                    isDark
                        ? scheme.onSurface.withValues(alpha: 0.10)
                        : foreground.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation<Color>(
                  isDark ? scheme.primary : foreground,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                _Tag(text: '$completed concluídas'),
                _Tag(text: '$skipped puladas'),
                _Tag(text: '$total no total'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final foreground = isDark ? scheme.onSurface : scheme.onPrimary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: foreground.withValues(alpha: isDark ? 0.06 : 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: foreground.withValues(alpha: isDark ? 0.12 : 0.25),
        ),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
