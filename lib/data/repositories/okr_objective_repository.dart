import '../models/okr_objective.dart';
import '../services/local_storage_service.dart';

class OkrObjectiveRepository {
  OkrObjectiveRepository();

  Future<List<OkrObjective>> getAll() async {
    final values = LocalStorageService.okrObjectivesBox.values;
    return values
        .map((entry) => OkrObjective.fromMap(Map<String, dynamic>.from(entry)))
        .toList()
      ..sort(_sortObjectives);
  }

  Future<OkrObjective?> findById(String id) async {
    final raw = LocalStorageService.okrObjectivesBox.get(id);
    if (raw == null) return null;
    return OkrObjective.fromMap(Map<String, dynamic>.from(raw));
  }

  Future<void> upsert(OkrObjective objective) async {
    await LocalStorageService.okrObjectivesBox.put(
      objective.id,
      objective.toMap(),
    );
  }

  Future<void> delete(String id) async {
    await LocalStorageService.okrObjectivesBox.delete(id);
  }

  Future<void> clear() async {
    await LocalStorageService.okrObjectivesBox.clear();
  }

  int _sortObjectives(OkrObjective a, OkrObjective b) {
    if (a.isArchived != b.isArchived) return a.isArchived ? 1 : -1;
    final statusCompare = a.status.index.compareTo(b.status.index);
    if (statusCompare != 0) return statusCompare;
    final endCompare = a.endDate.compareTo(b.endDate);
    if (endCompare != 0) return endCompare;
    return a.title.compareTo(b.title);
  }
}
