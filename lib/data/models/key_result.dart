enum KeyResultMeasurementType {
  percentage,
  numeric,
  currency,
  quantity,
  boolean,
}

extension KeyResultMeasurementTypeValues on KeyResultMeasurementType {
  String get value => name;

  String get label => switch (this) {
    KeyResultMeasurementType.percentage => 'Percentual',
    KeyResultMeasurementType.numeric => 'Número atual até desejado',
    KeyResultMeasurementType.currency => 'Valor financeiro',
    KeyResultMeasurementType.quantity => 'Quantidade',
    KeyResultMeasurementType.boolean => 'Sim ou não',
  };
}

class KeyResultMeasurementTypeX {
  const KeyResultMeasurementTypeX._();

  static KeyResultMeasurementType fromValue(String? value) {
    return KeyResultMeasurementType.values.firstWhere(
      (item) => item.value == value,
      orElse: () => KeyResultMeasurementType.numeric,
    );
  }
}

enum KeyResultStatus { planned, active, completed, atRisk }

extension KeyResultStatusValues on KeyResultStatus {
  String get value => name;

  String get label => switch (this) {
    KeyResultStatus.planned => 'Planejado',
    KeyResultStatus.active => 'Ativo',
    KeyResultStatus.completed => 'Concluído',
    KeyResultStatus.atRisk => 'Em risco',
  };
}

class KeyResultStatusX {
  const KeyResultStatusX._();

  static KeyResultStatus fromValue(String? value) {
    return KeyResultStatus.values.firstWhere(
      (item) => item.value == value,
      orElse: () => KeyResultStatus.planned,
    );
  }
}

class KeyResult {
  const KeyResult({
    required this.id,
    required this.objectiveId,
    required this.title,
    required this.measurementType,
    required this.initialValue,
    required this.currentValue,
    required this.targetValue,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.unit,
    this.weight,
    this.lastCheckInAt,
    this.legacyGoalId,
  });

  final String id;
  final String objectiveId;
  final String title;
  final KeyResultMeasurementType measurementType;
  final double initialValue;
  final double currentValue;
  final double targetValue;
  final String? unit;
  final double? weight;
  final KeyResultStatus status;
  final DateTime? lastCheckInAt;
  final String? legacyGoalId;
  final DateTime createdAt;
  final DateTime updatedAt;

  KeyResult copyWith({
    String? id,
    String? objectiveId,
    String? title,
    KeyResultMeasurementType? measurementType,
    double? initialValue,
    double? currentValue,
    double? targetValue,
    String? unit,
    double? weight,
    KeyResultStatus? status,
    DateTime? lastCheckInAt,
    String? legacyGoalId,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool clearUnit = false,
    bool clearWeight = false,
    bool clearLastCheckInAt = false,
    bool clearLegacyGoalId = false,
  }) {
    return KeyResult(
      id: id ?? this.id,
      objectiveId: objectiveId ?? this.objectiveId,
      title: title ?? this.title,
      measurementType: measurementType ?? this.measurementType,
      initialValue: initialValue ?? this.initialValue,
      currentValue: currentValue ?? this.currentValue,
      targetValue: targetValue ?? this.targetValue,
      unit: clearUnit ? null : unit ?? this.unit,
      weight: clearWeight ? null : weight ?? this.weight,
      status: status ?? this.status,
      lastCheckInAt:
          clearLastCheckInAt ? null : lastCheckInAt ?? this.lastCheckInAt,
      legacyGoalId:
          clearLegacyGoalId ? null : legacyGoalId ?? this.legacyGoalId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'objectiveId': objectiveId,
      'title': title,
      'measurementType': measurementType.value,
      'initialValue': initialValue,
      'currentValue': currentValue,
      'targetValue': targetValue,
      'unit': unit,
      'weight': weight,
      'status': status.value,
      'lastCheckInAt': lastCheckInAt?.toIso8601String(),
      'legacyGoalId': legacyGoalId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory KeyResult.fromMap(Map<String, dynamic> map) {
    return KeyResult(
      id: map['id'] as String,
      objectiveId: map['objectiveId'] as String,
      title: map['title'] as String,
      measurementType: KeyResultMeasurementTypeX.fromValue(
        map['measurementType'] as String?,
      ),
      initialValue: (map['initialValue'] as num?)?.toDouble() ?? 0,
      currentValue: (map['currentValue'] as num?)?.toDouble() ?? 0,
      targetValue: (map['targetValue'] as num?)?.toDouble() ?? 0,
      unit: map['unit'] as String?,
      weight: (map['weight'] as num?)?.toDouble(),
      status: KeyResultStatusX.fromValue(map['status'] as String?),
      lastCheckInAt:
          map['lastCheckInAt'] == null
              ? null
              : DateTime.parse(map['lastCheckInAt'] as String),
      legacyGoalId: map['legacyGoalId'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }
}
