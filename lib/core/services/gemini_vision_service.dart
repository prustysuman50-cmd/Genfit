import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import '../../models/nutrition/food_recognition_result.dart';
import 'local_food_matcher.dart';

/// Service interfacing with Google Gemini Multimodal Vision API (e.g. Gemini 2.5 Flash / Flash-Lite)
/// to detect Indian hostel/mess foods from photos.
///
/// Local Development Configuration (NEVER hardcode or commit keys):
/// 1. Run flag: `flutter run --dart-define=GEMINI_API_KEY=YOUR_KEY`
/// 2. Config file: `flutter run --dart-define-from-file=secrets.json` (see secrets.example.json)
/// 3. In-app: Enter via Food Scan Screen Key dialog at runtime (stored in-memory only).
///
/// Optional model override:
/// - `--dart-define=GEMINI_MODEL=gemini-2.5-flash`
///
/// Security Architecture Note:
/// Client-side compile defines and environment values are embedded inside the compiled
/// client binary (.apk/.ipa) and are extractable via reverse-engineering. For a production
/// release, Gemini Vision API calls must be proxied through an authenticated backend server
/// that holds the API key secret and enforces per-user quotas.
///
/// Graceful Fallback:
/// If no API key is supplied, network is unavailable, or the API call fails, the service
/// returns `null` so [FoodRecognitionService] seamlessly uses the verified local food database.
class GeminiVisionService {
  final String apiKey;
  final String modelName;

  /// Optional runtime API key set dynamically by the user or testing environment.
  static String? runtimeApiKey;

  /// Last categorized diagnostic error (safe, never containing the API key).
  static String? lastApiError;

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

  /// Strips whitespace and accidental surrounding quotes from API keys.
  static String sanitizeApiKey(String raw) {
    var cleaned = raw.trim();
    if ((cleaned.startsWith('"') && cleaned.endsWith('"')) ||
        (cleaned.startsWith("'") && cleaned.endsWith("'"))) {
      if (cleaned.length >= 2) {
        cleaned = cleaned.substring(1, cleaned.length - 1).trim();
      }
    }
    return cleaned;
  }

  /// Removes any API keys or credentials from error strings to prevent leaking secrets.
  static String sanitizeErrorMessage(String error, [String? sensitiveToken]) {
    var sanitized = error;
    if (sensitiveToken != null && sensitiveToken.trim().isNotEmpty) {
      sanitized = sanitized.replaceAll(sensitiveToken.trim(), '[REDACTED_KEY]');
    }
    // Redact standard Google API Key pattern AIzaSy...
    sanitized = sanitized.replaceAll(
      RegExp(r'AIzaSy[0-9A-Za-z_-]{33}'),
      '[REDACTED_KEY]',
    );
    // Redact query parameter patterns like key=...
    sanitized = sanitized.replaceAll(
      RegExp(r'key=[0-9A-Za-z_%-]+'),
      'key=[REDACTED]',
    );
    return sanitized;
  }

  /// Classifies errors into clear, actionable human-readable messages.
  static String categorizeError(dynamic error, String model, [String? sensitiveToken]) {
    final raw = error.toString();
    final sanitized = sanitizeErrorMessage(raw, sensitiveToken);

    if (error is TimeoutException ||
        raw.contains('TimeoutException') ||
        raw.toLowerCase().contains('timed out') ||
        raw.toLowerCase().contains('timeout')) {
      return 'Network timeout: Gemini API took too long to respond. Please check your connection or select manually.';
    }

    if (raw.contains('401') ||
        raw.contains('403') ||
        raw.contains('API_KEY_INVALID') ||
        raw.contains('PERMISSION_DENIED') ||
        raw.toLowerCase().contains('api key not valid')) {
      return 'Invalid or unauthorized Gemini API key (HTTP 401/403). Please verify your API key.';
    }

    if (raw.contains('404') ||
        raw.contains('NOT_FOUND') ||
        (raw.contains('models/') && raw.contains('not found'))) {
      return "Gemini model '$model' not found or unsupported (HTTP 404). Please verify model name.";
    }

    if (raw.contains('429') ||
        raw.contains('RESOURCE_EXHAUSTED') ||
        raw.toLowerCase().contains('quota exceeded')) {
      return 'Gemini API rate limit or quota exceeded (HTTP 429). Please retry shortly.';
    }

    if (raw.contains('400') || raw.contains('INVALID_ARGUMENT')) {
      return 'Invalid Gemini API request (HTTP 400): $sanitized';
    }

    if (error is SocketException ||
        raw.contains('SocketException') ||
        raw.contains('Failed host lookup') ||
        raw.contains('Network is unreachable') ||
        raw.contains('Connection refused') ||
        raw.contains('HandshakeException') ||
        raw.contains('ClientException') ||
        raw.contains('HttpException')) {
      return 'Network error: Unable to connect to Gemini API. Please check your internet connection.';
    }

    return 'Gemini Vision API error: $sanitized';
  }

