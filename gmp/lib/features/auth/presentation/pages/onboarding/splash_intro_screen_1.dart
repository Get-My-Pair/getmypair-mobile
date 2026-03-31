import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../../core/utils/responsive.dart';
import 'onboarding_content.dart';

/// Screen 1 — centered “Welcome to” + “GetMyPair” (design: 234px-wide block, both lines centered).
class SplashIntroScreen1 extends StatelessWidget {
  const SplashIntroScreen1({super.key});

  static const double _designBlockWidth = 234;

  @override
  Widget build(BuildContext context) {
    final pad = Responsive.horizontalPaddingOf(context);
    final maxInner = OnboardingContent.maxContentWidth(context);
    final blockW = math.min(_designBlockWidth, maxInner);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: pad),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: blockW),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Welcome to',
                textAlign: TextAlign.center,
                style: OnboardingTypography.welcomeSubtitle(context),
              ),
              const SizedBox(height: 8),
              Text(
                'GetMyPair',
                textAlign: TextAlign.center,
                style: OnboardingTypography.welcomeTitle(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
