import '../../core/utils/motivation_utils.dart';
import '../services/local_storage_service.dart';

class MotivationPhraseRepository {
  MotivationPhraseRepository();

  static const _storageKey = 'motivation_phrases';
  static const _itemsKey = 'items';

  Future<List<String>> getAll() async {
    final raw = LocalStorageService.metadataBox.get(_storageKey);

    if (raw == null) {
      final defaults = List<String>.from(MotivationUtils.defaultPhrases);
      await saveAll(defaults);
      return defaults;
    }

    final data = Map<String, dynamic>.from(raw);
    final items =
        (data[_itemsKey] as List<dynamic>? ?? const [])
            .map((item) => item.toString().trim())
            .where((item) => item.isNotEmpty)
            .toList();

    return items;
  }

  Future<void> saveAll(List<String> phrases) async {
    final sanitized =
        phrases
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty)
            .toList();

    await LocalStorageService.metadataBox.put(_storageKey, {
      _itemsKey: sanitized,
    });
  }

  Future<void> clearAll() async {
    await saveAll(const []);
  }

  Future<void> restoreDefaults() async {
    await saveAll(MotivationUtils.defaultPhrases);
  }
}
