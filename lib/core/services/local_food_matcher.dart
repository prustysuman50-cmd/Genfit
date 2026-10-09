import '../../data/local_food_database.dart';
import '../../models/nutrition/food_item.dart';

/// Intelligent matcher connecting Gemini Vision AI dish names to verified
/// [FoodItem] records in GenFit's local Indian food database.
///
/// Principle:
/// - Vision AI identifies the visual dish names (e.g. "Rice", "Dal", "Maggi", "Chapati").
/// - LocalFoodMatcher bridges these labels to verified local database entries.
/// - GenFit's local food database remains the strict authority for nutrition data.
class LocalFoodMatcher {
  LocalFoodMatcher._();

  /// Canonical dictionary mapping common Indian/mess terms to local food IDs.
  static const Map<String, String> _aliasMap = {
    // -------------------------------------------------------------------------
    // 1. Rice & Indian Staples
    // -------------------------------------------------------------------------
    'rice': 'food_rice',
    'white rice': 'food_rice',
    'steamed rice': 'food_rice',
    'steamed white rice': 'food_rice',
    'boiled rice': 'food_rice',
    'cooked rice': 'food_rice',
    'plain rice': 'food_rice',
    'chawal': 'food_rice',
    'bhaat': 'food_rice',
    'basmati rice': 'food_rice',

    'dal': 'food_dal',
    'daal': 'food_dal',
    'dhal': 'food_dal',
    'toor dal': 'food_dal',
    'moong dal': 'food_dal',
    'yellow dal': 'food_dal',
    'yellow toor dal': 'food_dal',
    'dal fry': 'food_dal',
    'dal tadka': 'food_dal',
    'lentil': 'food_dal',
    'lentils': 'food_dal',
    'lentil soup': 'food_dal',

    'roti': 'food_roti',
    'rotis': 'food_roti',
    'chapati': 'food_roti',
    'chapatis': 'food_roti',
    'chapatti': 'food_roti',
    'phulka': 'food_roti',
    'fulka': 'food_roti',
    'wheat roti': 'food_roti',
    'whole wheat roti': 'food_roti',
    'tandoori roti': 'food_roti',
    'single roti': 'food_single_roti',
    '1 roti': 'food_single_roti',

    'paratha': 'food_paratha',
    'parathas': 'food_paratha',
    'plain paratha': 'food_paratha',
    'tawa paratha': 'food_paratha',

    'puri': 'food_puri',
    'puris': 'food_puri',
    'poori': 'food_puri',
    'poorais': 'food_puri',

    'naan': 'food_naan',
    'butter naan': 'food_naan',
    'plain naan': 'food_naan',
    'tandoori naan': 'food_naan',
    'garlic naan': 'food_naan',

    'idli': 'food_idli',
    'idlis': 'food_idli',
    'idly': 'food_idli',
    'idlies': 'food_idli',
    'steamed idli': 'food_idli',
    'idli sambar': 'food_idli_sambar',
    'idli with sambar': 'food_idli_sambar',
    'idli and sambar': 'food_idli_sambar',

    'dosa': 'food_dosa',
    'dosas': 'food_dosa',
    'plain dosa': 'food_dosa',
    'masala dosa': 'food_dosa',
    'crispy dosa': 'food_dosa',

    'sambar': 'food_sambar',
    'sambhar': 'food_sambar',

    'rasam': 'food_rasam',
    'saaru': 'food_rasam',
    'tomato rasam': 'food_rasam',

    'upma': 'food_upma',
    'suji upma': 'food_upma',
    'semolina upma': 'food_upma',
    'rava upma': 'food_upma',

    'poha': 'food_poha',
    'pohe': 'food_poha',
    'flattened rice': 'food_poha',
    'chuda upma': 'food_poha',
    'kanda poha': 'food_poha',

    'khichdi': 'food_khichdi',
    'khichri': 'food_khichdi',
    'dal khichdi': 'food_khichdi',
    'khechudi': 'food_khichdi',

    'rajma': 'food_rajma',
    'rajmah': 'food_rajma',
    'rajma curry': 'food_rajma',
    'rajma masala': 'food_rajma',
    'rajma chawal': 'food_rajma',
    'kidney beans': 'food_rajma',
    'red kidney beans': 'food_rajma',

    'chole': 'food_chole',
    'chhole': 'food_chole',
    'chole masala': 'food_chole',
    'chole bhature': 'food_chole',
    'chole chawal': 'food_chole',
    'punjabi chole': 'food_chole',

    'kadhi': 'food_kadhi',
    'kadhi pakora': 'food_kadhi',
    'kadhi chawal': 'food_kadhi',
    'karhi': 'food_kadhi',
    'punjabi kadhi': 'food_kadhi',
    'dahi kadhi': 'food_kadhi',

    // -------------------------------------------------------------------------
    // 2. Indian Meals & Curries
    // -------------------------------------------------------------------------
    'dalma': 'food_dalma',
    'odia dalma': 'food_dalma',

    'pakhala': 'food_pakhala',
    'dahi pakhala': 'food_pakhala',
    'fermented rice': 'food_pakhala',
    'water rice': 'food_pakhala',

    'potato curry': 'food_potato_curry',
    'potatoes curry': 'food_potato_curry',
    'aloo curry': 'food_potato_curry',
    'alu curry': 'food_potato_curry',
    'aloo tarkari': 'food_potato_curry',
    'alu dum': 'food_potato_curry',
    'aloo dum': 'food_potato_curry',
    'potato': 'food_potato_curry',
    'potatoes': 'food_potato_curry',
    'aloo': 'food_potato_curry',
    'alu': 'food_potato_curry',

    'aloo gobi': 'food_aloo_gobi',
    'alu gobi': 'food_aloo_gobi',
    'alugobi': 'food_aloo_gobi',
    'aloo gobhi': 'food_aloo_gobi',
    'potato cauliflower': 'food_aloo_gobi',

    'paneer': 'food_paneer',
    'paneer curry': 'food_paneer',
    'matar paneer': 'food_paneer',
    'mutter paneer': 'food_paneer',
    'paneer bhurji': 'food_paneer',
    'palak paneer': 'food_paneer',
    'shahi paneer': 'food_paneer',
    'kadai paneer': 'food_paneer',
    'cottage cheese': 'food_paneer',
    'raw paneer': 'food_paneer_raw',
    'paneer cubes': 'food_paneer_raw',
    'fresh paneer': 'food_paneer_raw',

    'chicken': 'food_chicken',
    'chicken curry': 'food_chicken',
    'desi chicken': 'food_chicken',
    'desi chicken curry': 'food_chicken',
    'hostel chicken curry': 'food_chicken',
    'chicken gravy': 'food_chicken',
    'murgh curry': 'food_chicken',
    'curry chicken': 'food_chicken',

    'chicken biryani': 'food_biryani',
    'chicken biriyani': 'food_biryani',
    'biryani': 'food_biryani',
    'biriyani': 'food_biryani',

    'veg biryani': 'food_veg_biryani',
    'vegetable biryani': 'food_veg_biryani',
    'veg biriyani': 'food_veg_biryani',

    'egg curry': 'food_egg_curry',
    'anda curry': 'food_egg_curry',
    'egg gravy': 'food_egg_curry',

    'fish': 'food_fish',
    'fish curry': 'food_fish',
    'machha': 'food_fish',
    'machha besara': 'food_fish',
    'rohu': 'food_fish',
    'rohu fish': 'food_fish',
    'fried fish': 'food_fish',

    'santula': 'food_santula',
    'odia santula': 'food_santula',

    'mushroom curry': 'food_mushroom_curry',
    'chhatu tarkari': 'food_mushroom_curry',

    'mixed tadka': 'food_mixed_tadka',
    'tadka': 'food_mixed_tadka',

    'sabzi': 'food_vegetables',
    'subzi': 'food_vegetables',
    'mixed sabzi': 'food_vegetables',
    'vegetables': 'food_vegetables',
    'mixed vegetables': 'food_vegetables',
    'bhaja': 'food_vegetables',
    'tarkari': 'food_vegetables',
    'veg curry': 'food_vegetables',
    'vegetable curry': 'food_vegetables',
    'mixed veg curry': 'food_vegetables',
    'mix veg curry': 'food_vegetables',
    'mixed vegetable curry': 'food_vegetables',
    'veg sabzi': 'food_vegetables',
    'vegetable sabzi': 'food_vegetables',
    'mix sabzi': 'food_vegetables',
    'mix veg': 'food_vegetables',
    'mixed veg': 'food_vegetables',
    'vegetable tarkari': 'food_vegetables',
    'veg tarkari': 'food_vegetables',

    'raita': 'food_raita',
    'boondi raita': 'food_raita',
    'cucumber raita': 'food_raita',

    'chutney': 'food_chutney',
    'coconut chutney': 'food_chutney',
    'green chutney': 'food_chutney',
    'tomato chutney': 'food_chutney',

    // -------------------------------------------------------------------------
    // 3. Hostel & College Foods
    // -------------------------------------------------------------------------
    'maggi': 'food_maggi',
    'maggi noodles': 'food_maggi',
    'maggie': 'food_maggi',
    'instant noodles': 'food_maggi',
    'masala maggi': 'food_maggi',
    'maggi noodle': 'food_maggi',

    'maggi with egg': 'food_egg_maggi',
    'egg maggi': 'food_egg_maggi',
    'egg maggie': 'food_egg_maggi',
    'maggi egg': 'food_egg_maggi',

    'bread omelette': 'food_bread_omelette',
    'bread omelet': 'food_bread_omelette',
    'bread omlet': 'food_bread_omelette',
    'bread amlet': 'food_bread_omelette',

    'egg bhurji': 'food_egg_bhurji',
    'anda bhurji': 'food_egg_bhurji',
    'scrambled eggs': 'food_egg_bhurji',
    'egg scramble': 'food_egg_bhurji',

    'egg': 'food_eggs',
    'eggs': 'food_eggs',
    'boiled egg': 'food_single_egg',
    'boiled eggs': 'food_eggs',
    'single egg': 'food_single_egg',
    '1 boiled egg': 'food_single_egg',
    '2 boiled eggs': 'food_eggs',
    'anda': 'food_eggs',

    'omelette': 'food_omelette',
    'omelet': 'food_omelette',
    'omlet': 'food_omelette',
    'plain omelette': 'food_omelette',
    'egg omelette': 'food_omelette',

    'tea': 'food_tea',
    'chai': 'food_tea',
    'milk tea': 'food_tea',
    'masala chai': 'food_tea',
    'tapri chai': 'food_tea',
    'hot tea': 'food_tea',

    'coffee': 'food_coffee',
    'milk coffee': 'food_coffee',
    'nescafe': 'food_coffee',
    'hot coffee': 'food_coffee',
    'instant coffee': 'food_coffee',
    'filter coffee': 'food_coffee',

    'milk': 'food_milk',
    'doodh': 'food_milk',
    'cow milk': 'food_milk',
    'glass of milk': 'food_milk',

    'curd': 'food_curd',
    'dahi': 'food_curd',
    'plain curd': 'food_curd',
    'plain dahi': 'food_curd',
    'yogurt': 'food_curd',
    'yoghurt': 'food_curd',

    'sattu': 'food_sattu',
    'sattu drink': 'food_sattu',
    'sattu sharbat': 'food_sattu',
    'chhatua': 'food_sattu',
    'chhatua drink': 'food_sattu',

    'banana shake': 'food_banana_shake',
    'banana smoothie': 'food_banana_shake',
    'banana milkshake': 'food_banana_shake',

    'bread': 'food_bread',
    'white bread': 'food_bread',
    'brown bread': 'food_bread',
    'bread slices': 'food_bread',
    'toast': 'food_bread',

    'jam': 'food_jam',
    'fruit jam': 'food_jam',
    'mixed fruit jam': 'food_jam',
    'kissan jam': 'food_jam',

    'butter': 'food_butter',
    'amul butter': 'food_butter',
    'table butter': 'food_butter',
    'makhan': 'food_butter',

    'biscuits': 'food_biscuits',
    'biscuit': 'food_biscuits',
    'cookies': 'food_biscuits',
    'parle g': 'food_biscuits',
    'marie gold': 'food_biscuits',
    'glucose biscuits': 'food_biscuits',

    // -------------------------------------------------------------------------
    // 4. Western & Fast Foods
    // -------------------------------------------------------------------------
    'pizza': 'food_pizza',
    'pizza slice': 'food_pizza',
    'veg pizza': 'food_pizza',
    'cheese pizza': 'food_pizza',

    'burger': 'food_burger',
    'veg burger': 'food_burger',
    'aloo tikki burger': 'food_burger',
    'hamburger': 'food_burger',

    'sandwich': 'food_sandwich',
    'veg sandwich': 'food_sandwich',
    'grilled sandwich': 'food_sandwich',
    'cheese sandwich': 'food_sandwich',
    'veg grilled sandwich': 'food_sandwich',

    'pasta': 'food_pasta',
    'red sauce pasta': 'food_pasta',
    'white sauce pasta': 'food_pasta',
    'macaroni': 'food_pasta',
    'penne pasta': 'food_pasta',

    'french fries': 'food_french_fries',
    'fries': 'food_french_fries',
    'finger chips': 'food_french_fries',
    'potato fries': 'food_french_fries',

    'noodles': 'food_noodles',
    'veg noodles': 'food_noodles',
    'hakka noodles': 'food_noodles',
    'chowmein': 'food_noodles',
    'chow mein': 'food_noodles',

    'fried rice': 'food_fried_rice',
    'veg fried rice': 'food_fried_rice',
    'chinese fried rice': 'food_fried_rice',

    'momos': 'food_momos',
    'momo': 'food_momos',
    'steamed momos': 'food_momos',
    'veg momos': 'food_momos',
    'dumplings': 'food_momos',

    'wrap': 'food_wrap',
    'kathi roll': 'food_wrap',
    'roll': 'food_wrap',
    'veg roll': 'food_wrap',
    'paneer roll': 'food_wrap',
    'frankie': 'food_wrap',

    'pancake': 'food_pancakes',
    'pancakes': 'food_pancakes',
    'hotcakes': 'food_pancakes',

    'oatmeal': 'food_oatmeal',
    'oats': 'food_oatmeal',
    'oat porridge': 'food_oatmeal',
    'rolled oats': 'food_oatmeal',

    'cereal': 'food_cereal',
    'corn flakes': 'food_cereal',
    'cornflakes': 'food_cereal',
    'muesli': 'food_cereal',

    // -------------------------------------------------------------------------
    // 5. Fruits
    // -------------------------------------------------------------------------
    'banana': 'food_banana',
    'bananas': 'food_banana',
    'kela': 'food_banana',
    'kadali': 'food_banana',
    'ripe banana': 'food_banana',

    'apple': 'food_apple',
    'apples': 'food_apple',
    'seb': 'food_apple',
    'red apple': 'food_apple',

    'orange': 'food_orange',
    'oranges': 'food_orange',
    'santara': 'food_orange',
    'mosambi': 'food_orange',
    'citrus': 'food_orange',

    'mango': 'food_mango',
    'mangoes': 'food_mango',
    'aam': 'food_mango',
    'ripe mango': 'food_mango',

    'papaya': 'food_papaya',
    'papita': 'food_papaya',

    'guava': 'food_guava',
    'amrood': 'food_guava',

    'watermelon': 'food_watermelon',
    'tarbooz': 'food_watermelon',
    'water melon': 'food_watermelon',

    'pineapple': 'food_pineapple',
    'ananas': 'food_pineapple',

    'grapes': 'food_grapes',
    'grape': 'food_grapes',
    'angoor': 'food_grapes',
    'black grapes': 'food_grapes',
    'green grapes': 'food_grapes',

    'pomegranate': 'food_pomegranate',
    'anaar': 'food_pomegranate',
    'anar': 'food_pomegranate',

    'coconut': 'food_coconut',
    'coconut water': 'food_coconut',
    'tender coconut': 'food_coconut',
    'nariyal pani': 'food_coconut',
    'daab': 'food_coconut',

    'pear': 'food_pear',
    'pears': 'food_pear',
    'nashpati': 'food_pear',

    // -------------------------------------------------------------------------
    // 6. Snacks
    // -------------------------------------------------------------------------
    'peanuts': 'food_peanuts',
    'peanut': 'food_peanuts',
    'groundnut': 'food_peanuts',
    'groundnuts': 'food_peanuts',
    'moongfali': 'food_peanuts',
    'mungfali': 'food_peanuts',
    'badam chinia': 'food_peanuts',

    'roasted chana': 'food_roasted_chana',
    'bhuna chana': 'food_roasted_chana',
    'roasted gram': 'food_roasted_chana',

    'cashews': 'food_cashews',
    'cashew': 'food_cashews',
    'kaju': 'food_cashews',
    'cashew nuts': 'food_cashews',

    'almonds': 'food_almonds',
    'almond': 'food_almonds',
    'badam': 'food_almonds',

    'walnuts': 'food_walnuts',
    'walnut': 'food_walnuts',
    'akhrot': 'food_walnuts',

    'protein bar': 'food_protein_bar',
    'granola bar': 'food_protein_bar',
    'energy bar': 'food_protein_bar',

    'chips': 'food_chips',
    'potato chips': 'food_chips',
    'lays': 'food_chips',
    'wafers': 'food_chips',

    'samosa': 'food_samosa',
    'samosas': 'food_samosa',
    'singara': 'food_samosa',
    'shingara': 'food_samosa',

    'pakora': 'food_pakora',
    'pakoda': 'food_pakora',
    'pakoras': 'food_pakora',
    'pakodas': 'food_pakora',
    'bhajiya': 'food_pakora',
    'onion pakora': 'food_pakora',
    'veg pakora': 'food_pakora',
    'fritters': 'food_pakora',

    'alu chop': 'food_alu_chop',
    'aloo chop': 'food_alu_chop',
    'potato cutlet': 'food_alu_chop',

    'namkeen': 'food_namkeen',
    'bhujia': 'food_namkeen',
    'sev': 'food_namkeen',
    'mixture': 'food_namkeen',
    'chanachur': 'food_namkeen',

    'popcorn': 'food_popcorn',
    'pop corn': 'food_popcorn',
    'buttered popcorn': 'food_popcorn',

    'mudhi': 'food_mudhi_mixture',
    'mudhi mixture': 'food_mudhi_mixture',

    'bara': 'food_bara',
    'vada': 'food_bara',
    'medu vada': 'food_bara',

    'dahibara': 'food_dahibara',
    'dahi vada': 'food_dahibara',
    'dahi bhalla': 'food_dahibara',

    'ice cream': 'food_ice_cream',
    'icecream': 'food_ice_cream',
    'vanilla ice cream': 'food_ice_cream',

    // -------------------------------------------------------------------------
    // 7. Protein & Common Nutrition Foods
    // -------------------------------------------------------------------------
    'tofu': 'food_tofu',
    'soya paneer': 'food_tofu',
    'bean curd': 'food_tofu',

    'soya': 'food_soya',
    'soya chunks': 'food_soya',
    'soya chunks curry': 'food_soya',
    'soya curry': 'food_soya',
    'soya badi': 'food_soya',
    'soya bean': 'food_soya',
    'nutrela': 'food_soya',

    'peanut butter': 'food_peanut_butter',
    'peanut butter spread': 'food_peanut_butter',
    'pb': 'food_peanut_butter',

    'whey': 'food_whey_protein',
    'whey protein': 'food_whey_protein',
    'protein shake': 'food_whey_protein',
    'whey shake': 'food_whey_protein',
    'whey protein shake': 'food_whey_protein',
    'protein powder': 'food_whey_protein',

    'chana': 'food_chana',
    'kala chana': 'food_chana',
    'boiled chana': 'food_chana',
    'black chickpeas': 'food_chana',
    'chickpeas': 'food_chana',
    'chickpea': 'food_chana',
    'bengal gram': 'food_chana',
    'ghugni': 'food_chana',

    'sprouts': 'food_sprouts',
    'moong sprouts': 'food_sprouts',
    'sprouted moong': 'food_sprouts',

    'ragi': 'food_ragi',
    'mandia': 'food_ragi',
    'millet': 'food_ragi',
    'ragi roti': 'food_ragi',
    'ragi porridge': 'food_ragi',

    'besan chilla': 'food_besan_chilla',
    'chilla': 'food_besan_chilla',
    'besan cheela': 'food_besan_chilla',

    'chakuli': 'food_chakuli_pitha',
    'chakuli pitha': 'food_chakuli_pitha',
  };

