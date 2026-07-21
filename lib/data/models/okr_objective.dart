enum OkrObjectiveStatus { planned, active, completed, archived }

extension OkrObjectiveStatusValues on OkrObjectiveStatus {
  String get value => name;

  String get label => switch (this) {
    OkrObjectiveStatus.planned => 'Planejado',
    OkrObjectiveStatus.active => 'Ativo',
    OkrObjectiveStatus.completed => 'Concluído',
    OkrObjectiveStatus.archived => 'Arquivado',
  };
}

class OkrObjectiveStatusX {
  const OkrObjectiveStatusX._();

  static OkrObjectiveStatus fromValue(String? value) {
    return OkrObjectiveStatus.values.firstWhere(
      (item) => item.value == value,
      orElse: () => OkrObjectiveStatus.planned,
    );
  }
}

class OkrObjective {
  const OkrObjective({
    required this.id,
    required this.title,
    required this.cycleId,
    required this.categoryId,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.legacyGoalId,
    this.checkInFrequencyDays,
    this.needsReview = false,
    this.isArchived = false,
  });

  final String id;
  final String title;
  final String? description;
  final String cycleId;
  final String categoryId;
  final DateTime startDate;
  final DateTime endDate;
  final OkrObjectiveStatus status;
  final int? checkInFrequencyDays;
  final bool needsReview;
  final bool isArchived;
  final String? legacyGoalId;
  final DateTime createdAt;
  final DateTime updatedAt;

  OkrObjective copyWith({
    String? id,
    String? title,
    String? description,
    String? cycleId,
    String? categoryId,
    DateTime? startDate,
    DateTime? endDate,
    OkrObjectiveStatus? status,
    int? checkInFrequencyDays,
    bool? needsReview,
    bool? isArchived,
    String? legacyGoalId,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool clearDescription = false,
    bool clearLegacyGoalId = false,
    bool clearCheckInFrequencyDays = false,
  }) {
    return OkrObjective(
      id: id ?? this.id,
      title: title ?? this.title,
      description: clearDescription ? null : description ?? this.description,
      cycleId: cycleId ?? this.cycleId,
      categoryId: categoryId ?? this.categoryId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      checkInFrequencyDays:
          clearCheckInFrequencyDays
              ? null
              : checkInFrequencyDays ?? this.checkInFrequencyDays,
      needsReview: needsReview ?? this.needsReview,
      isArchived: isArchived ?? this.isArchived,
      legacyGoalId:
          clearLegacyGoalId ? null : legacyGoalId ?? this.legacyGoalId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'cycleId': cycleId,
      'categoryId': categoryId,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'status': status.value,
      'checkInFrequencyDays': checkInFrequencyDays,
      'needsReview': needsReview,
      'isArchived': isArchived,
      'legacyGoalId': legacyGoalId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory OkrObjective.fromMap(Map<String, dynamic> map) {
    return OkrObjective(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      cycleId: map['cycleId'] as String,
      categoryId: map['categoryId'] as String,
      startDate: DateTime.parse(map['startDate'] as String),
      endDate: DateTime.parse(map['endDate'] as String),
      status: OkrObjectiveStatusX.fromValue(map['status'] as String?),
      checkInFrequencyDays: map['checkInFrequencyDays'] as int?,
      needsReview: (map['needsReview'] as bool?) ?? false,
      isArchived: (map['isArchived'] as bool?) ?? false,
      legacyGoalId: map['legacyGoalId'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }
}
