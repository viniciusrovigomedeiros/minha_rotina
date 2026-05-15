import '../models/user_settings.dart';
import '../services/local_storage_service.dart';

class UserSettingsRepository {
  UserSettingsRepository();

  static const _settingsKey = 'user_settings';

  Future<UserSettings> get() async {
    final raw = LocalStorageService.settingsBox.get(_settingsKey);
    if (raw == null) {
      final settings = UserSettings.initial();
      await save(settings);
      return settings;
    }

    return UserSettings.fromMap(Map<String, dynamic>.from(raw));
  }

  Future<void> save(UserSettings settings) async {
    await LocalStorageService.settingsBox.put(_settingsKey, settings.toMap());
  }

  Future<void> clear() async {
    await LocalStorageService.settingsBox.clear();
  }
}
