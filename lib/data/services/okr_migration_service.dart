import '../models/okr_cycle.dart';
import '../models/okr_objective.dart';
import '../models/key_result.dart';
import '../models/activity.dart';
import 'local_storage_service.dart';

class OkrMigrationService {
  OkrMigrationService();

  static const String _freshStartKey = 'okr_fresh_start_v2';
  static const String _starterSeedKey = 'manual_seed_starter_objective_v1';
  static const String _legacyNavalhaShowcaseSeedKey =
      'manual_seed_navalha_launch_v1';

  Future<void> ensureInitialized() async {
    final metadata = LocalStorageService.metadataBox;
    final now = DateTime.now();

    if (!metadata.containsKey(_freshStartKey)) {
      await _clearAllStoredData();
      await LocalStorageService.ensureDefaultCategories();
      await metadata.put(_freshStartKey, {
        'completedAt': now.toIso8601String(),
        'mode': 'fresh_start',
      });
    }

    await _ensureSeedCycles(referenceDate: now);
    await _ensureStarterObjective(referenceDate: now);
  }

  static List<OkrCycle> buildQuarterlyCyclesForYear(
    int year, {
    DateTime? referenceDate,
  }) {
    final now = referenceDate ?? DateTime.now();
    final cycles = <OkrCycle>[];

    for (int quarter = 0; quarter < 4; quarter++) {
      final startMonth = (quarter * 3) + 1;
      final startDate = DateTime(year, startMonth, 1);
      final endDate = DateTime(year, startMonth + 3, 0);
      final status =
          now.isBefore(startDate)
              ? OkrCycleStatus.planned
              : now.isAfter(endDate)
              ? OkrCycleStatus.completed
              : OkrCycleStatus.active;

      cycles.add(
        OkrCycle(
          id: 'cycle_${year}_q${quarter + 1}',
          name: _quarterLabel(year, quarter + 1),
          startDate: startDate,
          endDate: endDate,
          status: status,
          createdAt: now,
          updatedAt: now,
        ),
      );
    }

    return cycles;
  }

  Future<void> _ensureSeedCycles({required DateTime referenceDate}) async {
    final cyclesBox = LocalStorageService.okrCyclesBox;
    if (cyclesBox.isNotEmpty) return;

    final cycles = buildQuarterlyCyclesForYear(
      referenceDate.year,
      referenceDate: referenceDate,
    );
    for (final cycle in cycles) {
      await cyclesBox.put(cycle.id, cycle.toMap());
    }
  }

