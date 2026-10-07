import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:minha_rotina/core/utils/date_utils.dart';
import 'package:minha_rotina/data/models/activity.dart';
import 'package:minha_rotina/data/models/activity_status.dart';
import 'package:minha_rotina/data/models/daily_activity_log.dart';
import 'package:minha_rotina/data/repositories/activity_repository.dart';
import 'package:minha_rotina/data/repositories/daily_log_repository.dart';
import 'package:minha_rotina/data/repositories/daily_plan_repository.dart';
import 'package:minha_rotina/data/services/local_storage_service.dart';
import 'package:minha_rotina/features/today/services/today_state_loader.dart';
import 'package:minha_rotina/state/history_controller.dart';

void main() {
  late Directory directory;
  late ProviderContainer container;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('initiative_period_test');
    Hive.init(directory.path);
    for (final box in [
      LocalStorageService.activitiesBoxName,
      LocalStorageService.dailyLogsBoxName,
      LocalStorageService.dailyPlansBoxName,
      LocalStorageService.dailyClosuresBoxName,
      LocalStorageService.okrCyclesBoxName,
      LocalStorageService.okrObjectivesBoxName,
    ]) {
      await Hive.openBox<Map>(box);
    }
    container = ProviderContainer();
  });

  tearDown(() async {
    container.dispose();
    await Hive.close();
    await directory.delete(recursive: true);
  });

  test(
    'encerramento retroativo recalcula planos salvos e o calendário',
    () async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final start = today.subtract(const Duration(days: 10));
      final lastDay = today.subtract(const Duration(days: 5));
      final afterEnd = lastDay.add(const Duration(days: 1));
      final activity = Activity(
        id: 'old',
        name: 'Antiga',
        categoryId: 'health',
        weekdays: const [],
        recurrence: ActivityRecurrence.daily,
        isActive: false,
        remindersEnabled: false,
        createdAt: start,
        updatedAt: start,
      );
      final activities = ActivityRepository();
      final plans = DailyPlanRepository();
      final logs = DailyLogRepository();
      await activities.upsert(activity);
      final completed = DailyActivityLog(
        id: 'completed',
        activityId: activity.id,
        dayKey: DateUtilsX.toDayKey(lastDay),
        status: ActivityStatus.completed,
        updatedAt: lastDay,
      );
      final outsidePeriod = completed.copyWith(
        id: 'outside',
        dayKey: DateUtilsX.toDayKey(afterEnd),
        updatedAt: afterEnd,
      );
      await logs.saveLog(completed);
      await logs.saveLog(outsidePeriod);
      final allLogs = await logs.getAll();
      final before = await plans.snapshotForDay(
        date: afterEnd,
        activities: [activity],
        logs: allLogs,
      );
      expect(before.activityIds, ['old']);

      await activities.upsert(activity.copyWith(endDate: lastDay));
      final updatedActivities = await activities.getAll();
      final after = await plans.snapshotForDay(
        date: afterEnd,
        activities: updatedActivities,
        logs: allLogs,
      );
      expect(after.activityIds, isEmpty);
      expect((await plans.findByDayKey(after.dayKey))!.activityIds, isEmpty);
      final atEnd = await plans.snapshotForDay(
        date: lastDay,
        activities: updatedActivities,
        logs: allLogs,
      );
      expect(atEnd.activityIds, ['old']);

      final history = await container.read(historyControllerProvider.future);
      final within = history.singleWhere(
        (day) => day.dayKey == completed.dayKey,
      );
      final outside = history.singleWhere(
        (day) => day.dayKey == outsidePeriod.dayKey,
      );
      expect(within.totalPlanned, 1);
      expect(within.completedPlanned, 1);
      expect(outside.totalPlanned, 0);
      expect(outside.completed, 0);
      // Changing a period recalculates summaries without deleting saved records.
      expect(await logs.getAll(), hasLength(2));
    },
  );

  test(
    'visão diária e semanal respeita fim, início futuro e início retroativo',
    () async {
      final date = DateTime(2026, 9, 30);
      final base = Activity(
        id: 'daily',
        name: 'Diária',
        categoryId: 'health',
        weekdays: const [],
        recurrence: ActivityRecurrence.daily,
        isActive: true,
        remindersEnabled: false,
        createdAt: DateTime(2026, 10, 7),
        updatedAt: DateTime(2026, 10, 7),
        startDate: DateTime(2026, 7, 1),
        endDate: date,
      );
      final activities = ActivityRepository();
      await activities.upsert(base);
      await activities.upsert(
        base.copyWith(
          id: 'weekly',
          recurrence: ActivityRecurrence.weekly,
          weeklyTargetCount: 4,
        ),
      );
      final loader = container.read(todayStateLoaderProvider);
      final atEnd = await loader.load(date);
      expect(atEnd.items.map((item) => item.activity.id), ['daily']);
      expect(
        atEnd.weeklyGoalItems.map((item) => item.activity.id),
        containsAll(['daily', 'weekly']),
      );
      final afterEnd = await loader.load(DateTime(2026, 10, 1));
      expect(afterEnd.items, isEmpty);
      expect(afterEnd.weeklyGoalItems, isEmpty);
      final beforeStart = await loader.load(DateTime(2026, 6, 30));
      expect(beforeStart.items, isEmpty);
      expect(beforeStart.weeklyGoalItems, isEmpty);
    },
  );
}
