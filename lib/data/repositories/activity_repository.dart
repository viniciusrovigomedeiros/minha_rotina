import '../models/activity.dart';
import '../services/local_storage_service.dart';

class ActivityRepository {
  ActivityRepository();

  Future<List<Activity>> getAll() async {
    final values = LocalStorageService.activitiesBox.values;
    return values
        .map((entry) => Activity.fromMap(Map<String, dynamic>.from(entry)))
        .toList()
      ..sort(_compareBySchedule);
  }

  Future<Activity?> findById(String id) async {
    final raw = LocalStorageService.activitiesBox.get(id);
    if (raw == null) return null;
    return Activity.fromMap(Map<String, dynamic>.from(raw));
  }

  Future<void> upsert(Activity activity) async {
    await LocalStorageService.activitiesBox.put(activity.id, activity.toMap());
  }

  Future<void> delete(String id) async {
    await LocalStorageService.activitiesBox.delete(id);
  }

  Future<void> clear() async {
    await LocalStorageService.activitiesBox.clear();
  }

  int _compareBySchedule(Activity a, Activity b) {
    final aMinutes = a.startMinutes ?? 9999;
    final bMinutes = b.startMinutes ?? 9999;

    if (aMinutes != bMinutes) {
      return aMinutes.compareTo(bMinutes);
    }

    return a.name.compareTo(b.name);
  }
}
