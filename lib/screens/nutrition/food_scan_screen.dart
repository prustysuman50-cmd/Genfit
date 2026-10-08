import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/services/food_recognition_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/nutrition/food_recognition_result.dart';
import 'food_scan_review_screen.dart';

/// Screen for scanning or picking meal photos and reviewing AI recognition results.
///
/// Clean architecture:
/// FoodScanScreen -> FoodRecognitionService -> FoodRecognitionResult -> Review State
class FoodScanScreen extends StatefulWidget {
  final FoodRecognitionService? recognitionService;
  final ImagePicker? imagePicker;

  const FoodScanScreen({super.key, this.recognitionService, this.imagePicker});

  @override
  State<FoodScanScreen> createState() => _FoodScanScreenState();
}

class _FoodScanScreenState extends State<FoodScanScreen> {
  late final FoodRecognitionService _recognitionService;
  late final ImagePicker _imagePicker;

  XFile? _selectedImage;
  FoodRecognitionResult? _scanResult;
  bool _isAnalyzing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _recognitionService =
        widget.recognitionService ?? const FoodRecognitionService();
    _imagePicker = widget.imagePicker ?? ImagePicker();
  }

  Future<void> _pickImage(ImageSource source) async {
    setState(() {
      _errorMessage = null;
    });

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (image == null) return; // User cancelled

      setState(() {
        _selectedImage = image;
        _isAnalyzing = true;
        _scanResult = null;
      });

      // Analyze image via FoodRecognitionService
      final result = await _recognitionService.analyzeImage(image.path);

      if (!mounted) return;

      setState(() {
        _scanResult = result;
        _isAnalyzing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isAnalyzing = false;
        _errorMessage = 'Could not access image: $e';
      });
    }
  }

  void _resetScan() {
    setState(() {
      _selectedImage = null;
      _scanResult = null;
      _isAnalyzing = false;
      _errorMessage = null;
    });
  }

  void _onReviewMeal() {
    final result = _scanResult;
    if (result == null || !result.hasMatchedFoodItem) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            FoodScanReviewScreen(scanResult: result, imageFile: _selectedImage),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimaryDark,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'AI Food Scan',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimaryDark,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          if (_selectedImage != null)
            TextButton.icon(
              onPressed: _resetScan,
              icon: const Icon(
                Icons.refresh_rounded,
                size: 16,
                color: AppColors.primary,
              ),
              label: const Text(
                'Retake',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Screen subtitle explanation
              const Text(
                'Capture or select a meal photo to identify food items and calculate nutrition.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondaryDark,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),

              // Error banner if any
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.accentOrange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.accentOrange.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: AppColors.accentOrange,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.accentOrange,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Content: Empty State vs Analyzing vs Result State
              if (_selectedImage == null)
                _buildEmptyState()
              else if (_isAnalyzing)
                _buildAnalyzingState()
              else if (_scanResult != null)
                _buildResultState(_scanResult!),
            ],
          ),
        ),
      ),
    );
  }

  /// Empty state displayed before an image has been selected
  Widget _buildEmptyState() {
    return Column(
      children: [
        // Viewfinder Hero Placeholder Card
        Container(
          height: 280,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF14141E),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.25),
              width: 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Subtle background scan grid / gradient
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 0.8,
                    colors: [
                      AppColors.primary.withValues(alpha: 0.12),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),

              // Target reticle
              Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
              ),

              // Center icon and guidance
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.brightPurple],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera_enhance_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No Meal Selected',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimaryDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Take a picture of your plate or\nselect from your phone gallery',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textMutedDark,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),

        // Action Buttons: Scan with Camera & Choose from Gallery
        FilledButton.icon(
          onPressed: () => _pickImage(ImageSource.camera),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 4,
          ),
          icon: const Icon(Icons.camera_alt_rounded, size: 20),
          label: const Text(
            'Scan with Camera',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
        ),
        const SizedBox(height: 12),

        OutlinedButton.icon(
          onPressed: () => _pickImage(ImageSource.gallery),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textPrimaryDark,
            side: const BorderSide(color: AppColors.cardBorderDark, width: 1.2),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            backgroundColor: AppColors.surfaceDark,
          ),
          icon: const Icon(
            Icons.photo_library_rounded,
            color: AppColors.primary,
            size: 20,
          ),
          label: const Text(
            'Choose from Gallery',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  /// Analyzing/Loading indicator while vision recognition processes
  Widget _buildAnalyzingState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
      alignment: Alignment.center,
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const CircularProgressIndicator(
              strokeWidth: 3,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Analyzing meal photo...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimaryDark,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Matching against verified local food database',
            style: TextStyle(fontSize: 12, color: AppColors.textMutedDark),
          ),
        ],
      ),
    );
  }

  /// Scan result state displaying image preview, food detected, and review button
  Widget _buildResultState(FoodRecognitionResult result) {
    final food = result.matchedFoodItem;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Selected Image Preview Card
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Container(
            height: 220,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF14141E),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.cardBorderDark),
            ),
            child:
                _selectedImage != null &&
                    !kIsWeb &&
                    File(_selectedImage!.path).existsSync()
                ? Image.file(File(_selectedImage!.path), fit: BoxFit.cover)
                : Container(
                    color: const Color(0xFF1E1730),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.image_rounded,
                          size: 48,
                          color: AppColors.primary,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _selectedImage?.name ?? 'Captured Plate Image',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondaryDark,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 18),

        // 2. "Food Detected" Section Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF14141E),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.35),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row: Section title & Confidence Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.auto_awesome_rounded,
                          size: 16,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'FOOD DETECTED',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),

                  // AI Engine & Confidence Badge
                  Row(
                    children: [
                      if (result.isLiveAi) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            color: AppColors.brightPurple.withValues(
                              alpha: 0.2,
                            ),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: AppColors.brightPurple.withValues(
                                alpha: 0.5,
                              ),
                            ),
                          ),
                          child: const Text(
                            'GEMINI AI',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: AppColors.brightPurple,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ],
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.success.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.verified_rounded,
                              color: AppColors.success,
                              size: 13,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${result.confidencePercentage} Confidence',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: AppColors.success,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Detected Food Name
              Text(
                result.detectedLabel,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimaryDark,
                  letterSpacing: -0.4,
                ),
              ),

              // Multi-Item Plate Tray (e.g. Rice, Dal, Chicken Curry)
              if (result.detectedItems.length > 1) ...[
                const SizedBox(height: 12),
                const Text(
                  'PLATE ITEMS DETECTED',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                    color: AppColors.textMutedDark,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: result.detectedItems.map((item) {
                    final isSelected = item.label == result.detectedLabel;
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _scanResult = result.copyWithSelectedPrimary(item);
                        });
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withValues(alpha: 0.18)
                              : AppColors.surfaceElevatedDark,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.cardBorderDark,
                            width: isSelected ? 1.4 : 1.0,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isSelected) ...[
                              const Icon(
                                Icons.check_circle_rounded,
                                size: 12,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 4),
                            ],
                            Text(
                              item.label,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.textPrimaryDark,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              item.confidencePercentage,
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? AppColors.primary.withValues(alpha: 0.8)
                                    : AppColors.textMutedDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],

              if (food != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Standard serving: ${food.servingSize}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textMutedDark,
                  ),
                ),
                const SizedBox(height: 16),

                // Baseline Nutrition Grid (Strictly from verified LocalFoodDatabase)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevatedDark,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.cardBorderDark),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMacroBadge(
                        'Calories',
                        '${food.calories.toInt()} kcal',
                        AppColors.accentOrange,
                      ),
                      _buildMacroBadge(
                        'Protein',
                        '${food.protein.toStringAsFixed(1)}g',
                        AppColors.primary,
                      ),
                      _buildMacroBadge(
                        'Carbs',
                        '${food.carbohydrates.toStringAsFixed(1)}g',
                        AppColors.accentCyan,
                      ),
                      _buildMacroBadge(
                        'Fats',
                        '${food.fats.toStringAsFixed(1)}g',
                        const Color(0xFFE2E8F0),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 12),
              // Product rule disclosure note
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 14,
                    color: AppColors.textMutedDark,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'AI identifies the dish; verified database calculates baseline nutrition. You can adjust serving size and oil in the review step.',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: AppColors.textMutedDark.withValues(alpha: 0.9),
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // 3. "Review Meal" Action Button
        FilledButton.icon(
          onPressed: _onReviewMeal,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 4,
          ),
          icon: const Icon(Icons.arrow_forward_rounded, size: 20),
          label: const Text(
            'Review Meal',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMacroBadge(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.textMutedDark,
          ),
        ),
      ],
    );
  }
}
