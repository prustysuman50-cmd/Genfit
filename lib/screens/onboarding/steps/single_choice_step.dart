import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';
import '../widgets/onboarding_selection_card.dart';

class SingleChoiceOption {
  final String value;
  final String title;
  final String description;
  final IconData icon;
  final String? badgeText;

  const SingleChoiceOption({
    required this.value,
    required this.title,
    required this.description,
    required this.icon,
    this.badgeText,
  });
}

class SingleChoiceStep extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<SingleChoiceOption> options;
  final String selectedValue;
  final ValueChanged<String> onSelected;

  const SingleChoiceStep({
    super.key,
    required this.title,
    required this.subtitle,
    required this.options,
    required this.selectedValue,
    required this.onSelected,
  });

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
            final isSelected = selectedValue == option.value;
            return OnboardingSelectionCard(
              title: option.title,
              description: option.description,
              icon: option.icon,
              isSelected: isSelected,
              badgeText: option.badgeText,
              onTap: () => onSelected(option.value),
            );
          }),
        ],
      ),
    );
  }
}
