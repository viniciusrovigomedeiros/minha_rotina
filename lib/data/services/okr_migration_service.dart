import '../models/okr_cycle.dart';
import '../models/okr_objective.dart';
import '../models/key_result.dart';
import '../models/activity.dart';
import 'local_storage_service.dart';

class OkrMigrationService {
  OkrMigrationService();

  static const String _freshStartKey = 'okr_fresh_start_v2';
  static const String _navalhaShowcaseSeedKey = 'manual_seed_navalha_launch_v1';

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
    await _ensureNavalhaShowcaseObjective(referenceDate: now);
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

  Future<void> _ensureNavalhaShowcaseObjective({
    required DateTime referenceDate,
  }) async {
    final metadata = LocalStorageService.metadataBox;
    if (metadata.containsKey(_navalhaShowcaseSeedKey)) return;

    const cycleId = 'cycle_2026_q3';
    final cycleRaw = LocalStorageService.okrCyclesBox.get(cycleId);
    if (cycleRaw == null) return;

    const objectiveId = 'objective_navalha_launch_q3_2026';
    const kr1Id = 'kr_navalha_launch_q3_2026_1';
    const kr2Id = 'kr_navalha_launch_q3_2026_2';
    const kr3Id = 'kr_navalha_launch_q3_2026_3';
    const kr4Id = 'kr_navalha_launch_q3_2026_4';

    final objective = OkrObjective(
      id: objectiveId,
      title: 'Finalizar e lançar o Navalha',
      description:
          'Deixar o Navalha pronto, validado e preparado para iniciar as vendas em novembro de 2026.\n\n'
          'Acompanhamento semanal:\n'
          '- Ajustes concluídos\n'
          '- Erros encontrados/corrigidos\n'
          '- Testes realizados\n'
          '- Feedbacks recebidos\n'
          '- Principal pendência',
      cycleId: cycleId,
      categoryId: 'navalha',
      startDate: DateTime(2026, 7, 1),
      endDate: DateTime(2026, 9, 30),
      status: OkrObjectiveStatus.active,
      checkInFrequencyDays: 7,
      createdAt: referenceDate,
      updatedAt: referenceDate,
    );

    final keyResults = [
      KeyResult(
        id: kr1Id,
        objectiveId: objectiveId,
        title:
            'Finalizar 100% dos ajustes essenciais e eliminar os principais erros do aplicativo.',
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
            'Testar o sistema com pelo menos 5 barbearias ou usuários e corrigir os principais problemas de entendimento e usabilidade.',
        measurementType: KeyResultMeasurementType.quantity,
        initialValue: 0,
        currentValue: 0,
        targetValue: 5,
        unit: 'testes',
        status: KeyResultStatus.active,
        createdAt: referenceDate,
        updatedAt: referenceDate,
      ),
      KeyResult(
        id: kr3Id,
        objectiveId: objectiveId,
        title:
            'Definir e implementar o método de pagamento definitivo, mantendo Mercado Pago ou migrando para Asaas.',
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
        id: kr4Id,
        objectiveId: objectiveId,
        title:
            'Ter a estrutura comercial pronta para começar as vendas: planos, preços, apresentação e processo de cadastro.',
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
        id: 'initiative_navalha_launch_q3_2026_1',
        name: 'Finalizar os ajustes pendentes',
        description: 'Concluir os ajustes essenciais do produto.',
        categoryId: 'navalha',
        weekdays: const [],
        colorHex: 0xFF259D9B,
        iconKey: 'bolt',
        objectiveId: objectiveId,
        keyResultId: kr1Id,
        recurrence: ActivityRecurrence.flexible,
        isActive: true,
        remindersEnabled: false,
        createdAt: referenceDate,
        updatedAt: referenceDate,
      ),
      Activity(
        id: 'initiative_navalha_launch_q3_2026_2',
        name: 'Fazer testes completos no app e na web',
        description: 'Executar testes completos nos fluxos principais.',
        categoryId: 'navalha',
        weekdays: const [],
        colorHex: 0xFF259D9B,
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
        id: 'initiative_navalha_launch_q3_2026_3',
        name: 'Coletar feedback de usuários reais',
        description: 'Validar entendimento e usabilidade com usuários.',
        categoryId: 'navalha',
        weekdays: const [],
        colorHex: 0xFF259D9B,
        iconKey: 'chat',
        objectiveId: objectiveId,
        keyResultId: kr2Id,
        recurrence: ActivityRecurrence.flexible,
        isActive: true,
        remindersEnabled: false,
        createdAt: referenceDate,
        updatedAt: referenceDate,
      ),
      Activity(
        id: 'initiative_navalha_launch_q3_2026_4',
        name: 'Decidir sobre Mercado Pago ou Asaas',
        description: 'Escolher e implementar o gateway definitivo.',
        categoryId: 'navalha',
        weekdays: const [],
        colorHex: 0xFF259D9B,
        iconKey: 'payments',
        objectiveId: objectiveId,
        keyResultId: kr3Id,
        recurrence: ActivityRecurrence.flexible,
        isActive: true,
        remindersEnabled: false,
        createdAt: referenceDate,
        updatedAt: referenceDate,
      ),
      Activity(
        id: 'initiative_navalha_launch_q3_2026_5',
        name: 'Preparar material e abordagem de vendas',
        description: 'Montar planos, preços e processo comercial.',
        categoryId: 'navalha',
        weekdays: const [],
        colorHex: 0xFF259D9B,
        iconKey: 'work',
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

    await metadata.put(_navalhaShowcaseSeedKey, {
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
}
