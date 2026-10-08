import '../models/nutrition/budget_alternative.dart';
import '../models/nutrition/food_item.dart';
import '../models/nutrition/hostel_mess_menu.dart';
import '../models/nutrition/meal_category.dart';

class LocalFoodDatabase {
  LocalFoodDatabase._();

  static const List<FoodItem> foods = [
    // -------------------------------------------------------------
    // 1. Rice (Cooked White Rice)
    // -------------------------------------------------------------
    FoodItem(
      id: 'food_rice',
      name: 'Rice (Cooked White Rice)',
      servingSize: '1 bowl (150g)',
      servingUnit: 'bowl',
      calories: 195.0,
      protein: 4.1,
      carbohydrates: 43.5,
      fats: 0.5,
      isVegetarian: true,
      budgetCategory: 'Hostel Staple (₹)',
      regionalTags: [
        'Odisha Staple',
        'Daily Carb Fuel',
        'Hostel Lunch',
        'Hostel Dinner',
      ],
      alternativeFoodId: 'food_ragi',
      alternativeHint: 'Swap for Mandia/Ragi for 3x higher calcium, lower glycemic index and high fiber.',
      mealCategories: [MealCategory.lunch, MealCategory.dinner],
    ),

    // -------------------------------------------------------------
    // 2. Dal (Moong / Toor Dal)
    // -------------------------------------------------------------
    FoodItem(
      id: 'food_dal',
      name: 'Dal (Moong / Toor Dal)',
      servingSize: '1 medium katori (150g)',
      servingUnit: 'katori',
      calories: 160.0,
      protein: 9.2,
      carbohydrates: 23.0,
      fats: 3.2,
      isVegetarian: true,
      budgetCategory: 'Pocket Friendly (₹)',
      regionalTags: [
        'Mess Essential',
        'Daily Desi Protein',
        'Hostel Lunch',
        'Hostel Dinner',
      ],
      mealCategories: [MealCategory.lunch, MealCategory.dinner],
    ),

    // -------------------------------------------------------------
    // 3. Dalma (Odia Lentil & Veggie Stew)
    // -------------------------------------------------------------
    FoodItem(
      id: 'food_dalma',
      name: 'Dalma (Odia Lentil & Veggie Stew)',
      servingSize: '1 large bowl (200g)',
      servingUnit: 'bowl',
      calories: 175.0,
      protein: 8.5,
      carbohydrates: 27.0,
      fats: 3.5,
      isVegetarian: true,
      budgetCategory: 'Pocket Friendly (₹)',
      regionalTags: [
        'Odia Heritage',
        'Fiber & Micronutrients',
        'Hostel Feast',
        'Hostel Lunch',
        'Hostel Dinner',
      ],
      mealCategories: [MealCategory.lunch, MealCategory.dinner],
    ),

    // -------------------------------------------------------------
    // 4. Pakhala (Fermented Curd Rice)
    // -------------------------------------------------------------
    FoodItem(
      id: 'food_pakhala',
      name: 'Pakhala (Fermented Curd Rice)',
      servingSize: '1 large bowl (300g)',
      servingUnit: 'bowl',
      calories: 210.0,
      protein: 5.2,
      carbohydrates: 42.0,
      fats: 2.1,
      isVegetarian: true,
      budgetCategory: 'Hostel Staple (₹)',
      regionalTags: [
        'Odia Heritage',
        'Natural Probiotic',
        'Cooling Recovery',
        'Hostel Lunch',
        'Summer Staple',
      ],
      mealCategories: [MealCategory.breakfast, MealCategory.lunch],
    ),

    // -------------------------------------------------------------
    // 5. Ragi / Mandia (Porridge / Roti)
    // -------------------------------------------------------------
    FoodItem(
      id: 'food_ragi',
      name: 'Ragi / Mandia (Porridge / Roti)',
      servingSize: '1 bowl / 2 rotis (150g)',
      servingUnit: 'bowl',
      calories: 165.0,
      protein: 5.5,
      carbohydrates: 34.0,
      fats: 1.1,
      isVegetarian: true,
      budgetCategory: 'Super Saver (₹)',
      regionalTags: [
        'Odisha Millet Mission',
        'Superfood',
        'High Calcium & Iron',
        'Hostel Breakfast',
        'Hostel Dinner',
      ],
      mealCategories: [MealCategory.breakfast, MealCategory.dinner],
    ),

    // -------------------------------------------------------------
    // 6. Chana (Boiled Kala Chana)
    // -------------------------------------------------------------
    FoodItem(
      id: 'food_chana',
      name: 'Chana (Boiled Kala Chana)',
      servingSize: '1 cup (150g)',
      servingUnit: 'cup',
      calories: 215.0,
      protein: 13.5,
      carbohydrates: 35.0,
      fats: 3.0,
      isVegetarian: true,
      budgetCategory: 'Student Budget (₹)',
      regionalTags: [
        'Desi Powerhouse',
        'Pre/Post Workout',
        'High Fiber Protein',
        'Evening Snack',
        'Hostel Breakfast',
      ],
      mealCategories: [MealCategory.breakfast, MealCategory.snacks],
    ),

    // -------------------------------------------------------------
    // 7. Soya (Soya Chunks Cooked)
    // -------------------------------------------------------------
    FoodItem(
      id: 'food_soya',
      name: 'Soya (Soya Chunks Cooked)',
      servingSize: '1 cup cooked (150g)',
      servingUnit: 'cup',
      calories: 170.0,
      protein: 26.0,
      carbohydrates: 16.5,
      fats: 0.8,
      isVegetarian: true,
      budgetCategory: 'King of Budget Protein (₹)',
      regionalTags: [
        '52% Protein Raw',
        'Student Cheat Code',
        'Hostel MVP',
        'Hostel Lunch',
        'Hostel Dinner',
      ],
      mealCategories: [MealCategory.lunch, MealCategory.dinner],
    ),

    // -------------------------------------------------------------
    // 8. Eggs (Boiled Whole Eggs)
    // -------------------------------------------------------------
    FoodItem(
      id: 'food_eggs',
      name: 'Eggs (Boiled Whole Eggs)',
      servingSize: '2 eggs (100g)',
      servingUnit: 'pair',
      calories: 148.0,
      protein: 12.6,
      carbohydrates: 1.1,
      fats: 10.0,
      isVegetarian: false,
      budgetCategory: 'Affordable (₹)',
      regionalTags: [
        'Complete Amino Profile',
        'Hostel Quick Protein',
        'Bioavailable',
        'Hostel Breakfast',
        'Evening Snack',
      ],
      mealCategories: [
        MealCategory.breakfast,
        MealCategory.lunch,
        MealCategory.dinner,
        MealCategory.snacks,
      ],
    ),

    // -------------------------------------------------------------
    // 9. Chicken (Desi Chicken Curry)
    // -------------------------------------------------------------
    FoodItem(
      id: 'food_chicken',
      name: 'Chicken (Desi Chicken Curry)',
      servingSize: '1 plate / 150g',
      servingUnit: 'plate',
      calories: 245.0,
      protein: 31.0,
      carbohydrates: 4.0,
      fats: 11.5,
      isVegetarian: false,
      budgetCategory: 'Premium (₹₹₹)',
      regionalTags: [
        'Lean Muscle Builder',
        'High Protein',
        'Hostel Dinner',
        'Hostel Feast',
      ],
      alternativeFoodId: 'food_soya',
      alternativeHint: 'Swap Chicken (₹90) with Soya Chunks (₹15) for equal protein at 80% lower cost.',
      mealCategories: [MealCategory.lunch, MealCategory.dinner],
    ),

    // -------------------------------------------------------------
    // 10. Fish (Machha Besara / Rohu Curry)
    // -------------------------------------------------------------
    FoodItem(
      id: 'food_fish',
      name: 'Fish (Machha Besara / Rohu Curry)',
      servingSize: '1 plate / 150g',
      servingUnit: 'plate',
      calories: 210.0,
      protein: 24.0,
      carbohydrates: 5.0,
      fats: 10.2,
      isVegetarian: false,
      budgetCategory: 'Moderate to High (₹₹₹)',
      regionalTags: [
        'Odisha Freshwater',
        'Omega-3 Rich',
        'Hostel Lunch',
        'Odia Heritage',
      ],
      alternativeFoodId: 'food_eggs',
      alternativeHint: 'Swap Fish (₹80) with 2 Boiled Eggs (₹14) or Chana (₹12) to save ~₹65 with high bioavailable protein.',
      mealCategories: [MealCategory.lunch, MealCategory.dinner],
    ),

    // -------------------------------------------------------------
    // 11. Roti (Whole Wheat Chapati)
    // -------------------------------------------------------------
    FoodItem(
      id: 'food_roti',
      name: 'Roti (Whole Wheat Chapati)',
      servingSize: '2 rotis (60g)',
      servingUnit: 'serving',
      calories: 160.0,
      protein: 5.2,
      carbohydrates: 32.0,
      fats: 1.2,
      isVegetarian: true,
      budgetCategory: 'Hostel Staple (₹)',
      regionalTags: [
        'Daily Fuel',
        'Complex Carbs',
        'Hostel Dinner',
        'Hostel Lunch',
      ],
      mealCategories: [MealCategory.lunch, MealCategory.dinner],
    ),

    // -------------------------------------------------------------
    // 12. Common vegetables (Mixed Sabzi / Bhaja)
    // -------------------------------------------------------------
    FoodItem(
      id: 'food_vegetables',
      name: 'Common Vegetables (Mixed Sabzi / Bhaja)',
      servingSize: '1 cup (150g)',
      servingUnit: 'cup',
      calories: 110.0,
      protein: 3.0,
      carbohydrates: 14.0,
      fats: 5.0,
      isVegetarian: true,
      budgetCategory: 'Pocket Friendly (₹)',
      regionalTags: [
        'Vitamins & Minerals',
        'Mess Side Dish',
        'Gut Fiber',
        'Hostel Lunch',
        'Hostel Dinner',
      ],
      mealCategories: [MealCategory.lunch, MealCategory.dinner],
    ),

    // -------------------------------------------------------------
    // 13. Potato Curry (Alu Dum / Aloo Tarkari)
    // -------------------------------------------------------------
    FoodItem(
      id: 'food_potato_curry',
      name: 'Potato Curry (Alu Dum / Aloo Tarkari)',
      servingSize: '1 katori (150g)',
      servingUnit: 'katori',
      calories: 165.0,
      protein: 3.2,
      carbohydrates: 28.5,
      fats: 4.5,
      isVegetarian: true,
      budgetCategory: 'Hostel Staple (₹)',
      regionalTags: [
        'Mess Essential',
        'Daily Comfort',
        'Odia Hostel Classic',
        'Alu Dum',
        'Aloo Dum',
        'Hostel Lunch',
        'Hostel Dinner',
      ],
      mealCategories: [
        MealCategory.breakfast,
        MealCategory.lunch,
        MealCategory.dinner,
      ],
    ),

    // -------------------------------------------------------------
    // 14. Paneer (Paneer Curry / Matar Paneer)
    // -------------------------------------------------------------
    FoodItem(
      id: 'food_paneer',
      name: 'Paneer (Paneer Curry / Matar Paneer)',
      servingSize: '1 plate (150g)',
      servingUnit: 'plate',
      calories: 280.0,
      protein: 16.5,
      carbohydrates: 11.0,
      fats: 19.5,
      isVegetarian: true,
      budgetCategory: 'Special Mess Day (₹₹₹)',
      regionalTags: [
        'Sunday Special',
        'Desi Vegetarian Protein',
        'Canteen Feast',
        'Hostel Dinner',
      ],
      alternativeFoodId: 'food_soya',
      alternativeHint: 'Swap Canteen Paneer (₹80) with Soya Chunks (₹15) for 1.5x more protein at 80% lower cost.',
      mealCategories: [MealCategory.lunch, MealCategory.dinner],
    ),

    // -------------------------------------------------------------
    // 15. Raw Paneer (Fresh Dairy Cubes)
    // -------------------------------------------------------------
    FoodItem(
      id: 'food_paneer_raw',
      name: 'Raw Paneer (Fresh Dairy Cubes)',
      servingSize: '100g',
      servingUnit: '100g',
      calories: 265.0,
      protein: 18.3,
      carbohydrates: 3.5,
      fats: 20.0,
      isVegetarian: true,
      budgetCategory: 'Moderate (₹₹)',
      regionalTags: [
        'Gym Bro Staple',
        'Desi Protein',
        'Zero Cook Snack',
        'Evening Snack',
      ],
      alternativeFoodId: 'food_soya',
      alternativeHint: 'Swap 100g Paneer (₹45) with 50g Soya Chunks (₹12) to double protein (26g) and save money.',
      mealCategories: [MealCategory.breakfast, MealCategory.snacks],
    ),

    // -------------------------------------------------------------
    // 16. Curd / Dahi (Fresh Plain Yogurt)
    // -------------------------------------------------------------
    FoodItem(
      id: 'food_curd',
      name: 'Curd / Dahi (Fresh Plain Curd)',
      servingSize: '1 katori (150g)',
      servingUnit: 'katori',
      calories: 98.0,
      protein: 5.5,
      carbohydrates: 6.8,
      fats: 4.8,
      isVegetarian: true,
      budgetCategory: 'Pocket Friendly (₹)',
      regionalTags: [
        'Natural Probiotic',
        'Gut Health',
        'Mess Cooling Fuel',
        'Hostel Lunch',
      ],
      mealCategories: [
        MealCategory.breakfast,
        MealCategory.lunch,
        MealCategory.snacks,
      ],
    ),

    // -------------------------------------------------------------
    // 17. Milk (Toned Cow Milk)
    // -------------------------------------------------------------
    FoodItem(
      id: 'food_milk',
      name: 'Milk (Toned Cow Milk)',
      servingSize: '1 glass (250ml)',
      servingUnit: 'glass',
      calories: 150.0,
      protein: 8.2,
      carbohydrates: 12.5,
      fats: 7.5,
      isVegetarian: true,
      budgetCategory: 'Daily Essential (₹)',
      regionalTags: [
        'Hostel Night Fuel',
        'Bone Health & Calcium',
        'Post-Workout',
        'Evening Snack',
      ],
      mealCategories: [
        MealCategory.breakfast,
        MealCategory.snacks,
        MealCategory.dinner,
      ],
    ),

    // -------------------------------------------------------------
    // 18. Banana (Ripe Banana / Kadali)
    // -------------------------------------------------------------
    FoodItem(
      id: 'food_banana',
      name: 'Banana (Ripe Banana / Kadali)',
      servingSize: '1 medium banana (100g)',
      servingUnit: 'piece',
      calories: 89.0,
      protein: 1.1,
      carbohydrates: 22.8,
      fats: 0.3,
      isVegetarian: true,
      budgetCategory: 'Super Saver (₹)',
      regionalTags: [
        'Pre-Workout Energy',
        'Instant Potassium',
        'Hostel Quick Bite',
        'Evening Snack',
      ],
      mealCategories: [MealCategory.breakfast, MealCategory.snacks],
    ),

    // -------------------------------------------------------------
    // 19. Peanuts (Roasted Groundnuts / Badam)
    // -------------------------------------------------------------
    FoodItem(
      id: 'food_peanuts',
      name: 'Peanuts (Roasted Groundnuts / Badam)',
      servingSize: '1 small bowl / 50g',
      servingUnit: 'bowl',
      calories: 285.0,
      protein: 13.0,
      carbohydrates: 8.0,
      fats: 24.5,
      isVegetarian: true,
      budgetCategory: 'Student Superfood (₹)',
      regionalTags: [
        'Hostel Room Staple',
        'Healthy Fats & High Calorie',
        'Bulking Fuel',
        'Evening Snack',
      ],
      mealCategories: [MealCategory.snacks],
    ),

    // -------------------------------------------------------------
    // 20. Poha (Chuda Upma / Flattened Rice)
    // -------------------------------------------------------------
    FoodItem(
      id: 'food_poha',
      name: 'Poha (Chuda Upma / Flattened Rice)',
      servingSize: '1 plate (150g)',
      servingUnit: 'plate',
      calories: 210.0,
      protein: 4.6,
      carbohydrates: 38.0,
      fats: 4.5,
      isVegetarian: true,
      budgetCategory: 'Pocket Friendly (₹)',
      regionalTags: [
        'Mess Breakfast',
        'Easy Digestible',
        'Light Morning Fuel',
        'Hostel Breakfast',
      ],
      mealCategories: [MealCategory.breakfast, MealCategory.snacks],
    ),

    // -------------------------------------------------------------
    // 21. Upma (Suji / Semolina Upma)
    // -------------------------------------------------------------
    FoodItem(
      id: 'food_upma',
      name: 'Upma (Suji / Semolina Upma)',
      servingSize: '1 bowl (150g)',
      servingUnit: 'bowl',
      calories: 195.0,
      protein: 5.2,
      carbohydrates: 33.5,
      fats: 4.8,
      isVegetarian: true,
      budgetCategory: 'Hostel Staple (₹)',
      regionalTags: [
        'Mess Classic',
        'Morning Carbs',
        'College Canteen',
        'Hostel Breakfast',
      ],
      mealCategories: [MealCategory.breakfast, MealCategory.snacks],
    ),

    // -------------------------------------------------------------
    // 22. Sattu Sharbat (Chhatua Drink)
    // -------------------------------------------------------------
    FoodItem(
      id: 'food_sattu',
      name: 'Sattu Sharbat (Chhatua Drink)',
      servingSize: '1 glass (250ml)',
      servingUnit: 'glass',
      calories: 180.0,
      protein: 10.4,
      carbohydrates: 26.0,
      fats: 2.8,
      isVegetarian: true,
      budgetCategory: 'King of Desi Protein (₹)',
      regionalTags: [
        'Desi Whey Alternative',
        'Odia Heritage',
        'High Fiber Summer Drink',
        'Evening Snack',
      ],
      mealCategories: [MealCategory.breakfast, MealCategory.snacks],
    ),

    // -------------------------------------------------------------
    // 23. Boiled Egg (Single Whole Egg)
    // -------------------------------------------------------------
    FoodItem(
      id: 'food_single_egg',
      name: 'Boiled Egg (Single Whole Egg)',
      servingSize: '1 egg (50g)',
      servingUnit: 'egg',
      calories: 74.0,
      protein: 6.3,
      carbohydrates: 0.6,
      fats: 5.0,
      isVegetarian: false,
      budgetCategory: 'Affordable (₹)',
      regionalTags: [
        'Single Egg Serving',
        'Clean Bioavailable Protein',
        'Daily Macro Hack',
        'Hostel Breakfast',
      ],
      mealCategories: [
        MealCategory.breakfast,
        MealCategory.lunch,
        MealCategory.dinner,
        MealCategory.snacks,
      ],
    ),

    // -------------------------------------------------------------
    // 24. Single Roti (1 Whole Wheat Chapati)
    // -------------------------------------------------------------
    FoodItem(
      id: 'food_single_roti',
      name: 'Single Roti (1 Whole Wheat Chapati)',
      servingSize: '1 roti (30g)',
      servingUnit: 'roti',
      calories: 80.0,
      protein: 2.6,
      carbohydrates: 16.0,
      fats: 0.6,
      isVegetarian: true,
      budgetCategory: 'Hostel Staple (₹)',
      regionalTags: [
        'Single Roti Unit',
        'Whole Wheat Fiber',
        'Clean Carbs',
        'Hostel Dinner',
      ],
      mealCategories: [MealCategory.lunch, MealCategory.dinner],
    ),

    // -------------------------------------------------------------
    // 25. Egg Curry (2 Eggs in Desi Gravy)
    // -------------------------------------------------------------
    FoodItem(
      id: 'food_egg_curry',
      name: 'Egg Curry (2 Eggs in Desi Gravy)',
      servingSize: '1 plate (200g)',
      servingUnit: 'plate',
      calories: 235.0,
      protein: 14.5,
      carbohydrates: 7.5,
      fats: 16.0,
      isVegetarian: false,
      budgetCategory: 'Pocket Friendly (₹)',
      regionalTags: [
        'Mess Dinner Classic',
        'High Protein Curry',
        'Wednesday/Sunday Special',
        'Hostel Dinner',
      ],
      mealCategories: [MealCategory.lunch, MealCategory.dinner],
    ),

    // -------------------------------------------------------------
    // 26. Santula (Odia Light Mixed Veg Stew)
    // -------------------------------------------------------------
    FoodItem(
      id: 'food_santula',
      name: 'Santula (Odia Light Mixed Veg Stew)',
      servingSize: '1 katori (150g)',
      servingUnit: 'katori',
      calories: 85.0,
      protein: 2.5,
      carbohydrates: 13.0,
      fats: 2.2,
      isVegetarian: true,
      budgetCategory: 'Pocket Friendly (₹)',
      regionalTags: [
        'Odia Heritage',
        'Light & Digestible',
        'Raw Papaya & Gourd',
        'Hostel Lunch',
      ],
      mealCategories: [MealCategory.lunch, MealCategory.dinner],
    ),

    // -------------------------------------------------------------
    // 27. Khichdi (Odia Khechudi / Dal Khichdi)
    // -------------------------------------------------------------
    FoodItem(
      id: 'food_khichdi',
      name: 'Khichdi (Odia Khechudi / Dal Khichdi)',
      servingSize: '1 bowl (200g)',
      servingUnit: 'bowl',
      calories: 240.0,
      protein: 8.8,
      carbohydrates: 42.0,
      fats: 4.2,
      isVegetarian: true,
      budgetCategory: 'Hostel Staple (₹)',
      regionalTags: [
        'Saturday Mess Dinner',
        'Odia Comfort Food',
        'Lentil & Rice Protein Balance',
        'Hostel Dinner',
      ],
      mealCategories: [MealCategory.lunch, MealCategory.dinner],
    ),

    // -------------------------------------------------------------
    // 28. Boiled Green Moong Sprouts
    // -------------------------------------------------------------
    FoodItem(
      id: 'food_sprouts',
      name: 'Boiled Green Moong Sprouts',
      servingSize: '1 cup (100g)',
      servingUnit: 'cup',
      calories: 105.0,
      protein: 8.0,
      carbohydrates: 17.5,
      fats: 0.5,
      isVegetarian: true,
      budgetCategory: 'Pocket Friendly (₹)',
      regionalTags: [
        'Gym Bro Morning',
        'Living Enzymes & Micronutrients',
        'Clean Protein',
        'Evening Snack',
      ],
      mealCategories: [MealCategory.breakfast, MealCategory.snacks],
    ),

    // -------------------------------------------------------------
    // 29. Idli with Sambar (2 Steamed Idlis & Sambar)
    // -------------------------------------------------------------
    FoodItem(
      id: 'food_idli_sambar',
      name: 'Idli with Sambar (2 Steamed Idlis & Sambar)',
      servingSize: '1 plate (180g)',
      servingUnit: 'plate',
      calories: 190.0,
      protein: 6.8,
      carbohydrates: 36.5,
      fats: 1.8,
      isVegetarian: true,
      budgetCategory: 'Mess Breakfast (₹)',
      regionalTags: [
        'Fermented Rice & Lentil',
        'Light Breakfast',
        'Hostel Mess Menu',
        'Hostel Breakfast',
      ],
      mealCategories: [MealCategory.breakfast],
    ),

    // -------------------------------------------------------------
    // 30. Maggi (Instant Masala Noodles)
    // -------------------------------------------------------------
    FoodItem(
      id: 'food_maggi',
      name: 'Maggi (Instant Masala Noodles)',
      servingSize: '1 bowl (150g)',
      servingUnit: 'bowl',
      calories: 310.0,
      protein: 5.5,
      carbohydrates: 46.0,
      fats: 11.5,
      isVegetarian: true,
      budgetCategory: 'Hostel Late Night (₹)',
      regionalTags: [
        'Hostel Midnight Staple',
        'Exam Night Fuel',
        'Comfort Carb',
        'Evening Snack',
      ],
      mealCategories: [MealCategory.snacks, MealCategory.dinner],
    ),

    // -------------------------------------------------------------
    // 31. Odia Mudhi Mixture (Puffed Rice & Peanuts)
    // -------------------------------------------------------------
    FoodItem(
      id: 'food_mudhi_mixture',
      name: 'Odia Mudhi Mixture (Puffed Rice & Peanuts)',
      servingSize: '1 bowl (100g)',
      servingUnit: 'bowl',
      calories: 220.0,
      protein: 6.0,
      carbohydrates: 34.0,
      fats: 6.5,
      isVegetarian: true,
      budgetCategory: 'Super Saver (₹)',
      regionalTags: [
        'Odia Heritage',
        'Evening Adda Snack',
        'Light & Crunchy',
        'Evening Snack',
      ],
      mealCategories: [MealCategory.snacks],
    ),

    // -------------------------------------------------------------
    // 32. Besan Chilla (Desi Protein Pancake)
    // -------------------------------------------------------------
    FoodItem(
      id: 'food_besan_chilla',
      name: 'Besan Chilla (Desi Protein Pancake)',
      servingSize: '1 piece (100g)',
      servingUnit: 'piece',
      calories: 160.0,
      protein: 8.5,
      carbohydrates: 21.0,
      fats: 4.5,
      isVegetarian: true,
      budgetCategory: 'Student Budget (₹)',
      regionalTags: [
        'High Protein Breakfast',
        'Desi Protein Pancake',
        'Quick Hostel Cook',
        'Hostel Breakfast',
      ],
      mealCategories: [MealCategory.breakfast, MealCategory.snacks],
    ),

    // -------------------------------------------------------------
    // 33. Bara (Odia Crispy Urad Dal Vada)
    // -------------------------------------------------------------
    FoodItem(
      id: 'food_bara',
      name: 'Bara (Odia Crispy Urad Dal Vada)',
      servingSize: '2 pieces (80g)',
      servingUnit: 'piece',
      calories: 180.0,
      protein: 5.8,
      carbohydrates: 22.0,
      fats: 7.8,
      isVegetarian: true,
      budgetCategory: 'Pocket Friendly (₹)',
      regionalTags: [
        'Odia Heritage',
        'Hostel Breakfast',
        'Street Food Classic',
        'Evening Snack',
      ],
      mealCategories: [MealCategory.breakfast, MealCategory.snacks],
    ),

    // -------------------------------------------------------------
    // 34. Dahibara (Odia Dahi Bara)
    // -------------------------------------------------------------
    FoodItem(
      id: 'food_dahibara',
      name: 'Dahibara (Odia Dahi Bara)',
      servingSize: '1 plate (200g)',
      servingUnit: 'plate',
      calories: 210.0,
      protein: 7.5,
      carbohydrates: 28.0,
      fats: 6.5,
      isVegetarian: true,
      budgetCategory: 'Pocket Friendly (₹)',
      regionalTags: [
        'Odia Heritage',
        'Cuttack Famous',
        'Natural Probiotic',
        'Hostel Breakfast',
        'Evening Snack',
      ],
      mealCategories: [MealCategory.breakfast, MealCategory.snacks],
    ),

    // -------------------------------------------------------------
    // 35. Chakuli Pitha (Odia Rice & Black Gram Crepe)
    // -------------------------------------------------------------
    FoodItem(
      id: 'food_chakuli_pitha',
      name: 'Chakuli Pitha (Odia Rice & Urad Crepe)',
      servingSize: '2 pieces (100g)',
      servingUnit: 'piece',
      calories: 165.0,
      protein: 4.8,
      carbohydrates: 32.0,
      fats: 2.1,
      isVegetarian: true,
      budgetCategory: 'Hostel Staple (₹)',
      regionalTags: [
        'Odia Heritage',
        'Fermented Batter',
        'Hostel Breakfast',
        'Light Morning Fuel',
      ],
      mealCategories: [MealCategory.breakfast, MealCategory.dinner],
    ),

    // -------------------------------------------------------------
    // 36. Alu Chop (Spiced Potato Cutlet)
    // -------------------------------------------------------------
    FoodItem(
      id: 'food_alu_chop',
      name: 'Alu Chop (Spiced Potato Cutlet)',
      servingSize: '2 pieces (100g)',
      servingUnit: 'piece',
      calories: 195.0,
      protein: 3.5,
      carbohydrates: 26.5,
      fats: 8.5,
      isVegetarian: true,
      budgetCategory: 'Super Saver (₹)',
      regionalTags: [
        'Odia Street Food',
        'Hostel Canteen Classic',
        'Evening Snack',
        'Hostel Breakfast',
      ],
      mealCategories: [MealCategory.breakfast, MealCategory.snacks],
    ),

    // -------------------------------------------------------------
    // 37. Paratha (Whole Wheat Tawa Paratha)
    // -------------------------------------------------------------
    FoodItem(
      id: 'food_paratha',
      name: 'Paratha (Whole Wheat Tawa Paratha)',
      servingSize: '1 paratha (60g)',
      servingUnit: 'piece',
      calories: 175.0,
      protein: 3.8,
      carbohydrates: 24.5,
      fats: 7.0,
      isVegetarian: true,
      budgetCategory: 'Hostel Staple (₹)',
      regionalTags: [
        'Hostel Breakfast',
        'Hostel Dinner',
        'Mess Classic',
        'Layered Flatbread',
      ],
      mealCategories: [MealCategory.breakfast, MealCategory.dinner],
    ),

    // -------------------------------------------------------------
    // 38. Chutney (Coconut / Tomato Chutney)
    // -------------------------------------------------------------
    FoodItem(
      id: 'food_chutney',
      name: 'Chutney (Coconut / Tomato Chutney)',
      servingSize: '1 small katori (40g)',
      servingUnit: 'katori',
      calories: 45.0,
      protein: 0.8,
      carbohydrates: 4.2,
      fats: 2.8,
      isVegetarian: true,
      budgetCategory: 'Pocket Friendly (₹)',
      regionalTags: [
        'Mess Side Dish',
        'Breakfast Condiment',
        'Fresh Desi Dip',
        'Hostel Breakfast',
      ],
      mealCategories: [MealCategory.breakfast, MealCategory.snacks],
    ),

    // -------------------------------------------------------------
    // 39. Biryani (Hostel Mess / Canteen Biryani)
    // -------------------------------------------------------------
    FoodItem(
      id: 'food_biryani',
      name: 'Biryani (Hostel Mess / Canteen Biryani)',
      servingSize: '1 plate (250g)',
      servingUnit: 'plate',
      calories: 380.0,
      protein: 16.5,
      carbohydrates: 52.0,
      fats: 12.0,
      isVegetarian: false,
      budgetCategory: 'Sunday Mess Special (₹₹₹)',
      regionalTags: [
        'Sunday Feast',
        'Hostel Special',
        'Aromatic Rice',
        'Hostel Lunch',
        'Hostel Dinner',
      ],
      mealCategories: [MealCategory.lunch, MealCategory.dinner],
    ),

    // -------------------------------------------------------------
    // 40. Raita (Boondi / Cucumber Curd Raita)
    // -------------------------------------------------------------
    FoodItem(
      id: 'food_raita',
      name: 'Raita (Boondi / Cucumber Curd Raita)',
      servingSize: '1 katori (120g)',
      servingUnit: 'katori',
      calories: 85.0,
      protein: 3.5,
      carbohydrates: 7.2,
      fats: 4.5,
      isVegetarian: true,
      budgetCategory: 'Pocket Friendly (₹)',
      regionalTags: [
        'Cooling Side',
        'Natural Probiotic',
        'Biryani Companion',
        'Hostel Lunch',
        'Hostel Dinner',
      ],
      mealCategories: [MealCategory.lunch, MealCategory.dinner],
    ),

    // -------------------------------------------------------------
    // 41. Egg Bhurji (2 Spiced Scrambled Eggs)
    // -------------------------------------------------------------
    FoodItem(
      id: 'food_egg_bhurji',
      name: 'Egg Bhurji (2 Spiced Scrambled Eggs)',
      servingSize: '1 plate (120g)',
      servingUnit: 'plate',
      calories: 175.0,
      protein: 13.5,
      carbohydrates: 3.5,
      fats: 12.0,
      isVegetarian: false,
      budgetCategory: 'Pocket Friendly (₹)',
      regionalTags: [
        'Quick Hostel Protein',
        'Dhaba Style',
        'Roti Companion',
        'Hostel Dinner',
        'Hostel Breakfast',
      ],
      mealCategories: [
        MealCategory.breakfast,
        MealCategory.lunch,
        MealCategory.dinner,
      ],
    ),

    // -------------------------------------------------------------
    // 42. Mixed Tadka (Green Gram / Moong Dal Tadka)
    // -------------------------------------------------------------
    FoodItem(
      id: 'food_mixed_tadka',
      name: 'Mixed Tadka (Green Gram / Moong Dal Tadka)',
      servingSize: '1 bowl (180g)',
      servingUnit: 'bowl',
      calories: 210.0,
      protein: 11.2,
      carbohydrates: 26.5,
      fats: 6.5,
      isVegetarian: true,
      budgetCategory: 'Pocket Friendly (₹)',
      regionalTags: [
        'Odisha Dhaba Staple',
        'Roti Tadka Combo',
        'High Fiber Protein',
        'Hostel Dinner',
      ],
      mealCategories: [MealCategory.lunch, MealCategory.dinner],
    ),

    // -------------------------------------------------------------
    // 43. Mushroom Curry (Odia Chhatu Tarkari)
    // -------------------------------------------------------------
    FoodItem(
      id: 'food_mushroom_curry',
      name: 'Mushroom Curry (Odia Chhatu Tarkari)',
      servingSize: '1 plate (150g)',
      servingUnit: 'plate',
      calories: 135.0,
      protein: 6.2,
      carbohydrates: 12.0,
      fats: 6.8,
      isVegetarian: true,
      budgetCategory: 'Special Mess Day (₹₹)',
      regionalTags: [
        'Odisha Specialty',
        'Low Calorie Micronutrients',
        'Hostel Dinner',
        'Sunday Veg Special',
      ],
      mealCategories: [MealCategory.lunch, MealCategory.dinner],
    ),

    // -------------------------------------------------------------
    // 44. Ice Cream (Vanilla / Chocolate Cup)
    // -------------------------------------------------------------
    FoodItem(
      id: 'food_ice_cream',
      name: 'Ice Cream (Vanilla / Chocolate Cup)',
      servingSize: '1 cup (100ml / 65g)',
      servingUnit: 'cup',
      calories: 135.0,
      protein: 2.5,
      carbohydrates: 16.0,
      fats: 7.0,
      isVegetarian: true,
      budgetCategory: 'Hostel Treat (₹)',
      regionalTags: [
        'Mess Sunday Special',
        'Hostel Feast Dessert',
        'Late Night Canteen',
        'Hostel Dinner',
      ],
      mealCategories: [MealCategory.dinner, MealCategory.snacks],
    ),

    // -------------------------------------------------------------
    // 45. Puri / Poori (Deep Fried Whole Wheat)
    // -------------------------------------------------------------
    FoodItem(
      id: 'food_puri',
      name: 'Puri / Poori (Deep Fried Whole Wheat)',
      servingSize: '2 puris (70g)',
      servingUnit: 'plate',
      calories: 220.0,
      protein: 4.0,
      carbohydrates: 26.0,
      fats: 11.0,
      isVegetarian: true,
      budgetCategory: 'Hostel Staple (₹)',
      regionalTags: [
        'North Indian',
        'Breakfast Special',
        'Mess Weekend',
        'Deep Fried',
      ],
      mealCategories: [MealCategory.breakfast, MealCategory.dinner],
    ),

    // -------------------------------------------------------------
    // 46. Naan / Butter Naan (Tandoori Flatbread)
    // -------------------------------------------------------------
    FoodItem(
      id: 'food_naan',
      name: 'Naan / Butter Naan (Tandoori Flatbread)',
      servingSize: '1 naan (90g)',
      servingUnit: 'piece',
      calories: 260.0,
      protein: 7.5,
      carbohydrates: 45.0,
      fats: 5.5,
      isVegetarian: true,
      budgetCategory: 'Pocket Friendly (₹)',
      regionalTags: [
        'North Indian',
        'Tandoor Bread',
        'Canteen Feast',
        'Dinner Special',
      ],
      mealCategories: [MealCategory.lunch, MealCategory.dinner],
    ),

    // -------------------------------------------------------------
    // 47. Idli (Plain Steamed Rice & Urad Cakes)
    // -------------------------------------------------------------
    FoodItem(
      id: 'food_idli',
      name: 'Idli (Plain Steamed Rice & Urad Cakes)',
      servingSize: '2 idlis (100g)',
      servingUnit: 'plate',
      calories: 130.0,
      protein: 4.2,
      carbohydrates: 26.0,
      fats: 0.8,
      isVegetarian: true,
      budgetCategory: 'Hostel Staple (₹)',
      regionalTags: [
        'South Indian',
        'Steamed',
        'Light Digestion',
        'Hostel Breakfast',
      ],
      mealCategories: [MealCategory.breakfast, MealCategory.dinner],
    ),

    // -------------------------------------------------------------
    // 48. Dosa (Crispy Plain Rice & Dal Crepe)
    // -------------------------------------------------------------
    FoodItem(
      id: 'food_dosa',
      name: 'Dosa (Crispy Plain Rice & Dal Crepe)',
      servingSize: '1 plain dosa (120g)',
      servingUnit: 'piece',
      calories: 170.0,
      protein: 4.0,
      carbohydrates: 29.0,
      fats: 4.2,
      isVegetarian: true,
      budgetCategory: 'Hostel Staple (₹)',
      regionalTags: [
        'South Indian',
        'Fermented Batter',
        'Crispy Breakfast',
        'Canteen Classic',
      ],
      mealCategories: [
        MealCategory.breakfast,
        MealCategory.dinner,
        MealCategory.snacks,
      ],
    ),

    // -------------------------------------------------------------
    // 49. Sambar (Lentil & Mixed Vegetable Stew)
    // -------------------------------------------------------------
    FoodItem(
      id: 'food_sambar',
      name: 'Sambar (Lentil & Mixed Vegetable Stew)',
      servingSize: '1 medium bowl (150g)',
      servingUnit: 'bowl',
      calories: 90.0,
      protein: 4.5,
      carbohydrates: 14.0,
      fats: 2.0,
      isVegetarian: true,
      budgetCategory: 'Pocket Friendly (₹)',
      regionalTags: [
        'South Indian',
        'Mess Essential',
        'Lentil Soup',
        'Tiffin Side',
      ],
      mealCategories: [
        MealCategory.breakfast,
        MealCategory.lunch,
        MealCategory.dinner,
      ],
    ),

    // -------------------------------------------------------------
    // 50. Rasam (Spiced Tomato Tamarind Soup)
    // -------------------------------------------------------------
    FoodItem(
      id: 'food_rasam',
      name: 'Rasam (Spiced Tomato Tamarind Soup)',
      servingSize: '1 bowl (150g)',
      servingUnit: 'bowl',
      calories: 60.0,
      protein: 1.5,
      carbohydrates: 9.0,
      fats: 1.8,
      isVegetarian: true,
      budgetCategory: 'Hostel Staple (₹)',
      regionalTags: [
        'South Indian',
        'Digestive Broth',
        'Spiced Broth',
        'Mess Lunch',
      ],
      mealCategories: [MealCategory.lunch, MealCategory.dinner],
    ),

    // -------------------------------------------------------------
    // 51. Rajma (Punjabi Red Kidney Bean Curry)
    // -------------------------------------------------------------
    FoodItem(
      id: 'food_rajma',
      name: 'Rajma (Punjabi Red Kidney Bean Curry)',
      servingSize: '1 bowl (150g)',
      servingUnit: 'bowl',
      calories: 180.0,
      protein: 9.5,
      carbohydrates: 26.0,
      fats: 4.5,
      isVegetarian: true,
      budgetCategory: 'Pocket Friendly (₹)',
      regionalTags: [
        'North Indian',
        'High Fiber Protein',
        'Mess Feast',
        'Rajma Chawal',
      ],
      mealCategories: [MealCategory.lunch, MealCategory.dinner],
    ),

    // -------------------------------------------------------------
    // 52. Chole (Spiced White Chickpea Curry)
    // -------------------------------------------------------------
    FoodItem(
      id: 'food_chole',
      name: 'Chole (Spiced White Chickpea Curry)',
      servingSize: '1 bowl (150g)',
      servingUnit: 'bowl',
      calories: 210.0,
      protein: 8.5,
      carbohydrates: 28.0,
      fats: 7.5,
      isVegetarian: true,
      budgetCategory: 'Pocket Friendly (₹)',
      regionalTags: [
        'North Indian',
        'Desi Protein',
        'Chole Bhature',
        'Sunday Special',
      ],
      mealCategories: [
        MealCategory.breakfast,
        MealCategory.lunch,
        MealCategory.dinner,
      ],
    ),

    // -------------------------------------------------------------
    // 53. Kadhi Pakora (Spiced Gram Flour & Curd Gravy)
    // -------------------------------------------------------------
    FoodItem(
      id: 'food_kadhi',
      name: 'Kadhi Pakora (Spiced Gram Flour & Curd Gravy)',
      servingSize: '1 bowl (150g)',
      servingUnit: 'bowl',
      calories: 160.0,
      protein: 5.0,
      carbohydrates: 15.0,
      fats: 9.0,
      isVegetarian: true,
      budgetCategory: 'Hostel Staple (₹)',
      regionalTags: [
        'North Indian',
        'Curd Gravy',
        'Hostel Comfort',
        'Kadhi Chawal',
      ],
      mealCategories: [MealCategory.lunch, MealCategory.dinner],
    ),

    // -------------------------------------------------------------
    // 54. Aloo Gobi (Spiced Potato & Cauliflower)
    // -------------------------------------------------------------
    FoodItem(
      id: 'food_aloo_gobi',
      name: 'Aloo Gobi (Spiced Potato & Cauliflower)',
      servingSize: '1 katori (150g)',
      servingUnit: 'katori',
      calories: 135.0,
      protein: 3.2,
      carbohydrates: 18.0,
      fats: 6.0,
      isVegetarian: true,
      budgetCategory: 'Hostel Staple (₹)',
      regionalTags: [
        'North Indian',
        'Mess Sabzi',
        'Dry Tarkari',
        'Hostel Dinner',
      ],
      mealCategories: [MealCategory.lunch, MealCategory.dinner],
    ),

    // -------------------------------------------------------------
    // 55. Veg Biryani (Aromatic Spiced Rice & Veggies)
    // -------------------------------------------------------------
    FoodItem(
      id: 'food_veg_biryani',
      name: 'Veg Biryani (Aromatic Spiced Rice & Veggies)',
      servingSize: '1 plate (250g)',
      servingUnit: 'plate',
      calories: 310.0,
      protein: 6.5,
      carbohydrates: 54.0,
      fats: 7.5,
      isVegetarian: true,
      budgetCategory: 'Pocket Friendly (₹)',
      regionalTags: [
        'Fragrant Rice',
        'Hostel Weekend Feast',
        'Veggie Delight',
        'Mess Lunch',
      ],
      mealCategories: [MealCategory.lunch, MealCategory.dinner],
    ),

    // -------------------------------------------------------------
    // 56. Egg Maggi (Instant Noodles with Scrambled Egg)
    // -------------------------------------------------------------
    FoodItem(
      id: 'food_egg_maggi',
      name: 'Egg Maggi (Instant Noodles with Scrambled Egg)',
      servingSize: '1 plate / bowl (180g)',
      servingUnit: 'bowl',
      calories: 380.0,
      protein: 14.5,
      carbohydrates: 45.0,
      fats: 16.0,
      isVegetarian: false,
      budgetCategory: 'Student Budget (₹)',
      regionalTags: [
        'Hostel Midnight Snack',
        'Hostel MVP',
        'Exam Fuel',
        'Canteen Hit',
      ],
      mealCategories: [
        MealCategory.breakfast,
        MealCategory.dinner,
        MealCategory.snacks,
      ],
    ),

    // -------------------------------------------------------------
    // 57. Bread Omelette (2 Slices with 2-Egg Omelette)
    // -------------------------------------------------------------
    FoodItem(
      id: 'food_bread_omelette',
      name: 'Bread Omelette (2 Slices with 2-Egg Omelette)',
      servingSize: '1 plate (160g)',
      servingUnit: 'plate',
      calories: 320.0,
      protein: 16.5,
      carbohydrates: 28.0,
      fats: 15.0,
      isVegetarian: false,
      budgetCategory: 'Student Budget (₹)',
      regionalTags: [
        'Hostel Gate Stall',
        'High Protein Breakfast',
        'Quick Muscle Fuel',
        'Canteen Classic',
      ],
      mealCategories: [
        MealCategory.breakfast,
        MealCategory.snacks,
        MealCategory.dinner,
      ],
    ),

    // -------------------------------------------------------------
    // 58. Omelette (2 Eggs with Onion & Green Chilli)
    // -------------------------------------------------------------
    FoodItem(
      id: 'food_omelette',
      name: 'Omelette (2 Eggs with Onion & Green Chilli)',
      servingSize: '1 plate (110g)',
      servingUnit: 'plate',
      calories: 180.0,
      protein: 13.0,
      carbohydrates: 2.0,
      fats: 13.5,
      isVegetarian: false,
      budgetCategory: 'Student Budget (₹)',
      regionalTags: [
        'Complete Protein',
        'Quick Breakfast',
        'Low Carb',
        'Post Workout',
      ],
      mealCategories: [
        MealCategory.breakfast,
        MealCategory.dinner,
        MealCategory.snacks,
      ],
    ),

    // -------------------------------------------------------------
    // 59. Chai / Milk Tea (Indian Tapri Masala Chai)
    // -------------------------------------------------------------
    FoodItem(
      id: 'food_tea',
      name: 'Chai / Milk Tea (Indian Tapri Masala Chai)',
      servingSize: '1 cup (100ml)',
      servingUnit: 'cup',
      calories: 75.0,
      protein: 2.0,
      carbohydrates: 10.0,
      fats: 2.8,
      isVegetarian: true,
      budgetCategory: 'Hostel Staple (₹)',
      regionalTags: [
        'Campus Fuel',
        'Tapri Classic',
        'Morning Boost',
        'Exam Study',
      ],
      mealCategories: [MealCategory.breakfast, MealCategory.snacks],
    ),

    // -------------------------------------------------------------
    // 60. Coffee (Indian Milk Coffee / Nescafe)
    // -------------------------------------------------------------
    FoodItem(
      id: 'food_coffee',
      name: 'Coffee (Indian Milk Coffee / Nescafe)',
      servingSize: '1 cup (100ml)',
      servingUnit: 'cup',
      calories: 85.0,
      protein: 2.2,
      carbohydrates: 11.0,
      fats: 3.2,
      isVegetarian: true,
      budgetCategory: 'Hostel Staple (₹)',
      regionalTags: [
        'Hostel Energy',
        'Caffeine Kick',
        'Late Night Study',
        'Morning Routine',
      ],
      mealCategories: [MealCategory.breakfast, MealCategory.snacks],
    ),

    // -------------------------------------------------------------
    // 61. Banana Shake (Banana Milkshake with Milk)
    // -------------------------------------------------------------
    FoodItem(
      id: 'food_banana_shake',
      name: 'Banana Shake (Banana Milkshake with Milk)',
      servingSize: '1 glass (250ml)',
      servingUnit: 'glass',
      calories: 220.0,
      protein: 7.5,
      carbohydrates: 38.0,
      fats: 4.5,
      isVegetarian: true,
      budgetCategory: 'Student Budget (₹)',
      regionalTags: [
        'Bulking Fuel',
        'Post Workout Smoothie',
        'Potassium Energy',
        'Gym Classic',
      ],
      mealCategories: [MealCategory.breakfast, MealCategory.snacks],
    ),

    // -------------------------------------------------------------
    // 62. Bread (2 Slices White / Brown Bread)
    // -------------------------------------------------------------
    FoodItem(
      id: 'food_bread',
      name: 'Bread (2 Slices White / Brown Bread)',
      servingSize: '2 slices (50g)',
      servingUnit: 'serving',
      calories: 135.0,
      protein: 4.5,
      carbohydrates: 26.0,
      fats: 1.5,
      isVegetarian: true,
      budgetCategory: 'Hostel Staple (₹)',
      regionalTags: [
        'Hostel Breakfast',
        'Carb Base',
        'Easy Snack',
        'Room Staple',
      ],
      mealCategories: [MealCategory.breakfast, MealCategory.snacks],
    ),

    // -------------------------------------------------------------
    // 63. Fruit Jam (Mixed Fruit Jam Spread)
    // -------------------------------------------------------------
    FoodItem(
      id: 'food_jam',
      name: 'Fruit Jam (Mixed Fruit Jam Spread)',
      servingSize: '1 tbsp (20g)',
      servingUnit: 'spoon',
      calories: 55.0,
      protein: 0.1,
      carbohydrates: 13.5,
      fats: 0.0,
      isVegetarian: true,
      budgetCategory: 'Hostel Staple (₹)',
      regionalTags: [
        'Breakfast Spread',
        'Quick Sugar',
        'Toast Topping',
        'Room Stock',
      ],
      mealCategories: [MealCategory.breakfast, MealCategory.snacks],
    ),

    // -------------------------------------------------------------
    // 64. Butter (Table Butter Cube / Amul Butter)
    // -------------------------------------------------------------
    FoodItem(
      id: 'food_butter',
      name: 'Butter (Table Butter Cube / Amul Butter)',
      servingSize: '1 cube (10g)',
      servingUnit: 'piece',
      calories: 72.0,
      protein: 0.1,
      carbohydrates: 0.1,
      fats: 8.0,
      isVegetarian: true,
      budgetCategory: 'Hostel Staple (₹)',
      regionalTags: [
        'Dairy Fat',
        'Toast Spread',
        'Paratha Topping',
        'Hostel Breakfast',
      ],
      mealCategories: [MealCategory.breakfast, MealCategory.snacks],
    ),

    // -------------------------------------------------------------
    // 65. Biscuits (Glucose / Marie / Parle-G)
    // -------------------------------------------------------------
    FoodItem(
      id: 'food_biscuits',
      name: 'Biscuits (Glucose / Marie / Parle-G)',
      servingSize: '4 biscuits (30g)',
      servingUnit: 'serving',
      calories: 130.0,
      protein: 2.2,
      carbohydrates: 23.0,
      fats: 3.5,
      isVegetarian: true,
      budgetCategory: 'Hostel Staple (₹)',
      regionalTags: [
        'Tea Time Companion',
        'Hostel Cheap Snack',
        'Desk Nibble',
        'Pocket Saver',
      ],
      mealCategories: [MealCategory.breakfast, MealCategory.snacks],
    ),

    // -------------------------------------------------------------
    // 66. Pizza (1 Medium Slice Veg / Cheese Pizza)
    // -------------------------------------------------------------
    FoodItem(
      id: 'food_pizza',
      name: 'Pizza (1 Medium Slice Veg / Cheese Pizza)',
      servingSize: '1 slice (100g)',
      servingUnit: 'slice',
      calories: 250.0,
      protein: 9.5,
      carbohydrates: 30.0,
      fats: 10.5,
      isVegetarian: true,
      budgetCategory: 'Premium (₹₹₹)',
      regionalTags: [
        'Fast Food',
        'Weekend Treat',
        'Cheesy Indulgence',
        'Birthday Party',
      ],
      mealCategories: [
        MealCategory.lunch,
        MealCategory.dinner,
        MealCategory.snacks,
      ],
    ),

    // -------------------------------------------------------------
    // 67. Burger (Veg / Aloo Tikki Burger)
    // -------------------------------------------------------------
    FoodItem(
      id: 'food_burger',
      name: 'Burger (Veg / Aloo Tikki Burger)',
      servingSize: '1 burger (140g)',
      servingUnit: 'piece',
      calories: 280.0,
      protein: 7.0,
      carbohydrates: 38.0,
      fats: 11.0,
      isVegetarian: true,
      budgetCategory: 'Moderate to High (₹₹₹)',
      regionalTags: [
        'Fast Food',
        'Canteen Bite',
        'Evening Hunger',
        'Crunchy Patty',
      ],
      mealCategories: [
        MealCategory.lunch,
        MealCategory.dinner,
        MealCategory.snacks,
      ],
    ),

    // -------------------------------------------------------------
    // 68. Sandwich (Veg Grilled Cheese Sandwich)
    // -------------------------------------------------------------
    FoodItem(
      id: 'food_sandwich',
      name: 'Sandwich (Veg Grilled Cheese Sandwich)',
      servingSize: '1 sandwich (150g)',
      servingUnit: 'piece',
      calories: 210.0,
      protein: 6.0,
      carbohydrates: 32.0,
      fats: 6.5,
      isVegetarian: true,
      budgetCategory: 'Student Budget (₹)',
      regionalTags: [
        'Hostel Canteen Hit',
        'Grilled Veggies',
        'Evening Snack',
        'Tiffin Classic',
      ],
      mealCategories: [MealCategory.breakfast, MealCategory.snacks],
    ),

    // -------------------------------------------------------------
    // 69. Pasta (Red Tomato / White Sauce Pasta)
    // -------------------------------------------------------------
    FoodItem(
      id: 'food_pasta',
      name: 'Pasta (Red Tomato / White Sauce Pasta)',
      servingSize: '1 bowl (180g)',
      servingUnit: 'bowl',
      calories: 260.0,
      protein: 7.5,
      carbohydrates: 42.0,
      fats: 7.0,
      isVegetarian: true,
      budgetCategory: 'Moderate to High (₹₹₹)',
      regionalTags: [
        'Cafe Favorite',
        'Italian Desi Fusion',
        'Hostel Feast',
        'Comfort Carbs',
      ],
      mealCategories: [
        MealCategory.lunch,
        MealCategory.dinner,
        MealCategory.snacks,
      ],
    ),

    // -------------------------------------------------------------
    // 70. French Fries (Salted Crispy Potato Fries)
    // -------------------------------------------------------------
    FoodItem(
      id: 'food_french_fries',
      name: 'French Fries (Salted Crispy Potato Fries)',
      servingSize: '1 packet (100g)',
      servingUnit: 'packet',
      calories: 310.0,
      protein: 3.5,
      carbohydrates: 41.0,
      fats: 15.0,
      isVegetarian: true,
      budgetCategory: 'Pocket Friendly (₹)',
      regionalTags: [
        'Deep Fried',
        'Crispy Finger Food',
        'Canteen Munch',
        'Party Snack',
      ],
      mealCategories: [MealCategory.snacks],
    ),

    // -------------------------------------------------------------
    // 71. Noodles (Veg Hakka Chowmein Noodles)
    // -------------------------------------------------------------
    FoodItem(
      id: 'food_noodles',
      name: 'Noodles (Veg Hakka Chowmein Noodles)',
      servingSize: '1 plate (180g)',
      servingUnit: 'plate',
      calories: 270.0,
      protein: 6.0,
      carbohydrates: 45.0,
      fats: 7.5,
      isVegetarian: true,
      budgetCategory: 'Pocket Friendly (₹)',
      regionalTags: [
        'Desi Chinese',
        'Street Food Hit',
        'Evening Canteen',
        'Wok Tossed',
      ],
      mealCategories: [
        MealCategory.lunch,
        MealCategory.dinner,
        MealCategory.snacks,
      ],
    ),

    // -------------------------------------------------------------
    // 72. Fried Rice (Desi Chinese Veg Fried Rice)
    // -------------------------------------------------------------
    FoodItem(
      id: 'food_fried_rice',
      name: 'Fried Rice (Desi Chinese Veg Fried Rice)',
      servingSize: '1 plate (200g)',
      servingUnit: 'plate',
      calories: 290.0,
      protein: 5.5,
      carbohydrates: 50.0,
      fats: 8.0,
      isVegetarian: true,
      budgetCategory: 'Pocket Friendly (₹)',
      regionalTags: [
        'Desi Chinese',
        'Canteen Lunch',
        'Wok Tossed',
        'Quick Dinner',
      ],
      mealCategories: [MealCategory.lunch, MealCategory.dinner],
    ),

    // -------------------------------------------------------------
    // 73. Momos (6 Steamed Veggie / Chicken Dumplings)
    // -------------------------------------------------------------
    FoodItem(
      id: 'food_momos',
      name: 'Momos (6 Steamed Veggie / Chicken Dumplings)',
      servingSize: '6 momos (150g)',
      servingUnit: 'plate',
      calories: 210.0,
      protein: 7.0,
      carbohydrates: 36.0,
      fats: 4.0,
      isVegetarian: true,
      budgetCategory: 'Pocket Friendly (₹)',
      regionalTags: [
        'Steamed Dumplings',
        'Street Food Hit',
        'Spicy Chutney',
        'Evening Adda',
      ],
      mealCategories: [MealCategory.snacks],
    ),

    // -------------------------------------------------------------
    // 74. Wrap / Kathi Roll (Veggie Spiced Kathi Roll)
    // -------------------------------------------------------------
    FoodItem(
      id: 'food_wrap',
      name: 'Wrap / Kathi Roll (Veggie Spiced Kathi Roll)',
      servingSize: '1 roll (150g)',
      servingUnit: 'piece',
      calories: 270.0,
      protein: 7.5,
      carbohydrates: 38.0,
      fats: 9.5,
      isVegetarian: true,
      budgetCategory: 'Student Budget (₹)',
      regionalTags: [
        'Grab and Go',
        'Kathi Roll',
        'Campus Walk Snack',
        'Tawa Toasted',
      ],
      mealCategories: [
        MealCategory.lunch,
        MealCategory.dinner,
        MealCategory.snacks,
      ],
    ),

    // -------------------------------------------------------------
    // 75. Pancakes (2 Golden Fluffy Pancakes)
    // -------------------------------------------------------------
    FoodItem(
      id: 'food_pancakes',
      name: 'Pancakes (2 Golden Fluffy Pancakes)',
      servingSize: '2 pancakes (100g)',
      servingUnit: 'plate',
      calories: 225.0,
      protein: 6.0,
      carbohydrates: 36.0,
      fats: 6.0,
      isVegetarian: true,
      budgetCategory: 'Student Budget (₹)',
      regionalTags: [
        'Sunday Breakfast',
        'Sweet Start',
        'Fluffy Batter',
        'Western Brunch',
      ],
      mealCategories: [MealCategory.breakfast, MealCategory.snacks],
    ),

    // -------------------------------------------------------------
    // 76. Oatmeal (Cooked Rolled Oats Porridge)
    // -------------------------------------------------------------
    FoodItem(
      id: 'food_oatmeal',
      name: 'Oatmeal (Cooked Rolled Oats Porridge)',
      servingSize: '1 bowl (150g)',
      servingUnit: 'bowl',
      calories: 160.0,
      protein: 6.5,
      carbohydrates: 28.0,
      fats: 2.8,
      isVegetarian: true,
      budgetCategory: 'Student Budget (₹)',
      regionalTags: [
        'High Beta Glucan',
        'Heart Healthy Carbs',
        'Fitness Staple',
        'Clean Breakfast',
      ],
      mealCategories: [MealCategory.breakfast, MealCategory.snacks],
    ),

    // -------------------------------------------------------------
    // 77. Cereal (Corn Flakes with Milk)
    // -------------------------------------------------------------
    FoodItem(
      id: 'food_cereal',
      name: 'Cereal (Corn Flakes with Milk)',
      servingSize: '1 bowl (150g)',
      servingUnit: 'bowl',
      calories: 190.0,
      protein: 6.5,
      carbohydrates: 35.0,
      fats: 2.5,
      isVegetarian: true,
      budgetCategory: 'Student Budget (₹)',
      regionalTags: [
        'Crunchy Breakfast',
        'Iron Fortified',
        'Instant Fuel',
        'Hostel Morning',
      ],
      mealCategories: [MealCategory.breakfast, MealCategory.snacks],
    ),

    // -------------------------------------------------------------
    // 78. Apple (Fresh Red Crisp Apple)
    // -------------------------------------------------------------
    FoodItem(
      id: 'food_apple',
      name: 'Apple (Fresh Red Crisp Apple)',
      servingSize: '1 medium apple (150g)',
      servingUnit: 'piece',
      calories: 78.0,
      protein: 0.4,
      carbohydrates: 20.0,
      fats: 0.3,
      isVegetarian: true,
      budgetCategory: 'Pocket Friendly (₹)',
      regionalTags: [
        'Dietary Fiber',
        'Antioxidants',
        'Clean Snack',
        'Pre Workout Fruit',
      ],
      mealCategories: [MealCategory.breakfast, MealCategory.snacks],
    ),

    // -------------------------------------------------------------
    // 79. Orange (Fresh Juicy Citrus Fruit / Santara)
    // -------------------------------------------------------------
    FoodItem(
      id: 'food_orange',
      name: 'Orange (Fresh Juicy Citrus Fruit / Santara)',
      servingSize: '1 medium orange (130g)',
      servingUnit: 'piece',
      calories: 62.0,
      protein: 1.2,
      carbohydrates: 15.0,
      fats: 0.2,
      isVegetarian: true,
      budgetCategory: 'Pocket Friendly (₹)',
      regionalTags: [
        'Vitamin C Bomb',
        'Immunity Shield',
        'Hydrating Citrus',
        'Hostel Fruit',
      ],
      mealCategories: [MealCategory.breakfast, MealCategory.snacks],
    ),

    // -------------------------------------------------------------
    // 80. Mango (Ripe Sweet Mango / Aam Slices)
    // -------------------------------------------------------------
    FoodItem(
      id: 'food_mango',
      name: 'Mango (Ripe Sweet Mango / Aam Slices)',
      servingSize: '1 cup sliced (150g)',
      servingUnit: 'piece',
      calories: 99.0,
      protein: 1.2,
      carbohydrates: 25.0,
      fats: 0.6,
      isVegetarian: true,
      budgetCategory: 'Pocket Friendly (₹)',
      regionalTags: [
        'King of Fruits',
        'Natural Sugar Fuel',
        'Summer Seasonal',
        'Rich Vitamin A',
      ],
      mealCategories: [MealCategory.breakfast, MealCategory.snacks],
    ),

    // -------------------------------------------------------------
    // 81. Papaya (Ripe Diced Papaya / Papita)
    // -------------------------------------------------------------
    FoodItem(
      id: 'food_papaya',
      name: 'Papaya (Ripe Diced Papaya / Papita)',
      servingSize: '1 bowl (150g)',
      servingUnit: 'bowl',
      calories: 60.0,
      protein: 0.9,
      carbohydrates: 15.0,
      fats: 0.3,
      isVegetarian: true,
      budgetCategory: 'Pocket Friendly (₹)',
      regionalTags: [
        'Digestive Enzyme Papain',
        'Low Calorie Snack',
        'Gut Healer',
        'Hostel Stall',
      ],
      mealCategories: [MealCategory.breakfast, MealCategory.snacks],
    ),

    // -------------------------------------------------------------
    // 82. Guava (Fresh Green Guava / Amrood)
    // -------------------------------------------------------------
    FoodItem(
      id: 'food_guava',
      name: 'Guava (Fresh Green Guava / Amrood)',
      servingSize: '1 medium guava (120g)',
      servingUnit: 'piece',
      calories: 82.0,
      protein: 3.1,
      carbohydrates: 17.0,
      fats: 1.2,
      isVegetarian: true,
      budgetCategory: 'Super Saver (₹)',
      regionalTags: [
        'Highest Vitamin C',
        'Massive Fiber',
        'Hostel Budget Fruit',
        'Desi Superfood',
      ],
      mealCategories: [MealCategory.breakfast, MealCategory.snacks],
    ),

    // -------------------------------------------------------------
    // 83. Watermelon (Chilled Diced Watermelon / Tarbooz)
    // -------------------------------------------------------------
    FoodItem(
      id: 'food_watermelon',
      name: 'Watermelon (Chilled Diced Watermelon / Tarbooz)',
      servingSize: '1 bowl (200g)',
      servingUnit: 'bowl',
      calories: 60.0,
      protein: 1.2,
      carbohydrates: 15.0,
      fats: 0.3,
      isVegetarian: true,
      budgetCategory: 'Hostel Staple (₹)',
      regionalTags: [
        'Ultra Hydration',
        'L-Citrulline Pump',
        'Summer Relief',
        'Low Calorie Fullness',
      ],
      mealCategories: [MealCategory.breakfast, MealCategory.snacks],
    ),

    // -------------------------------------------------------------
    // 84. Pineapple (Juicy Sliced Pineapple / Ananas)
    // -------------------------------------------------------------
    FoodItem(
      id: 'food_pineapple',
      name: 'Pineapple (Juicy Sliced Pineapple / Ananas)',
      servingSize: '1 bowl (150g)',
      servingUnit: 'bowl',
      calories: 75.0,
      protein: 0.8,
      carbohydrates: 19.5,
      fats: 0.2,
      isVegetarian: true,
      budgetCategory: 'Pocket Friendly (₹)',
      regionalTags: [
        'Bromelain Anti-inflammatory',
        'Post Workout Recovery',
        'Tropical Sweet',
        'Fruit Plate',
      ],
      mealCategories: [MealCategory.breakfast, MealCategory.snacks],
    ),

    // -------------------------------------------------------------
    // 85. Grapes (Fresh Green / Black Grapes / Angoor)
    // -------------------------------------------------------------
    FoodItem(
      id: 'food_grapes',
      name: 'Grapes (Fresh Green / Black Grapes / Angoor)',
      servingSize: '1 cup (100g)',
      servingUnit: 'cup',
      calories: 69.0,
      protein: 0.7,
      carbohydrates: 18.0,
      fats: 0.2,
      isVegetarian: true,
      budgetCategory: 'Pocket Friendly (₹)',
      regionalTags: [
        'Quick Glucose',
        'Resveratrol Boost',
        'Handful Snack',
        'Study Session',
      ],
      mealCategories: [MealCategory.breakfast, MealCategory.snacks],
    ),

    // -------------------------------------------------------------
    // 86. Pomegranate (Fresh Ruby Arils / Anaar)
    // -------------------------------------------------------------
    FoodItem(
      id: 'food_pomegranate',
      name: 'Pomegranate (Fresh Ruby Arils / Anaar)',
      servingSize: '1 bowl (100g)',
      servingUnit: 'bowl',
      calories: 83.0,
      protein: 1.7,
      carbohydrates: 19.0,
      fats: 1.2,
      isVegetarian: true,
      budgetCategory: 'Pocket Friendly (₹)',
      regionalTags: [
        'Blood Flow Nitrate',
        'Iron Support',
        'Potent Antioxidants',
        'Gym Fuel',
      ],
      mealCategories: [MealCategory.breakfast, MealCategory.snacks],
    ),

    // -------------------------------------------------------------
    // 87. Tender Coconut Water (Fresh Green Coconut Water)
    // -------------------------------------------------------------
    FoodItem(
      id: 'food_coconut',
      name: 'Tender Coconut Water (Fresh Green Coconut Water)',
      servingSize: '1 glass (200ml)',
      servingUnit: 'glass',
      calories: 45.0,
      protein: 1.5,
      carbohydrates: 9.0,
      fats: 0.5,
      isVegetarian: true,
      budgetCategory: 'Pocket Friendly (₹)',
      regionalTags: [
        'Natural Electrolytes',
        'Pure Hydration',
        'Potassium Power',
        'Post Training Recharge',
      ],
      mealCategories: [MealCategory.breakfast, MealCategory.snacks],
    ),

    // -------------------------------------------------------------
    // 88. Pear (Sweet Crisp Pear / Nashpati)
    // -------------------------------------------------------------
    FoodItem(
      id: 'food_pear',
      name: 'Pear (Sweet Crisp Pear / Nashpati)',
      servingSize: '1 medium pear (150g)',
      servingUnit: 'piece',
      calories: 85.0,
      protein: 0.6,
      carbohydrates: 22.0,
      fats: 0.2,
      isVegetarian: true,
      budgetCategory: 'Pocket Friendly (₹)',
      regionalTags: [
        'High Pectin Fiber',
        'Satiety Fruit',
        'Clean Energy',
        'Campus Snack',
      ],
      mealCategories: [MealCategory.breakfast, MealCategory.snacks],
    ),

    // -------------------------------------------------------------
    // 89. Roasted Chana (Crispy Bhuna Kala Chana)
    // -------------------------------------------------------------
    FoodItem(
      id: 'food_roasted_chana',
      name: 'Roasted Chana (Crispy Bhuna Kala Chana)',
      servingSize: '1 cup (50g)',
      servingUnit: 'cup',
      calories: 185.0,
      protein: 11.5,
      carbohydrates: 29.0,
      fats: 2.5,
      isVegetarian: true,
      budgetCategory: 'Super Saver (₹)',
      regionalTags: [
        'Desi Protein MVP',
        'Zero Cooking Snack',
        'Crunchy Filler',
        'Hostel Pocket God',
      ],
      mealCategories: [MealCategory.breakfast, MealCategory.snacks],
    ),

    // -------------------------------------------------------------
    // 90. Cashew Nuts (Raw / Roasted Kaju)
    // -------------------------------------------------------------
    FoodItem(
      id: 'food_cashews',
      name: 'Cashew Nuts (Raw / Roasted Kaju)',
      servingSize: '1 handful (30g)',
      servingUnit: 'serving',
      calories: 165.0,
      protein: 5.5,
      carbohydrates: 9.0,
      fats: 13.0,
      isVegetarian: true,
      budgetCategory: 'Premium (₹₹₹)',
      regionalTags: [
        'Healthy Fats',
        'Magnesium Rich',
        'Brain Booster',
        'Nutrient Dense',
      ],
      mealCategories: [MealCategory.breakfast, MealCategory.snacks],
    ),

    // -------------------------------------------------------------
    // 91. Almonds (Raw California Badam)
    // -------------------------------------------------------------
    FoodItem(
      id: 'food_almonds',
      name: 'Almonds (Raw California Badam)',
      servingSize: '1 handful (25g)',
      servingUnit: 'serving',
      calories: 145.0,
      protein: 5.3,
      carbohydrates: 5.5,
      fats: 12.5,
      isVegetarian: true,
      budgetCategory: 'Premium (₹₹₹)',
      regionalTags: [
        'Vitamin E Glow',
        'Lean Healthy Fats',
        'Hostel Brain Fuel',
        'Daily Soak',
      ],
      mealCategories: [MealCategory.breakfast, MealCategory.snacks],
    ),

    // -------------------------------------------------------------
    // 92. Walnuts (Brain Nut Halves / Akhrot)
    // -------------------------------------------------------------
    FoodItem(
      id: 'food_walnuts',
      name: 'Walnuts (Brain Nut Halves / Akhrot)',
      servingSize: '1 handful (25g)',
      servingUnit: 'serving',
      calories: 163.0,
      protein: 3.8,
      carbohydrates: 3.5,
      fats: 16.3,
      isVegetarian: true,
      budgetCategory: 'Premium (₹₹₹)',
      regionalTags: [
        'Plant Omega 3 ALA',
        'Cognitive Support',
        'Antioxidants',
        'Exam Stamina',
      ],
      mealCategories: [MealCategory.breakfast, MealCategory.snacks],
    ),

    // -------------------------------------------------------------
    // 93. Protein Bar (High Protein Fitness Bar)
    // -------------------------------------------------------------
    FoodItem(
      id: 'food_protein_bar',
      name: 'Protein Bar (High Protein Fitness Bar)',
      servingSize: '1 bar (50g)',
      servingUnit: 'bar',
      calories: 200.0,
      protein: 15.0,
      carbohydrates: 22.0,
      fats: 6.0,
      isVegetarian: true,
      budgetCategory: 'Premium (₹₹₹)',
      regionalTags: [
        'On-The-Go Protein',
        'Muscle Builder',
        'Convenient Snack',
        'Gym Essential',
      ],
      mealCategories: [MealCategory.snacks],
    ),

    // -------------------------------------------------------------
    // 94. Potato Chips (Crispy Salted Chips / Wafers)
    // -------------------------------------------------------------
    FoodItem(
      id: 'food_chips',
      name: 'Potato Chips (Crispy Salted Chips / Wafers)',
      servingSize: '1 packet (35g)',
      servingUnit: 'packet',
      calories: 185.0,
      protein: 2.0,
      carbohydrates: 18.5,
      fats: 11.5,
      isVegetarian: true,
      budgetCategory: 'Hostel Staple (₹)',
      regionalTags: [
        'Canteen Crunch',
        'Late Night Craving',
        'Salty Nibble',
        'Adda Snack',
      ],
      mealCategories: [MealCategory.snacks],
    ),

    // -------------------------------------------------------------
    // 95. Samosa (Spiced Potato Crispy Cone / Singara)
    // -------------------------------------------------------------
    FoodItem(
      id: 'food_samosa',
      name: 'Samosa (Spiced Potato Crispy Cone / Singara)',
      servingSize: '1 piece (70g)',
      servingUnit: 'piece',
      calories: 190.0,
      protein: 3.5,
      carbohydrates: 24.0,
      fats: 9.0,
      isVegetarian: true,
      budgetCategory: 'Hostel Staple (₹)',
      regionalTags: [
        'Tea Time King',
        'Campus Gate Stall',
        'Crispy Potato',
        'College Adda Hit',
      ],
      mealCategories: [MealCategory.breakfast, MealCategory.snacks],
    ),

    // -------------------------------------------------------------
    // 96. Pakora (Onion / Vegetable Crispy Fritters)
    // -------------------------------------------------------------
    FoodItem(
      id: 'food_pakora',
      name: 'Pakora (Onion / Vegetable Crispy Fritters)',
      servingSize: '1 plate (80g)',
      servingUnit: 'plate',
      calories: 220.0,
      protein: 4.5,
      carbohydrates: 20.0,
      fats: 14.0,
      isVegetarian: true,
      budgetCategory: 'Pocket Friendly (₹)',
      regionalTags: [
        'Rainy Day Classic',
        'Besan Fritters',
        'Chai Companion',
        'Hostel Canteen Hit',
      ],
      mealCategories: [MealCategory.snacks],
    ),

    // -------------------------------------------------------------
    // 97. Namkeen (Spiced Bhujia / Sev Mixture)
    // -------------------------------------------------------------
    FoodItem(
      id: 'food_namkeen',
      name: 'Namkeen (Spiced Bhujia / Sev Mixture)',
      servingSize: '1 cup (50g)',
      servingUnit: 'cup',
      calories: 275.0,
      protein: 5.0,
      carbohydrates: 24.0,
      fats: 18.0,
      isVegetarian: true,
      budgetCategory: 'Hostel Staple (₹)',
      regionalTags: [
        'Tea Time Crunch',
        'Besan Sev',
        'Roomate Sharing',
        'Salty Snack',
      ],
      mealCategories: [MealCategory.snacks],
    ),

    // -------------------------------------------------------------
    // 98. Popcorn (Salted Hot Buttered Popcorn)
    // -------------------------------------------------------------
    FoodItem(
      id: 'food_popcorn',
      name: 'Popcorn (Salted Hot Buttered Popcorn)',
      servingSize: '1 bowl (50g)',
      servingUnit: 'bowl',
      calories: 190.0,
      protein: 4.0,
      carbohydrates: 32.0,
      fats: 5.5,
      isVegetarian: true,
      budgetCategory: 'Pocket Friendly (₹)',
      regionalTags: [
        'Whole Grain Snack',
        'Movie Night Fuel',
        'Fiber Rich Fullness',
        'Low Density',
      ],
      mealCategories: [MealCategory.snacks],
    ),

    // -------------------------------------------------------------
    // 99. Tofu (Firm Soya Paneer Cubes)
    // -------------------------------------------------------------
    FoodItem(
      id: 'food_tofu',
      name: 'Tofu (Firm Soya Paneer Cubes)',
      servingSize: '100g raw cubes',
      servingUnit: '100g',
      calories: 85.0,
      protein: 9.5,
      carbohydrates: 2.0,
      fats: 4.8,
      isVegetarian: true,
      budgetCategory: 'Pocket Friendly (₹)',
      regionalTags: [
        'Plant Based Protein',
        'Zero Cholesterol',
        'Vegan Paneer',
        'Lean Muscle',
      ],
      mealCategories: [
        MealCategory.lunch,
        MealCategory.dinner,
        MealCategory.snacks,
      ],
    ),

    // -------------------------------------------------------------
    // 100. Peanut Butter (Roasted Crunchy / Smooth Spread)
    // -------------------------------------------------------------
    FoodItem(
      id: 'food_peanut_butter',
      name: 'Peanut Butter (Roasted Crunchy / Smooth Spread)',
      servingSize: '2 tbsp (32g)',
      servingUnit: 'spoon',
      calories: 190.0,
      protein: 8.0,
      carbohydrates: 7.0,
      fats: 16.0,
      isVegetarian: true,
      budgetCategory: 'Student Budget (₹)',
      regionalTags: [
        'Calorie Dense Fuel',
        'Student Bulking Cheat',
        'Plant Protein',
        'Toast Spread',
      ],
      mealCategories: [MealCategory.breakfast, MealCategory.snacks],
    ),

    // -------------------------------------------------------------
    // 101. Whey Protein Shake (1 Scoop in Water)
    // -------------------------------------------------------------
    FoodItem(
      id: 'food_whey_protein',
      name: 'Whey Protein Shake (1 Scoop in Water)',
      servingSize: '1 scoop (30g powder)',
      servingUnit: 'scoop',
      calories: 120.0,
      protein: 24.0,
      carbohydrates: 2.5,
      fats: 1.5,
      isVegetarian: true,
      budgetCategory: 'Premium (₹₹₹)',
      regionalTags: [
        'Fast Digesting',
        'Complete BCAA Profile',
        'Gym Athlete Fuel',
        'Post Workout Anabolic',
      ],
      mealCategories: [MealCategory.breakfast, MealCategory.snacks],
    ),
  ];

