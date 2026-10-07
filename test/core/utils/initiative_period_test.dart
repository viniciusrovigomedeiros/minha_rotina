import 'package:flutter_test/flutter_test.dart';
import 'package:minha_rotina/core/utils/activity_planning_utils.dart';
import 'package:minha_rotina/core/utils/quarter_date_range.dart';
import 'package:minha_rotina/core/utils/weekly_goal_progress_utils.dart';
import 'package:minha_rotina/data/models/activity.dart';
import 'package:minha_rotina/data/models/activity_status.dart';
import 'package:minha_rotina/data/models/daily_activity_log.dart';
import 'package:minha_rotina/data/models/weekly_goal.dart';

Activity initiative({
  ActivityRecurrence recurrence = ActivityRecurrence.daily,
}) => Activity(
  id: 'initiative',
  name: 'Iniciativa',
  categoryId: 'health',
  weekdays: const [1, 3, 5],
  weeklyTargetCount: 4,
  recurrence: recurrence,
  isActive: true,
  remindersEnabled: false,
  createdAt: DateTime(2026, 7, 1),
  updatedAt: DateTime(2026, 7, 1),
  startDate: DateTime(2026, 9, 28),
  endDate: DateTime(2026, 9, 30),
  scheduledDate: DateTime(2026, 9, 30),
);

DailyActivityLog completed(String day) => DailyActivityLog(
  id: day,
  activityId: 'initiative',
  dayKey: day,
  status: ActivityStatus.completed,
  updatedAt: DateTime.parse(day),
);

