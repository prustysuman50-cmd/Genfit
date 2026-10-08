import '../../data/local_food_database.dart';
import '../../models/nutrition/food_recognition_result.dart';
import 'gemini_vision_service.dart';

/// Service responsible for recognizing foods from photos using Gemini Vision AI
/// and matching them against GenFit's verified local food database.
///
/// Architecture:
/// - Connects to Google Gemini Multimodal Vision API when configured with `--dart-define=GEMINI_API_KEY=...`.
/// - Gracefully falls back to local deterministic plate recognition when unconfigured or offline.
/// - Adheres strictly to the product rule: Vision AI identifies food dish names,
///   while GenFit's [LocalFoodDatabase] supplies verified nutrition values.
class FoodRecognitionService {
  /// Optional Gemini Vision client (configured via `--dart-define=GEMINI_API_KEY=...`).
  final GeminiVisionService geminiVisionService;

  /// Default primary food ID to match in local fallback mode.
  final String defaultMockFoodId;

  /// Default primary mock detected food label.
  final String defaultMockLabel;

  /// Default primary confidence score.
  final double defaultMockConfidence;

  /// Simulated inference delay for mock mode (zero in unit tests).
  final Duration simulatedDelay;

  const FoodRecognitionService({
    this.geminiVisionService = const GeminiVisionService(),
    this.defaultMockFoodId = 'food_chicken',
    this.defaultMockLabel = 'Chicken Curry',
    this.defaultMockConfidence = 0.91,
    this.simulatedDelay = const Duration(milliseconds: 350),
  });

  /// Analyzes a food photo located at [imagePath] and returns a [FoodRecognitionResult].
  Future<FoodRecognitionResult> analyzeImage(String imagePath) async {
    // 1. Attempt live Gemini Vision recognition if configured
    if (geminiVisionService.isConfigured) {
      final geminiResult = await geminiVisionService.analyzeImage(imagePath);
      if (geminiResult != null && geminiResult.detectedItems.isNotEmpty) {
        return geminiResult;
      }
    }

    // 2. Resilient local fallback engine (simulates multi-item thali plate: Chicken Curry, Rice, Dal)
    if (simulatedDelay > Duration.zero) {
      await Future.delayed(simulatedDelay);
    }

    final chickenFood = LocalFoodDatabase.getFoodById('food_chicken');
    final riceFood = LocalFoodDatabase.getFoodById('food_rice');
    final dalFood = LocalFoodDatabase.getFoodById('food_dal');

    final multiItems = <DetectedPlateItem>[
      DetectedPlateItem(
        label: 'Chicken Curry',
        confidence: defaultMockConfidence,
        matchedFoodItem: chickenFood,
      ),
      DetectedPlateItem(
        label: 'Rice',
        confidence: 0.91,
        matchedFoodItem: riceFood,
      ),
      DetectedPlateItem(
        label: 'Dal',
        confidence: 0.88,
        matchedFoodItem: dalFood,
      ),
    ];

    final primaryFood =
        LocalFoodDatabase.getFoodById(defaultMockFoodId) ?? chickenFood;

    return FoodRecognitionResult(
      detectedLabel: defaultMockLabel,
      confidence: defaultMockConfidence,
      matchedFoodItem: primaryFood,
      detectedItems: multiItems,
      candidateLabels: [defaultMockLabel, 'Rice', 'Dal'],
      imagePath: imagePath,
      analyzedAt: DateTime.now(),
      isLiveAi: false,
    );
  }
}
