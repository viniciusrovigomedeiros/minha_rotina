import '../models/category.dart';
import '../services/local_storage_service.dart';

class CategoryRepository {
  CategoryRepository();

  Future<List<Category>> getAll() async {
    final values = LocalStorageService.categoriesBox.values;
    return values
        .map((entry) => Category.fromMap(Map<String, dynamic>.from(entry)))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  Future<Category?> findById(String id) async {
    final raw = LocalStorageService.categoriesBox.get(id);
    if (raw == null) return null;
    return Category.fromMap(Map<String, dynamic>.from(raw));
  }

  Future<void> upsert(Category category) async {
    await LocalStorageService.categoriesBox.put(category.id, category.toMap());
  }

  Future<void> clear() async {
    await LocalStorageService.categoriesBox.clear();
  }
}
