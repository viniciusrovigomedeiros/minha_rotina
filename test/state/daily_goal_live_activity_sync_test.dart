import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:minha_rotina/data/models/activity.dart';
import 'package:minha_rotina/data/models/activity_status.dart';
import 'package:minha_rotina/features/today/models/today_state.dart';
import 'package:minha_rotina/state/daily_goal_live_activity_sync.dart';

TodayActivityItem item(
  String id, {
  ActivityStatus status = ActivityStatus.pending,
  bool due = false,
  bool counted = false,
  String? name,
}) => TodayActivityItem(
  activity: Activity(
    id: id,
    name: name ?? id,
    categoryId: 'routine',
    weekdays: const [],
    isActive: true,
    remindersEnabled: false,
    createdAt: DateTime(2026, 10, 1),
    updatedAt: DateTime(2026, 10, 1),
  ),
  status: status,
  completionQuality: null,
  qualityScore: null,
  isDueTodayInWeeklyGoals: due,
  countsTowardDailyProgress: counted,
);

void main() {
  setUpAll(() => initializeDateFormatting('pt_BR'));
  final date = DateTime(2026, 10, 7);

  test('separa três obrigatórias e duas opcionais das atividades feitas', () {
    final payload = buildDailyGoalLiveActivityPayload(
      TodayState(
        date: date,
        items: [
          item('Ler'),
          item('Estudar'),
          item('Meditar', status: ActivityStatus.completed),
        ],
        weeklyGoalItems: [
          item('Treinar', due: true, counted: true),
          item('Caminhar'),
          item('Organizar'),
          item('Escrever', status: ActivityStatus.completed, counted: true),
        ],
      ),
    );

    expect(payload.requiredPendingCount, 3);
    expect(payload.optionalPendingCount, 2);
    expect(payload.pendingCount, 5);
    expect(payload.completedCount, 2);
    expect(payload.requiredTotalCount, 4);
    expect(payload.requiredCompletedCount, 1);
    expect(payload.progress, 0.25);
    expect(payload.optionalPendingTitles, ['Caminhar', 'Organizar']);
    expect(payload.completedTitles, containsAll(['Meditar', 'Escrever']));
    expect(payload.toMap()['requiredPendingCount'], 3);
  });

  test('concluir uma opcional não a transforma em obrigatória', () {
    final payload = buildDailyGoalLiveActivityPayload(
      TodayState(
        date: date,
        items: [item('Ler', status: ActivityStatus.completed)],
        weeklyGoalItems: [
          item('Treinar', status: ActivityStatus.completed, counted: true),
          item('Caminhar'),
        ],
      ),
    );

    expect(payload.requiredTotalCount, 1);
    expect(payload.requiredCompletedCount, 1);
    expect(payload.completedCount, 2);
    expect(payload.progress, 1);
    expect(payload.statusText, 'Obrigatórias concluídas');
    expect(payload.optionalPendingCount, 1);
  });

  test(
    'só opcionais ainda geram um resumo válido sem progresso obrigatório',
    () {
      final payload = buildDailyGoalLiveActivityPayload(
        TodayState(
          date: date,
          items: const [],
          weeklyGoalItems: [item('Treinar')],
        ),
      );
      expect(payload.totalCount, 1);
      expect(payload.optionalPendingCount, 1);
      expect(payload.requiredTotalCount, 0);
      expect(payload.progress, 0);
      expect(payload.statusText, 'Sem obrigatórias hoje');
    },
  );

  test('não duplica atividades e não trata puladas como concluídas', () {
    final skipped = item('Treinar', status: ActivityStatus.skipped, due: true);
    final payload = buildDailyGoalLiveActivityPayload(
      TodayState(date: date, items: [skipped], weeklyGoalItems: [skipped]),
    );
    expect(payload.totalCount, 1);
    expect(payload.requiredTotalCount, 1);
    expect(payload.requiredSkippedCount, 1);
    expect(payload.completedCount, 0);
    expect(payload.progress, 0);
    expect(payload.statusText, contains('pulada'));
  });

  test('limita títulos e tamanho do conteúdo mesmo com muitas atividades', () {
    final longName = List.filled(200, '🏃').join();
    final payload = buildDailyGoalLiveActivityPayload(
      TodayState(
        date: date,
        items: List.generate(100, (i) => item('required-$i', name: longName)),
        weeklyGoalItems: [
          ...List.generate(100, (i) => item('optional-$i', name: longName)),
          ...List.generate(
            100,
            (i) => item(
              'done-$i',
              name: longName,
              status: ActivityStatus.completed,
            ),
          ),
        ],
      ),
    );
    expect(payload.requiredPendingCount, 100);
    expect(payload.completedCount, 100);
    expect(payload.requiredPendingTitles.length, 2);
    expect(payload.optionalPendingTitles.length, 2);
    expect(payload.completedTitles.length, 2);
    expect(payload.completedTitles.first.runes.length, lessThanOrEqualTo(40));
    expect(utf8.encode(jsonEncode(payload.toMap())).length, lessThan(3500));
  });
}
