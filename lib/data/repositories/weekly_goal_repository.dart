import '../models/weekly_goal.dart';
import '../services/local_storage_service.dart';

class WeeklyGoalRepository {
  WeeklyGoalRepository();

  Future<List<WeeklyGoal>> getAll() async {
    final values = LocalStorageService.weeklyGoalsBox.values;
    return values
        .map((entry) => WeeklyGoal.fromMap(Map<String, dynamic>.from(entry)))
        .toList()
      ..sort(_sortGoals);
  }

  Future<void> upsert(WeeklyGoal goal) async {
    await LocalStorageService.weeklyGoalsBox.put(goal.id, goal.toMap());
  }

  Future<void> delete(String id) async {
    await LocalStorageService.weeklyGoalsBox.delete(id);
  }

  Future<void> clear() async {
    await LocalStorageService.weeklyGoalsBox.clear();
  }

  int _sortGoals(WeeklyGoal a, WeeklyGoal b) {
    if (a.isActive != b.isActive) return a.isActive ? -1 : 1;
    final updatedCompare = b.updatedAt.compareTo(a.updatedAt);
    if (updatedCompare != 0) return updatedCompare;
    return a.name.compareTo(b.name);
  }
}
