import 'meal_category.dart';

/// Represents a modular hostel/mess menu definition for a specific college campus.
class HostelMessMenu {
  final String id;
  final String college;
  final String campus;
  final String messName;
  final Map<MealCategory, List<String>> dailyFoodIds;
  final Map<String, Map<MealCategory, List<String>>>? weeklyScheduleFoodIds;

  const HostelMessMenu({
    required this.id,
    required this.college,
    required this.campus,
    required this.messName,
    required this.dailyFoodIds,
    this.weeklyScheduleFoodIds,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'college': college,
    'campus': campus,
    'messName': messName,
    'dailyFoodIds': dailyFoodIds.map((k, v) => MapEntry(k.name, v)),
    if (weeklyScheduleFoodIds != null)
      'weeklyScheduleFoodIds': weeklyScheduleFoodIds!.map(
        (day, catMap) =>
            MapEntry(day, catMap.map((cat, ids) => MapEntry(cat.name, ids))),
      ),
  };

  factory HostelMessMenu.fromJson(Map<String, dynamic> json) {
    final dailyRaw = json['dailyFoodIds'] as Map<String, dynamic>? ?? {};
    final dailyFoodIds = <MealCategory, List<String>>{};
    for (final entry in dailyRaw.entries) {
      final category = MealCategory.fromString(entry.key);
      if (entry.value is List) {
        dailyFoodIds[category] = (entry.value as List)
            .map((e) => e.toString())
            .toList();
      }
    }

    Map<String, Map<MealCategory, List<String>>>? weeklySchedule;
    if (json['weeklyScheduleFoodIds'] is Map) {
      weeklySchedule = {};
      final weeklyRaw = json['weeklyScheduleFoodIds'] as Map<String, dynamic>;
      for (final dayEntry in weeklyRaw.entries) {
        final catMap = <MealCategory, List<String>>{};
        if (dayEntry.value is Map) {
          final catRaw = dayEntry.value as Map<String, dynamic>;
          for (final cEntry in catRaw.entries) {
            final cat = MealCategory.fromString(cEntry.key);
            if (cEntry.value is List) {
              catMap[cat] = (cEntry.value as List)
                  .map((e) => e.toString())
                  .toList();
            }
          }
        }
        weeklySchedule[dayEntry.key] = catMap;
      }
    }

    return HostelMessMenu(
      id: json['id'] as String,
      college: json['college'] as String,
      campus: json['campus'] as String,
      messName: json['messName'] as String,
      dailyFoodIds: dailyFoodIds,
      weeklyScheduleFoodIds: weeklySchedule,
    );
  }
}
