class BudgetAlternative {
  final String originalFoodId;
  final String alternativeFoodId;
  final String title;
  final String description;
  final String estimatedSavings;
  final String proteinComparison;
  final String badgeText;

  const BudgetAlternative({
    required this.originalFoodId,
    required this.alternativeFoodId,
    required this.title,
    required this.description,
    required this.estimatedSavings,
    required this.proteinComparison,
    this.badgeText = 'Budget Protein Hack',
  });

  Map<String, dynamic> toJson() => {
    'originalFoodId': originalFoodId,
    'alternativeFoodId': alternativeFoodId,
    'title': title,
    'description': description,
    'estimatedSavings': estimatedSavings,
    'proteinComparison': proteinComparison,
    'badgeText': badgeText,
  };

  factory BudgetAlternative.fromJson(Map<String, dynamic> json) =>
      BudgetAlternative(
        originalFoodId: json['originalFoodId'] as String,
        alternativeFoodId: json['alternativeFoodId'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        estimatedSavings: json['estimatedSavings'] as String,
        proteinComparison: json['proteinComparison'] as String,
        badgeText: (json['badgeText'] as String?) ?? 'Budget Protein Hack',
      );
}
