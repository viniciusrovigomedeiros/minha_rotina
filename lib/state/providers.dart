import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/activity_repository.dart';
import '../data/repositories/app_data_repository.dart';
import '../data/repositories/category_repository.dart';
import '../data/repositories/daily_closure_repository.dart';
import '../data/repositories/daily_log_repository.dart';
import '../data/repositories/daily_plan_repository.dart';
import '../data/repositories/motivation_phrase_repository.dart';
import '../data/repositories/user_settings_repository.dart';
import '../data/repositories/weekly_goal_repository.dart';
import '../data/services/json_backup_service.dart';
import '../data/services/notification_service.dart';

final activityRepositoryProvider = Provider<ActivityRepository>((ref) {
  return ActivityRepository();
});

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository();
});

final dailyLogRepositoryProvider = Provider<DailyLogRepository>((ref) {
  return DailyLogRepository();
});

final dailyClosureRepositoryProvider = Provider<DailyClosureRepository>((ref) {
  return DailyClosureRepository();
});

final dailyPlanRepositoryProvider = Provider<DailyPlanRepository>((ref) {
  return DailyPlanRepository();
});

final weeklyGoalRepositoryProvider = Provider<WeeklyGoalRepository>((ref) {
  return WeeklyGoalRepository();
});

final userSettingsRepositoryProvider = Provider<UserSettingsRepository>((ref) {
  return UserSettingsRepository();
});

final motivationPhraseRepositoryProvider = Provider<MotivationPhraseRepository>(
  (ref) {
    return MotivationPhraseRepository();
  },
);

final appDataRepositoryProvider = Provider<AppDataRepository>((ref) {
  return AppDataRepository(
    activityRepository: ref.read(activityRepositoryProvider),
    dailyLogRepository: ref.read(dailyLogRepositoryProvider),
    dailyClosureRepository: ref.read(dailyClosureRepositoryProvider),
    dailyPlanRepository: ref.read(dailyPlanRepositoryProvider),
    weeklyGoalRepository: ref.read(weeklyGoalRepositoryProvider),
    categoryRepository: ref.read(categoryRepositoryProvider),
    userSettingsRepository: ref.read(userSettingsRepositoryProvider),
    motivationPhraseRepository: ref.read(motivationPhraseRepositoryProvider),
  );
});

final jsonBackupServiceProvider = Provider<JsonBackupService>((ref) {
  return JsonBackupService(
    appDataRepository: ref.read(appDataRepositoryProvider),
  );
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});
