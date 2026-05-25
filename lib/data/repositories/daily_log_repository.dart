import 'package:uuid/uuid.dart';

import '../models/activity_completion_quality.dart';
import '../models/activity_status.dart';
import '../models/daily_activity_log.dart';
import '../services/local_storage_service.dart';

class DailyLogRepository {
  DailyLogRepository({Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final Uuid _uuid;

  Future<List<DailyActivityLog>> getAll() async {
    final values = LocalStorageService.dailyLogsBox.values;
    return values
        .map(
          (entry) => DailyActivityLog.fromMap(Map<String, dynamic>.from(entry)),
        )
        .toList()
      ..sort((a, b) => b.dayKey.compareTo(a.dayKey));
  }

  Future<List<DailyActivityLog>> findByDayKey(String dayKey) async {
    final all = await getAll();
    return all.where((log) => log.dayKey == dayKey).toList();
  }

  Future<DailyActivityLog?> findByActivityAndDay({
    required String activityId,
    required String dayKey,
  }) async {
    final logs = await findByDayKey(dayKey);
    for (final log in logs) {
      if (log.activityId == activityId) return log;
    }
    return null;
  }

  Future<void> saveLog(DailyActivityLog log) async {
    await LocalStorageService.dailyLogsBox.put(log.id, log.toMap());
  }

  Future<DailyActivityLog> upsertStatus({
    required String activityId,
    required String dayKey,
    required ActivityStatus status,
    ActivityCompletionQuality? completionQuality,
    int? qualityScore,
    int? qualityChecklistCheckedCount,
    int? qualityChecklistTotalCount,
    String? qualityHighlight,
    String? qualityImprovement,
  }) async {
    final existing = await findByActivityAndDay(
      activityId: activityId,
      dayKey: dayKey,
    );

    final now = DateTime.now();
    final resolvedQuality =
        status == ActivityStatus.completed
            ? (completionQuality ??
                existing?.completionQuality ??
                ActivityCompletionQuality.medium)
            : null;
    final resolvedQualityScore =
        status == ActivityStatus.completed
            ? (qualityScore ??
                existing?.qualityScore ??
                _defaultScoreForQuality(
                  resolvedQuality ?? ActivityCompletionQuality.medium,
                ))
            : null;
    final resolvedChecklistCheckedCount =
        status == ActivityStatus.completed
            ? (qualityChecklistCheckedCount ??
                existing?.qualityChecklistCheckedCount ??
                0)
            : null;
    final resolvedChecklistTotalCount =
        status == ActivityStatus.completed
            ? (qualityChecklistTotalCount ??
                existing?.qualityChecklistTotalCount ??
                4)
            : null;
    final resolvedQualityHighlight =
        status == ActivityStatus.completed
            ? (qualityHighlight?.trim().isEmpty ?? true
                ? existing?.qualityHighlight
                : qualityHighlight?.trim())
            : null;
    final resolvedQualityImprovement =
        status == ActivityStatus.completed
            ? (qualityImprovement?.trim().isEmpty ?? true
                ? existing?.qualityImprovement
                : qualityImprovement?.trim())
            : null;

    if (existing != null) {
      final updated = existing.copyWith(
        status: status,
        completionQuality: resolvedQuality,
        qualityScore: resolvedQualityScore,
        qualityChecklistCheckedCount: resolvedChecklistCheckedCount,
        qualityChecklistTotalCount: resolvedChecklistTotalCount,
        qualityHighlight: resolvedQualityHighlight,
        qualityImprovement: resolvedQualityImprovement,
        clearCompletionQuality: status != ActivityStatus.completed,
        clearQualityScore: status != ActivityStatus.completed,
        clearQualityChecklistCheckedCount: status != ActivityStatus.completed,
        clearQualityChecklistTotalCount: status != ActivityStatus.completed,
        clearQualityHighlight: status != ActivityStatus.completed,
        clearQualityImprovement: status != ActivityStatus.completed,
        updatedAt: now,
      );
      await saveLog(updated);
      return updated;
    }

    final created = DailyActivityLog(
      id: _uuid.v4(),
      activityId: activityId,
      dayKey: dayKey,
      status: status,
      completionQuality: resolvedQuality,
      qualityScore: resolvedQualityScore,
      qualityChecklistCheckedCount: resolvedChecklistCheckedCount,
      qualityChecklistTotalCount: resolvedChecklistTotalCount,
      qualityHighlight: resolvedQualityHighlight,
      qualityImprovement: resolvedQualityImprovement,
      updatedAt: now,
    );
    await saveLog(created);
    return created;
  }

  Future<void> deleteByActivity(String activityId) async {
    final all = await getAll();
    final ids =
        all
            .where((log) => log.activityId == activityId)
            .map((log) => log.id)
            .toList();

    if (ids.isEmpty) return;
    await LocalStorageService.dailyLogsBox.deleteAll(ids);
  }

  Future<void> clear() async {
    await LocalStorageService.dailyLogsBox.clear();
  }

  int _defaultScoreForQuality(ActivityCompletionQuality quality) {
    switch (quality) {
      case ActivityCompletionQuality.low:
        return 4;
      case ActivityCompletionQuality.medium:
        return 7;
      case ActivityCompletionQuality.high:
        return 9;
    }
  }
}
