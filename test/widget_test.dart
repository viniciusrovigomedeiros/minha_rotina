import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minha_rotina/core/theme/app_theme.dart';

void main() {
  test('tema claro padrao esta disponivel', () {
    expect(AppTheme.light().colorScheme.primary, const Color(0xFF5A7DFA));
  });
}
