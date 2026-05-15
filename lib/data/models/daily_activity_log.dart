import 'activity_status.dart';

class DailyActivityLog {
  const DailyActivityLog({
    required this.id,
    required this.activityId,
    required this.dayKey,
    required this.status,
    required this.updatedAt,
    this.note,
  });

  final String id;
  final String activityId;
  final String dayKey;
  final ActivityStatus status;
  final String? note;
  final DateTime updatedAt;

  DailyActivityLog copyWith({
    String? id,
    String? activityId,
    String? dayKey,
    ActivityStatus? status,
    String? note,
    DateTime? updatedAt,
    bool clearNote = false,
  }) {
    return DailyActivityLog(
      id: id ?? this.id,
      activityId: activityId ?? this.activityId,
      dayKey: dayKey ?? this.dayKey,
      status: status ?? this.status,
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
      'note': note,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory DailyActivityLog.fromMap(Map<String, dynamic> map) {
    return DailyActivityLog(
      id: map['id'] as String,
      activityId: map['activityId'] as String,
      dayKey: map['dayKey'] as String,
      status: ActivityStatusX.fromValue(map['status'] as String),
      note: map['note'] as String?,
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }
}
