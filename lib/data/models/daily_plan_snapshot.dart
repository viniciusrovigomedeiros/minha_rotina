class DailyPlanSnapshot {
  const DailyPlanSnapshot({
    required this.dayKey,
    required this.activityIds,
    required this.updatedAt,
  });

  final String dayKey;
  final List<String> activityIds;
  final DateTime updatedAt;

  int get totalPlanned => activityIds.length;

  DailyPlanSnapshot copyWith({
    String? dayKey,
    List<String>? activityIds,
    DateTime? updatedAt,
  }) {
    return DailyPlanSnapshot(
      dayKey: dayKey ?? this.dayKey,
      activityIds: activityIds ?? this.activityIds,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'dayKey': dayKey,
      'activityIds': activityIds,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory DailyPlanSnapshot.fromMap(Map<String, dynamic> map) {
    return DailyPlanSnapshot(
      dayKey: map['dayKey'] as String,
      activityIds: List<String>.from(map['activityIds'] as List<dynamic>),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }
}
