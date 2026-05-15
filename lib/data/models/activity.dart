import 'package:flutter/material.dart';

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
    this.colorHex,
    this.iconKey,
  });

  final String id;
  final String name;
  final String? description;
  final String categoryId;
  final int? startMinutes;
  final int? endMinutes;
  final List<int> weekdays;
  final int? colorHex;
  final String? iconKey;
  final bool isActive;
  final bool remindersEnabled;
  final DateTime createdAt;
  final DateTime updatedAt;

  Color? get colorOrNull => colorHex == null ? null : Color(colorHex!);

  Activity copyWith({
    String? id,
    String? name,
    String? description,
    String? categoryId,
    int? startMinutes,
    int? endMinutes,
    List<int>? weekdays,
    int? colorHex,
    String? iconKey,
    bool? isActive,
    bool? remindersEnabled,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool clearDescription = false,
    bool clearStartMinutes = false,
    bool clearEndMinutes = false,
    bool clearColor = false,
    bool clearIcon = false,
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
      colorHex: clearColor ? null : colorHex ?? this.colorHex,
      iconKey: clearIcon ? null : iconKey ?? this.iconKey,
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
      'colorHex': colorHex,
      'iconKey': iconKey,
      'isActive': isActive,
      'remindersEnabled': remindersEnabled,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Activity.fromMap(Map<String, dynamic> map) {
    return Activity(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      categoryId: map['categoryId'] as String,
      startMinutes: map['startMinutes'] as int?,
      endMinutes: map['endMinutes'] as int?,
      weekdays: List<int>.from(map['weekdays'] as List<dynamic>),
      colorHex: map['colorHex'] as int?,
      iconKey: map['iconKey'] as String?,
      isActive: map['isActive'] as bool,
      remindersEnabled: (map['remindersEnabled'] as bool?) ?? false,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }
}
