class DailyClosureEntry {
  const DailyClosureEntry({
    required this.id,
    required this.dayKey,
    required this.bestWork,
    required this.lostStandard,
    required this.improvementForTomorrow,
    required this.updatedAt,
  });

  final String id;
  final String dayKey;
  final String bestWork;
  final String lostStandard;
  final String improvementForTomorrow;
  final DateTime updatedAt;

  DailyClosureEntry copyWith({
    String? id,
    String? dayKey,
    String? bestWork,
    String? lostStandard,
    String? improvementForTomorrow,
    DateTime? updatedAt,
  }) {
    return DailyClosureEntry(
      id: id ?? this.id,
      dayKey: dayKey ?? this.dayKey,
      bestWork: bestWork ?? this.bestWork,
      lostStandard: lostStandard ?? this.lostStandard,
      improvementForTomorrow:
          improvementForTomorrow ?? this.improvementForTomorrow,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'dayKey': dayKey,
      'bestWork': bestWork,
      'lostStandard': lostStandard,
      'improvementForTomorrow': improvementForTomorrow,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory DailyClosureEntry.fromMap(Map<String, dynamic> map) {
    return DailyClosureEntry(
      id: map['id'] as String,
      dayKey: map['dayKey'] as String,
      bestWork: map['bestWork'] as String? ?? '',
      lostStandard: map['lostStandard'] as String? ?? '',
      improvementForTomorrow: map['improvementForTomorrow'] as String? ?? '',
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }
}
