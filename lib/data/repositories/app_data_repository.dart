import '../models/activity.dart';
import '../models/category.dart';
import '../models/daily_activity_log.dart';
import '../models/daily_closure_entry.dart';
import '../models/daily_plan_snapshot.dart';
import '../models/user_settings.dart';
import '../models/weekly_goal.dart';
import 'activity_repository.dart';
import 'category_repository.dart';
import 'daily_log_repository.dart';
import 'daily_closure_repository.dart';
import 'daily_plan_repository.dart';
import 'motivation_phrase_repository.dart';
import 'user_settings_repository.dart';
import 'weekly_goal_repository.dart';

class AppDataSnapshot {
  const AppDataSnapshot({
    required this.activities,
    required this.dailyLogs,
    required this.dailyClosures,
    required this.dailyPlans,
    required this.weeklyGoals,
    required this.categories,
    required this.userSettings,
    required this.motivationPhrases,
    required this.exportedAt,
  });

  final List<Activity> activities;
  final List<DailyActivityLog> dailyLogs;
  final List<DailyClosureEntry> dailyClosures;
  final List<DailyPlanSnapshot> dailyPlans;
  final List<WeeklyGoal> weeklyGoals;
  final List<Category> categories;
  final UserSettings userSettings;
  final List<String> motivationPhrases;
  final DateTime exportedAt;

  Map<String, dynamic> toMap() {
    return {
      'meta': {'version': 1, 'exportedAt': exportedAt.toIso8601String()},
      'activities': activities.map((e) => e.toMap()).toList(),
      'dailyLogs': dailyLogs.map((e) => e.toMap()).toList(),
      'dailyClosures': dailyClosures.map((e) => e.toMap()).toList(),
      'dailyPlans': dailyPlans.map((e) => e.toMap()).toList(),
      'weeklyGoals': weeklyGoals.map((e) => e.toMap()).toList(),
      'categories': categories.map((e) => e.toMap()).toList(),
      'userSettings': userSettings.toMap(),
      'motivationPhrases': motivationPhrases,
    };
  }
}

class AppDataRepository {
  AppDataRepository({
    required ActivityRepository activityRepository,
    required DailyLogRepository dailyLogRepository,
    required DailyClosureRepository dailyClosureRepository,
    required DailyPlanRepository dailyPlanRepository,
    required WeeklyGoalRepository weeklyGoalRepository,
    required CategoryRepository categoryRepository,
    required UserSettingsRepository userSettingsRepository,
    required MotivationPhraseRepository motivationPhraseRepository,
  }) : _activityRepository = activityRepository,
       _dailyLogRepository = dailyLogRepository,
       _dailyClosureRepository = dailyClosureRepository,
       _dailyPlanRepository = dailyPlanRepository,
       _weeklyGoalRepository = weeklyGoalRepository,
       _categoryRepository = categoryRepository,
       _userSettingsRepository = userSettingsRepository,
       _motivationPhraseRepository = motivationPhraseRepository;

  final ActivityRepository _activityRepository;
  final DailyLogRepository _dailyLogRepository;
  final DailyClosureRepository _dailyClosureRepository;
  final DailyPlanRepository _dailyPlanRepository;
  final WeeklyGoalRepository _weeklyGoalRepository;
  final CategoryRepository _categoryRepository;
  final UserSettingsRepository _userSettingsRepository;
  final MotivationPhraseRepository _motivationPhraseRepository;

  Future<AppDataSnapshot> snapshot() async {
    final activities = await _activityRepository.getAll();
    final dailyLogs = await _dailyLogRepository.getAll();
    final dailyClosures = await _dailyClosureRepository.getAll();
    final dailyPlans = await _dailyPlanRepository.getAll();
    final weeklyGoals = await _weeklyGoalRepository.getAll();
    final categories = await _categoryRepository.getAll();
    final userSettings = await _userSettingsRepository.get();
    final motivationPhrases = await _motivationPhraseRepository.getAll();

    return AppDataSnapshot(
      activities: activities,
      dailyLogs: dailyLogs,
      dailyClosures: dailyClosures,
      dailyPlans: dailyPlans,
      weeklyGoals: weeklyGoals,
      categories: categories,
      userSettings: userSettings,
      motivationPhrases: motivationPhrases,
      exportedAt: DateTime.now(),
    );
  }

  Future<void> replaceAll({
    required List<Activity> activities,
    required List<DailyActivityLog> dailyLogs,
    required List<DailyClosureEntry> dailyClosures,
    required List<DailyPlanSnapshot> dailyPlans,
    required List<WeeklyGoal> weeklyGoals,
    required List<Category> categories,
    required UserSettings userSettings,
    required List<String> motivationPhrases,
  }) async {
    await _activityRepository.clear();
    await _dailyLogRepository.clear();
    await _dailyClosureRepository.clear();
    await _dailyPlanRepository.clear();
    await _weeklyGoalRepository.clear();
    await _categoryRepository.clear();
    await _userSettingsRepository.clear();
    await _motivationPhraseRepository.clearAll();

    final safeCategories =
        categories.isEmpty ? Category.defaults() : categories;

    for (final category in safeCategories) {
      await _categoryRepository.upsert(category);
    }
    for (final activity in activities) {
      await _activityRepository.upsert(activity);
    }
    for (final log in dailyLogs) {
      await _dailyLogRepository.saveLog(log);
    }
    for (final closure in dailyClosures) {
      await _dailyClosureRepository.save(closure);
    }
    for (final plan in dailyPlans) {
      await _dailyPlanRepository.save(plan);
    }
    for (final goal in weeklyGoals) {
      await _weeklyGoalRepository.upsert(goal);
    }
    await _userSettingsRepository.save(userSettings);
    await _motivationPhraseRepository.saveAll(motivationPhrases);
  }

  Future<void> clearAll() async {
    await _activityRepository.clear();
    await _dailyLogRepository.clear();
    await _dailyClosureRepository.clear();
    await _dailyPlanRepository.clear();
    await _weeklyGoalRepository.clear();
    await _categoryRepository.clear();
    await _userSettingsRepository.clear();
    await _motivationPhraseRepository.clearAll();
  }
}
