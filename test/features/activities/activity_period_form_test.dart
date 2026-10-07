import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minha_rotina/data/models/activity.dart';
import 'package:minha_rotina/data/models/category.dart';
import 'package:minha_rotina/features/activities/screens/activity_form_screen.dart';
import 'package:minha_rotina/state/activities_controller.dart';
import 'package:minha_rotina/state/categories_controller.dart';
import 'package:minha_rotina/state/okr_workspace_controller.dart';

class _Activities extends ActivitiesController {
  Activity? saved;
  @override
  Future<List<Activity>> build() async => [];
  @override
  Future<void> updateActivity(Activity activity) async => saved = activity;
}

class _Categories extends CategoriesController {
  @override
  Future<List<Category>> build() async => Category.defaults();
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

Activity _initiative({DateTime? endDate}) => Activity(
  id: 'old',
  name: 'Antiga',
  categoryId: 'saude',
  weekdays: const [],
  recurrence: ActivityRecurrence.daily,
  isActive: false,
  remindersEnabled: false,
  createdAt: DateTime(2026, 7, 1),
  updatedAt: DateTime(2026, 7, 1),
  endDate: endDate,
);

Future<_Activities> _openForm(WidgetTester tester, Activity activity) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final controller = _Activities();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        activitiesControllerProvider.overrideWith(() => controller),
        categoriesControllerProvider.overrideWith(_Categories.new),
        okrWorkspaceControllerProvider.overrideWith(_Workspace.new),
      ],
      child: MaterialApp(
        locale: const Locale('pt', 'BR'),
        supportedLocales: const [Locale('pt', 'BR')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: Builder(
          builder:
              (context) => Scaffold(
                body: TextButton(
                  child: const Text('Editar'),
                  onPressed:
                      () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder:
                              (_) => ActivityFormScreen(activity: activity),
                        ),
                      ),
                ),
              ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Editar'));
  await tester.pumpAndSettle();
  return controller;
}

Future<void> _save(WidgetTester tester) async {
  await tester.scrollUntilVisible(
    find.text('Salvar iniciativa'),
    400,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Salvar iniciativa'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('editor salva trimestre de ano anterior em iniciativa antiga', (
    tester,
  ) async {
    final controller = await _openForm(tester, _initiative());
    expect(find.text('Sem data final'), findsOneWidget);
    expect(
      find
          .byType(ChoiceChip)
          .evaluate()
          .where(
            (e) =>
                ((e.widget as ChoiceChip).label is Text) &&
                (((e.widget as ChoiceChip).label as Text).data?.contains(
                      'trimestre',
                    ) ??
                    false),
          ),
      hasLength(4),
    );
    await tester.ensureVisible(find.byTooltip('Ano anterior'));
    await tester.tap(find.byTooltip('Ano anterior'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('2º trimestre · abr–jun'));
    await tester.tap(find.text('2º trimestre · abr–jun'));
    await tester.pumpAndSettle();
    expect(find.text('01/04/2025'), findsOneWidget);
    expect(find.text('30/06/2025'), findsOneWidget);
    await _save(tester);
    expect(controller.saved?.startDate, DateTime(2025, 4, 1));
    expect(controller.saved?.endDate, DateTime(2025, 6, 30));
    expect(controller.saved?.isActive, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('editor permite remover uma data final existente', (
    tester,
  ) async {
    final controller = await _openForm(
      tester,
      _initiative(endDate: DateTime(2026, 9, 30)),
    );
    await tester.ensureVisible(find.byTooltip('Remover data final'));
    await tester.tap(find.byTooltip('Remover data final'));
    await tester.pumpAndSettle();
    expect(find.text('Sem data final'), findsOneWidget);
    await _save(tester);
    expect(controller.saved, isNotNull);
    expect(controller.saved?.endDate, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('editor impede salvar fim anterior ao início', (tester) async {
    final controller = await _openForm(
      tester,
      _initiative(endDate: DateTime(2026, 6, 30)),
    );
    await _save(tester);
    expect(controller.saved, isNull);
    expect(
      find.text('A data final deve ser igual ou posterior à data inicial.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
