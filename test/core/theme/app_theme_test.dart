import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minha_rotina/core/theme/app_theme.dart';

void main() {
  test('tema padrao continua disponivel', () {
    final option = AppTheme.optionByKey('blue');
    expect(option.key, 'blue');
  });

  test('modo escuro e tema do sistema sao resolvidos por chave', () {
    expect(AppTheme.themeModeByKey('dark'), ThemeMode.dark);
    expect(AppTheme.themeModeByKey('system'), ThemeMode.system);
    expect(AppTheme.themeModeByKey('desconhecido'), ThemeMode.system);
  });

  test('temas claro e escuro expõem a paleta semantica', () {
    final light = AppTheme.light(themeKey: 'blue');
    final dark = AppTheme.dark(themeKey: 'blue');

    expect(light.extension<AppThemePalette>(), isNotNull);
    expect(dark.extension<AppThemePalette>(), isNotNull);
  });
}
