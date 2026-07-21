import 'package:flutter_test/flutter_test.dart';
import 'package:minha_rotina/core/theme/app_theme.dart';

void main() {
  test('tema padrão continua disponível', () {
    final option = AppTheme.optionByKey('blue');
    expect(option.key, 'blue');
  });
}
