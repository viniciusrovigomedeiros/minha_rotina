import 'package:hive_flutter/hive_flutter.dart';

import '../models/category.dart';

class LocalStorageService {
  const LocalStorageService._();

  static const String activitiesBoxName = 'activities_box';
  static const String dailyLogsBoxName = 'daily_logs_box';
  static const String dailyPlansBoxName = 'daily_plans_box';
  static const String weeklyGoalsBoxName = 'weekly_goals_box';
  static const String dailyClosuresBoxName = 'daily_closures_box';
  static const String settingsBoxName = 'settings_box';
  static const String categoriesBoxName = 'categories_box';
  static const String metadataBoxName = 'metadata_box';
  static const String okrCyclesBoxName = 'okr_cycles_box';
  static const String okrObjectivesBoxName = 'okr_objectives_box';
  static const String keyResultsBoxName = 'key_results_box';
  static const String keyResultCheckInsBoxName = 'key_result_check_ins_box';

  static Future<void> init() async {
    await Hive.initFlutter();

    await Future.wait([
      Hive.openBox<Map>(activitiesBoxName),
      Hive.openBox<Map>(dailyLogsBoxName),
      Hive.openBox<Map>(dailyPlansBoxName),
      Hive.openBox<Map>(weeklyGoalsBoxName),
      Hive.openBox<Map>(dailyClosuresBoxName),
      Hive.openBox<Map>(settingsBoxName),
      Hive.openBox<Map>(categoriesBoxName),
      Hive.openBox<Map>(metadataBoxName),
      Hive.openBox<Map>(okrCyclesBoxName),
      Hive.openBox<Map>(okrObjectivesBoxName),
      Hive.openBox<Map>(keyResultsBoxName),
      Hive.openBox<Map>(keyResultCheckInsBoxName),
    ]);

    await ensureDefaultCategories();
  }

  static Future<void> ensureDefaultCategories() async {
    final categoriesBox = Hive.box<Map>(categoriesBoxName);
    if (categoriesBox.isNotEmpty) return;

    for (final category in Category.defaults()) {
      await categoriesBox.put(category.id, category.toMap());
    }
  }

  static Box<Map> get activitiesBox => Hive.box<Map>(activitiesBoxName);
  static Box<Map> get dailyLogsBox => Hive.box<Map>(dailyLogsBoxName);
  static Box<Map> get dailyPlansBox => Hive.box<Map>(dailyPlansBoxName);
  static Box<Map> get weeklyGoalsBox => Hive.box<Map>(weeklyGoalsBoxName);
  static Box<Map> get dailyClosuresBox => Hive.box<Map>(dailyClosuresBoxName);
  static Box<Map> get settingsBox => Hive.box<Map>(settingsBoxName);
  static Box<Map> get categoriesBox => Hive.box<Map>(categoriesBoxName);
  static Box<Map> get metadataBox => Hive.box<Map>(metadataBoxName);
  static Box<Map> get okrCyclesBox => Hive.box<Map>(okrCyclesBoxName);
  static Box<Map> get okrObjectivesBox => Hive.box<Map>(okrObjectivesBoxName);
  static Box<Map> get keyResultsBox => Hive.box<Map>(keyResultsBoxName);
  static Box<Map> get keyResultCheckInsBox =>
      Hive.box<Map>(keyResultCheckInsBoxName);
}
