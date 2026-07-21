import '../models/key_result_check_in.dart';
import '../services/local_storage_service.dart';

class KeyResultCheckInRepository {
  KeyResultCheckInRepository();

  Future<List<KeyResultCheckIn>> getAll() async {
    final values = LocalStorageService.keyResultCheckInsBox.values;
    return values
        .map(
          (entry) => KeyResultCheckIn.fromMap(Map<String, dynamic>.from(entry)),
        )
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> upsert(KeyResultCheckIn checkIn) async {
    await LocalStorageService.keyResultCheckInsBox.put(
      checkIn.id,
      checkIn.toMap(),
    );
  }

  Future<void> clear() async {
    await LocalStorageService.keyResultCheckInsBox.clear();
  }
}
