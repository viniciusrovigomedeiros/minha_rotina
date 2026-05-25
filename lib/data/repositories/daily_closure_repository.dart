import 'package:uuid/uuid.dart';

import '../models/daily_closure_entry.dart';
import '../services/local_storage_service.dart';

class DailyClosureRepository {
  DailyClosureRepository({Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final Uuid _uuid;

  Future<List<DailyClosureEntry>> getAll() async {
    final values = LocalStorageService.dailyClosuresBox.values;
    return values
        .map(
          (entry) =>
              DailyClosureEntry.fromMap(Map<String, dynamic>.from(entry)),
        )
        .toList()
      ..sort((a, b) => b.dayKey.compareTo(a.dayKey));
  }

  Future<DailyClosureEntry?> findByDayKey(String dayKey) async {
    final all = await getAll();
    for (final item in all) {
      if (item.dayKey == dayKey) return item;
    }
    return null;
  }

  Future<void> save(DailyClosureEntry entry) async {
    await LocalStorageService.dailyClosuresBox.put(entry.id, entry.toMap());
  }

  Future<DailyClosureEntry> upsertForDay({
    required String dayKey,
    required String bestWork,
    required String lostStandard,
    required String improvementForTomorrow,
  }) async {
    final now = DateTime.now();
    final existing = await findByDayKey(dayKey);

    if (existing != null) {
      final updated = existing.copyWith(
        bestWork: bestWork,
        lostStandard: lostStandard,
        improvementForTomorrow: improvementForTomorrow,
        updatedAt: now,
      );
      await save(updated);
      return updated;
    }

    final created = DailyClosureEntry(
      id: _uuid.v4(),
      dayKey: dayKey,
      bestWork: bestWork,
      lostStandard: lostStandard,
      improvementForTomorrow: improvementForTomorrow,
      updatedAt: now,
    );

    await save(created);
    return created;
  }

  Future<void> clear() async {
    await LocalStorageService.dailyClosuresBox.clear();
  }
}
