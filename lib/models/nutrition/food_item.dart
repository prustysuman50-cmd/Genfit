import 'meal_category.dart';

class FoodItem {
  final String id;
  final String name;
  final String servingSize;
  final String servingUnit;
  final double calories; // kcal per 1.0 serving
  final double protein; // grams per 1.0 serving
  final double carbohydrates; // grams per 1.0 serving
  final double fats; // grams per 1.0 serving
  final bool isVegetarian;
  final String budgetCategory;
  final List<String> regionalTags;
  final String? alternativeFoodId;
  final String? alternativeHint;
  final List<MealCategory> mealCategories;

  const FoodItem({
    required this.id,
    required this.name,
    required this.servingSize,
    required this.servingUnit,
    required this.calories,
    required this.protein,
    required this.carbohydrates,
    required this.fats,
    required this.isVegetarian,
    required this.budgetCategory,
    required this.regionalTags,
    this.alternativeFoodId,
    this.alternativeHint,
    this.mealCategories = const [
      MealCategory.breakfast,
      MealCategory.lunch,
      MealCategory.dinner,
      MealCategory.snacks,
    ],
  });

  /// Checks if this food item is suitable for a given meal category
  bool matchesCategory(MealCategory category) =>
      mealCategories.contains(category);

  /// Checks if this food item matches a regional/contextual tag
  bool matchesRegionalTag(String tag) {
    final clean = tag.trim().toLowerCase();
    return regionalTags.any((t) => t.toLowerCase().contains(clean));
  }

  /// Calculates scaled nutritional values based on serving multiplier
  FoodNutritionalValues calculateForServings(double quantity) {
    return FoodNutritionalValues(
      calories: double.parse((calories * quantity).toStringAsFixed(1)),
      protein: double.parse((protein * quantity).toStringAsFixed(1)),
      carbohydrates: double.parse(
        (carbohydrates * quantity).toStringAsFixed(1),
      ),
      fats: double.parse((fats * quantity).toStringAsFixed(1)),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'servingSize': servingSize,
    'servingUnit': servingUnit,
    'calories': calories,
    'protein': protein,
    'carbohydrates': carbohydrates,
    'fats': fats,
    'isVegetarian': isVegetarian,
    'budgetCategory': budgetCategory,
    'regionalTags': regionalTags,
    'alternativeFoodId': alternativeFoodId,
    'alternativeHint': alternativeHint,
    'mealCategories': mealCategories.map((c) => c.name).toList(),
  };

  factory FoodItem.fromJson(Map<String, dynamic> json) => FoodItem(
    id: json['id'] as String,
    name: json['name'] as String,
    servingSize: json['servingSize'] as String,
    servingUnit: json['servingUnit'] as String,
    calories: (json['calories'] as num).toDouble(),
    protein: (json['protein'] as num).toDouble(),
    carbohydrates: (json['carbohydrates'] as num).toDouble(),
    fats: (json['fats'] as num).toDouble(),
    isVegetarian: json['isVegetarian'] as bool,
    budgetCategory: json['budgetCategory'] as String,
    regionalTags:
        (json['regionalTags'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        const [],
    alternativeFoodId: json['alternativeFoodId'] as String?,
    alternativeHint: json['alternativeHint'] as String?,
    mealCategories:
        (json['mealCategories'] as List<dynamic>?)
            ?.map((e) => MealCategory.fromString(e.toString()))
            .toList() ??
        const [
          MealCategory.breakfast,
          MealCategory.lunch,
          MealCategory.dinner,
          MealCategory.snacks,
        ],
  );
}

class FoodNutritionalValues {
  final double calories;
  final double protein;
  final double carbohydrates;
  final double fats;

  const FoodNutritionalValues({
    required this.calories,
    required this.protein,
    required this.carbohydrates,
    required this.fats,
  });
}
