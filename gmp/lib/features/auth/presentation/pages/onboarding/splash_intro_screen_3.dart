import 'package:flutter/material.dart';

import 'onboarding_content.dart';

/// Screen 3 — same layout as screen 2: lower third, centered.
class SplashIntroScreen3 extends StatelessWidget {
  const SplashIntroScreen3({super.key});

  @override
  Widget build(BuildContext context) {
    return OnboardingCopyPanel(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            'Try your footwear',
            textAlign: TextAlign.end,
            style: OnboardingTypography.scanIntroBody(context),
          ),
          const SizedBox(height: 8),
          Text(
            'virtually!',
            textAlign: TextAlign.center,
            style: OnboardingTypography.scanIntroAccent(context),
          ),
        ],
      ),
    );
  }
}
