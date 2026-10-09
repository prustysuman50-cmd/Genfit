import 'package:flutter/material.dart';

import '../../../core/services/weekly_quest_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import 'weekly_quest_board_card.dart';

/// Modal bottom sheet presenting the Weekly Quest Board.
///
/// Features:
/// - Polished bottom modal with top drag handle and close button.
/// - Renders [WeeklyQuestBoardCard] with real-time ISO-week progress.
/// - Strictly read-only: opening and dismissing leaves all state and XP unchanged.
class WeeklyQuestBoardSheet extends StatelessWidget {
  final WeeklyQuestService? questService;

  const WeeklyQuestBoardSheet({super.key, this.questService});

  /// Presents the Weekly Quest Board modal bottom sheet.
  static Future<void> show(
    BuildContext context, {
    WeeklyQuestService? questService,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => WeeklyQuestBoardSheet(
        questService: questService,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: AppColors.backgroundDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        border: Border(
          top: BorderSide(
            color: AppColors.cardBorderDark,
            width: 1.2,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. Drag Handle & Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 16, 8),
              child: Column(
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.cardBorderDark,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Weekly Quests',
                        style: AppTextStyles.titleLarge.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: AppColors.textSecondaryDark,
                          size: 22,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                        tooltip: 'Close',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(color: AppColors.cardBorderDark, height: 1),

            // 2. Scrollable Weekly Quest Board
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: WeeklyQuestBoardCard(questService: questService),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
