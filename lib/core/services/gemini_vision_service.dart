import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import '../../models/nutrition/food_recognition_result.dart';
import 'local_food_matcher.dart';

/// Service interfacing with Google Gemini Multimodal Vision API (e.g. Gemini 2.0 Flash / Flash-Lite)
/// to detect Indian hostel/mess foods from photos.
///
/// Configuration:
/// - Pass via `--dart-define=GEMINI_API_KEY=YOUR_KEY`
/// - Optional model override via `--dart-define=GEMINI_MODEL=gemini-3.5-flash-lite`
/// - If no API key is provided or if network calls fail, gracefully returns `null`
///   so [FoodRecognitionService] automatically uses the resilient local engine.
class GeminiVisionService {
  final String apiKey;
  final String modelName;

  const GeminiVisionService({
    this.apiKey = const String.fromEnvironment(
      'GEMINI_API_KEY',
      defaultValue: '',
    ),
    this.modelName = const String.fromEnvironment(
      'GEMINI_MODEL',
      defaultValue: 'gemini-3.5-flash-lite',
    ),
  });

  /// Whether an API key is configured for live Gemini Vision calls.
  bool get isConfigured => apiKey.trim().isNotEmpty;

  /// Analyzes a food photo at [imagePath] with Gemini Multimodal Vision.
  ///
  /// Returns a structured [FoodRecognitionResult] with matched [LocalFoodDatabase]
  /// foods, or `null` if unconfigured / unavailable / failed.
  Future<FoodRecognitionResult?> analyzeImage(String imagePath) async {
    if (!isConfigured) {
      debugPrint(
        '[GeminiVision] No GEMINI_API_KEY provided; falling back to local engine.',
      );
      return null;
    }

    try {
      final file = File(imagePath);
      if (!file.existsSync()) {
        debugPrint('[GeminiVision] Image file not found at: $imagePath');
        return null;
      }

      final bytes = await file.readAsBytes();
      final lower = imagePath.toLowerCase();
      final mimeType = lower.endsWith('.png') ? 'image/png' : 'image/jpeg';

      final model = GenerativeModel(model: modelName, apiKey: apiKey);

      const promptText = '''
You are an expert Indian nutrition and college hostel/mess food recognition vision AI.
Analyze this meal photo carefully.
Identify the food dishes visible on the plate or tray (e.g. Rice, Dal, Chicken Curry, Roti, Paneer, Egg Curry, Soya, Chana, Sabzi, Alu Dum, etc.).

Output strictly valid JSON with this exact structure and NO other text:
{
  "items": [
    {
      "name": "Food Name",
      "confidence": 0.95
    }
  ]
}
''';

      final content = Content.multi([
        TextPart(promptText),
        DataPart(mimeType, bytes),
      ]);

      final response = await model.generateContent([content]);
      final rawText = response.text?.trim() ?? '';
      if (rawText.isEmpty) {
        debugPrint('[GeminiVision] Empty response from Gemini API.');
        return null;
      }

      return _parseGeminiResponse(rawText, imagePath);
    } catch (e) {
      debugPrint('[GeminiVision] Vision API call failed: $e');
      return null;
    }
  }

  /// Parses Gemini's JSON output and matches dishes with [LocalFoodMatcher].
  FoodRecognitionResult? _parseGeminiResponse(
    String rawText,
    String imagePath,
  ) {
    try {
      // Clean markdown code blocks if returned
      String sanitized = rawText;
      if (sanitized.contains('```json')) {
        sanitized = sanitized.split('```json')[1].split('```')[0].trim();
      } else if (sanitized.contains('```')) {
        sanitized = sanitized.split('```')[1].split('```')[0].trim();
      }

      final dynamic decoded = jsonDecode(sanitized);
      List<dynamic> itemsList = [];
      if (decoded is Map<String, dynamic> && decoded['items'] is List) {
        itemsList = decoded['items'] as List<dynamic>;
      } else if (decoded is List) {
        itemsList = decoded;
      }

      if (itemsList.isEmpty) return null;

      final detectedItems = <DetectedPlateItem>[];

      for (final item in itemsList) {
        if (item is Map<String, dynamic>) {
          final name = (item['name'] ?? item['label'] ?? '').toString().trim();
          if (name.isEmpty) continue;

          final confidence = (item['confidence'] as num?)?.toDouble() ?? 0.90;
          final matchedFood = LocalFoodMatcher.match(name);

          detectedItems.add(
            DetectedPlateItem(
              label: name,
              confidence: confidence,
              matchedFoodItem: matchedFood,
            ),
          );
        } else if (item is String && item.trim().isNotEmpty) {
          final matchedFood = LocalFoodMatcher.match(item.trim());
          detectedItems.add(
            DetectedPlateItem(
              label: item.trim(),
              confidence: 0.90,
              matchedFoodItem: matchedFood,
            ),
          );
        }
      }

      if (detectedItems.isEmpty) return null;

      // Primary detected item is the highest confidence or first item
      final primary = detectedItems.first;

      return FoodRecognitionResult(
        detectedLabel: primary.label,
        confidence: primary.confidence,
        matchedFoodItem: primary.matchedFoodItem,
        detectedItems: detectedItems,
        candidateLabels: detectedItems.map((i) => i.label).toList(),
        imagePath: imagePath,
        analyzedAt: DateTime.now(),
        isLiveAi: true,
      );
    } catch (e) {
      debugPrint('[GeminiVision] Failed to parse response: $e\nRaw: $rawText');
      return null;
    }
  }
}
