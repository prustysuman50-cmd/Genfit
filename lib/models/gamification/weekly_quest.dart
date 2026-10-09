import 'package:flutter/material.dart';

/// Represents an individual objective on the Weekly Quest Board.
///
/// Quests track ISO-week progress from [DailyStatsService] without altering
/// daily challenges, badges, or existing gamification logic.
class WeeklyQuest {
  final String id;
  final String title;
  final String description;
  final int target;
  final int current;
  final String unit;
  final int rewardXp;
  final String category;
  final IconData icon;
  final bool isClaimed;

  const WeeklyQuest({
    required this.id,
    required this.title,
    required this.description,
    required this.target,
    this.current = 0,
    required this.unit,
    this.rewardXp = 150,
    this.category = 'General',
    this.icon = Icons.star_rounded,
    this.isClaimed = false,
  });

  /// Whether the quest's target has been met or exceeded.
  bool get isCompleted => current >= target;

  /// Fractional completion clamped between 0.0 and 1.0.
  double get fraction =>
      target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;

  /// Integer percentage between 0 and 100.
  int get percent => (fraction * 100).round();

  /// Human-readable progress representation, e.g. "3 / 3 workouts".
  String get progressLabel => '$current / $target $unit';

  WeeklyQuest copyWith({
    String? id,
    String? title,
    String? description,
    int? target,
    int? current,
    String? unit,
    int? rewardXp,
    String? category,
    IconData? icon,
    bool? isClaimed,
  }) {
    return WeeklyQuest(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      target: target ?? this.target,
      current: current ?? this.current,
      unit: unit ?? this.unit,
      rewardXp: rewardXp ?? this.rewardXp,
      category: category ?? this.category,
      icon: icon ?? this.icon,
      isClaimed: isClaimed ?? this.isClaimed,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'target': target,
    'current': current,
    'unit': unit,
    'rewardXp': rewardXp,
    'category': category,
    'iconCodePoint': icon.codePoint,
    'isClaimed': isClaimed,
  };

  factory WeeklyQuest.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String;
    return WeeklyQuest(
      id: id,
      title: json['title'] as String,
      description: json['description'] as String,
      target: (json['target'] as num).toInt(),
      current: (json['current'] as num?)?.toInt() ?? 0,
      unit: json['unit'] as String,
      rewardXp: (json['rewardXp'] as num?)?.toInt() ?? 150,
      category: json['category'] as String? ?? 'General',
      icon: _iconForId(id),
      isClaimed: (json['isClaimed'] as bool?) ?? false,
    );
  }

  static IconData _iconForId(String id) {
    switch (id) {
      case 'weekly_workouts':
        return Icons.fitness_center_rounded;
      case 'weekly_steps':
        return Icons.directions_walk_rounded;
      case 'weekly_reps':
        return Icons.military_tech_rounded;
      case 'weekly_meal_days':
        return Icons.restaurant_rounded;
      case 'weekly_active_minutes':
        return Icons.timer_rounded;
      default:
        return Icons.emoji_events_rounded;
    }
  }
}
