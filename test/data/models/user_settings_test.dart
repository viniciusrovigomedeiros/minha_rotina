import 'package:flutter_test/flutter_test.dart';
import 'package:minha_rotina/data/models/user_settings.dart';

void main() {
  test('configuracoes antigas sem modo salvo assumem tema escuro', () {
    final settings = UserSettings.fromMap({
      'userName': 'Vinicius',
      'notificationsEnabled': true,
      'activityReminderNotificationsEnabled': true,
      'goalReminderNotificationsEnabled': false,
      'dailyClosureReminderEnabled': true,
      'goalReminderMinutes': 600,
      'dailyClosureReminderMinutes': 1200,
      'themeKey': 'blue',
      'updatedAt': DateTime(2026, 8, 13).toIso8601String(),
    });

    expect(settings.themeModeKey, 'dark');
  });

  test('aceita o modo do sistema salvo', () {
    final settings = UserSettings.fromMap({
      'themeModeKey': 'system',
      'updatedAt': DateTime(2026, 8, 13).toIso8601String(),
    });

    expect(settings.themeModeKey, 'system');
  });

  test('serializacao preserva themeModeKey', () {
    final settings = UserSettings.initial().copyWith(themeModeKey: 'dark');

    expect(settings.toMap()['themeModeKey'], 'dark');
  });
}
