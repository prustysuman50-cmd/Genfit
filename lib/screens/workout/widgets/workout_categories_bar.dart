import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class WorkoutCategoriesBar extends StatelessWidget {
  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String> onSelectCategory;

  const WorkoutCategoriesBar({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onSelectCategory,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((cat) {
          final isSelected = cat == selectedCategory;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: isSelected,
              label: Text(cat),
              onSelected: (_) => onSelectCategory(cat),
              selectedColor: AppColors.primary,
              backgroundColor: AppColors.surfaceElevatedDark,
              checkmarkColor: Colors.black,
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? Colors.black : AppColors.textPrimaryDark,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.cardBorderDark,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
