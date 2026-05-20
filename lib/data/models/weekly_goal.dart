enum GoalTrackingMode { automatic, manual }

extension GoalTrackingModeValues on GoalTrackingMode {
  String get value => name;

  String get label => switch (this) {
    GoalTrackingMode.automatic => 'Execução automática',
    GoalTrackingMode.manual => 'Resultado manual',
  };

  String get helperText => switch (this) {
    GoalTrackingMode.automatic =>
      'A meta avança sozinha conforme suas atividades concluídas.',
    GoalTrackingMode.manual =>
      'Você atualiza o progresso manualmente para metas de resultado.',
  };
}

class GoalTrackingModeX {
  const GoalTrackingModeX._();

  static GoalTrackingMode fromValue(String value) {
    return GoalTrackingMode.values.firstWhere(
      (item) => item.value == value,
      orElse: () => GoalTrackingMode.automatic,
    );
  }
}

enum GoalPeriod { week, month, quarter, year, custom }

extension GoalPeriodValues on GoalPeriod {
  String get value => name;

  String get label => switch (this) {
    GoalPeriod.week => 'Semanal',
    GoalPeriod.month => 'Mensal',
    GoalPeriod.quarter => 'Trimestral',
    GoalPeriod.year => 'Anual',
    GoalPeriod.custom => 'Período livre',
  };
}

class GoalPeriodX {
  const GoalPeriodX._();

  static GoalPeriod fromValue(String value) {
    return GoalPeriod.values.firstWhere(
      (item) => item.value == value,
      orElse: () => GoalPeriod.week,
    );
  }
}

enum WeeklyGoalType { completions, activeDays, qualityPoints }

extension WeeklyGoalTypeValues on WeeklyGoalType {
  String get value => name;

  String get label => switch (this) {
    WeeklyGoalType.completions => 'Conclusões',
    WeeklyGoalType.activeDays => 'Dias ativos',
    WeeklyGoalType.qualityPoints => 'Pontos de qualidade',
  };

  String get helperText => switch (this) {
    WeeklyGoalType.completions =>
      'Conta quantas atividades foram concluídas dentro do período.',
    WeeklyGoalType.activeDays =>
      'Conta em quantos dias houve pelo menos uma conclusão.',
    WeeklyGoalType.qualityPoints =>
      'Soma os pesos de qualidade das atividades concluídas.',
  };
}

class WeeklyGoalTypeX {
  const WeeklyGoalTypeX._();

  static WeeklyGoalType fromValue(String value) {
    return WeeklyGoalType.values.firstWhere(
      (item) => item.value == value,
      orElse: () => WeeklyGoalType.completions,
    );
  }
}

enum WeeklyGoalScope { overall, activity, category }

extension WeeklyGoalScopeValues on WeeklyGoalScope {
  String get value => name;

  String get label => switch (this) {
    WeeklyGoalScope.overall => 'Geral',
    WeeklyGoalScope.activity => 'Atividade',
    WeeklyGoalScope.category => 'Categoria',
  };
}

class WeeklyGoalScopeX {
  const WeeklyGoalScopeX._();

  static WeeklyGoalScope fromValue(String value) {
    return WeeklyGoalScope.values.firstWhere(
      (item) => item.value == value,
      orElse: () => WeeklyGoalScope.overall,
    );
  }
}

class WeeklyGoal {
  const WeeklyGoal({
    required this.id,
    required this.name,
    required this.trackingMode,
    required this.period,
    required this.targetValue,
    required this.currentValue,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.type,
    this.scope,
    this.activityId,
    this.categoryId,
    this.unit,
    this.startDate,
    this.endDate,
  });

  final String id;
  final String name;
  final GoalTrackingMode trackingMode;
  final GoalPeriod period;
  final WeeklyGoalType? type;
  final WeeklyGoalScope? scope;
  final double targetValue;
  final double currentValue;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? activityId;
  final String? categoryId;
  final String? unit;
  final DateTime? startDate;
  final DateTime? endDate;

  bool get isAutomatic => trackingMode == GoalTrackingMode.automatic;
  bool get isManual => trackingMode == GoalTrackingMode.manual;

  WeeklyGoal copyWith({
    String? id,
    String? name,
    GoalTrackingMode? trackingMode,
    GoalPeriod? period,
    WeeklyGoalType? type,
    WeeklyGoalScope? scope,
    double? targetValue,
    double? currentValue,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? activityId,
    String? categoryId,
    String? unit,
    DateTime? startDate,
    DateTime? endDate,
    bool clearType = false,
    bool clearScope = false,
    bool clearActivityId = false,
    bool clearCategoryId = false,
    bool clearUnit = false,
    bool clearStartDate = false,
    bool clearEndDate = false,
  }) {
    return WeeklyGoal(
      id: id ?? this.id,
      name: name ?? this.name,
      trackingMode: trackingMode ?? this.trackingMode,
      period: period ?? this.period,
      type: clearType ? null : type ?? this.type,
      scope: clearScope ? null : scope ?? this.scope,
      targetValue: targetValue ?? this.targetValue,
      currentValue: currentValue ?? this.currentValue,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      activityId: clearActivityId ? null : activityId ?? this.activityId,
      categoryId: clearCategoryId ? null : categoryId ?? this.categoryId,
      unit: clearUnit ? null : unit ?? this.unit,
      startDate: clearStartDate ? null : startDate ?? this.startDate,
      endDate: clearEndDate ? null : endDate ?? this.endDate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'trackingMode': trackingMode.value,
      'period': period.value,
      'type': type?.value,
      'scope': scope?.value,
      'targetValue': targetValue,
      'currentValue': currentValue,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'activityId': activityId,
      'categoryId': categoryId,
      'unit': unit,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
    };
  }

  factory WeeklyGoal.fromMap(Map<String, dynamic> map) {
    final trackingMode = GoalTrackingModeX.fromValue(
      map['trackingMode'] as String? ?? 'automatic',
    );

    return WeeklyGoal(
      id: map['id'] as String,
      name: map['name'] as String,
      trackingMode: trackingMode,
      period: GoalPeriodX.fromValue(map['period'] as String? ?? 'week'),
      type:
          map['type'] == null
              ? (trackingMode == GoalTrackingMode.automatic
                  ? WeeklyGoalType.completions
                  : null)
              : WeeklyGoalTypeX.fromValue(map['type'] as String),
      scope:
          map['scope'] == null
              ? (trackingMode == GoalTrackingMode.automatic
                  ? WeeklyGoalScope.overall
                  : null)
              : WeeklyGoalScopeX.fromValue(map['scope'] as String),
      targetValue: (map['targetValue'] as num).toDouble(),
      currentValue: (map['currentValue'] as num?)?.toDouble() ?? 0,
      isActive: (map['isActive'] as bool?) ?? true,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      activityId: map['activityId'] as String?,
      categoryId: map['categoryId'] as String?,
      unit: map['unit'] as String?,
      startDate:
          map['startDate'] == null
              ? null
              : DateTime.parse(map['startDate'] as String),
      endDate:
          map['endDate'] == null
              ? null
              : DateTime.parse(map['endDate'] as String),
    );
  }
}
