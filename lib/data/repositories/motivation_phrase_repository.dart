import '../../core/utils/motivation_utils.dart';
import '../services/local_storage_service.dart';

class MotivationPhraseRepository {
  MotivationPhraseRepository();

  static const _storageKey = 'motivation_phrases';
  static const _itemsKey = 'items';

  Future<List<String>> getAll() async {
    final raw = LocalStorageService.metadataBox.get(_storageKey);
    final defaults = List<String>.from(MotivationUtils.defaultPhrases);

    if (raw == null) {
      await saveAll(defaults);
      return defaults;
    }

    final data = Map<String, dynamic>.from(raw);
    final items =
        (data[_itemsKey] as List<dynamic>? ?? const [])
            .map((item) => item.toString().trim())
            .where((item) => item.isNotEmpty)
            .toList();

    if (!_listsEqual(items, defaults)) {
      await saveAll(defaults);
      return defaults;
    }

    return defaults;
  }

  Future<void> saveAll(List<String> phrases) async {
    final defaults = List<String>.from(MotivationUtils.defaultPhrases);
    final allowed = defaults.toSet();
    final sanitized =
        phrases
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty)
            .where(allowed.contains)
            .toList();
    final result = sanitized.isEmpty ? defaults : sanitized;

    await LocalStorageService.metadataBox.put(_storageKey, {_itemsKey: result});
  }

  Future<void> clearAll() async {
    await saveAll(MotivationUtils.defaultPhrases);
  }

  Future<void> restoreDefaults() async {
    await saveAll(MotivationUtils.defaultPhrases);
  }

  bool _listsEqual(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
