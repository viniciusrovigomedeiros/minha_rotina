import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:minha_rotina/app.dart';

void main() {
  testWidgets('app inicia sem falhas', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MinhaRotinaApp()));
    expect(find.text('Hoje'), findsOneWidget);
  });
}