  Future<void> _ensureStarterObjective({
    required DateTime referenceDate,
  }) async {
    final metadata = LocalStorageService.metadataBox;
    if (metadata.containsKey(_starterSeedKey) ||
        metadata.containsKey(_legacyNavalhaShowcaseSeedKey)) {
      return;
    }

    final cycleId = _currentQuarterCycleId(referenceDate);
    final cycleRaw = LocalStorageService.okrCyclesBox.get(cycleId);
    if (cycleRaw == null) return;
    final cycle = OkrCycle.fromMap(Map<String, dynamic>.from(cycleRaw));

    final objectiveId =
        'objective_starter_${referenceDate.year}_q${_quarterForDate(referenceDate)}';
    final kr1Id = '${objectiveId}_kr_1';
    final kr2Id = '${objectiveId}_kr_2';
    final kr3Id = '${objectiveId}_kr_3';
    final kr4Id = '${objectiveId}_kr_4';

    final objective = OkrObjective(
      id: objectiveId,
      title: 'Exemplo: organizar a rotina com mais clareza',
      description:
          'Este objetivo serve como exemplo para mostrar como os OKRs funcionam no app. '
          'Edite ou exclua quando quiser.\n\n'
          'Acompanhamento semanal:\n'
          '- O que avancou na semana\n'
          '- O que travou\n'
          '- Qual e a prioridade da proxima semana\n'
          '- O que vale ajustar na rotina',
      cycleId: cycleId,
      categoryId: 'pessoal',
      startDate: cycle.startDate,
      endDate: cycle.endDate,
      status: OkrObjectiveStatus.active,
      checkInFrequencyDays: 7,
      createdAt: referenceDate,
      updatedAt: referenceDate,
    );

    final keyResults = [
      KeyResult(
        id: kr1Id,
        objectiveId: objectiveId,
        title: 'Planejar a semana com clareza em 100% das semanas do ciclo.',
        measurementType: KeyResultMeasurementType.percentage,
        initialValue: 0,
        currentValue: 0,
        targetValue: 100,
        unit: '%',
        status: KeyResultStatus.active,
        createdAt: referenceDate,
        updatedAt: referenceDate,
      ),
      KeyResult(
        id: kr2Id,
        objectiveId: objectiveId,
        title:
            'Concluir pelo menos 12 atividades prioritarias definidas no planejamento.',
        measurementType: KeyResultMeasurementType.quantity,
        initialValue: 0,
        currentValue: 0,
        targetValue: 12,
        unit: 'atividades',
        status: KeyResultStatus.active,
        createdAt: referenceDate,
        updatedAt: referenceDate,
      ),
      KeyResult(
        id: kr3Id,
        objectiveId: objectiveId,
        title:
            'Fazer 8 revisoes semanais para ajustar prioridades e manter consistencia.',
        measurementType: KeyResultMeasurementType.quantity,
        initialValue: 0,
        currentValue: 0,
        targetValue: 8,
        unit: 'revisoes',
        status: KeyResultStatus.active,
        createdAt: referenceDate,
        updatedAt: referenceDate,
      ),
      KeyResult(
        id: kr4Id,
        objectiveId: objectiveId,
        title:
            'Manter 3 iniciativas recorrentes ativas que apoiem sua rotina principal.',
        measurementType: KeyResultMeasurementType.percentage,
        initialValue: 0,
        currentValue: 0,
        targetValue: 100,
        unit: '%',
        status: KeyResultStatus.active,
        createdAt: referenceDate,
        updatedAt: referenceDate,
      ),
    ];

    final initiatives = [
      Activity(
        id: '${objectiveId}_initiative_1',
        name: 'Planejar as prioridades da semana',
        description:
            'Definir o que realmente precisa acontecer nos proximos dias.',
        categoryId: 'pessoal',
        weekdays: const [],
        colorHex: 0xFFCF6F89,
        iconKey: 'calendar',
        objectiveId: objectiveId,
        keyResultId: kr1Id,
        recurrence: ActivityRecurrence.flexible,
        isActive: true,
        remindersEnabled: false,
        createdAt: referenceDate,
        updatedAt: referenceDate,
      ),
      Activity(
        id: '${objectiveId}_initiative_2',
        name: 'Executar as atividades mais importantes',
        description:
            'Avancar nas entregas que foram definidas como prioridade.',
        categoryId: 'pessoal',
        weekdays: const [],
        colorHex: 0xFFCF6F89,
        iconKey: 'checklist',
        objectiveId: objectiveId,
        keyResultId: kr2Id,
        recurrence: ActivityRecurrence.flexible,
        isActive: true,
        remindersEnabled: false,
        createdAt: referenceDate,
        updatedAt: referenceDate,
      ),
      Activity(
        id: '${objectiveId}_initiative_3',
        name: 'Fazer uma revisao semanal',
        description: 'Registrar progresso, bloqueios e proximos ajustes.',
        categoryId: 'pessoal',
        weekdays: const [],
        colorHex: 0xFFCF6F89,
        iconKey: 'target',
        objectiveId: objectiveId,
        keyResultId: kr3Id,
        recurrence: ActivityRecurrence.flexible,
        isActive: true,
        remindersEnabled: false,
        createdAt: referenceDate,
        updatedAt: referenceDate,
      ),
      Activity(
        id: '${objectiveId}_initiative_4',
        name: 'Bloquear tempo para a rotina principal',
        description: 'Reservar espacos fixos na agenda para o que importa.',
        categoryId: 'pessoal',
        weekdays: const [],
        colorHex: 0xFFCF6F89,
        iconKey: 'alarm',
        objectiveId: objectiveId,
        keyResultId: kr4Id,
        recurrence: ActivityRecurrence.flexible,
        isActive: true,
        remindersEnabled: false,
        createdAt: referenceDate,
        updatedAt: referenceDate,
      ),
      Activity(
        id: '${objectiveId}_initiative_5',
        name: 'Eliminar uma fonte recorrente de distracao',
        description: 'Remover ou simplificar algo que atrapalha sua execucao.',
        categoryId: 'pessoal',
        weekdays: const [],
        colorHex: 0xFFCF6F89,
        iconKey: 'clean',
        objectiveId: objectiveId,
        keyResultId: kr4Id,
        recurrence: ActivityRecurrence.flexible,
        isActive: true,
        remindersEnabled: false,
        createdAt: referenceDate,
        updatedAt: referenceDate,
      ),
    ];

    await LocalStorageService.okrObjectivesBox.put(
      objective.id,
      objective.toMap(),
    );
    for (final keyResult in keyResults) {
      await LocalStorageService.keyResultsBox.put(
        keyResult.id,
        keyResult.toMap(),
      );
    }
    for (final initiative in initiatives) {
      await LocalStorageService.activitiesBox.put(
        initiative.id,
        initiative.toMap(),
      );
    }

    await metadata.put(_starterSeedKey, {
      'createdAt': referenceDate.toIso8601String(),
      'objectiveId': objectiveId,
    });
  }

  Future<void> _clearAllStoredData() async {
    await LocalStorageService.activitiesBox.clear();
    await LocalStorageService.dailyLogsBox.clear();
    await LocalStorageService.dailyPlansBox.clear();
    await LocalStorageService.weeklyGoalsBox.clear();
    await LocalStorageService.dailyClosuresBox.clear();
    await LocalStorageService.settingsBox.clear();
    await LocalStorageService.categoriesBox.clear();
    await LocalStorageService.okrCyclesBox.clear();
    await LocalStorageService.okrObjectivesBox.clear();
    await LocalStorageService.keyResultsBox.clear();
    await LocalStorageService.keyResultCheckInsBox.clear();
    await LocalStorageService.metadataBox.clear();
  }

  static String _quarterLabel(int year, int quarter) {
    final names = switch (quarter) {
      1 => 'Janeiro a março',
      2 => 'Abril a junho',
      3 => 'Julho a setembro',
      _ => 'Outubro a dezembro',
    };
    return '$names de $year';
  }

  static String _currentQuarterCycleId(DateTime date) {
    final quarter = _quarterForDate(date);
    return 'cycle_${date.year}_q$quarter';
  }

  static int _quarterForDate(DateTime date) {
    return ((date.month - 1) ~/ 3) + 1;
  }
}
