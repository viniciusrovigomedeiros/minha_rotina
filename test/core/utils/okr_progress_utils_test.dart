import 'package:flutter_test/flutter_test.dart';
import 'package:minha_rotina/core/utils/okr_progress_utils.dart';
import 'package:minha_rotina/data/models/key_result.dart';

void main() {
  group('OkrProgressUtils.calculateKeyResultProgress', () {
    test('calcula progresso percentual e limita em 100%', () {
      final keyResult = KeyResult(
        id: 'kr-1',
        objectiveId: 'obj-1',
        title: 'Cobertura',
        measurementType: KeyResultMeasurementType.percentage,
        initialValue: 0,
        currentValue: 140,
        targetValue: 100,
        status: KeyResultStatus.active,
        createdAt: DateTime(2026, 7, 20),
        updatedAt: DateTime(2026, 7, 20),
      );

      expect(OkrProgressUtils.calculateKeyResultProgress(keyResult), 1);
    });

    test('calcula progresso numérico usando valor inicial e alvo', () {
      final keyResult = KeyResult(
        id: 'kr-2',
        objectiveId: 'obj-1',
        title: 'Conversas em inglês',
        measurementType: KeyResultMeasurementType.quantity,
        initialValue: 10,
        currentValue: 20,
        targetValue: 30,
        status: KeyResultStatus.active,
        createdAt: DateTime(2026, 7, 20),
        updatedAt: DateTime(2026, 7, 20),
      );

      expect(
        OkrProgressUtils.calculateKeyResultProgress(keyResult),
        closeTo(0.5, 0.0001),
      );
    });
  });

  group('OkrProgressUtils.calculateObjectiveProgress', () {
    test('usa média ponderada quando todos os resultados possuem peso', () {
      final keyResults = [
        KeyResultProgress(
          keyResult: KeyResult(
            id: 'kr-1',
            objectiveId: 'obj-1',
            title: 'KR 1',
            measurementType: KeyResultMeasurementType.numeric,
            initialValue: 0,
            currentValue: 0,
            targetValue: 10,
            weight: 2,
            status: KeyResultStatus.active,
            createdAt: DateTime(2026, 7, 20),
            updatedAt: DateTime(2026, 7, 20),
          ),
          progress: 0.25,
        ),
        KeyResultProgress(
          keyResult: KeyResult(
            id: 'kr-2',
            objectiveId: 'obj-1',
            title: 'KR 2',
            measurementType: KeyResultMeasurementType.numeric,
            initialValue: 0,
            currentValue: 0,
            targetValue: 10,
            weight: 1,
            status: KeyResultStatus.active,
            createdAt: DateTime(2026, 7, 20),
            updatedAt: DateTime(2026, 7, 20),
          ),
          progress: 1,
        ),
      ];

      expect(
        OkrProgressUtils.calculateObjectiveProgress(keyResults),
        closeTo(0.5, 0.0001),
      );
    });

    test('usa média simples quando há pesos ausentes', () {
      final keyResults = [
        KeyResultProgress(
          keyResult: KeyResult(
            id: 'kr-1',
            objectiveId: 'obj-1',
            title: 'KR 1',
            measurementType: KeyResultMeasurementType.numeric,
            initialValue: 0,
            currentValue: 0,
            targetValue: 10,
            status: KeyResultStatus.active,
            createdAt: DateTime(2026, 7, 20),
            updatedAt: DateTime(2026, 7, 20),
          ),
          progress: 0.4,
        ),
        KeyResultProgress(
          keyResult: KeyResult(
            id: 'kr-2',
            objectiveId: 'obj-1',
            title: 'KR 2',
            measurementType: KeyResultMeasurementType.numeric,
            initialValue: 0,
            currentValue: 0,
            targetValue: 10,
            weight: 4,
            status: KeyResultStatus.active,
            createdAt: DateTime(2026, 7, 20),
            updatedAt: DateTime(2026, 7, 20),
          ),
          progress: 0.8,
        ),
      ];

      expect(
        OkrProgressUtils.calculateObjectiveProgress(keyResults),
        closeTo(0.6, 0.0001),
      );
    });
  });
}
