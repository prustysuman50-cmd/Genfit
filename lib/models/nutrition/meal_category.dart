import 'package:flutter/material.dart';

enum MealCategory {
  breakfast,
  lunch,
  dinner,
  snacks;

  String get displayName {
    switch (this) {
      case MealCategory.breakfast:
        return 'Breakfast';
      case MealCategory.lunch:
        return 'Lunch';
      case MealCategory.dinner:
        return 'Dinner';
      case MealCategory.snacks:
        return 'Snacks';
    }
  }

  IconData get icon {
    switch (this) {
      case MealCategory.breakfast:
        return Icons.wb_sunny_rounded;
      case MealCategory.lunch:
        return Icons.lunch_dining_rounded;
      case MealCategory.dinner:
        return Icons.dinner_dining_rounded;
      case MealCategory.snacks:
        return Icons.cookie_rounded;
    }
  }

  Color get accentColor {
    switch (this) {
      case MealCategory.breakfast:
        return const Color(0xFFF97316); // Amber/Orange
      case MealCategory.lunch:
        return const Color(0xFF06B6D4); // Cyan
      case MealCategory.dinner:
        return const Color(0xFFA855F7); // Purple
      case MealCategory.snacks:
        return const Color(0xFFEAB308); // Yellow
    }
  }

  String get suggestedTiming {
    switch (this) {
      case MealCategory.breakfast:
        return '7:00 AM - 10:00 AM';
      case MealCategory.lunch:
        return '12:30 PM - 2:30 PM';
      case MealCategory.dinner:
        return '7:30 PM - 9:30 PM';
      case MealCategory.snacks:
        return 'Evening / Post-workout';
    }
  }

  static MealCategory fromString(String value) {
    return MealCategory.values.firstWhere(
      (c) => c.name.toLowerCase() == value.trim().toLowerCase(),
      orElse: () => MealCategory.breakfast,
    );
  }
}
