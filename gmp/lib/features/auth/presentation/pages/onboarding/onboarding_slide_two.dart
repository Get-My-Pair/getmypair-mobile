import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Onboarding screen 2 — “Never Guess Your Size Again” with AI KIX graphic ([sc2.png]).
///
/// Layout from Figma export frame **430×932** (positions scaled to the slide bounds).
class OnboardingSlideTwo extends StatelessWidget {
  const OnboardingSlideTwo({super.key});

  static const String _graphicAsset = 'assets/images/onboarding/sc2.png';

  /// Figma export frame (logical px).
  static const double _figmaW = 430;
  static const double _figmaH = 932;

  // Copy block — Figma: left 40, top 157, width 368.
  static const double _copyLeft = 40;
  static const double _copyTop = 157;
  static const double _copyWidth = 368;
  static const double _bodyWidth = 318;
  static const double _copyGap = 20;

  // AI KIX circle — Figma: left -9; nudged further left so edge clips off-screen.
  static const double _graphicLeft = -38;
  static const double _graphicTop = 510;
  static const double _graphicSize = 282;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        final scale = math.min(w / _figmaW, h / _figmaH);

        final copyLeft = _copyLeft / _figmaW * w;
        final copyTop = _copyTop / _figmaH * h;
        final copyWidth = _copyWidth / _figmaW * w;
        final bodyWidth = _bodyWidth / _figmaW * w;
        final copyGap = _copyGap / _figmaH * h;

        final graphicLeft = _graphicLeft / _figmaW * w;
        final graphicTop = _graphicTop / _figmaH * h;
        final graphicSize = _graphicSize / _figmaW * w;

        final titleStyle = GoogleFonts.boldonse(
          fontSize: (48 * scale).clamp(32.0, 52.0),
          fontWeight: FontWeight.w400,
          color: Colors.white,
          height: 1.40,
          letterSpacing: 0,
        );
        final bodyStyle = GoogleFonts.montserrat(
          fontSize: (24 * scale).clamp(15.0, 22.0),
          fontWeight: FontWeight.w400,
          color: Colors.white.withValues(alpha: 0.92),
          height: 1.45,
          letterSpacing: 0,
        );

        return ClipRect(
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
            Positioned(
              left: copyLeft,
              top: copyTop,
              width: copyWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: copyWidth,
                    child: Text(
                      'Never Guess Your Size Again',
                      textAlign: TextAlign.right,
                      style: titleStyle,
                    ),
                  ),
                  SizedBox(height: copyGap),
                  SizedBox(
                    width: bodyWidth,
                    child: Text(
                      'Let AI KIX map your feet with absolute precision '
                      'to find your perfect fit across global brands.',
                      textAlign: TextAlign.right,
                      style: bodyStyle,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: graphicLeft,
              top: graphicTop,
              width: graphicSize,
              height: graphicSize,
              child: Image.asset(
                _graphicAsset,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                gaplessPlayback: true,
              ),
            ),
          ],
          ),
        );
      },
    );
  }
}
