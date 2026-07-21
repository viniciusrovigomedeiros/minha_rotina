enum OkrCycleStatus { planned, active, completed }

extension OkrCycleStatusValues on OkrCycleStatus {
  String get value => name;

  String get label => switch (this) {
    OkrCycleStatus.planned => 'Planejado',
    OkrCycleStatus.active => 'Ativo',
    OkrCycleStatus.completed => 'Concluído',
  };
}

class OkrCycleStatusX {
  const OkrCycleStatusX._();

  static OkrCycleStatus fromValue(String? value) {
    return OkrCycleStatus.values.firstWhere(
      (item) => item.value == value,
      orElse: () => OkrCycleStatus.planned,
    );
  }
}

class OkrCycle {
  const OkrCycle({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.isCustom = false,
  });

  final String id;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final OkrCycleStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isCustom;

  OkrCycle copyWith({
    String? id,
    String? name,
    DateTime? startDate,
    DateTime? endDate,
    OkrCycleStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isCustom,
  }) {
    return OkrCycle(
      id: id ?? this.id,
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isCustom: isCustom ?? this.isCustom,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'status': status.value,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isCustom': isCustom,
    };
  }

  factory OkrCycle.fromMap(Map<String, dynamic> map) {
    return OkrCycle(
      id: map['id'] as String,
      name: map['name'] as String,
      startDate: DateTime.parse(map['startDate'] as String),
      endDate: DateTime.parse(map['endDate'] as String),
      status: OkrCycleStatusX.fromValue(map['status'] as String?),
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      isCustom: (map['isCustom'] as bool?) ?? false,
    );
  }
}
