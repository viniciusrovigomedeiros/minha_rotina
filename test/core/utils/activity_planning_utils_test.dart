import 'package:flutter_test/flutter_test.dart';
import 'package:minha_rotina/core/utils/activity_planning_utils.dart';
import 'package:minha_rotina/data/models/activity.dart';
import 'package:minha_rotina/data/models/activity_status.dart';
import 'package:minha_rotina/data/models/daily_activity_log.dart';

void main() {
  group('ActivityPlanningUtils', () {
    test('nao inclui meta semanal flexivel como planejada no dia', () {
      final activity = Activity(
        id: 'gym',
        name: 'Academia',
        categoryId: 'health',
        weekdays: const [1, 3, 5],
        weeklyTargetCount: 4,
        isActive: true,
        remindersEnabled: false,
        createdAt: DateTime(2026, 8, 3),
        updatedAt: DateTime(2026, 8, 3),
        recurrence: ActivityRecurrence.weekly,
      );

      final planned = ActivityPlanningUtils.plannedActivityIdsForDay(
        date: DateTime(2026, 8, 3),
        activities: [activity],
        logs: const [],
        respectCurrentActiveFlag: true,
      );

      expect(planned, isEmpty);
    });

    test('inclui meta semanal no dia quando ela vira necessaria', () {
      final activity = Activity(
        id: 'gym',
        name: 'Academia',
        categoryId: 'health',
        weekdays: const [1, 3, 5],
        weeklyTargetCount: 4,
        isActive: true,
        remindersEnabled: false,
        createdAt: DateTime(2026, 8, 3),
        updatedAt: DateTime(2026, 8, 3),
        recurrence: ActivityRecurrence.weekly,
      );

      final planned = ActivityPlanningUtils.plannedActivityIdsForDay(
        date: DateTime(2026, 8, 6),
        activities: [activity],
        logs: const [],
        respectCurrentActiveFlag: true,
      );

      expect(planned, ['gym']);
    });

    test(
      'inclui meta semanal no dia quando foi concluida antes da urgencia',
      () {
        final activity = Activity(
          id: 'gym',
          name: 'Academia',
          categoryId: 'health',
          weekdays: const [1, 3, 5],
          weeklyTargetCount: 4,
          isActive: true,
          remindersEnabled: false,
          createdAt: DateTime(2026, 8, 3),
          updatedAt: DateTime(2026, 8, 3),
          recurrence: ActivityRecurrence.weekly,
        );

        final logs = [
          DailyActivityLog(
            id: 'log-1',
            activityId: 'gym',
            dayKey: '2026-08-04',
            status: ActivityStatus.completed,
            updatedAt: DateTime(2026, 8, 4, 8),
          ),
        ];

        final planned = ActivityPlanningUtils.plannedActivityIdsForDay(
          date: DateTime(2026, 8, 4),
          activities: [activity],
          logs: logs,
          respectCurrentActiveFlag: true,
        );

        expect(planned, ['gym']);
      },
    );

    test('mantem meta semanal disponivel ate bater a quantidade da semana', () {
      final activity = Activity(
        id: 'gym',
        name: 'Academia',
        categoryId: 'health',
        weekdays: const [1, 3, 5],
        weeklyTargetCount: 4,
        isActive: true,
        remindersEnabled: false,
        createdAt: DateTime(2026, 8, 3),
        updatedAt: DateTime(2026, 8, 3),
        recurrence: ActivityRecurrence.weekly,
      );

      final logs = [
        DailyActivityLog(
          id: 'log-1',
          activityId: 'gym',
          dayKey: '2026-08-03',
          status: ActivityStatus.completed,
          updatedAt: DateTime(2026, 8, 3, 8),
        ),
      ];

      final shouldShow = ActivityPlanningUtils.shouldShowFlexibleWeeklyActivity(
        activity: activity,
        date: DateTime(2026, 8, 4),
        logs: logs,
      );

      expect(shouldShow, isTrue);
    });

    test('inclui meta diaria na secao semanal com alvo da semana', () {
      final activity = Activity(
        id: 'water',
        name: 'Beber agua',
        categoryId: 'health',
        weekdays: const [],
        isActive: true,
        remindersEnabled: false,
        createdAt: DateTime(2026, 8, 3),
        updatedAt: DateTime(2026, 8, 3),
        recurrence: ActivityRecurrence.daily,
      );

      final shouldShow = ActivityPlanningUtils.shouldShowInWeeklyGoalsSection(
        activity: activity,
        date: DateTime(2026, 8, 12),
        logs: const [],
      );
      final target = ActivityPlanningUtils.weeklyTargetCountForActivity(
        activity: activity,
        date: DateTime(2026, 8, 12),
      );
      final label = ActivityPlanningUtils.deadlineLabelForWeeklyGoalActivity(
        activity: activity,
        date: DateTime(2026, 8, 12),
        logs: const [],
      );

      expect(shouldShow, isTrue);
      expect(target, 7);
      expect(label, 'Faça hoje');
    });

    test('inclui meta unica da semana com prazo ate o dia agendado', () {
      final activity = Activity(
        id: 'trip',
        name: 'Levar carro na revisao',
        categoryId: 'life',
        weekdays: const [],
        isActive: true,
        remindersEnabled: false,
        createdAt: DateTime(2026, 8, 1),
        updatedAt: DateTime(2026, 8, 1),
        recurrence: ActivityRecurrence.oneOff,
        scheduledDate: DateTime(2026, 8, 14),
      );

      final shouldShow = ActivityPlanningUtils.shouldShowInWeeklyGoalsSection(
        activity: activity,
        date: DateTime(2026, 8, 12),
        logs: const [],
      );
      final target = ActivityPlanningUtils.weeklyTargetCountForActivity(
        activity: activity,
        date: DateTime(2026, 8, 12),
      );
      final label = ActivityPlanningUtils.deadlineLabelForWeeklyGoalActivity(
        activity: activity,
        date: DateTime(2026, 8, 12),
        logs: const [],
      );

      expect(shouldShow, isTrue);
      expect(target, 1);
      expect(label, 'Faça até sex');
    });

    test('inclui meta mensal quando o dia cai na semana atual', () {
      final activity = Activity(
        id: 'rent',
        name: 'Pagar aluguel',
        categoryId: 'finance',
        weekdays: const [],
        isActive: true,
        remindersEnabled: false,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
        recurrence: ActivityRecurrence.monthly,
        scheduledDate: DateTime(2026, 1, 14),
      );

      final shouldShow = ActivityPlanningUtils.shouldShowInWeeklyGoalsSection(
        activity: activity,
        date: DateTime(2026, 8, 12),
        logs: const [],
      );
      final target = ActivityPlanningUtils.weeklyTargetCountForActivity(
        activity: activity,
        date: DateTime(2026, 8, 12),
      );
      final label = ActivityPlanningUtils.deadlineLabelForWeeklyGoalActivity(
        activity: activity,
        date: DateTime(2026, 8, 12),
        logs: const [],
      );

      expect(shouldShow, isTrue);
      expect(target, 1);
      expect(label, 'Faça até sex');
    });

    test('resolve data relevante da semana para ordenar metas futuras', () {
      final oneOff = Activity(
        id: 'trip',
        name: 'Levar carro na revisao',
        categoryId: 'life',
        weekdays: const [],
        isActive: true,
        remindersEnabled: false,
        createdAt: DateTime(2026, 8, 1),
        updatedAt: DateTime(2026, 8, 1),
        recurrence: ActivityRecurrence.oneOff,
        scheduledDate: DateTime(2026, 8, 14),
      );
      final monthly = Activity(
        id: 'rent',
        name: 'Pagar aluguel',
        categoryId: 'finance',
        weekdays: const [],
        isActive: true,
        remindersEnabled: false,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
        recurrence: ActivityRecurrence.monthly,
        scheduledDate: DateTime(2026, 1, 16),
      );

      final oneOffDate = ActivityPlanningUtils.relevantDateForWeeklyGoalsSection(
        activity: oneOff,
        date: DateTime(2026, 8, 12),
      );
      final monthlyDate =
          ActivityPlanningUtils.relevantDateForWeeklyGoalsSection(
            activity: monthly,
            date: DateTime(2026, 8, 12),
          );

      expect(oneOffDate, DateTime(2026, 8, 14));
      expect(monthlyDate, DateTime(2026, 8, 16));
      expect(oneOffDate!.isBefore(monthlyDate!), isTrue);
    });
  });

  test('converte recorrencia legada weeklyFixed em weekly', () {
    expect(
      ActivityRecurrenceX.fromValue('weeklyFixed'),
      ActivityRecurrence.weekly,
    );
  });
}
