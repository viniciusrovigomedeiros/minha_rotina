import '../models/okr_cycle.dart';
import 'local_storage_service.dart';

class OkrMigrationService {
  OkrMigrationService();

  static const String _freshStartKey = 'okr_fresh_start_v2';

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
