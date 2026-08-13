import 'package:flutter/material.dart';
import 'package:liquid_glass_nav/liquid_glass_nav.dart';

import '../../../core/theme/app_theme.dart';
import '../../execution/screens/execution_screen.dart';
import '../../okr/screens/okr_home_screen.dart';
import '../../okr/screens/okr_objectives_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  static const _screens = [
    ExecutionScreen(),
    OkrHomeScreen(),
    OkrObjectivesScreen(),
  ];

  static const _items = [
    LiquidGlassNavItem(
      icon: Icons.checklist_outlined,
      activeIcon: Icons.checklist_rounded,
      label: 'Iniciativas',
    ),
    LiquidGlassNavItem(
      icon: Icons.track_changes_outlined,
      activeIcon: Icons.track_changes_rounded,
      label: 'OKRs',
    ),
    LiquidGlassNavItem(
      icon: Icons.flag_outlined,
      activeIcon: Icons.flag_rounded,
      label: 'Objetivos',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final navWidth = screenWidth > 420 ? 320.0 : screenWidth * 0.78;
    final sideInset = (screenWidth - navWidth) / 2;
    const navReservedSpace = 60.0;

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          Positioned.fill(
            bottom: navReservedSpace,
            child: IndexedStack(index: _currentIndex, children: _screens),
          ),
          LiquidGlassBottomNav(
            items: _items,
            currentIndex: _currentIndex,
            height: 66,
            borderRadius: 38,
            margin: EdgeInsets.fromLTRB(sideInset, 0, sideInset, 14),
            blurStrength: 16,
            backgroundColor: palette.glassBackground,
            borderColor: palette.glassBorder,
            borderWidth: 1,
            activeColor: Theme.of(context).colorScheme.primary,
            inactiveColor: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.52),
            iconSize: 22,
            fontSize: 10,
            enableShadow: false,
            useGradient: true,
            gradientColors: [
              palette.glassGradientStart,
              palette.glassGradientEnd,
            ],
            animationType: NavAnimationType.slideUp,
            onTap: (index) {
              if (_currentIndex == index) return;
              setState(() => _currentIndex = index);
            },
          ),
        ],
      ),
    );
  }
}
