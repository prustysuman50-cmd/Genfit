import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';
import '../widgets/onboarding_selection_card.dart';

class MultiChoiceOption {
  final String value;
  final String title;
  final String description;
  final IconData icon;
  final String? badgeText;

  const MultiChoiceOption({
    required this.value,
    required this.title,
    required this.description,
    required this.icon,
    this.badgeText,
  });
}

class MultiChoiceStep extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<MultiChoiceOption> options;
  final List<String> selectedValues;
  final ValueChanged<List<String>> onSelectionChanged;
  final int minSelections;

  const MultiChoiceStep({
    super.key,
    required this.title,
    required this.subtitle,
    required this.options,
    required this.selectedValues,
    required this.onSelectionChanged,
    this.minSelections = 1,
  });

  void _handleToggle(String value) {
    final updated = List<String>.from(selectedValues);
    if (updated.contains(value)) {
      if (updated.length > minSelections) {
        updated.remove(value);
      }
    } else {
      updated.add(value);
    }
    onSelectionChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.displayMedium.copyWith(fontSize: 24),
          ),
          const SizedBox(height: 6),
          Text(subtitle, style: AppTextStyles.bodyMedium),
          const SizedBox(height: 20),
          ...options.map((option) {
            final isSelected = selectedValues.contains(option.value);
            return OnboardingSelectionCard(
              title: option.title,
              description: option.description,
              icon: option.icon,
              isSelected: isSelected,
              isMultiSelect: true,
              badgeText: option.badgeText,
              onTap: () => _handleToggle(option.value),
            );
          }),
        ],
      ),
    );
  }
}
