import '../models/key_result.dart';
import '../services/local_storage_service.dart';

class KeyResultRepository {
  KeyResultRepository();

  Future<List<KeyResult>> getAll() async {
    final values = LocalStorageService.keyResultsBox.values;
    return values
        .map((entry) => KeyResult.fromMap(Map<String, dynamic>.from(entry)))
        .toList()
      ..sort(_sortKeyResults);
  }

  Future<List<KeyResult>> findByObjectiveId(String objectiveId) async {
    final all = await getAll();
    return all.where((item) => item.objectiveId == objectiveId).toList();
  }

  Future<void> upsert(KeyResult keyResult) async {
    await LocalStorageService.keyResultsBox.put(
      keyResult.id,
      keyResult.toMap(),
    );
  }

  Future<void> delete(String id) async {
    await LocalStorageService.keyResultsBox.delete(id);
  }

  Future<void> deleteByObjectiveId(String objectiveId) async {
    final all = await getAll();
    for (final item in all.where((entry) => entry.objectiveId == objectiveId)) {
      await delete(item.id);
    }
  }

  Future<void> clear() async {
    await LocalStorageService.keyResultsBox.clear();
  }

  int _sortKeyResults(KeyResult a, KeyResult b) {
    final updatedCompare = b.updatedAt.compareTo(a.updatedAt);
    if (updatedCompare != 0) return updatedCompare;
    return a.title.compareTo(b.title);
  }
}
