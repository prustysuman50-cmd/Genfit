import 'food_item.dart';
import 'meal_category.dart';

class LoggedMeal {
  final String id;
  final String foodId;
  final String name;
  final MealCategory category;
  final double servings;
  final String servingSize;
  final double calories;
  final double protein;
  final double carbohydrates;
  final double fats;
  final bool isVegetarian;
  final String budgetCategory;
  final DateTime loggedAt;
  final bool isBudgetAlternativeUsed;
  final double preparationMultiplier;

  const LoggedMeal({
    required this.id,
    required this.foodId,
    required this.name,
    required this.category,
    required this.servings,
    required this.servingSize,
    required this.calories,
    required this.protein,
    required this.carbohydrates,
    required this.fats,
    required this.isVegetarian,
    required this.budgetCategory,
    required this.loggedAt,
    this.isBudgetAlternativeUsed = false,
    this.preparationMultiplier = 1.0,
  });

  factory LoggedMeal.fromFoodItem({
    required FoodItem food,
    required MealCategory category,
    required double servings,
    DateTime? loggedAt,
    String? id,
    bool isBudgetAlternativeUsed = false,
    double preparationMultiplier = 1.0,
  }) {
    final values = food.calculateForServings(servings);
    final now = loggedAt ?? DateTime.now();
    final factor = preparationMultiplier;
    return LoggedMeal(
      id: id ?? 'meal_${now.millisecondsSinceEpoch}_${food.id}',
      foodId: food.id,
      name: food.name,
      category: category,
      servings: servings,
      servingSize: food.servingSize,
      calories: double.parse((values.calories * factor).toStringAsFixed(1)),
      protein: double.parse((values.protein * factor).toStringAsFixed(1)),
      carbohydrates: double.parse(
        (values.carbohydrates * factor).toStringAsFixed(1),
      ),
      fats: double.parse((values.fats * factor).toStringAsFixed(1)),
      isVegetarian: food.isVegetarian,
      budgetCategory: food.budgetCategory,
      loggedAt: now,
      isBudgetAlternativeUsed: isBudgetAlternativeUsed,
      preparationMultiplier: preparationMultiplier,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'foodId': foodId,
    'name': name,
    'category': category.name,
    'servings': servings,
    'servingSize': servingSize,
    'calories': calories,
    'protein': protein,
    'carbohydrates': carbohydrates,
    'fats': fats,
    'isVegetarian': isVegetarian,
    'budgetCategory': budgetCategory,
    'loggedAt': loggedAt.toIso8601String(),
    'isBudgetAlternativeUsed': isBudgetAlternativeUsed,
    'preparationMultiplier': preparationMultiplier,
  };

  factory LoggedMeal.fromJson(Map<String, dynamic> json) => LoggedMeal(
    id: json['id'] as String,
    foodId: json['foodId'] as String,
    name: json['name'] as String,
    category: MealCategory.fromString(json['category'] as String),
    servings: (json['servings'] as num).toDouble(),
    servingSize: json['servingSize'] as String,
    calories: (json['calories'] as num).toDouble(),
    protein: (json['protein'] as num).toDouble(),
    carbohydrates: (json['carbohydrates'] as num).toDouble(),
    fats: (json['fats'] as num).toDouble(),
    isVegetarian: json['isVegetarian'] as bool,
    budgetCategory: json['budgetCategory'] as String,
    loggedAt: DateTime.parse(json['loggedAt'] as String),
    isBudgetAlternativeUsed:
        (json['isBudgetAlternativeUsed'] as bool?) ?? false,
    preparationMultiplier:
        (json['preparationMultiplier'] as num?)?.toDouble() ?? 1.0,
  );
}