  static const List<BudgetAlternative> alternatives = [
    BudgetAlternative(
      originalFoodId: 'food_chicken',
      alternativeFoodId: 'food_soya',
      title: 'Desi Student Protein Hack',
      description: 'Swap Chicken (₹90/serving) for Soya Chunks (₹15/serving). You get 26g of pure plant protein at 80% lower cost.',
      estimatedSavings: 'Save ₹75 per meal',
      proteinComparison: '26g vs 31g protein (Matched macro density)',
      badgeText: '80% Cost Saver',
    ),
    BudgetAlternative(
      originalFoodId: 'food_fish',
      alternativeFoodId: 'food_eggs',
      title: 'Pocket-Friendly Protein Swap',
      description: 'Swap Freshwater Fish (₹80/serving) for 2 Boiled Eggs (₹14). High biological value protein that fits hostel pocket money.',
      estimatedSavings: 'Save ₹66 per meal',
      proteinComparison: '12.6g bioavailable protein for ₹14',
      badgeText: 'Smart Hostel Swap',
    ),
    BudgetAlternative(
      originalFoodId: 'food_rice',
      alternativeFoodId: 'food_ragi',
      title: 'Millet Mission Power Upgrade',
      description: 'Swap White Rice for Mandia (Ragi). Triple the calcium and micronutrients with a lower glycemic index at identical student budget.',
      estimatedSavings: 'Identical cost • 3x higher calcium',
      proteinComparison:
          '5.5g Mandia protein + complex sustained release energy',
      badgeText: 'Nutrition Upgrade',
    ),
    BudgetAlternative(
      originalFoodId: 'food_paneer',
      alternativeFoodId: 'food_soya',
      title: 'Hostel Vegetarian Protein Swap',
      description: 'Swap Canteen Paneer (₹80/serving) for Soya Chunks (₹15/serving). Soya delivers 26g of protein vs 16.5g in paneer with 90% less saturated fat at 80% lower cost.',
      estimatedSavings: 'Save ₹65 per meal',
      proteinComparison: '26g Soya vs 16.5g Paneer (More protein, less fat)',
      badgeText: 'Canteen Money Saver',
    ),
    BudgetAlternative(
      originalFoodId: 'food_paneer_raw',
      alternativeFoodId: 'food_sattu',
      title: 'Desi Sattu Energy Upgrade',
      description: 'Swap costly commercial protein snacks for Chhatua/Sattu Sharbat. High plant protein, dietary fiber, and natural cooling for hostel students.',
      estimatedSavings: 'Save ₹35 per serving',
      proteinComparison: '10.4g natural roasted gram protein for ₹10',
      badgeText: 'Desi Gold',
    ),
  ];

