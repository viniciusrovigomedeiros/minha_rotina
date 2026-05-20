import 'package:flutter/material.dart';

class MotivationCarouselCard extends StatefulWidget {
  const MotivationCarouselCard({
    super.key,
    required this.phrases,
    required this.initialIndex,
  });

  final List<String> phrases;
  final int initialIndex;

  @override
  State<MotivationCarouselCard> createState() => _MotivationCarouselCardState();
}

class _MotivationCarouselCardState extends State<MotivationCarouselCard> {
  late final PageController _pageController;
  late int _currentPage;

  @override
  void initState() {
    super.initState();
    _currentPage = _safePageIndex(
      requestedIndex: widget.initialIndex,
      phraseCount: widget.phrases.length,
    );
    _pageController = PageController(initialPage: _currentPage);
  }

  @override
  void didUpdateWidget(covariant MotivationCarouselCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.phrases.length != widget.phrases.length) {
      final safeIndex = _safePageIndex(
        requestedIndex: _currentPage,
        phraseCount: widget.phrases.length,
      );
      _currentPage = safeIndex;

      if (widget.phrases.isEmpty) {
        return;
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_pageController.hasClients) return;
        _pageController.jumpToPage(safeIndex);
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.phrases.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Sem frases motivacionais. Adicione nas configurações.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      );
    }

    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_darken(primary, 0.16), _lighten(primary, 0.08)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Frases do dia',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 76,
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemCount: widget.phrases.length,
                itemBuilder: (context, index) {
                  return Text(
                    '"${widget.phrases[index]}"',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'Deslize para o lado',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
                const Spacer(),
                ...List.generate(widget.phrases.length.clamp(1, 8), (index) {
                  final active =
                      index == (_currentPage % widget.phrases.length);
                  return Container(
                    margin: const EdgeInsets.only(left: 4),
                    width: active ? 14 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color:
                          active
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  );
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _lighten(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    final lightness = (hsl.lightness + amount).clamp(0, 1).toDouble();
    return hsl.withLightness(lightness).toColor();
  }

  Color _darken(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    final lightness = (hsl.lightness - amount).clamp(0, 1).toDouble();
    return hsl.withLightness(lightness).toColor();
  }

  int _safePageIndex({required int requestedIndex, required int phraseCount}) {
    if (phraseCount <= 0) {
      return 0;
    }
    return requestedIndex.clamp(0, phraseCount - 1);
  }
}