  /// Precomputed sorted list of alias entries ordered by key length descending
  /// so specific multi-word phrases (e.g. "maggi with egg", "bread omelette")
  /// match before shorter individual words (e.g. "egg", "bread").
  static final List<MapEntry<String, String>> _sortedAliasEntries = () {
    final list = _aliasMap.entries.toList();
    list.sort((a, b) => b.key.length.compareTo(a.key.length));
    return list;
  }();

  /// Generic food descriptors that must NOT resolve to a specific dish via substring or blind search.
  static const Set<String> _genericDescriptors = {
    'curry',
    'curries',
    'gravy',
    'gravies',
    'dish',
    'dishes',
    'food',
    'foods',
    'meal',
    'meals',
    'plate',
    'plates',
    'bowl',
    'bowls',
    'item',
    'items',
  };

  /// Matches a dish label (e.g., from Gemini Vision) to a verified [FoodItem].
  ///
  /// Returns `null` if no plausible match is found.
  static FoodItem? match(String rawLabel) {
    if (rawLabel.trim().isEmpty) return null;

    final clean = _normalize(rawLabel);

    // 1. Direct exact alias match
    if (_aliasMap.containsKey(clean)) {
      final foodId = _aliasMap[clean]!;
      final found = LocalFoodDatabase.getFoodById(foodId);
      if (found != null) return found;
    }

    // 2. Tokenized word-boundary alias match (longest, most specific match first)
    final paddedClean = ' $clean ';
    for (final entry in _sortedAliasEntries) {
      if (paddedClean.contains(' ${entry.key} ')) {
        final found = LocalFoodDatabase.getFoodById(entry.value);
        if (found != null) return found;
      }
    }

    // Never allow generic single-word descriptors (e.g., "curry", "gravy", "dish")
    // to map to the first database item (e.g. Chicken Curry) via broad substring or search.
    if (_genericDescriptors.contains(clean)) {
      return null;
    }

    // 3. Exact database name or component match
    for (final food in LocalFoodDatabase.foods) {
      final foodNameClean = _normalize(food.name);
      // Exact full name match
      if (clean == foodNameClean) {
        return food;
      }
      // Match primary name before parenthesis (e.g. "Chicken" from "Chicken (Desi Chicken Curry)")
      final primaryClean = _normalize(food.name.split('(').first);
      if (clean == primaryClean) {
        return food;
      }
      // Match names inside parenthesis (e.g. "Desi Chicken Curry")
      if (food.name.contains('(') && food.name.contains(')')) {
        final parenContent = food.name.split('(')[1].split(')')[0];
        for (final subPart in parenContent.split('/')) {
          if (clean == _normalize(subPart)) {
            return food;
          }
        }
      }
    }

    // 4. Substring containment ONLY for specific multi-word phrases (>= 2 words)
    // to avoid generic single words (like "curry", "soup", "stew", "boiled") from matching the first database item.
    final cleanWords = clean.split(' ').where((w) => w.isNotEmpty).toList();
    if (cleanWords.length >= 2) {
      for (final food in LocalFoodDatabase.foods) {
        final foodNameClean = _normalize(food.name);
        if (foodNameClean.contains(clean) || clean.contains(foodNameClean)) {
          return food;
        }
      }

      // 5. Fallback search query for multi-word non-generic queries
      final searchMatches = LocalFoodDatabase.searchFoods(clean);
      if (searchMatches.isNotEmpty) {
        return searchMatches.first;
      }
    }

    return null;
  }

  static String _normalize(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
