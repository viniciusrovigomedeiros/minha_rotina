import '../models/okr_cycle.dart';
import '../services/local_storage_service.dart';

class OkrCycleRepository {
  OkrCycleRepository();

  Future<List<OkrCycle>> getAll() async {
    final values = LocalStorageService.okrCyclesBox.values;
    return values
        .map((entry) => OkrCycle.fromMap(Map<String, dynamic>.from(entry)))
        .toList()
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
  }

  Future<OkrCycle?> findById(String id) async {
    final raw = LocalStorageService.okrCyclesBox.get(id);
    if (raw == null) return null;
    return OkrCycle.fromMap(Map<String, dynamic>.from(raw));
  }

  Future<void> upsert(OkrCycle cycle) async {
    await LocalStorageService.okrCyclesBox.put(cycle.id, cycle.toMap());
  }

  Future<void> clear() async {
    await LocalStorageService.okrCyclesBox.clear();
  }
}
