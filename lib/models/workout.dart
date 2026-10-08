class Workout {
  final String id;
  final String title;
  final String category;
  final int durationMinutes;
  final int calories;
  final String intensity;
  final int exercisesCount;
  final String equipment;
  final List<String> tags;
  final bool isCompleted;

  const Workout({
    required this.id,
    required this.title,
    required this.category,
    required this.durationMinutes,
    required this.calories,
    required this.intensity,
    required this.exercisesCount,
    required this.equipment,
    required this.tags,
    this.isCompleted = false,
  });

  Workout copyWith({
    String? id,
    String? title,
    String? category,
    int? durationMinutes,
    int? calories,
    String? intensity,
    int? exercisesCount,
    String? equipment,
    List<String>? tags,
    bool? isCompleted,
  }) {
    return Workout(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      calories: calories ?? this.calories,
      intensity: intensity ?? this.intensity,
      exercisesCount: exercisesCount ?? this.exercisesCount,
      equipment: equipment ?? this.equipment,
      tags: tags ?? this.tags,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