void main() {
  test('persiste o período, aceita dados legados e permite remover o fim', () {
    final activity = initiative();
    final restored = Activity.fromMap(activity.toMap());
    expect(restored.startDate, activity.startDate);
    expect(restored.endDate, activity.endDate);
    expect(restored.copyWith(name: 'Outro nome').endDate, activity.endDate);
    expect(restored.copyWith(clearEndDate: true).endDate, isNull);
    final legacy =
        activity.toMap()
          ..remove('startDate')
          ..remove('endDate');
    final restoredLegacy = Activity.fromMap(legacy);
    expect(restoredLegacy.effectiveStartDate, activity.createdAt);
    expect(restoredLegacy.endDate, isNull);
    expect(restoredLegacy.isWithinPeriod(DateTime(2027)), isTrue);
  });

  test('inclui todo o primeiro e último dia e aceita início retroativo', () {
    final activity = initiative().copyWith(createdAt: DateTime(2026, 10, 7));
    expect(activity.isWithinPeriod(DateTime(2026, 9, 27, 23, 59)), isFalse);
    expect(activity.isWithinPeriod(DateTime(2026, 9, 28)), isTrue);
    expect(activity.isWithinPeriod(DateTime(2026, 9, 30, 23, 59)), isTrue);
    expect(activity.isWithinPeriod(DateTime(2026, 10, 1)), isFalse);
  });

  for (final recurrence in ActivityRecurrence.values) {
    test(
      '${recurrence.name} não conta fora do período mesmo com registros',
      () {
        final activity = initiative(
          recurrence: recurrence,
        ).copyWith(isActive: false);
        for (final date in [DateTime(2026, 9, 27), DateTime(2026, 10, 1)]) {
          final logs = [completed('2026-10-01')];
          expect(
            ActivityPlanningUtils.plannedActivityIdsForDay(
              date: date,
              activities: [activity],
              logs: logs,
              respectCurrentActiveFlag: false,
            ),
            isEmpty,
          );
          expect(
            ActivityPlanningUtils.countsTowardDailyProgressInWeeklyGoals(
              activity: activity,
              date: date,
              logs: logs,
            ),
            isFalse,
          );
          expect(
            ActivityPlanningUtils.shouldShowInWeeklyGoalsSection(
              activity: activity.copyWith(isActive: true),
              date: date,
              logs: logs,
            ),
            isFalse,
          );
        }
      },
    );
  }

  test('preserva planejamento passado da iniciativa desativada até o fim', () {
    final activity = initiative().copyWith(isActive: false);
    expect(
      ActivityPlanningUtils.plannedActivityIdsForDay(
        date: DateTime(2026, 9, 30),
        activities: [activity],
        logs: const [],
        respectCurrentActiveFlag: false,
      ),
      ['initiative'],
    );
    expect(
      ActivityPlanningUtils.plannedActivityIdsForDay(
        date: DateTime(2026, 9, 30),
        activities: [activity],
        logs: const [],
        respectCurrentActiveFlag: true,
      ),
      isEmpty,
    );
  });

  test('limita meta e prazo semanal ao encerramento na quarta-feira', () {
    final activity = initiative(recurrence: ActivityRecurrence.weekly);
    expect(
      ActivityPlanningUtils.weeklyTargetCountForActivity(
        activity: activity,
        date: DateTime(2026, 9, 28),
      ),
      3,
    );
    expect(
      ActivityPlanningUtils.isFlexibleWeeklyActivityDueToday(
        activity: activity,
        date: DateTime(2026, 9, 28),
        logs: const [],
      ),
      isTrue,
    );
    final smallerTarget = activity.copyWith(weeklyTargetCount: 1);
    expect(
      ActivityPlanningUtils.deadlineLabelForFlexibleWeeklyActivity(
        activity: smallerTarget,
        date: DateTime(2026, 9, 28),
        logs: const [],
      ),
      'Faça até qua',
    );
    expect(
      ActivityPlanningUtils.weeklyTargetCountForActivity(
        activity: activity,
        date: DateTime(2026, 10, 5),
      ),
      0,
    );
  });

  test(
    'acumulado trimestral para de crescer depois do fim e ignora registros externos',
    () {
      final logs = [
        completed('2026-09-27'),
        completed('2026-09-28'),
        completed('2026-09-30'),
        completed('2026-10-01'),
      ];
      for (final recurrence in [
        ActivityRecurrence.daily,
        ActivityRecurrence.weekly,
        ActivityRecurrence.weeklyFixed,
        ActivityRecurrence.monthly,
        ActivityRecurrence.oneOff,
      ]) {
        final activity = initiative(recurrence: recurrence);
        final atEnd = ActivityPlanningUtils.progressInPeriodUntilDate(
          activity: activity,
          logs: logs,
          periodStart: DateTime(2026, 7, 1),
          periodEnd: DateTime(2026, 12, 31),
          date: DateTime(2026, 9, 30),
        );
        final afterEnd = ActivityPlanningUtils.progressInPeriodUntilDate(
          activity: activity,
          logs: logs,
          periodStart: DateTime(2026, 7, 1),
          periodEnd: DateTime(2026, 12, 31),
          date: DateTime(2026, 12, 31),
        );
        expect(afterEnd.completedCount, 2);
        expect(afterEnd.plannedCount, atEnd.plannedCount);
        expect(atEnd.plannedCount, switch (recurrence) {
          ActivityRecurrence.daily || ActivityRecurrence.weekly => 3,
          ActivityRecurrence.weeklyFixed => 2,
          _ => 1,
        });
      }
    },
  );

  test('metas automáticas contam somente conclusões dentro do período', () {
    final goal = WeeklyGoal(
      id: 'goal',
      name: 'Meta',
      scope: WeeklyGoalScope.overall,
      type: WeeklyGoalType.completions,
      targetValue: 10,
      currentValue: 0,
      isActive: true,
      trackingMode: GoalTrackingMode.automatic,
      period: GoalPeriod.custom,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
      startDate: DateTime(2026, 9, 1),
      endDate: DateTime(2026, 10, 31),
    );
    final progress =
        WeeklyGoalProgressUtils.buildProgresses(
          goals: [goal],
          activities: [initiative()],
          dailyLogs: [
            completed('2026-09-27'),
            completed('2026-09-28'),
            completed('2026-09-30'),
            completed('2026-10-01'),
          ],
        ).single;
    expect(progress.currentValue, 2);
  });

  test('quatro trimestres cobrem o ano inteiro inclusive anos bissextos', () {
    for (final year in [2024, 2025, 2026, 2027]) {
      final ranges = QuarterDateRange.forYear(year);
      expect(ranges, hasLength(4));
      expect(ranges.first.start, DateTime(year, 1, 1));
      expect(ranges.last.end, DateTime(year, 12, 31));
      for (var i = 0; i < 3; i++) {
        expect(ranges[i].end.add(const Duration(days: 1)), ranges[i + 1].start);
      }
      expect(QuarterDateRange.containing(DateTime(year, 3, 31)).quarter, 1);
      expect(QuarterDateRange.containing(DateTime(year, 4, 1)).quarter, 2);
      expect(
        QuarterDateRange.containing(DateTime(year, 10, 7)).end,
        DateTime(year, 12, 31),
      );
    }
  });
}
