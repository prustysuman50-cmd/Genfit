import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/workout.dart';

class TodaysWorkoutCard extends StatefulWidget {
  final Workout workout;
  final VoidCallback onStart;

  const TodaysWorkoutCard({
    super.key,
    required this.workout,
    required this.onStart,
  });

  @override
  State<TodaysWorkoutCard> createState() => _TodaysWorkoutCardState();
}

class _TodaysWorkoutCardState extends State<TodaysWorkoutCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final workout = widget.workout;
    const progressPercent = 70; // 70% training progress

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: AppColors.purpleGlow.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // 1. Photographic Hero Background
            Positioned.fill(
              child: Image.asset(
                'assets/images/fitness/hero_workout.jpg',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF1C1A28), Color(0xFF09090D)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  );
                },
              ),
            ),

            // 2. Multi-layer Dark & Purple Gradient Overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF09090D).withValues(alpha: 0.88),
                      const Color(0xFF14141D).withValues(alpha: 0.82),
                      const Color(0xFF26184A).withValues(alpha: 0.65),
                      const Color(0xFF09090D).withValues(alpha: 0.94),
                    ],
                    stops: const [0.0, 0.45, 0.75, 1.0],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),

            // 3. Ambient Purple Radial Glow Accent
            Positioned(
              top: -40,
              right: -30,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.25),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 60,
                      spreadRadius: 20,
                    ),
                  ],
                ),
              ),
            ),

            // 4. Hero Content Layout
            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: Category kicker & Intensity pill
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.brightPurple.withValues(
                                alpha: 0.4,
                              ),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.bolt_rounded,
                                size: 13,
                                color: AppColors.brightPurple,
                              ),
                              SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  "Today's Workout",
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.brightPurple,
                                    letterSpacing: 0.5,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.cardBorderDark,
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          workout.intensity.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textSecondaryDark,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Middle Section: Workout Title & Large Circular Progress
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Workout Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              workout.title,
                              style: AppTextStyles.heroHeadline.copyWith(
                                fontSize: 24,
                                height: 1.2,
                                letterSpacing: -0.6,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${workout.category} • ${workout.equipment}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.softPurple,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tailored for hostel rooms • Zero equipment needed',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondaryDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Large Circular Progress Ring (e.g. 70%)
                      SizedBox(
                        width: 76,
                        height: 76,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 74,
                              height: 74,
                              child: CircularProgressIndicator(
                                value: progressPercent / 100,
                                strokeWidth: 7,
                                strokeCap: StrokeCap.round,
                                backgroundColor: AppColors.surfaceElevatedDark
                                    .withValues(alpha: 0.6),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  AppColors.brightPurple,
                                ),
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '$progressPercent%',
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.textPrimaryDark,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const Text(
                                  'DONE',
                                  style: TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.softPurple,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Telemetry Stats Row (responsive Wrap)
                  Wrap(
                    spacing: 14,
                    runSpacing: 6,
                    children: [
                      _buildTelemetryItem(
                        Icons.timer_outlined,
                        '${workout.durationMinutes} mins',
                      ),
                      _buildTelemetryItem(
                        Icons.fitness_center_rounded,
                        '${workout.exercisesCount} exercises',
                      ),
                      _buildTelemetryItem(
                        Icons.local_fire_department_rounded,
                        '${workout.calories} kcal',
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Prominent "Continue Workout" CTA with circular arrow button on right
                  GestureDetector(
                    onTapDown: (_) => setState(() => _isPressed = true),
                    onTapUp: (_) {
                      setState(() => _isPressed = false);
                      widget.onStart();
                    },
                    onTapCancel: () => setState(() => _isPressed = false),
                    child: AnimatedScale(
                      scale: _isPressed ? 0.98 : 1.0,
                      duration: const Duration(milliseconds: 100),
                      curve: Curves.easeInOut,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryGlow.withValues(
                                alpha: 0.45,
                              ),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Expanded(
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.play_arrow_rounded,
                                    size: 22,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Continue Workout',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        letterSpacing: 0.2,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.25),
                              ),
                              child: const Icon(
                                Icons.arrow_forward_rounded,
                                size: 18,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTelemetryItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.softPurple),
        const SizedBox(width: 5),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondaryDark,
          ),
        ),
      ],
    );
  }
}