  /// Modular college-specific hostel/mess menus
  static const List<HostelMessMenu> hostelMenus = [
    // 1. GCEK Kalahandi Mess Menu
    HostelMessMenu(
      id: 'menu_gcek_hostel',
      college: 'GCEK Kalahandi',
      campus: 'Bhawanipatna Campus',
      messName: 'Main Hostel Boys/Girls Mess',
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
          'food_santula',
          'food_raita',
          'food_curd',
        ],
        MealCategory.snacks: [
          'food_alu_chop',
          'food_dahibara',
          'food_peanuts',
          'food_mudhi_mixture',
          'food_sattu',
          'food_banana',
        ],
        MealCategory.dinner: [
          'food_roti',
          'food_paratha',
          'food_dal',
          'food_mixed_tadka',
          'food_soya',
          'food_egg_curry',
          'food_mushroom_curry',
          'food_khichdi',
          'food_ice_cream',
        ],
      },
    ),
    // 2. ITER SOA University Mess Menu
    HostelMessMenu(
      id: 'menu_iter_hostel',
      college: 'ITER / SOA University',
      campus: 'Bhubaneswar Campus',
      messName: 'Campus 1 Central Hostel Mess',
      dailyFoodIds: {
        MealCategory.breakfast: [
          'food_idli_sambar',
          'food_poha',
          'food_paratha',
          'food_single_egg',
          'food_sprouts',
          'food_milk',
        ],
        MealCategory.lunch: [
          'food_rice',
          'food_dal',
          'food_biryani',
          'food_raita',
          'food_vegetables',
          'food_paneer',
          'food_fish',
          'food_curd',
        ],
        MealCategory.snacks: [
          'food_chana',
          'food_maggi',
          'food_peanuts',
          'food_milk',
        ],
        MealCategory.dinner: [
          'food_roti',
          'food_paratha',
          'food_dal',
          'food_egg_bhurji',
          'food_chicken',
          'food_paneer',
          'food_potato_curry',
          'food_ice_cream',
        ],
      },
    ),
  ];

  static List<FoodItem> getAllFoods() => List.unmodifiable(foods);

  static FoodItem? getFoodById(String id) {
    try {
      return foods.firstWhere((food) => food.id == id);
    } catch (_) {
      return null;
    }
  }

  static List<FoodItem> searchFoods(
    String query, {
    bool? vegetarianOnly,
    bool? highProteinOnly,
    MealCategory? category,
    String? regionalTag,
  }) {
    final cleanQuery = query.trim().toLowerCase();
    final cleanTag = regionalTag?.trim().toLowerCase();
    return foods.where((food) {
      if (vegetarianOnly == true && !food.isVegetarian) {
        return false;
      }
      if (highProteinOnly == true && food.protein < 10.0) {
        return false;
      }
      if (category != null && !food.mealCategories.contains(category)) {
        return false;
      }
      if (cleanTag != null &&
          cleanTag.isNotEmpty &&
          !food.regionalTags.any((t) => t.toLowerCase().contains(cleanTag))) {
        return false;
      }
      if (cleanQuery.isEmpty) {
        return true;
      }
      final matchesName = food.name.toLowerCase().contains(cleanQuery);
      final matchesTags = food.regionalTags.any(
        (tag) => tag.toLowerCase().contains(cleanQuery),
      );
      final matchesBudget = food.budgetCategory.toLowerCase().contains(
        cleanQuery,
      );
      final matchesServing = food.servingSize.toLowerCase().contains(
        cleanQuery,
      );
      final matchesUnit = food.servingUnit.toLowerCase().contains(cleanQuery);
      return matchesName ||
          matchesTags ||
          matchesBudget ||
          matchesServing ||
          matchesUnit;
    }).toList();
  }

  static BudgetAlternative? getAlternativeForFood(String foodId) {
    try {
      return alternatives.firstWhere((alt) => alt.originalFoodId == foodId);
    } catch (_) {
      return null;
    }
  }

  /// Returns all foods suitable for a given meal category
  static List<FoodItem> getFoodsForCategory(MealCategory category) {
    return foods.where((f) => f.mealCategories.contains(category)).toList();
  }

  /// Returns foods matching a specific regional/contextual tag
  static List<FoodItem> getFoodsByTag(String tag) {
    final cleanTag = tag.trim().toLowerCase();
    return foods
        .where(
          (f) => f.regionalTags.any((t) => t.toLowerCase().contains(cleanTag)),
        )
        .toList();
  }

  /// Returns all unique regional/contextual tags across the food database
  static List<String> getAllTags() {
    final set = <String>{};
    for (final food in foods) {
      set.addAll(food.regionalTags);
    }
    final list = set.toList();
    list.sort();
    return list;
  }

  /// Returns all unique serving units across the food database
  static List<String> getAllServingUnits() {
    final set = <String>{};
    for (final food in foods) {
      set.add(food.servingUnit);
    }
    final list = set.toList();
    list.sort();
    return list;
  }

  /// Finds hostel mess menu matching a student's college/institution
  static HostelMessMenu? getHostelMenuForCollege(
    String college, {
    String? campus,
  }) {
    final cleanCollege = college.trim().toLowerCase();
    final cleanCampus = campus?.trim().toLowerCase();
    try {
      return hostelMenus.firstWhere((menu) {
        final matchesCollege =
            menu.college.toLowerCase().contains(cleanCollege) ||
            cleanCollege.contains(menu.college.toLowerCase());
        final matchesCampus =
            cleanCampus == null ||
            cleanCampus.isEmpty ||
            menu.campus.toLowerCase().contains(cleanCampus) ||
            cleanCampus.contains(menu.campus.toLowerCase());
        return matchesCollege && matchesCampus;
      });
    } catch (_) {
      return null;
    }
  }

  /// Returns food items for a specific college's hostel mess menu for the requested category
  static List<FoodItem> getFoodsForHostelMenu(
    String college,
    MealCategory category, {
    String? campus,
  }) {
    final menu = getHostelMenuForCollege(college, campus: campus);
    if (menu == null) {
      return getFoodsForCategory(category);
    }
    final foodIds = menu.dailyFoodIds[category] ?? [];
    final result = <FoodItem>[];
    for (final id in foodIds) {
      final food = getFoodById(id);
      if (food != null) result.add(food);
    }
    return result.isNotEmpty ? result : getFoodsForCategory(category);
  }
}
