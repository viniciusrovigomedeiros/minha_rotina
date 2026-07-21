enum CheckInConfidence { low, medium, high }

extension CheckInConfidenceValues on CheckInConfidence {
  String get value => name;

  String get label => switch (this) {
    CheckInConfidence.low => 'Baixa',
    CheckInConfidence.medium => 'Média',
    CheckInConfidence.high => 'Alta',
  };
}

class CheckInConfidenceX {
  const CheckInConfidenceX._();

  static CheckInConfidence fromValue(String? value) {
    return CheckInConfidence.values.firstWhere(
      (item) => item.value == value,
      orElse: () => CheckInConfidence.medium,
    );
  }
}

class KeyResultCheckIn {
  const KeyResultCheckIn({
    required this.id,
    required this.keyResultId,
    required this.valueBefore,
    required this.valueAfter,
    required this.createdAt,
    this.note,
    this.confidence = CheckInConfidence.medium,
  });

  final String id;
  final String keyResultId;
  final double valueBefore;
  final double valueAfter;
  final String? note;
  final CheckInConfidence confidence;
  final DateTime createdAt;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'keyResultId': keyResultId,
      'valueBefore': valueBefore,
      'valueAfter': valueAfter,
      'note': note,
      'confidence': confidence.value,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory KeyResultCheckIn.fromMap(Map<String, dynamic> map) {
    return KeyResultCheckIn(
      id: map['id'] as String,
      keyResultId: map['keyResultId'] as String,
      valueBefore: (map['valueBefore'] as num?)?.toDouble() ?? 0,
      valueAfter: (map['valueAfter'] as num?)?.toDouble() ?? 0,
      note: map['note'] as String?,
      confidence: CheckInConfidenceX.fromValue(map['confidence'] as String?),
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}
