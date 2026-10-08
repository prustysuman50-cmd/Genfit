import '../../data/local_food_database.dart';
import '../../models/nutrition/food_item.dart';
import '../../models/nutrition/hostel_mess_menu.dart';
import '../../models/nutrition/meal_category.dart';
import 'user_service.dart';

/// Service managing today's hostel/mess menu based on the student's college and campus.
/// Modularly extensible to support College -> Hostel -> Today's Menu.
class HostelMenuService {
  HostelMenuService._();

  static final HostelMenuService instance = HostelMenuService._();

  HostelMessMenu? _customMenu;

  /// Sets a custom hostel menu (useful for testing or specific hostel overrides)
  void setCustomMenu(HostelMessMenu? menu) {
    _customMenu = menu;
  }

  /// Returns today's active hostel/mess menu for the user's institution
  HostelMessMenu getTodaysMenu({String? college, String? campus}) {
    if (_customMenu != null) return _customMenu!;

    final user = UserService.instance.currentUser;
    final targetCollege = college ?? user.college;
    final targetCampus = campus ?? user.campus;

    final matched = LocalFoodDatabase.getHostelMenuForCollege(
      targetCollege,
      campus: targetCampus,
    );

    return matched ?? _defaultSampleMenu;
  }

  /// Returns individual food items available in a given meal section
  List<FoodItem> getFoodsForSection(
    MealCategory category, {
    String? college,
    String? campus,
  }) {
    final menu = getTodaysMenu(college: college, campus: campus);
    final foodIds = menu.dailyFoodIds[category] ?? [];
    final foods = <FoodItem>[];

    for (final id in foodIds) {
      final item = LocalFoodDatabase.getFoodById(id);
      if (item != null) {
        foods.add(item);
      }
    }

    if (foods.isEmpty) {
      // Graceful fallback to all items tagged for this category
      return LocalFoodDatabase.getFoodsForCategory(category);
    }

    return foods;
  }

  /// Returns user-friendly title for the 4 hostel meal sections
  String getSectionTitle(MealCategory category) {
    switch (category) {
      case MealCategory.breakfast:
        return 'Breakfast';
      case MealCategory.lunch:
        return 'Lunch';
      case MealCategory.snacks:
        return 'Evening';
      case MealCategory.dinner:
        return 'Dinner';
    }
  }

  /// Default sample hostel menu covering all individual staple foods
  static const HostelMessMenu _defaultSampleMenu = HostelMessMenu(
    id: 'menu_default_sample',
    college: 'Campus Mess',
    campus: 'Main Hostel',
    messName: 'Central Student Dining Hall',
    dailyFoodIds: {
      MealCategory.breakfast: [
        'food_upma',
        'food_poha',
        'food_bara',
        'food_chakuli_pitha',
        'food_chutney',
        'food_single_egg',
        'food_banana',
        'food_milk',
      ],
      MealCategory.lunch: [
        'food_rice',
        'food_dal',
        'food_dalma',
        'food_potato_curry',
        'food_fish',
        'food_chicken',
        'food_soya',
        'food_vegetables',
        'food_raita',
        'food_curd',
      ],
      MealCategory.snacks: [
        'food_alu_chop',
        'food_dahibara',
        'food_peanuts',
        'food_sattu',
        'food_mudhi_mixture',
        'food_banana',
        'food_milk',
      ],
      MealCategory.dinner: [
        'food_roti',
        'food_paratha',
        'food_dal',
        'food_mixed_tadka',
        'food_paneer',
        'food_egg_curry',
        'food_egg_bhurji',
        'food_mushroom_curry',
        'food_potato_curry',
        'food_ice_cream',
      ],
    },
  );
}
