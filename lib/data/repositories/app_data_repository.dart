import '../models/activity.dart';
import '../models/category.dart';
import '../models/daily_activity_log.dart';
import '../models/user_settings.dart';
import 'activity_repository.dart';
import 'category_repository.dart';
import 'daily_log_repository.dart';
import 'motivation_phrase_repository.dart';
import 'user_settings_repository.dart';

class AppDataSnapshot {
  const AppDataSnapshot({
    required this.activities,
    required this.dailyLogs,
    required this.categories,
    required this.userSettings,
    required this.motivationPhrases,
    required this.exportedAt,
  });

  final List<Activity> activities;
  final List<DailyActivityLog> dailyLogs;
  final List<Category> categories;
  final UserSettings userSettings;
  final List<String> motivationPhrases;
  final DateTime exportedAt;

  Map<String, dynamic> toMap() {
    return {
      'meta': {'version': 1, 'exportedAt': exportedAt.toIso8601String()},
      'activities': activities.map((e) => e.toMap()).toList(),
      'dailyLogs': dailyLogs.map((e) => e.toMap()).toList(),
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
    required CategoryRepository categoryRepository,
    required UserSettingsRepository userSettingsRepository,
    required MotivationPhraseRepository motivationPhraseRepository,
  }) : _activityRepository = activityRepository,
       _dailyLogRepository = dailyLogRepository,
       _categoryRepository = categoryRepository,
       _userSettingsRepository = userSettingsRepository,
       _motivationPhraseRepository = motivationPhraseRepository;

  final ActivityRepository _activityRepository;
  final DailyLogRepository _dailyLogRepository;
  final CategoryRepository _categoryRepository;
  final UserSettingsRepository _userSettingsRepository;
  final MotivationPhraseRepository _motivationPhraseRepository;

  Future<AppDataSnapshot> snapshot() async {
    final activities = await _activityRepository.getAll();
    final dailyLogs = await _dailyLogRepository.getAll();
    final categories = await _categoryRepository.getAll();
    final userSettings = await _userSettingsRepository.get();
    final motivationPhrases = await _motivationPhraseRepository.getAll();

    return AppDataSnapshot(
      activities: activities,
      dailyLogs: dailyLogs,
      categories: categories,
      userSettings: userSettings,
      motivationPhrases: motivationPhrases,
      exportedAt: DateTime.now(),
    );
  }

  Future<void> replaceAll({
    required List<Activity> activities,
    required List<DailyActivityLog> dailyLogs,
    required List<Category> categories,
    required UserSettings userSettings,
    required List<String> motivationPhrases,
  }) async {
    await _activityRepository.clear();
    await _dailyLogRepository.clear();
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
    await _userSettingsRepository.save(userSettings);
    await _motivationPhraseRepository.saveAll(motivationPhrases);
  }

  Future<void> clearAll() async {
    await _activityRepository.clear();
    await _dailyLogRepository.clear();
    await _categoryRepository.clear();
    await _userSettingsRepository.clear();
    await _motivationPhraseRepository.clearAll();
  }
}
