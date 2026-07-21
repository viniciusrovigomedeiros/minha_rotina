import 'package:flutter_test/flutter_test.dart';
import 'package:minha_rotina/data/services/okr_migration_service.dart';

void main() {
  group('OkrMigrationService.buildQuarterlyCyclesForYear', () {
    test(
      'gera ciclos trimestrais com status coerente em Monday, July 20, 2026',
      () {
        final cycles = OkrMigrationService.buildQuarterlyCyclesForYear(
          2026,
          referenceDate: DateTime(2026, 7, 20),
        );

        expect(cycles, hasLength(4));
        expect(cycles[0].name, 'Janeiro a março de 2026');
        expect(cycles[1].name, 'Abril a junho de 2026');
        expect(cycles[2].name, 'Julho a setembro de 2026');
        expect(cycles[3].name, 'Outubro a dezembro de 2026');
        expect(cycles[0].status.name, 'completed');
        expect(cycles[1].status.name, 'completed');
        expect(cycles[2].status.name, 'active');
        expect(cycles[3].status.name, 'planned');
      },
    );
  });
}
