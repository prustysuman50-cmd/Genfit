import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/user_profile.dart';

class PersonalInfoStep extends StatefulWidget {
  final String initialName;
  final String initialCollege;
  final String initialCampus;
  final void Function(String name, String college, String campus, bool isValid)
  onChanged;

  const PersonalInfoStep({
    super.key,
    required this.initialName,
    required this.initialCollege,
    required this.initialCampus,
    required this.onChanged,
  });

  @override
  State<PersonalInfoStep> createState() => _PersonalInfoStepState();
}

class _PersonalInfoStepState extends State<PersonalInfoStep> {
  late final TextEditingController _nameController;
  late final TextEditingController _collegeController;
  late final TextEditingController _campusController;

  String? _nameError;
  String? _collegeError;
  bool _hasInteractedName = false;
  bool _hasInteractedCollege = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _collegeController = TextEditingController(text: widget.initialCollege);
    _campusController = TextEditingController(text: widget.initialCampus);

    _validateAndNotify(fromInitState: true);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _collegeController.dispose();
    _campusController.dispose();
    super.dispose();
  }

  void _validateAndNotify({bool fromInitState = false}) {
    final name = _nameController.text.trim();
    final college = _collegeController.text.trim();
    final campus = _campusController.text.trim();

    bool isValid = true;

    if (name.isEmpty) {
      if (_hasInteractedName || !fromInitState) {
        _nameError = 'Please enter your name';
      }
      isValid = false;
    } else {
      _nameError = null;
    }

    if (college.isEmpty) {
      if (_hasInteractedCollege || !fromInitState) {
        _collegeError = 'Please enter your college name';
      }
      isValid = false;
    } else {
      _collegeError = null;
    }

    if (fromInitState) {
      widget.onChanged(name, college, campus, isValid);
    } else {
      setState(() {});
      widget.onChanged(name, college, campus, isValid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentName = _nameController.text.trim();
    final currentCollege = _collegeController.text.trim();
    final currentCampus = _campusController.text.trim();

    final initials = currentName.isNotEmpty
        ? UserProfile.computeInitials(currentName)
        : 'GF';

    final locationPreview = currentCollege.isNotEmpty
        ? (currentCampus.isNotEmpty && !currentCollege.contains(currentCampus)
              ? '$currentCollege • $currentCampus'
              : currentCollege)
        : (currentCampus.isNotEmpty ? currentCampus : 'Your College • Campus');

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Student Identity',
            style: AppTextStyles.displayMedium.copyWith(fontSize: 24),
          ),
          const SizedBox(height: 6),
          const Text(
            'Enter your identity so we can personalize your workouts, leaderboard, and campus circle.',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondaryDark,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),

          // Live Student Identity Card Preview
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E293B), Color(0xFF131D31)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.35),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.primaryGradient,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentName.isNotEmpty ? currentName : 'Student Name',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: currentName.isNotEmpty
                              ? AppColors.textPrimaryDark
                              : AppColors.textMutedDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(
                            Icons.school_outlined,
                            size: 13,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              locationPreview,
                              style: TextStyle(
                                fontSize: 12,
                                color: currentCollege.isNotEmpty
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textMutedDark,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 1. Name Input Field
          _buildInputField(
            label: 'Full Name *',
            hintText: 'Enter your name',
            controller: _nameController,
            icon: Icons.person_outline_rounded,
            errorText: _nameError,
            onChanged: (val) {
              _hasInteractedName = true;
              _validateAndNotify();
            },
          ),
          const SizedBox(height: 16),

          // 2. College / Institution Input Field
          _buildInputField(
            label: 'College / University *',
            hintText: 'Enter your college',
            controller: _collegeController,
            icon: Icons.school_outlined,
            errorText: _collegeError,
            onChanged: (val) {
              _hasInteractedCollege = true;
              _validateAndNotify();
            },
          ),
          const SizedBox(height: 16),

          // 3. Campus Input Field (Optional)
          _buildInputField(
            label: 'Campus / Location (Optional)',
            hintText: 'Enter your campus',
            controller: _campusController,
            icon: Icons.location_on_outlined,
            errorText: null,
            helperText: 'If your college has a single campus, enter city or campus name',
            onChanged: (val) => _validateAndNotify(),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required String hintText,
    required TextEditingController controller,
    required IconData icon,
    required String? errorText,
    String? helperText,
    required ValueChanged<String> onChanged,
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
          width: errorText != null ? 1.2 : 0.8,
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
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            onChanged: onChanged,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimaryDark,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: const TextStyle(
                fontSize: 14,
                color: AppColors.textMutedDark,
              ),
              filled: true,
              fillColor: AppColors.surfaceElevatedDark.withValues(alpha: 0.5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              isDense: true,
            ),
          ),
          if (errorText != null) ...[
            const SizedBox(height: 6),
            Text(
              errorText,
              style: const TextStyle(
                color: AppColors.accentRed,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ] else if (helperText != null) ...[
            const SizedBox(height: 6),
            Text(
              helperText,
              style: const TextStyle(
                color: AppColors.textMutedDark,
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
