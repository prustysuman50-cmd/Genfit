import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/services/food_recognition_service.dart';
import '../../core/services/gemini_vision_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/local_food_database.dart';
import '../../models/nutrition/food_item.dart';
import '../../models/nutrition/food_recognition_result.dart';
import 'food_scan_review_screen.dart';

/// Screen for scanning or picking meal photos and reviewing AI recognition results.
///
/// Clean architecture:
/// FoodScanScreen -> FoodRecognitionService -> FoodRecognitionResult -> Review State
///
/// Resilient Design:
/// - Online: Gemini Vision analyzes photo and auto-detects visual dishes.
/// - Offline / Unavailable: Never forces Chicken Curry. Instead provides an honest,
///   interactive local database search & selector across all 101 verified Indian/mess foods.
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

  final TextEditingController _searchController = TextEditingController();
  FoodItem? _manuallySelectedFood;

  static final List<FoodItem> _popularStaples = [
    LocalFoodDatabase.getFoodById('food_rice'),
    LocalFoodDatabase.getFoodById('food_dal'),
    LocalFoodDatabase.getFoodById('food_dalma'),
    LocalFoodDatabase.getFoodById('food_pakhala'),
    LocalFoodDatabase.getFoodById('food_roti'),
    LocalFoodDatabase.getFoodById('food_eggs'),
    LocalFoodDatabase.getFoodById('food_paneer'),
    LocalFoodDatabase.getFoodById('food_chicken'),
    LocalFoodDatabase.getFoodById('food_soya'),
    LocalFoodDatabase.getFoodById('food_vegetables'),
    LocalFoodDatabase.getFoodById('food_maggi'),
    LocalFoodDatabase.getFoodById('food_poha'),
    LocalFoodDatabase.getFoodById('food_chana'),
    LocalFoodDatabase.getFoodById('food_dosa'),
    LocalFoodDatabase.getFoodById('food_idli'),
    LocalFoodDatabase.getFoodById('food_banana'),
  ].whereType<FoodItem>().toList();

  @override
  void initState() {
    super.initState();
    _recognitionService =
        widget.recognitionService ?? const FoodRecognitionService();
    _imagePicker = widget.imagePicker ?? ImagePicker();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
        _manuallySelectedFood = null;
        _searchController.clear();
      });

      // Analyze image via FoodRecognitionService
      final result = await _recognitionService.analyzeImage(image.path);

      if (!mounted) return;

      setState(() {
        _scanResult = result;
        _isAnalyzing = false;
        if (result.hasMatchedFoodItem) {
          _manuallySelectedFood = result.matchedFoodItem;
        } else if (_recognitionService.geminiVisionService.isConfigured &&
            result.isOfflineFallback) {
          _errorMessage = result.offlineReason;
        }
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
      _manuallySelectedFood = null;
      _searchController.clear();
      _isAnalyzing = false;
      _errorMessage = null;
    });
  }

  void _onReviewMeal() {
    final food = _manuallySelectedFood ?? _scanResult?.matchedFoodItem;
    if (food == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select a food item before proceeding to review.',
          ),
          backgroundColor: AppColors.accentOrange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final result = _scanResult;
    final reviewResult = FoodRecognitionResult(
      detectedLabel:
          result != null && result.isLiveAi ? result.detectedLabel : food.name,
      confidence: result != null && result.isLiveAi ? result.confidence : 1.0,
      matchedFoodItem: food,
      detectedItems:
          result != null && result.isLiveAi && result.detectedItems.isNotEmpty
              ? result.detectedItems
              : [
                DetectedPlateItem(
                  label: food.name,
                  confidence: 1.0,
                  matchedFoodItem: food,
                ),
              ],
      candidateLabels: result?.candidateLabels ?? [food.name],
      imagePath: _selectedImage?.path,
      analyzedAt: DateTime.now(),
      isLiveAi: result?.isLiveAi ?? false,
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => FoodScanReviewScreen(
              scanResult: reviewResult,
              imageFile: _selectedImage,
            ),
      ),
    );
  }

  void _showApiKeyDialog() {
    final controller = TextEditingController(
      text: GeminiVisionService.runtimeApiKey ?? '',
    );
    bool obscure = true;

    showDialog(
      context: context,
      builder:
          (dialogCtx) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  backgroundColor: const Color(0xFF14141E),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: const BorderSide(color: AppColors.cardBorderDark),
                  ),
                  title: const Row(
                    children: [
                      Icon(
                        Icons.key_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Gemini API Key',
                        style: TextStyle(
                          color: AppColors.textPrimaryDark,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Enter your Google Gemini API key to enable live camera photo recognition:',
                        style: TextStyle(
                          color: AppColors.textMutedDark,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: controller,
                        obscureText: obscure,
                        style: const TextStyle(
                          color: AppColors.textPrimaryDark,
                          fontSize: 13,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter Gemini API Key...',
                          hintStyle: const TextStyle(
                            color: AppColors.textMutedDark,
                            fontSize: 12,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscure
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                              color: AppColors.textMutedDark,
                              size: 18,
                            ),
                            onPressed: () {
                              setDialogState(() {
                                obscure = !obscure;
                              });
                            },
                          ),
                          filled: true,
                          fillColor: AppColors.surfaceElevatedDark,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.cardBorderDark,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogCtx).pop(),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: AppColors.textMutedDark),
                      ),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.black,
                      ),
                      onPressed: () {
                        final key = controller.text.trim();
                        Navigator.of(dialogCtx).pop();
                        if (key.isNotEmpty) {
                          GeminiVisionService.runtimeApiKey = key;
                          if (_selectedImage != null) {
                            _reanalyzeWithLiveKey(_selectedImage!.path);
                          } else {
                            setState(() {});
                          }
                        }
                      },
                      child: const Text(
                        'Save & Enable',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
          ),
    );
  }

  Future<void> _reanalyzeWithLiveKey(String path) async {
    setState(() {
      _isAnalyzing = true;
      _errorMessage = null;
    });
    try {
      final result = await _recognitionService.analyzeImage(path);
      if (!mounted) return;
      setState(() {
        _scanResult = result;
        _isAnalyzing = false;
        if (result.hasMatchedFoodItem) {
          _manuallySelectedFood = result.matchedFoodItem;
        } else if (_recognitionService.geminiVisionService.isConfigured &&
            result.isOfflineFallback) {
          _errorMessage = result.offlineReason;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isAnalyzing = false;
        _errorMessage = 'Scan error: $e';
      });
    }
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
          IconButton(
            icon: const Icon(
              Icons.key_rounded,
              size: 20,
              color: AppColors.primary,
            ),
            tooltip: _recognitionService.geminiVisionService.isConfigured
                ? 'Update Gemini API Key'
                : 'Configure Gemini API Key',
            onPressed: _showApiKeyDialog,
          ),
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

  /// Decides whether to render the auto-detected result or the offline food selector
  Widget _buildResultState(FoodRecognitionResult result) {
    if (result.hasMatchedFoodItem) {
      return _buildMatchedResultState(result);
    }
    return _buildOfflineFoodSelectionState(result);
  }

  /// Reusable selected image preview card
  Widget _buildImagePreviewCard() {
    return ClipRRect(
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
    );
  }

  /// State when an AI/mock dish is successfully matched
  Widget _buildMatchedResultState(FoodRecognitionResult result) {
    final food = _manuallySelectedFood ?? result.matchedFoodItem;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildImagePreviewCard(),
        const SizedBox(height: 18),

        // Food Detected Card
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

                  // Engine & Confidence Badge
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
                      ] else ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            color: AppColors.accentOrange.withValues(
                              alpha: 0.2,
                            ),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: AppColors.accentOrange.withValues(
                                alpha: 0.5,
                              ),
                            ),
                          ),
                          child: const Text(
                            'OFFLINE DEMO',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: AppColors.accentOrange,
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
                          color:
                              (result.isLiveAi
                                      ? AppColors.success
                                      : AppColors.accentOrange)
                                  .withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color:
                                (result.isLiveAi
                                        ? AppColors.success
                                        : AppColors.accentOrange)
                                    .withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              result.isLiveAi
                                  ? Icons.verified_rounded
                                  : Icons.science_outlined,
                              color:
                                  result.isLiveAi
                                      ? AppColors.success
                                      : AppColors.accentOrange,
                              size: 13,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${result.confidencePercentage} Confidence',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color:
                                    result.isLiveAi
                                        ? AppColors.success
                                        : AppColors.accentOrange,
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
                  children:
                      result.detectedItems.map((item) {
                        final isSelected = item.label == result.detectedLabel;
                        return InkWell(
                          onTap: () {
                            setState(() {
                              _scanResult = result.copyWithSelectedPrimary(
                                item,
                              );
                              _manuallySelectedFood = item.matchedFoodItem;
                            });
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  isSelected
                                      ? AppColors.primary.withValues(alpha: 0.18)
                                      : AppColors.surfaceElevatedDark,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color:
                                    isSelected
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
                                    color:
                                        isSelected
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
                                    color:
                                        isSelected
                                            ? AppColors.primary.withValues(
                                              alpha: 0.8,
                                            )
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
                const SizedBox(height: 12),
                Text(
                  'Standard serving: ${food.servingSize}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textMutedDark,
                  ),
                ),
                const SizedBox(height: 14),

                // Baseline Nutrition Grid
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
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Review Meal Action Button
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
        const SizedBox(height: 10),

        // Optional Manual Override
        OutlinedButton.icon(
          onPressed: () {
            setState(() {
              _manuallySelectedFood = null;
              _scanResult = FoodRecognitionResult.offline(
                imagePath: _selectedImage?.path,
                offlineReason: 'Select dish manually from verified database.',
              );
            });
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textSecondaryDark,
            side: const BorderSide(color: AppColors.cardBorderDark),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          icon: const Icon(
            Icons.swap_horiz_rounded,
            size: 18,
            color: AppColors.primary,
          ),
          label: const Text(
            'Wrong dish? Select from 101 foods',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  /// Offline / Unrecognized State: Search & select verified food from local database
  Widget _buildOfflineFoodSelectionState(FoodRecognitionResult result) {
    final query = _searchController.text.trim();
    final List<FoodItem> searchResults =
        query.isEmpty ? _popularStaples : LocalFoodDatabase.searchFoods(query);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildImagePreviewCard(),
        const SizedBox(height: 18),

        // Offline Selector Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF14141E),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.accentOrange.withValues(alpha: 0.35),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.accentOrange.withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Mode Badge + Set API Key button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: (result.isLiveAi
                                  ? AppColors.brightPurple
                                  : AppColors.accentOrange)
                              .withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          result.isLiveAi
                              ? Icons.search_rounded
                              : Icons.cloud_off_rounded,
                          size: 16,
                          color: result.isLiveAi
                              ? AppColors.brightPurple
                              : AppColors.accentOrange,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        result.isLiveAi ? 'MANUAL SELECTION' : 'OFFLINE MODE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                          color: result.isLiveAi
                              ? AppColors.brightPurple
                              : AppColors.accentOrange,
                        ),
                      ),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: _showApiKeyDialog,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(
                      Icons.key_rounded,
                      size: 14,
                      color: AppColors.primary,
                    ),
                    label: const Text(
                      'Set API Key',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              const Text(
                'Select Food from Verified Database',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimaryDark,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                result.isLiveAi && result.detectedLabel.isNotEmpty
                    ? 'AI detected "${result.detectedLabel}". Choose the matching item or search GenFit\'s 101 verified hostel foods:'
                    : 'Search or select your food from GenFit\'s 101 verified hostel items:',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMutedDark,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 14),

              // Search Input Field
              TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(
                  color: AppColors.textPrimaryDark,
                  fontSize: 13,
                ),
                decoration: InputDecoration(
                  hintText:
                      'Search food (e.g. Rice, Dalma, Pakhala, Roti, Eggs...)',
                  hintStyle: const TextStyle(
                    color: AppColors.textMutedDark,
                    fontSize: 12,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppColors.primary,
                    size: 18,
                  ),
                  suffixIcon:
                      _searchController.text.isNotEmpty
                          ? IconButton(
                            icon: const Icon(
                              Icons.clear_rounded,
                              size: 16,
                              color: AppColors.textMutedDark,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                          : null,
                  filled: true,
                  fillColor: AppColors.surfaceElevatedDark,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.cardBorderDark,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.cardBorderDark,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 1.2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Section Label
              Text(
                query.isEmpty
                    ? 'POPULAR HOSTEL STAPLES'
                    : 'SEARCH RESULTS (${searchResults.length})',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.6,
                  color: AppColors.textMutedDark,
                ),
              ),
              const SizedBox(height: 8),

              // Food Chips / Selector
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 180),
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        searchResults.take(18).map((foodItem) {
                          final isSelected =
                              _manuallySelectedFood?.id == foodItem.id;
                          return InkWell(
                            onTap: () {
                              setState(() {
                                _manuallySelectedFood = foodItem;
                              });
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    isSelected
                                        ? AppColors.primary.withValues(
                                          alpha: 0.22,
                                        )
                                        : AppColors.surfaceElevatedDark,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color:
                                      isSelected
                                          ? AppColors.primary
                                          : AppColors.cardBorderDark,
                                  width: isSelected ? 1.5 : 1.0,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isSelected) ...[
                                    const Icon(
                                      Icons.check_circle_rounded,
                                      size: 13,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 5),
                                  ],
                                  Text(
                                    foodItem.name.split('(').first.trim(),
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color:
                                          isSelected
                                              ? AppColors.primary
                                              : AppColors.textPrimaryDark,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${foodItem.calories.toInt()} kcal',
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      color:
                                          isSelected
                                              ? AppColors.primary.withValues(
                                                alpha: 0.8,
                                              )
                                              : AppColors.textMutedDark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                ),
              ),

              // Selected Food Nutrition Preview Card
              if (_manuallySelectedFood != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevatedDark,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              _manuallySelectedFood!.name,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimaryDark,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            _manuallySelectedFood!.servingSize,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textMutedDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildMacroBadge(
                            'Calories',
                            '${_manuallySelectedFood!.calories.toInt()} kcal',
                            AppColors.accentOrange,
                          ),
                          _buildMacroBadge(
                            'Protein',
                            '${_manuallySelectedFood!.protein.toStringAsFixed(1)}g',
                            AppColors.primary,
                          ),
                          _buildMacroBadge(
                            'Carbs',
                            '${_manuallySelectedFood!.carbohydrates.toStringAsFixed(1)}g',
                            AppColors.accentCyan,
                          ),
                          _buildMacroBadge(
                            'Fats',
                            '${_manuallySelectedFood!.fats.toStringAsFixed(1)}g',
                            const Color(0xFFE2E8F0),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Action Button: Review & Log Meal
        FilledButton.icon(
          onPressed: _manuallySelectedFood != null ? _onReviewMeal : null,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.black,
            disabledBackgroundColor: AppColors.surfaceElevatedDark,
            disabledForegroundColor: AppColors.textMutedDark,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 4,
          ),
          icon: const Icon(Icons.arrow_forward_rounded, size: 20),
          label: Text(
            _manuallySelectedFood != null
                ? 'Review & Log Meal'
                : 'Select a Food to Continue',
            style: const TextStyle(
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
