import 'package:flutter/material.dart';

/// Pill-shaped linear progress used in onboarding-style bottom bars.
class OnboardingBottomProgress extends StatelessWidget {
  const OnboardingBottomProgress({
    super.key,
    required this.currentIndex,
    required this.totalSteps,
  });

  final int currentIndex;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    final safeTotal = totalSteps <= 0 ? 1 : totalSteps;
    final progress = ((currentIndex + 1) / safeTotal).clamp(0.0, 1.0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: LinearProgressIndicator(
        value: progress,
        minHeight: 6,
        backgroundColor: const Color(0x4DDDE6E9),
        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFDDE6E9)),
      ),
    );
  }
}
