import 'package:flutter/material.dart';

import '../../../../core/theme/app_gradients.dart';

/// Subtle dot grid over the brand gradient (onboarding).
class OnboardingDotLayer extends StatelessWidget {
  const OnboardingDotLayer({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DotGridPainter(),
      size: Size.infinite,
    );
  }
}

class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const spacing = 14.0;
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.07);
    for (double x = 0; x < size.width + spacing; x += spacing) {
      for (double y = 0; y < size.height + spacing; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Full-screen gradient used by splash + onboarding flows.
class OnboardingGradientBackdrop extends StatelessWidget {
  const OnboardingGradientBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(gradient: AppGradients.heroVertical),
    );
  }
}

/// Large vertical watermark on the leading edge (screens 2–4).
class OnboardingBrandWatermark extends StatelessWidget {
  const OnboardingBrandWatermark({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Align(
        alignment: Alignment.centerLeft,
        child: Transform.translate(
          offset: const Offset(-28, 0),
          child: RotatedBox(
            quarterTurns: 3,
            child: Text(
              'GetMyPair',
              style: TextStyle(
                fontSize: 56,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                color: Colors.white.withValues(alpha: 0.07),
                height: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
