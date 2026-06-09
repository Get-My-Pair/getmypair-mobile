import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Onboarding screen 3 — “Give your pairs a second life!” with cobbler hero ([sc3.png]).
///
/// Layout from Figma export frame **430×932** (positions scaled to the slide bounds).
class OnboardingSlideThree extends StatelessWidget {
  const OnboardingSlideThree({super.key});

  static const String _heroAsset = 'assets/images/onboarding/sc3.png';

  /// Figma export frame (logical px).
  static const double _figmaW = 430;
  static const double _figmaH = 932;

  // Hero — Figma: left 0, top 135, 430×292.
  static const double _heroTop = 135;
  static const double _heroH = 292;

  // Copy — Figma: left 36, top 466, width 353.
  static const double _copyLeft = 36;
  static const double _copyTop = 466;
  static const double _copyWidth = 353;
  static const double _copyGap = 20;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        final scale = math.min(w / _figmaW, h / _figmaH);

        final heroTop = _heroTop / _figmaH * h;
        final heroHeight = _heroH / _figmaH * h;

        final copyLeft = _copyLeft / _figmaW * w;
        final copyTop = _copyTop / _figmaH * h;
        final copyWidth = _copyWidth / _figmaW * w;
        final copyGap = _copyGap / _figmaH * h;

        final titleStyle = GoogleFonts.boldonse(
          fontSize: (48 * scale).clamp(32.0, 52.0),
          fontWeight: FontWeight.w400,
          color: Colors.white,
          height: 1.33,
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
                left: 0,
                top: heroTop,
                width: w,
                height: heroHeight,
                child: Image.asset(
                  _heroAsset,
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  filterQuality: FilterQuality.high,
                  gaplessPlayback: true,
                ),
              ),
              Positioned(
                left: copyLeft,
                top: copyTop,
                width: copyWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: copyWidth,
                      child: Text(
                        'Give your pairs a second life!',
                        style: titleStyle,
                        textAlign: TextAlign.left,
                      ),
                    ),
                    SizedBox(height: copyGap),
                    SizedBox(
                      width: copyWidth,
                      child: Text(
                        'From deep cleaning to expert restoration, book premium '
                        'cobbler services right to your doorstep.',
                        style: bodyStyle,
                        textAlign: TextAlign.left,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
