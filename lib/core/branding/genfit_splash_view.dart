import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'genfit_logo.dart';
import 'genfit_symbol.dart';
import 'genfit_wordmark.dart';

/// Minimal, premium branded opening experience for GenFit.
/// Features a subtle 450ms sports-brand reveal animation.
class GenfitSplashView extends StatefulWidget {
  final VoidCallback? onFinished;

  const GenfitSplashView({super.key, this.onFinished});

  @override
  State<GenfitSplashView> createState() => _GenfitSplashViewState();
}

class _GenfitSplashViewState extends State<GenfitSplashView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _symbolAnimation;
  late final Animation<double> _wordmarkOpacity;
  late final Animation<Offset> _wordmarkSlide;
  late final Animation<double> _taglineOpacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    // 0.0 to 0.6: Athlete + G symbol resolves into view
    _symbolAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.65, curve: Curves.easeOutCubic),
    );

    // 0.35 to 0.85: Wordmark slides up and fades in
    _wordmarkOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.35, 0.85, curve: Curves.easeOut),
    );
    _wordmarkSlide =
        Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.35, 0.85, curve: Curves.easeOutCubic),
          ),
        );

    // 0.6 to 1.0: Tagline fades in subtly
    _taglineOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.60, 1.0, curve: Curves.easeOut),
    );

    _controller.forward().then((_) {
      widget.onFinished?.call();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 1. Athlete + G Symbol with reveal
                Opacity(
                  opacity: _symbolAnimation.value,
                  child: GenfitSymbol(
                    size: 84,
                    animationProgress: _symbolAnimation.value,
                  ),
                ),
                const SizedBox(height: 20),

                // 2. GenFit Wordmark with subtle slide & fade
                SlideTransition(
                  position: _wordmarkSlide,
                  child: FadeTransition(
                    opacity: _wordmarkOpacity,
                    child: const GenfitWordmark(
                      fontSize: 36,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // 3. Official Tagline
                FadeTransition(
                  opacity: _taglineOpacity,
                  child: const Text(
                    GenfitLogo.officialTagline,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                      letterSpacing: 0.2,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
