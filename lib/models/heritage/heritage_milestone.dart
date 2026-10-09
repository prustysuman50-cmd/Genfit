/// Represents a culturally significant landmark/milestone along an Odisha Heritage Journey.
class HeritageMilestone {
  final String id;
  final String name;
  final String landmark;
  final String shortDescription;
  final double requiredDistanceKm;
  final int requiredSteps;
  final String visualIdentifier;
  final int rewardXp;
  final String? badgeId;
  final String? badgeName;
  final bool isUnlocked;
  final bool isCompleted;

  const HeritageMilestone({
    required this.id,
    required this.name,
    required this.landmark,
    required this.shortDescription,
    required this.requiredDistanceKm,
    required this.requiredSteps,
    this.visualIdentifier = 'monument',
    this.rewardXp = 50,
    this.badgeId,
    this.badgeName,
    this.isUnlocked = false,
    this.isCompleted = false,
  });

  /// Returns true if the user's virtual distance in km is >= milestone requirement.
  bool isReached(double distanceKm) => distanceKm >= requiredDistanceKm;

  HeritageMilestone copyWith({
    String? id,
    String? name,
    String? landmark,
    String? shortDescription,
    double? requiredDistanceKm,
    int? requiredSteps,
    String? visualIdentifier,
    int? rewardXp,
    String? badgeId,
    String? badgeName,
    bool? isUnlocked,
    bool? isCompleted,
  }) {
    return HeritageMilestone(
      id: id ?? this.id,
      name: name ?? this.name,
      landmark: landmark ?? this.landmark,
      shortDescription: shortDescription ?? this.shortDescription,
      requiredDistanceKm: requiredDistanceKm ?? this.requiredDistanceKm,
      requiredSteps: requiredSteps ?? this.requiredSteps,
      visualIdentifier: visualIdentifier ?? this.visualIdentifier,
      rewardXp: rewardXp ?? this.rewardXp,
      badgeId: badgeId ?? this.badgeId,
      badgeName: badgeName ?? this.badgeName,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'landmark': landmark,
    'shortDescription': shortDescription,
    'requiredDistanceKm': requiredDistanceKm,
    'requiredSteps': requiredSteps,
    'visualIdentifier': visualIdentifier,
    'rewardXp': rewardXp,
    'badgeId': badgeId,
    'badgeName': badgeName,
    'isUnlocked': isUnlocked,
    'isCompleted': isCompleted,
  };

  factory HeritageMilestone.fromJson(Map<String, dynamic> json) =>
      HeritageMilestone(
        id: json['id'] as String,
        name: json['name'] as String,
        landmark: json['landmark'] as String? ?? json['name'] as String,
        shortDescription: json['shortDescription'] as String? ?? '',
        requiredDistanceKm: (json['requiredDistanceKm'] as num).toDouble(),
        requiredSteps: (json['requiredSteps'] as num?)?.toInt() ?? 0,
        visualIdentifier: json['visualIdentifier'] as String? ?? 'monument',
        rewardXp: (json['rewardXp'] as num?)?.toInt() ?? 50,
        badgeId: json['badgeId'] as String?,
        badgeName: json['badgeName'] as String?,
        isUnlocked: json['isUnlocked'] as bool? ?? false,
        isCompleted: json['isCompleted'] as bool? ?? false,
      );

  @override
  String toString() =>
      'HeritageMilestone(id: $id, name: $name, requiredDistanceKm: $requiredDistanceKm, isCompleted: $isCompleted)';
}
