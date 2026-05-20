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
    this.note,
  });

  final String id;
  final String activityId;
  final String dayKey;
  final ActivityStatus status;
  final ActivityCompletionQuality? completionQuality;
  final String? note;
  final DateTime updatedAt;

  DailyActivityLog copyWith({
    String? id,
    String? activityId,
    String? dayKey,
    ActivityStatus? status,
    ActivityCompletionQuality? completionQuality,
    String? note,
    DateTime? updatedAt,
    bool clearCompletionQuality = false,
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
      'note': note,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory DailyActivityLog.fromMap(Map<String, dynamic> map) {
    final status = ActivityStatusX.fromValue(map['status'] as String);
    final rawQuality = map['completionQuality'] as String?;

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
      note: map['note'] as String?,
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }
}
