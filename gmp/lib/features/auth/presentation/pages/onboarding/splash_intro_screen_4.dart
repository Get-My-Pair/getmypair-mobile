import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import 'onboarding_content.dart';

/// Screen 4 — lifecycle + repair / maintain / donate / sell (same panel as 2–3).
class SplashIntroScreen4 extends StatelessWidget {
  const SplashIntroScreen4({super.key});

  @override
  Widget build(BuildContext context) {
    final stackStyle = OnboardingTypography.stackWord(
      context,
      color: AppColors.onboardingTrulyFits,
    );
    return OnboardingCopyPanel(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Extend the life of every pair',
            textAlign: TextAlign.start,
            style: OnboardingTypography.scanIntroBody(context),
          ),
          const SizedBox(height: 12),
          ...['repair', 'maintain', 'donate', 'sell!'].map(
            (w) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                w,
                textAlign: TextAlign.start,
                style: stackStyle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
