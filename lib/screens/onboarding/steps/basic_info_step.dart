import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class BasicInfoStep extends StatefulWidget {
  final int initialAge;
  final double initialHeightCm;
  final double initialWeightKg;
  final void Function(int age, double heightCm, double weightKg, bool isValid)
  onChanged;

  const BasicInfoStep({
    super.key,
    required this.initialAge,
    required this.initialHeightCm,
    required this.initialWeightKg,
    required this.onChanged,
  });

  @override
  State<BasicInfoStep> createState() => _BasicInfoStepState();
}

class _BasicInfoStepState extends State<BasicInfoStep> {
  late TextEditingController _ageController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;

  String? _ageError;
  String? _heightError;
  String? _weightError;

  @override
  void initState() {
    super.initState();
    _ageController = TextEditingController(text: widget.initialAge.toString());
    _heightController = TextEditingController(
      text: widget.initialHeightCm.toInt().toString(),
    );
    _weightController = TextEditingController(
      text: widget.initialWeightKg.toInt().toString(),
    );

    _validateAndNotify(fromInitState: true);
  }

  @override
  void dispose() {
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _validateAndNotify({bool fromInitState = false}) {
    final ageText = _ageController.text.trim();
    final heightText = _heightController.text.trim();
    final weightText = _weightController.text.trim();

    final age = int.tryParse(ageText);
    final height = double.tryParse(heightText);
    final weight = double.tryParse(weightText);

    bool isValid = true;

    // Age validation: 12 to 100
    if (age == null) {
      _ageError = 'Enter a valid age';
      isValid = false;
    } else if (age < 12 || age > 100) {
      _ageError = 'Age must be between 12 and 100';
      isValid = false;
    } else {
      _ageError = null;
    }

    // Height validation: 100 to 250 cm
    if (height == null) {
      _heightError = 'Enter height in cm';
      isValid = false;
    } else if (height < 100 || height > 250) {
      _heightError = 'Height must be between 100 and 250 cm';
      isValid = false;
    } else {
      _heightError = null;
    }

    // Weight validation: 30 to 250 kg
    if (weight == null) {
      _weightError = 'Enter weight in kg';
      isValid = false;
    } else if (weight < 30 || weight > 250) {
      _weightError = 'Weight must be between 30 and 250 kg';
      isValid = false;
    } else {
      _weightError = null;
    }

    if (fromInitState) {
      // In initState, initial errors are set on fields directly without setState.
      // Schedule parent notification after the current frame to prevent setState during build.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          widget.onChanged(
            age ?? widget.initialAge,
            height ?? widget.initialHeightCm,
            weight ?? widget.initialWeightKg,
            isValid,
          );
        }
      });
    } else {
      if (mounted) {
        setState(() {});
      }

      widget.onChanged(
        age ?? widget.initialAge,
        height ?? widget.initialHeightCm,
        weight ?? widget.initialWeightKg,
        isValid,
      );
    }
  }

  double _getBmi() {
    final height = double.tryParse(_heightController.text.trim()) ?? 0.0;
    final weight = double.tryParse(_weightController.text.trim()) ?? 0.0;
    if (height <= 0 || weight <= 0) return 0.0;
    final hMeters = height / 100.0;
    return weight / (hMeters * hMeters);
  }

  String _getBmiCategory(double bmi) {
    if (bmi <= 0) return 'Incomplete';
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25.0) return 'Normal Weight';
    if (bmi < 30.0) return 'Overweight';
    return 'Obese';
  }

  Color _getBmiColor(double bmi) {
    if (bmi <= 0) return AppColors.textMutedDark;
    if (bmi < 18.5) return AppColors.accentCyan;
    if (bmi < 25.0) return AppColors.primary;
    if (bmi < 30.0) return AppColors.accentOrange;
    return AppColors.accentRed;
  }

  void _adjustValue(
    TextEditingController controller,
    int delta,
    int min,
    int max,
  ) {
    final current = int.tryParse(controller.text.trim()) ?? min;
    final updated = (current + delta).clamp(min, max);
    controller.text = updated.toString();
    _validateAndNotify();
  }

  @override
  Widget build(BuildContext context) {
    final bmi = _getBmi();
    final bmiCategory = _getBmiCategory(bmi);
    final bmiColor = _getBmiColor(bmi);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'A bit about your body',
            style: AppTextStyles.displayMedium.copyWith(fontSize: 24),
          ),
          const SizedBox(height: 6),
          const Text(
            'We use your measurements to calibrate your daily burn rate and workout intensity.',
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: 24),

          // Age Input Field
          _buildNumericField(
            label: 'Age',
            controller: _ageController,
            unit: 'years',
            icon: Icons.cake_outlined,
            errorText: _ageError,
            onDecrement: () => _adjustValue(_ageController, -1, 12, 100),
            onIncrement: () => _adjustValue(_ageController, 1, 12, 100),
          ),
          const SizedBox(height: 16),

          // Height Input Field
          _buildNumericField(
            label: 'Height',
            controller: _heightController,
            unit: 'cm',
            icon: Icons.height_rounded,
            errorText: _heightError,
            onDecrement: () => _adjustValue(_heightController, -1, 100, 250),
            onIncrement: () => _adjustValue(_heightController, 1, 100, 250),
          ),
          const SizedBox(height: 16),

          // Weight Input Field
          _buildNumericField(
            label: 'Weight',
            controller: _weightController,
            unit: 'kg',
            icon: Icons.monitor_weight_outlined,
            errorText: _weightError,
            onDecrement: () => _adjustValue(_weightController, -1, 30, 250),
            onIncrement: () => _adjustValue(_weightController, 1, 30, 250),
          ),
          const SizedBox(height: 24),

          // Live BMI Card
          if (bmi > 0)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: bmiColor.withValues(alpha: 0.4),
                  width: 1.2,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: bmiColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.insights_rounded,
                      color: bmiColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'BMI ${bmi.toStringAsFixed(1)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimaryDark,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: bmiColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                bmiCategory,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: bmiColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          'Estimated based on your height and weight.',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textMutedDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNumericField({
    required String label,
    required TextEditingController controller,
    required String unit,
    required IconData icon,
    required String? errorText,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: errorText != null
              ? AppColors.accentRed
              : AppColors.cardBorderDark,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Text(label, style: AppTextStyles.titleSmall),
              const Spacer(),
              Text(
                '($unit)',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMutedDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Decrement button
              _buildStepperButton(icon: Icons.remove, onTap: onDecrement),
              const SizedBox(width: 12),
              // Text Field
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimaryDark,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (_) => _validateAndNotify(),
                ),
              ),
              const SizedBox(width: 12),
              // Increment button
              _buildStepperButton(icon: Icons.add, onTap: onIncrement),
            ],
          ),
          if (errorText != null) ...[
            const SizedBox(height: 8),
            Text(
              errorText,
              style: const TextStyle(
                color: AppColors.accentRed,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStepperButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.surfaceElevatedDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorderDark),
        ),
        child: Icon(icon, size: 18, color: AppColors.textPrimaryDark),
      ),
    );
  }
}
