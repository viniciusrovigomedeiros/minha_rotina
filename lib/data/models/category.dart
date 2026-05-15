import 'package:flutter/material.dart';

class Category {
  const Category({
    required this.id,
    required this.name,
    required this.colorHex,
    required this.iconKey,
    this.isDefault = false,
  });

  final String id;
  final String name;
  final int colorHex;
  final String iconKey;
  final bool isDefault;

  Color get color => Color(colorHex);

  Category copyWith({
    String? id,
    String? name,
    int? colorHex,
    String? iconKey,
    bool? isDefault,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      colorHex: colorHex ?? this.colorHex,
      iconKey: iconKey ?? this.iconKey,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'colorHex': colorHex,
      'iconKey': iconKey,
      'isDefault': isDefault,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as String,
      name: map['name'] as String,
      colorHex: map['colorHex'] as int,
      iconKey: map['iconKey'] as String,
      isDefault: (map['isDefault'] as bool?) ?? false,
    );
  }

  static List<Category> defaults() {
    return const [
      Category(
        id: 'saude',
        name: 'Saúde',
        colorHex: 0xFF3FAE7A,
        iconKey: 'favorite',
        isDefault: true,
      ),
      Category(
        id: 'trabalho',
        name: 'Trabalho',
        colorHex: 0xFF5A7DFA,
        iconKey: 'work',
        isDefault: true,
      ),
      Category(
        id: 'estudo',
        name: 'Estudo',
        colorHex: 0xFF9A6DF5,
        iconKey: 'school',
        isDefault: true,
      ),
      Category(
        id: 'navalha',
        name: 'Navalha',
        colorHex: 0xFF259D9B,
        iconKey: 'bolt',
        isDefault: true,
      ),
      Category(
        id: 'casa',
        name: 'Casa',
        colorHex: 0xFFE09A3C,
        iconKey: 'home',
        isDefault: true,
      ),
      Category(
        id: 'pessoal',
        name: 'Pessoal',
        colorHex: 0xFFCF6F89,
        iconKey: 'person',
        isDefault: true,
      ),
    ];
  }
}
