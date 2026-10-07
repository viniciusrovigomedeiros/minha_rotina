import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minha_rotina/data/models/activity.dart';
import 'package:minha_rotina/features/activities/screens/activities_screen.dart';
import 'package:minha_rotina/state/activities_controller.dart';
import 'package:minha_rotina/state/okr_workspace_controller.dart';

class _Activities extends ActivitiesController {
  _Activities(this.items);
  List<Activity> items;
  @override
  Future<List<Activity>> build() async => items;

  void replace(List<Activity> updated) {
    items = updated;
    state = AsyncData(updated);
  }
}

class _Workspace extends OkrWorkspaceController {
  @override
  Future<OkrWorkspaceState> build() async => const OkrWorkspaceState(
    cycleProgresses: [],
    currentCycle: null,
    activeObjectives: [],
    staleKeyResults: [],
    weekInitiatives: [],
    independentActivities: [],
    nextCheckInDate: null,
  );
}

void main() {
  testWidgets(
    'separa períodos sem perder futuras e move edição retroativa para passadas',
    (tester) async {
      tester.view.physicalSize = const Size(430, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      Activity activity(String name, {DateTime? end, bool active = true}) =>
          Activity(
            id: name,
            name: name,
            categoryId: 'health',
            weekdays: const [],
            recurrence: ActivityRecurrence.daily,
            isActive: active,
            remindersEnabled: false,
            createdAt: today.subtract(const Duration(days: 90)),
            updatedAt: today,
            endDate: end,
          );
      final endingToday = activity('Termina hoje', end: today);
      final future = activity(
        'Próximo trimestre',
        end: today.add(const Duration(days: 120)),
      ).copyWith(startDate: today.add(const Duration(days: 90)));
      final past = activity('Trimestre encerrado', end: yesterday);
      final inactive = activity('Desativada', active: false);
      final oneOff = activity('Tarefa passada').copyWith(
        recurrence: ActivityRecurrence.oneOff,
        scheduledDate: yesterday,
      );
      final controller = _Activities([
        endingToday,
        future,
        past,
        inactive,
        oneOff,
      ]);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activitiesControllerProvider.overrideWith(() => controller),
            okrWorkspaceControllerProvider.overrideWith(_Workspace.new),
          ],
          child: const MaterialApp(home: ActivitiesScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Termina hoje'), findsOneWidget);
      expect(find.text('Próximo trimestre'), findsOneWidget);
      expect(find.text('Trimestre encerrado'), findsNothing);
      expect(find.text('Desativada'), findsNothing);
      expect(find.text('Tarefa passada'), findsNothing);

      await tester.tap(find.text('Passadas'));
      await tester.pumpAndSettle();
      expect(find.text('Trimestre encerrado'), findsOneWidget);
      expect(find.text('Desativada'), findsOneWidget);
      expect(find.text('Tarefa passada'), findsOneWidget);
      expect(find.text('Termina hoje'), findsNothing);
      expect(find.text('Próximo trimestre'), findsNothing);

      controller.replace([
        endingToday.copyWith(endDate: yesterday),
        past,
        inactive,
        oneOff,
      ]);
      await tester.pumpAndSettle();
      expect(find.text('Termina hoje'), findsOneWidget);
      await tester.tap(find.text('Atuais'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Nenhuma iniciativa atual.\nToque em + para cadastrar uma nova.',
        ),
        findsOneWidget,
      );
      expect(find.text('Termina hoje'), findsNothing);

      controller.replace([endingToday.copyWith(clearEndDate: true)]);
      await tester.pumpAndSettle();
      expect(find.text('Termina hoje'), findsOneWidget);
      await tester.tap(find.text('Passadas'));
      await tester.pumpAndSettle();
      expect(find.text('Nenhuma iniciativa passada.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
