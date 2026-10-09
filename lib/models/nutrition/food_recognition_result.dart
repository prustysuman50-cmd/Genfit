import 'food_item.dart';

/// Single food item recognized on a plate or in a thali meal.
class DetectedPlateItem {
  /// Name of the dish detected by Vision AI (e.g. "Chicken Curry", "Rice", "Dal").
  final String label;

  /// Confidence score between 0.0 and 1.0.
  final double confidence;

  /// Matched verified food item from GenFit's local nutrition database.
  final FoodItem? matchedFoodItem;

  const DetectedPlateItem({
    required this.label,
    required this.confidence,
    required this.matchedFoodItem,
  });

  /// Whether a valid local food item was successfully matched.
  bool get hasMatchedFoodItem => matchedFoodItem != null;

  /// Confidence formatted as an integer percentage string (e.g. "94%").
  String get confidencePercentage => '${(confidence * 100).toInt()}%';
}

/// Structured result produced by food vision recognition (Gemini / AI).
///
/// Contains identified food metadata and matched references to [FoodItem]s
/// from GenFit's local nutrition database.
///
/// IMPORTANT: No nutritional values (calories, macros) are invented here.
/// All nutrition values are derived strictly from verified database entries.
class FoodRecognitionResult {
  /// The primary label identified by the vision recognition system.
  final String detectedLabel;

  /// Confidence score for the primary item between 0.0 and 1.0 (e.g. 0.94).
  final double confidence;

  /// Reference to the primary matched [FoodItem] in GenFit's local database.
  final FoodItem? matchedFoodItem;

  /// Backing list of items when explicitly provided.
  final List<DetectedPlateItem> _explicitDetectedItems;

  /// Candidate labels returned by the vision recognition model.
  final List<String> candidateLabels;

  /// Path of the analyzed image file.
  final String? imagePath;

  /// Timestamp when recognition occurred.
  final DateTime analyzedAt;

  /// Whether this result was produced by live Gemini AI (true) or local engine (false).
  final bool isLiveAi;

  /// Whether this result was generated because Gemini AI was offline/unconfigured/failed.
  final bool isOfflineFallback;

  /// Optional explanatory reason when operating in offline fallback mode.
  final String? offlineReason;

  const FoodRecognitionResult({
    required this.detectedLabel,
    required this.confidence,
    required this.matchedFoodItem,
    List<DetectedPlateItem> detectedItems = const [],
    this.candidateLabels = const [],
    this.imagePath,
    required this.analyzedAt,
    this.isLiveAi = false,
    this.isOfflineFallback = false,
    this.offlineReason,
  }) : _explicitDetectedItems = detectedItems;

  /// Creates an offline / unconfigured result with no arbitrary preselected food or confidence.
  FoodRecognitionResult.offline({
    this.imagePath,
    this.offlineReason = 'AI recognition unavailable (offline mode).',
    DateTime? analyzedAt,
  })  : detectedLabel = '',
        confidence = 0.0,
        matchedFoodItem = null,
        _explicitDetectedItems = const [],
        candidateLabels = const [],
        analyzedAt = analyzedAt ?? DateTime.now(),
        isLiveAi = false,
        isOfflineFallback = true;

  /// All distinct items identified on the plate/meal.
  List<DetectedPlateItem> get detectedItems => _explicitDetectedItems.isNotEmpty
      ? _explicitDetectedItems
      : (matchedFoodItem != null
            ? [
                DetectedPlateItem(
                  label: detectedLabel,
                  confidence: confidence,
                  matchedFoodItem: matchedFoodItem,
                ),
              ]
            : const []);

  /// Whether a valid local food item was successfully matched.
  bool get hasMatchedFoodItem => matchedFoodItem != null;

  /// Confidence formatted as an integer percentage string (e.g. "94%").
  String get confidencePercentage => '${(confidence * 100).toInt()}%';

  /// Returns a copy of this result with a new primary selected item.
  FoodRecognitionResult copyWithSelectedPrimary(DetectedPlateItem selected) {
    return FoodRecognitionResult(
      detectedLabel: selected.label,
      confidence: selected.confidence,
      matchedFoodItem: selected.matchedFoodItem,
      detectedItems: detectedItems,
      candidateLabels: candidateLabels,
      imagePath: imagePath,
      analyzedAt: analyzedAt,
      isLiveAi: isLiveAi,
      isOfflineFallback: isOfflineFallback,
      offlineReason: offlineReason,
    );
  }

  /// Returns a copy of this result updated with a user-selected manual [FoodItem].
  FoodRecognitionResult copyWithManualFood(FoodItem food) {
    return FoodRecognitionResult(
      detectedLabel: food.name,
      confidence: 1.0,
      matchedFoodItem: food,
      detectedItems: detectedItems.isNotEmpty
          ? detectedItems
          : [
              DetectedPlateItem(
                label: food.name,
                confidence: 1.0,
                matchedFoodItem: food,
              ),
            ],
      candidateLabels: candidateLabels,
      imagePath: imagePath,
      analyzedAt: analyzedAt,
      isLiveAi: isLiveAi,
      isOfflineFallback: isOfflineFallback,
      offlineReason: offlineReason,
    );
  }
}
