import 'package:flutter/foundation.dart';

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

  /// Optional mock food ID to match in explicit test simulation mode.
  final String? defaultMockFoodId;

  /// Optional mock detected food label in explicit test simulation mode.
  final String? defaultMockLabel;

  /// Default mock confidence score when mock simulation is explicitly active.
  final double defaultMockConfidence;

  /// Simulated inference delay for mock mode (zero in unit tests).
  final Duration simulatedDelay;

  /// Whether to enable mock thali simulation fallback (false by default for honest offline mode).
  final bool enableMockFallback;

  const FoodRecognitionService({
    this.geminiVisionService = const GeminiVisionService(),
    this.defaultMockFoodId,
    this.defaultMockLabel,
    this.defaultMockConfidence = 0.91,
    this.simulatedDelay = const Duration(milliseconds: 350),
    this.enableMockFallback = false,
  });

  /// Analyzes a food photo located at [imagePath] and returns a [FoodRecognitionResult].
  Future<FoodRecognitionResult> analyzeImage(String imagePath) async {
    debugPrint(
      '[FoodScan] analyzeImage called (path: $imagePath, geminiConfigured: ${geminiVisionService.isConfigured})',
    );

    // 1. Attempt live Gemini Vision recognition if configured
    if (geminiVisionService.isConfigured) {
      debugPrint('[FoodScan] Invoking Gemini Vision service...');
      final geminiResult = await geminiVisionService.analyzeImage(imagePath);
      if (geminiResult != null && geminiResult.detectedItems.isNotEmpty) {
        debugPrint(
          '[FoodScan] Live Gemini scan succeeded: ${geminiResult.detectedLabel} '
          '(items: ${geminiResult.detectedItems.map((e) => e.label).join(", ")})',
        );
        return geminiResult;
      }
      debugPrint(
        '[FoodScan] Gemini Vision returned null or empty items; switching to offline fallback.',
      );
    } else {
      debugPrint(
        '[FoodScan] Gemini not configured; switching to offline fallback.',
      );
    }

    if (simulatedDelay > Duration.zero) {
      await Future.delayed(simulatedDelay);
    }

    // 2. If mock fallback is explicitly enabled (e.g. in targeted mock unit tests), return simulated thali
    if (enableMockFallback || defaultMockFoodId != null) {
      final mockId = defaultMockFoodId ?? 'food_chicken';
      final mockLabel = defaultMockLabel ?? 'Chicken Curry';
      final primaryFood =
          LocalFoodDatabase.getFoodById(mockId) ??
          LocalFoodDatabase.getFoodById('food_chicken')!;
      final riceFood = LocalFoodDatabase.getFoodById('food_rice');
      final dalFood = LocalFoodDatabase.getFoodById('food_dal');

      final multiItems = <DetectedPlateItem>[
        DetectedPlateItem(
          label: mockLabel,
          confidence: defaultMockConfidence,
          matchedFoodItem: primaryFood,
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

      return FoodRecognitionResult(
        detectedLabel: mockLabel,
        confidence: defaultMockConfidence,
        matchedFoodItem: primaryFood,
        detectedItems: multiItems,
        candidateLabels: [mockLabel, 'Rice', 'Dal'],
        imagePath: imagePath,
        analyzedAt: DateTime.now(),
        isLiveAi: false,
        isOfflineFallback: true,
      );
    }

    // 3. Default production behavior: Honest offline result with NO hardcoded food item
    return FoodRecognitionResult.offline(
      imagePath: imagePath,
      offlineReason: geminiVisionService.isConfigured
          ? (GeminiVisionService.lastApiError ??
              'Live AI recognition unavailable (network error or empty response).')
          : 'Gemini AI not configured (offline mode).',
    );
  }
}
