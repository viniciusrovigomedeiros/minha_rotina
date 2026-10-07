import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class DailyGoalLiveActivityPayload {
  const DailyGoalLiveActivityPayload({
    required this.title,
    required this.dateLabel,
    required this.summaryText,
    required this.statusText,
    required this.completedCount,
    required this.totalCount,
    required this.skippedCount,
    required this.pendingCount,
    required this.progress,
    required this.requiredTotalCount,
    required this.requiredCompletedCount,
    required this.requiredPendingCount,
    required this.requiredSkippedCount,
    required this.optionalPendingCount,
    required this.requiredPendingTitles,
    required this.optionalPendingTitles,
    required this.completedTitles,
  });

  final String title;
  final String dateLabel;
  final String summaryText;
  final String statusText;
  final int completedCount;
  final int totalCount;
  final int skippedCount;
  final int pendingCount;
  final double progress;
  final int requiredTotalCount;
  final int requiredCompletedCount;
  final int requiredPendingCount;
  final int requiredSkippedCount;
  final int optionalPendingCount;
  final List<String> requiredPendingTitles;
  final List<String> optionalPendingTitles;
  final List<String> completedTitles;

  Map<String, Object> toMap() {
    return {
      'title': title,
      'dateLabel': dateLabel,
      'summaryText': summaryText,
      'statusText': statusText,
      'completedCount': completedCount,
      'totalCount': totalCount,
      'skippedCount': skippedCount,
      'pendingCount': pendingCount,
      'progress': progress.clamp(0, 1),
      'requiredTotalCount': requiredTotalCount,
      'requiredCompletedCount': requiredCompletedCount,
      'requiredPendingCount': requiredPendingCount,
      'requiredSkippedCount': requiredSkippedCount,
      'optionalPendingCount': optionalPendingCount,
      'requiredPendingTitles': requiredPendingTitles,
      'optionalPendingTitles': optionalPendingTitles,
      'completedTitles': completedTitles,
    };
  }
}

class DailyGoalLiveActivityService {
  static const MethodChannel _channel = MethodChannel(
    'app.minharotina.mobile/live_activity',
  );

  Future<void> sync(DailyGoalLiveActivityPayload payload) async {
    if (!_isSupportedPlatform) return;
    await _channel.invokeMethod<void>('syncDailyGoal', payload.toMap());
  }

  Future<void> end() async {
    if (!_isSupportedPlatform) return;
    await _channel.invokeMethod<void>('endDailyGoal');
  }

  bool get _isSupportedPlatform =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
}
