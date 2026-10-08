/// Represents an explainable, rule-based adaptive recommendation.
class RecommendationItem {
  final String id;
  final String title;
  final String message;
  final String
  category; // 'Consistency', 'Workout', 'Nutrition', 'Journey', 'Streak'
  final String? actionLabel;
  final String
  iconIdentifier; // 'flame', 'fitness', 'nutrition', 'explore', 'star'
  final int priority; // 1 (highest) to 10 (lowest)

  const RecommendationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.category,
    this.actionLabel,
    this.iconIdentifier = 'star',
    this.priority = 5,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'message': message,
    'category': category,
    'actionLabel': actionLabel,
    'iconIdentifier': iconIdentifier,
    'priority': priority,
  };

  factory RecommendationItem.fromJson(Map<String, dynamic> json) =>
      RecommendationItem(
        id: json['id'] as String,
        title: json['title'] as String,
        message: json['message'] as String,
        category: json['category'] as String? ?? 'General',
        actionLabel: json['actionLabel'] as String?,
        iconIdentifier: json['iconIdentifier'] as String? ?? 'star',
        priority: (json['priority'] as num?)?.toInt() ?? 5,
      );

  RecommendationItem copyWith({
    String? id,
    String? title,
    String? message,
    String? category,
    String? actionLabel,
    String? iconIdentifier,
    int? priority,
  }) {
    return RecommendationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      category: category ?? this.category,
      actionLabel: actionLabel ?? this.actionLabel,
      iconIdentifier: iconIdentifier ?? this.iconIdentifier,
      priority: priority ?? this.priority,
    );
  }

  @override
  String toString() => 'RecommendationItem($category: "$title" - $message)';
}
