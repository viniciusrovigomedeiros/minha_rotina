import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minha_rotina/core/theme/app_theme.dart';

void main() {
  test('somente os modos claro e escuro sao resolvidos por chave', () {
    expect(AppTheme.themeModeByKey('light'), ThemeMode.light);
    expect(AppTheme.themeModeByKey('dark'), ThemeMode.dark);
    expect(AppTheme.themeModeByKey('system'), ThemeMode.system);
    expect(AppTheme.themeModeByKey('desconhecido'), ThemeMode.dark);
  });

  test('tema claro azul e escuro expõem a paleta semantica', () {
    final light = AppTheme.light();
    final dark = AppTheme.dark();

    expect(light.extension<AppThemePalette>(), isNotNull);
    expect(dark.extension<AppThemePalette>(), isNotNull);
    expect(light.colorScheme.primary, const Color(0xFF5A7DFA));
    expect(dark.colorScheme.primary, const Color(0xFF1DB954));
    expect(dark.scaffoldBackgroundColor, const Color(0xFF121212));
  });
}
