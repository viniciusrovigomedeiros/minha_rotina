import 'package:flutter/material.dart';

enum ActivityRecurrence {
  oneOff,
  daily,
  weekly,
  weeklyFixed,
  monthly,
  flexible,
}

extension ActivityRecurrenceValues on ActivityRecurrence {
  String get value => name;

  String get label => switch (this) {
    ActivityRecurrence.oneOff => 'Única',
    ActivityRecurrence.daily => 'Diária',
    ActivityRecurrence.weekly => 'Semanal',
    ActivityRecurrence.weeklyFixed => 'Semanal em dias fixos',
    ActivityRecurrence.monthly => 'Mensal',
    ActivityRecurrence.flexible => 'Sem recorrência',
  };
}

class ActivityRecurrenceX {
  const ActivityRecurrenceX._();

  static ActivityRecurrence fromValue(String? value) {
    if (value == ActivityRecurrence.weeklyFixed.value) {
      return ActivityRecurrence.weekly;
    }
    return ActivityRecurrence.values.firstWhere(
      (item) => item.value == value,
      orElse: () => ActivityRecurrence.flexible,
    );
  }
}

class Activity {
  const Activity({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.weekdays,
    required this.isActive,
    required this.remindersEnabled,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.startMinutes,
    this.endMinutes,
    this.weeklyTargetCount,
    this.colorHex,
    this.iconKey,
    this.objectiveId,
    this.keyResultId,
    this.recurrence = ActivityRecurrence.flexible,
    this.scheduledDate,
  });

  final String id;
  final String name;
  final String? description;
  final String categoryId;
  final int? startMinutes;
  final int? endMinutes;
  final List<int> weekdays;
  final int? weeklyTargetCount;
  final int? colorHex;
  final String? iconKey;
  final String? objectiveId;
  final String? keyResultId;
  final ActivityRecurrence recurrence;
  final DateTime? scheduledDate;
  final bool isActive;
  final bool remindersEnabled;
  final DateTime createdAt;
  final DateTime updatedAt;

  Color? get colorOrNull => colorHex == null ? null : Color(colorHex!);

  bool get isRecurringForObjective =>
      recurrence == ActivityRecurrence.daily ||
      recurrence == ActivityRecurrence.weekly ||
      recurrence == ActivityRecurrence.weeklyFixed ||
      recurrence == ActivityRecurrence.monthly;

  bool get isOneOffObjectiveAction =>
      recurrence == ActivityRecurrence.oneOff ||
      recurrence == ActivityRecurrence.flexible;

  int get effectiveWeeklyTargetCount {
    if (recurrence != ActivityRecurrence.weekly &&
        recurrence != ActivityRecurrence.weeklyFixed) {
      return 0;
    }
    final fallback = weekdays.isEmpty ? 1 : weekdays.length;
    return (weeklyTargetCount ?? fallback).clamp(1, 7);
  }

  Activity copyWith({
    String? id,
    String? name,
    String? description,
    String? categoryId,
    int? startMinutes,
    int? endMinutes,
    List<int>? weekdays,
    int? weeklyTargetCount,
    int? colorHex,
    String? iconKey,
    String? objectiveId,
    String? keyResultId,
    ActivityRecurrence? recurrence,
    DateTime? scheduledDate,
    bool? isActive,
    bool? remindersEnabled,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool clearDescription = false,
    bool clearStartMinutes = false,
    bool clearEndMinutes = false,
    bool clearColor = false,
    bool clearIcon = false,
    bool clearObjectiveId = false,
    bool clearKeyResultId = false,
    bool clearScheduledDate = false,
    bool clearWeeklyTargetCount = false,
  }) {
    return Activity(
      id: id ?? this.id,
      name: name ?? this.name,
      description: clearDescription ? null : description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      startMinutes:
          clearStartMinutes ? null : startMinutes ?? this.startMinutes,
      endMinutes: clearEndMinutes ? null : endMinutes ?? this.endMinutes,
      weekdays: weekdays ?? this.weekdays,
      weeklyTargetCount:
          clearWeeklyTargetCount
              ? null
              : weeklyTargetCount ?? this.weeklyTargetCount,
      colorHex: clearColor ? null : colorHex ?? this.colorHex,
      iconKey: clearIcon ? null : iconKey ?? this.iconKey,
      objectiveId: clearObjectiveId ? null : objectiveId ?? this.objectiveId,
      keyResultId: clearKeyResultId ? null : keyResultId ?? this.keyResultId,
      recurrence: recurrence ?? this.recurrence,
      scheduledDate:
          clearScheduledDate ? null : scheduledDate ?? this.scheduledDate,
      isActive: isActive ?? this.isActive,
      remindersEnabled: remindersEnabled ?? this.remindersEnabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'categoryId': categoryId,
      'startMinutes': startMinutes,
      'endMinutes': endMinutes,
      'weekdays': weekdays,
      'weeklyTargetCount': weeklyTargetCount,
      'colorHex': colorHex,
      'iconKey': iconKey,
      'objectiveId': objectiveId,
      'keyResultId': keyResultId,
      'recurrence': recurrence.value,
      'scheduledDate': scheduledDate?.toIso8601String(),
      'isActive': isActive,
      'remindersEnabled': remindersEnabled,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Activity.fromMap(Map<String, dynamic> map) {
    final weekdays = List<int>.from((map['weekdays'] as List<dynamic>? ?? []));

    return Activity(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      categoryId: map['categoryId'] as String,
      startMinutes: map['startMinutes'] as int?,
      endMinutes: map['endMinutes'] as int?,
      weekdays: weekdays,
      weeklyTargetCount: map['weeklyTargetCount'] as int?,
      colorHex: map['colorHex'] as int?,
      iconKey: map['iconKey'] as String?,
      objectiveId: map['objectiveId'] as String?,
      keyResultId: map['keyResultId'] as String?,
      recurrence: ActivityRecurrenceX.fromValue(
        map['recurrence'] as String? ??
            (weekdays.isEmpty ? 'flexible' : 'weekly'),
      ),
      scheduledDate:
          map['scheduledDate'] == null
              ? null
              : DateTime.parse(map['scheduledDate'] as String),
      isActive: map['isActive'] as bool,
      remindersEnabled: (map['remindersEnabled'] as bool?) ?? false,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }
}
