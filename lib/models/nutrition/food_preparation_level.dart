import 'food_item.dart';

/// Preparation / oil level selected by the user for a scanned meal.
///
/// Multipliers:
/// - Light: 0.90x (minimal oil, boiled, or light preparation)
/// - Standard: 1.00x (typical mess / cafeteria preparation)
/// - Rich: 1.15x (extra oil, ghee, rich gravy, or fried)
enum FoodPreparationLevel {
  light,
  standard,
  rich;

  String get displayName {
    switch (this) {
      case FoodPreparationLevel.light:
        return 'Light';
      case FoodPreparationLevel.standard:
        return 'Standard';
      case FoodPreparationLevel.rich:
        return 'Rich';
    }
  }

  double get multiplier {
    switch (this) {
      case FoodPreparationLevel.light:
        return 0.90;
      case FoodPreparationLevel.standard:
        return 1.00;
      case FoodPreparationLevel.rich:
        return 1.15;
    }
  }

  String get explanatoryTag {
    switch (this) {
      case FoodPreparationLevel.light:
        return 'Minimal oil (0.90x)';
      case FoodPreparationLevel.standard:
        return 'Standard mess (1.00x)';
      case FoodPreparationLevel.rich:
        return 'Extra oil / rich (1.15x)';
    }
  }
}

/// Helper value object to compute dynamically displayed review nutrition.
///
/// Combines the base [FoodItem.calculateForServings] with the selected
/// [FoodPreparationLevel] multiplier.
class FoodReviewNutrition {
  final double calories;
  final double protein;
  final double carbohydrates;
  final double fats;

  const FoodReviewNutrition({
    required this.calories,
    required this.protein,
    required this.carbohydrates,
    required this.fats,
  });

  factory FoodReviewNutrition.calculate({
    required FoodItem food,
    required double servings,
    required FoodPreparationLevel preparation,
  }) {
    final baseValues = food.calculateForServings(servings);
    final factor = preparation.multiplier;
    return FoodReviewNutrition(
      calories: double.parse((baseValues.calories * factor).toStringAsFixed(1)),
      protein: double.parse((baseValues.protein * factor).toStringAsFixed(1)),
      carbohydrates: double.parse(
        (baseValues.carbohydrates * factor).toStringAsFixed(1),
      ),
      fats: double.parse((baseValues.fats * factor).toStringAsFixed(1)),
    );
  }
}
