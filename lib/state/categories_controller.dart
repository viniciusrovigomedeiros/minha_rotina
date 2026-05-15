import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../data/models/category.dart';
import 'providers.dart';

final categoriesControllerProvider =
    AsyncNotifierProvider<CategoriesController, List<Category>>(
      CategoriesController.new,
    );

class CategoriesController extends AsyncNotifier<List<Category>> {
  final Uuid _uuid = const Uuid();

  @override
  Future<List<Category>> build() async {
    return ref.read(categoryRepositoryProvider).getAll();
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      return ref.read(categoryRepositoryProvider).getAll();
    });
  }

  Future<Category?> createCategory({
    required String name,
    required int colorHex,
    required String iconKey,
  }) async {
    final normalizedName = name.trim();
    if (normalizedName.isEmpty) return null;

    final category = Category(
      id: 'custom_${_uuid.v4()}',
      name: normalizedName,
      colorHex: colorHex,
      iconKey: iconKey,
      isDefault: false,
    );

    await ref.read(categoryRepositoryProvider).upsert(category);
    await reload();
    return category;
  }
}
