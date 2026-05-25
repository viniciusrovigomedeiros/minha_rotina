import 'activity_completion_quality.dart';
import 'activity_status.dart';

class DailyActivityLog {
  const DailyActivityLog({
    required this.id,
    required this.activityId,
    required this.dayKey,
    required this.status,
    required this.updatedAt,
    this.completionQuality,
    this.qualityScore,
    this.qualityChecklistCheckedCount,
    this.qualityChecklistTotalCount,
    this.qualityHighlight,
    this.qualityImprovement,
    this.note,
  });

  final String id;
  final String activityId;
  final String dayKey;
  final ActivityStatus status;
  final ActivityCompletionQuality? completionQuality;
  final int? qualityScore;
  final int? qualityChecklistCheckedCount;
  final int? qualityChecklistTotalCount;
  final String? qualityHighlight;
  final String? qualityImprovement;
  final String? note;
  final DateTime updatedAt;

  DailyActivityLog copyWith({
    String? id,
    String? activityId,
    String? dayKey,
    ActivityStatus? status,
    ActivityCompletionQuality? completionQuality,
    int? qualityScore,
    int? qualityChecklistCheckedCount,
    int? qualityChecklistTotalCount,
    String? qualityHighlight,
    String? qualityImprovement,
    String? note,
    DateTime? updatedAt,
    bool clearCompletionQuality = false,
    bool clearQualityScore = false,
    bool clearQualityChecklistCheckedCount = false,
    bool clearQualityChecklistTotalCount = false,
    bool clearQualityHighlight = false,
    bool clearQualityImprovement = false,
    bool clearNote = false,
  }) {
    return DailyActivityLog(
      id: id ?? this.id,
      activityId: activityId ?? this.activityId,
      dayKey: dayKey ?? this.dayKey,
      status: status ?? this.status,
      completionQuality:
          clearCompletionQuality
              ? null
              : completionQuality ?? this.completionQuality,
      qualityScore:
          clearQualityScore ? null : qualityScore ?? this.qualityScore,
      qualityChecklistCheckedCount:
          clearQualityChecklistCheckedCount
              ? null
              : qualityChecklistCheckedCount ??
                  this.qualityChecklistCheckedCount,
      qualityChecklistTotalCount:
          clearQualityChecklistTotalCount
              ? null
              : qualityChecklistTotalCount ?? this.qualityChecklistTotalCount,
      qualityHighlight:
          clearQualityHighlight
              ? null
              : qualityHighlight ?? this.qualityHighlight,
      qualityImprovement:
          clearQualityImprovement
              ? null
              : qualityImprovement ?? this.qualityImprovement,
      note: clearNote ? null : note ?? this.note,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'activityId': activityId,
      'dayKey': dayKey,
      'status': status.value,
      'completionQuality': completionQuality?.value,
      'qualityScore': qualityScore,
      'qualityChecklistCheckedCount': qualityChecklistCheckedCount,
      'qualityChecklistTotalCount': qualityChecklistTotalCount,
      'qualityHighlight': qualityHighlight,
      'qualityImprovement': qualityImprovement,
      'note': note,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory DailyActivityLog.fromMap(Map<String, dynamic> map) {
    final status = ActivityStatusX.fromValue(map['status'] as String);
    final rawQuality = map['completionQuality'] as String?;
    final rawQualityScore = map['qualityScore'];
    final qualityScore =
        rawQualityScore is int
            ? rawQualityScore
            : rawQualityScore is num
            ? rawQualityScore.toInt()
            : null;
    final rawChecklistCheckedCount = map['qualityChecklistCheckedCount'];
    final qualityChecklistCheckedCount =
        rawChecklistCheckedCount is int
            ? rawChecklistCheckedCount
            : rawChecklistCheckedCount is num
            ? rawChecklistCheckedCount.toInt()
            : null;
    final rawChecklistTotalCount = map['qualityChecklistTotalCount'];
    final qualityChecklistTotalCount =
        rawChecklistTotalCount is int
            ? rawChecklistTotalCount
            : rawChecklistTotalCount is num
            ? rawChecklistTotalCount.toInt()
            : null;

    return DailyActivityLog(
      id: map['id'] as String,
      activityId: map['activityId'] as String,
      dayKey: map['dayKey'] as String,
      status: status,
      completionQuality:
          rawQuality != null
              ? ActivityCompletionQualityX.fromValue(rawQuality)
              : status == ActivityStatus.completed
              ? ActivityCompletionQuality.medium
              : null,
      qualityScore: qualityScore,
      qualityChecklistCheckedCount: qualityChecklistCheckedCount,
      qualityChecklistTotalCount: qualityChecklistTotalCount,
      qualityHighlight: map['qualityHighlight'] as String?,
      qualityImprovement: map['qualityImprovement'] as String?,
      note: map['note'] as String?,
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }
}
