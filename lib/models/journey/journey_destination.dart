/// Represents a landmark/milestone destination on the Odisha Fitness Journey.
class JourneyDestination {
  final String id;
  final String name;
  final String shortDescription;
  final double distanceKm;
  final double requiredProgress;
  final String visualIdentifier;
  final bool isUnlocked;
  final bool isCompleted;

  const JourneyDestination({
    required this.id,
    required this.name,
    required this.shortDescription,
    required this.distanceKm,
    required this.requiredProgress,
    this.visualIdentifier = 'monument',
    this.isUnlocked = false,
    this.isCompleted = false,
  });

  JourneyDestination copyWith({
    String? id,
    String? name,
    String? shortDescription,
    double? distanceKm,
    double? requiredProgress,
    String? visualIdentifier,
    bool? isUnlocked,
    bool? isCompleted,
  }) {
    return JourneyDestination(
      id: id ?? this.id,
      name: name ?? this.name,
      shortDescription: shortDescription ?? this.shortDescription,
      distanceKm: distanceKm ?? this.distanceKm,
      requiredProgress: requiredProgress ?? this.requiredProgress,
      visualIdentifier: visualIdentifier ?? this.visualIdentifier,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'shortDescription': shortDescription,
    'distanceKm': distanceKm,
    'requiredProgress': requiredProgress,
    'visualIdentifier': visualIdentifier,
    'isUnlocked': isUnlocked,
    'isCompleted': isCompleted,
  };

  factory JourneyDestination.fromJson(Map<String, dynamic> json) =>
      JourneyDestination(
        id: json['id'] as String,
        name: json['name'] as String,
        shortDescription: json['shortDescription'] as String,
        distanceKm: (json['distanceKm'] as num).toDouble(),
        requiredProgress: (json['requiredProgress'] as num).toDouble(),
        visualIdentifier: json['visualIdentifier'] as String? ?? 'monument',
        isUnlocked: json['isUnlocked'] as bool? ?? false,
        isCompleted: json['isCompleted'] as bool? ?? false,
      );

  @override
  String toString() =>
      'JourneyDestination(id: $id, name: $name, requiredProgress: $requiredProgress, isUnlocked: $isUnlocked, isCompleted: $isCompleted)';
}
