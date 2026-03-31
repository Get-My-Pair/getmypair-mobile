import 'package:flutter/material.dart';

import 'onboarding_content.dart';

/// Screen 2 — lower third, centered: body + “truly fits!” (mint Boldonse).
class SplashIntroScreen2 extends StatelessWidget {
  const SplashIntroScreen2({super.key});

  @override
  Widget build(BuildContext context) {
    return OnboardingCopyPanel(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Scan your feet to find your perfect size and discover footwear that',
            textAlign: TextAlign.center,
            style: OnboardingTypography.scanIntroBody(context),
          ),
          const SizedBox(height: 8),
          Text(
            'truly fits!',
            textAlign: TextAlign.center,
            style: OnboardingTypography.scanIntroAccent(context),
          ),
        ],
      ),
    );
  }
}
