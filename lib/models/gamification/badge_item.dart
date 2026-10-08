import 'package:flutter/material.dart';

class BadgeItem {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final bool isUnlocked;
  final DateTime? unlockedAt;

  const BadgeItem({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    this.isUnlocked = false,
    this.unlockedAt,
  });

  BadgeItem copyWith({
    String? id,
    String? name,
    String? description,
    IconData? icon,
    bool? isUnlocked,
    DateTime? unlockedAt,
  }) {
    return BadgeItem(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'iconCodePoint': icon.codePoint,
    'isUnlocked': isUnlocked,
    'unlockedAt': unlockedAt?.toIso8601String(),
  };

  factory BadgeItem.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String;
    return BadgeItem(
      id: id,
      name: json['name'] as String,
      description: json['description'] as String,
      icon: _iconForBadgeId(id),
      isUnlocked: (json['isUnlocked'] as bool?) ?? false,
      unlockedAt: json['unlockedAt'] != null
          ? DateTime.parse(json['unlockedAt'] as String)
          : null,
    );
  }

  static IconData _iconForBadgeId(String id) {
    switch (id) {
      case 'first_workout':
        return Icons.fitness_center_rounded;
      case 'seven_day_streak':
        return Icons.local_fire_department_rounded;
      case 'hundred_reps':
        return Icons.military_tech_rounded;
      case 'first_meal_logged':
        return Icons.restaurant_rounded;
      case 'campus_challenger':
        return Icons.emoji_events_rounded;
      case 'journey_starter':
        return Icons.explore_rounded;
      case 'odisha_explorer':
        return Icons.map_rounded;
      default:
        return Icons.star_rounded;
    }
  }
}