  /// Effective API key: prefers runtime key over compile-time environment define.
  String get effectiveApiKey {
    if (runtimeApiKey != null && runtimeApiKey!.trim().isNotEmpty) {
      return sanitizeApiKey(runtimeApiKey!);
    }
    return sanitizeApiKey(apiKey);
  }

  /// Whether an API key is configured for live Gemini Vision calls.
  bool get isConfigured => effectiveApiKey.isNotEmpty;

  /// Analyzes a food photo at [imagePath] with Gemini Multimodal Vision.
  ///
  /// Returns a structured [FoodRecognitionResult] with matched [LocalFoodDatabase]
  /// foods, or `null` if unconfigured / unavailable / failed.
  Future<FoodRecognitionResult?> analyzeImage(String imagePath) async {
    lastApiError = null;

    if (!isConfigured) {
      lastApiError = 'Gemini API key is not configured.';
      debugPrint('[FoodScan] $lastApiError');
      return null;
    }

    try {
      final file = File(imagePath);
      if (!file.existsSync()) {
        lastApiError = 'Image file not found at: $imagePath';
        debugPrint('[FoodScan] $lastApiError');
        return null;
      }

      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        lastApiError = 'Selected image is empty (0 bytes).';
        debugPrint('[FoodScan] $lastApiError');
        return null;
      }

      final lower = imagePath.toLowerCase();
      String mimeType;
      if (lower.endsWith('.png')) {
        mimeType = 'image/png';
      } else if (lower.endsWith('.webp')) {
        mimeType = 'image/webp';
      } else if (lower.endsWith('.heic') || lower.endsWith('.heif')) {
        mimeType = 'image/heic';
      } else {
        mimeType = 'image/jpeg';
      }

      debugPrint(
        '[FoodScan] Sending image to Gemini Vision (bytes: ${bytes.length}, mime: $mimeType, model: $modelName)...',
      );

      final model = GenerativeModel(model: modelName, apiKey: effectiveApiKey);

      const promptText = '''
You are an expert Indian nutrition and college hostel/mess food recognition vision AI.
Analyze this meal photo carefully.
Identify the food dishes visible on the plate, thali, or tray. Common Indian, Odia, and hostel foods include:
- Rice, Dal, Dalma, Pakhala, Khichdi, Biryani
- Roti, Chapati, Paratha, Poori, Naan
- Chicken Curry, Fish Curry, Egg Curry, Paneer Curry, Soya Chunks, Chana Masala, Rajma, Alu Dum, Mixed Veg Sabzi
- Breakfast / Snacks: Idli, Dosa, Poha, Upma, Maggi, Bread Omelette, Samosa, Pakora, Sattu, Curd / Dahi
- Fruits / Beverages: Banana, Apple, Tea / Chai, Coffee, Milk

Output strictly valid JSON with this exact structure and NO other text:
{
  "items": [
    {
      "name": "Food Name",
      "confidence": 0.95
    }
  ]
}

If no food or meal is visible in the photo, output:
{
  "items": []
}
''';

      final content = Content.multi([
        TextPart(promptText),
        DataPart(mimeType, bytes),
      ]);

      final response = await model
          .generateContent([content])
          .timeout(const Duration(seconds: 18));
      final rawText = response.text?.trim() ?? '';
      if (rawText.isEmpty) {
        lastApiError = 'Gemini API returned an empty response ($modelName).';
        debugPrint('[FoodScan] $lastApiError');
        return null;
      }

      debugPrint('[FoodScan] Gemini response received ($modelName), parsing...');
      final parsed = parseGeminiResponse(rawText, imagePath);
      if (parsed == null) {
        lastApiError ??= 'Could not parse food items from Gemini response.';
        debugPrint('[FoodScan] $lastApiError (rawText: $rawText)');
        return null;
      }
      return parsed;
    } catch (e) {
      final categorized = categorizeError(e, modelName, effectiveApiKey);
      lastApiError = categorized;
      debugPrint('[FoodScan] Gemini Vision API call failed ($modelName): $categorized');
      return null;
    }
  }

  /// Parses Gemini's JSON output and matches dishes with [LocalFoodMatcher].
  FoodRecognitionResult? parseGeminiResponse(
    String rawText,
    String imagePath,
  ) {
    try {
      // 1. Clean markdown code blocks if returned
      String sanitized = rawText.trim();
      if (sanitized.contains('```json')) {
        final parts = sanitized.split('```json');
        if (parts.length > 1) {
          sanitized = parts[1].split('```')[0].trim();
        }
      } else if (sanitized.contains('```')) {
        final parts = sanitized.split('```');
        if (parts.length > 1) {
          sanitized = parts[1].split('```')[0].trim();
        }
      }

      dynamic decoded;
      try {
        decoded = jsonDecode(sanitized);
      } catch (_) {
        // Fallback: extract outermost JSON object {...} or array [...]
        final startBrace = rawText.indexOf('{');
        final endBrace = rawText.lastIndexOf('}');
        final startBracket = rawText.indexOf('[');
        final endBracket = rawText.lastIndexOf(']');

        if (startBrace != -1 && endBrace != -1 && endBrace > startBrace) {
          try {
            decoded = jsonDecode(rawText.substring(startBrace, endBrace + 1));
          } catch (_) {}
        }
        if (decoded == null &&
            startBracket != -1 &&
            endBracket != -1 &&
            endBracket > startBracket) {
          try {
            decoded = jsonDecode(rawText.substring(startBracket, endBracket + 1));
          } catch (_) {}
        }
      }

      if (decoded == null) {
        lastApiError =
            'Could not parse food items from Gemini response: Invalid JSON syntax.';
        return null;
      }

      List<dynamic> itemsList = [];
      if (decoded is Map<String, dynamic>) {
        if (decoded['items'] is List) {
          itemsList = decoded['items'] as List<dynamic>;
        } else if (decoded['dishes'] is List) {
          itemsList = decoded['dishes'] as List<dynamic>;
        } else if (decoded['food'] is List) {
          itemsList = decoded['food'] as List<dynamic>;
        } else if (decoded.containsKey('name') || decoded.containsKey('label')) {
          itemsList = [decoded];
        }
      } else if (decoded is List) {
        itemsList = decoded;
      }

      if (itemsList.isEmpty) {
        lastApiError =
            'No food items detected in the image. Please select your meal from the database below.';
        return null;
      }

      final detectedItems = <DetectedPlateItem>[];

      for (final item in itemsList) {
        if (item is Map<String, dynamic>) {
          final name =
              (item['name'] ?? item['label'] ?? item['dish'] ?? '').toString().trim();
          if (name.isEmpty) continue;

          final confidence = (item['confidence'] as num?)?.toDouble() ?? 0.90;
          final matchedFood = LocalFoodMatcher.match(name);
          debugPrint(
            '[FoodScan] Parsed item "$name" -> Matched: ${matchedFood?.name ?? "NO LOCAL MATCH"}',
          );

          detectedItems.add(
            DetectedPlateItem(
              label: name,
              confidence: confidence,
              matchedFoodItem: matchedFood,
            ),
          );
        } else if (item is String && item.trim().isNotEmpty) {
          final matchedFood = LocalFoodMatcher.match(item.trim());
          debugPrint(
            '[FoodScan] Parsed string "$item" -> Matched: ${matchedFood?.name ?? "NO LOCAL MATCH"}',
          );
          detectedItems.add(
            DetectedPlateItem(
              label: item.trim(),
              confidence: 0.90,
              matchedFoodItem: matchedFood,
            ),
          );
        }
      }

      if (detectedItems.isEmpty) {
        lastApiError =
            'No valid food names found in response. Please select your meal manually.';
        return null;
      }

      // Select primary: prefer the first item with a verified local database match,
      // or fall back to the first detected item if none matched.
      final primary = detectedItems.firstWhere(
        (item) => item.matchedFoodItem != null,
        orElse: () => detectedItems.first,
      );

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
      lastApiError = 'Could not parse food items from Gemini response.';
      return null;
    }
  }
}
