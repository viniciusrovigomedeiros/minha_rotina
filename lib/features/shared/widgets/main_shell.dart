import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_glass_nav/liquid_glass_nav.dart';

import '../../../core/theme/app_theme.dart';
import '../../execution/screens/execution_screen.dart';
import '../../okr/screens/okr_objective_form_screen.dart';
import '../../okr/screens/okr_home_screen.dart';
import '../../okr/screens/okr_objectives_screen.dart';
import '../../../state/daily_goal_live_activity_sync.dart';
import '../../../state/okr_workspace_controller.dart';
import '../../../state/okr_widget_sync.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell>
    with WidgetsBindingObserver {
  int _currentIndex = 0;
  bool _isPresentingFirstOkrFlow = false;

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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dailyGoalLiveActivitySyncProvider).refresh();
      ref.read(okrWidgetSyncProvider).refresh();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(dailyGoalLiveActivitySyncProvider).refresh();
      ref.read(okrWidgetSyncProvider).refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final navWidth = screenWidth > 420 ? 320.0 : screenWidth * 0.78;
    final sideInset = (screenWidth - navWidth) / 2;
    const navReservedSpace = 60.0;
    final workspace = ref.watch(okrWorkspaceControllerProvider);
    _handleFirstOkrFlow(workspace.valueOrNull);

    if (workspace.valueOrNull?.allObjectives.isEmpty ?? false) {
      return const _FirstOkrGate();
    }

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
            useGradient: false,
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

  void _handleFirstOkrFlow(OkrWorkspaceState? workspace) {
    if (workspace == null || workspace.allObjectives.isNotEmpty) {
      _isPresentingFirstOkrFlow = false;
      return;
    }
    if (_isPresentingFirstOkrFlow) return;

    _isPresentingFirstOkrFlow = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final created = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => const OkrObjectiveFormScreen(),
          fullscreenDialog: true,
        ),
      );
      _isPresentingFirstOkrFlow = false;
      if (created == true && mounted) {
        setState(() => _currentIndex = 1);
      }
    });
  }
}

class _FirstOkrGate extends StatelessWidget {
  const _FirstOkrGate();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  Icons.track_changes_rounded,
                  size: 34,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Comece criando seu primeiro OKR',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Sem objetivo definido, o app perde o norte. Crie um objetivo com pelo menos um resultado-chave para liberar o restante da rotina.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.55,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    _GateStep(
                      title: '1. Defina o objetivo',
                      body:
                          'O resultado macro que precisa acontecer neste ciclo.',
                    ),
                    SizedBox(height: 12),
                    _GateStep(
                      title: '2. Adicione os KRs',
                      body:
                          'Métricas objetivas para saber se você está chegando lá.',
                    ),
                    SizedBox(height: 12),
                    _GateStep(
                      title: '3. Depois organize as iniciativas',
                      body: 'A execução diária passa a responder ao objetivo.',
                    ),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (_) => const OkrObjectiveFormScreen(),
                        fullscreenDialog: true,
                      ),
                    );
                  },
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Criar primeiro OKR'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GateStep extends StatelessWidget {
  const _GateStep({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(body, style: theme.textTheme.bodySmall),
      ],
    );
  }
}
