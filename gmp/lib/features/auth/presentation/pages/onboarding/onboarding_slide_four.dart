import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Onboarding screen 4 — “Donate. Sell. Rent. Earn.” with rehome + carbon badges.
///
/// Layout from Figma frame **430×932**. Uses high-res flat PNGs + runtime tilt
/// (not the low-res pre-rotated `sc4.*` exports, which looked blurry).
class OnboardingSlideFour extends StatelessWidget {
  const OnboardingSlideFour({super.key});

  static const String _rehomeAsset =
      'assets/images/5ffd5d392d9fb22b1fcb70d7dd46f976f635eb18.png';
  static const String _creditsAsset =
      'assets/images/20868ffbf2d16aaa9386162dca63285509afb735.png';

  /// Figma export frame (logical px).
  static const double _figmaW = 430;
  static const double _figmaH = 932;

  // Rehome MyPair — Figma: left 100.60, top 163, 230×110, rotateZ(0.14).
  static const double _rehomeLeft = 100.60;
  static const double _rehomeTop = 163;
  static const double _rehomeW = 230;
  static const double _rehomeH = 110;
  static const double _rehomeAngle = 0.14;

  // Carbon Credits — Figma: left 45, top 341.14, 334×49, rotateZ(-0.17).
  static const double _creditsLeft = 45;
  static const double _creditsTop = 341.14;
  static const double _creditsW = 334;
  static const double _creditsH = 49;
  static const double _creditsAngle = -0.17;

  // Copy — Figma: left 36, top 423, width 353, gap 20.
  static const double _copyLeft = 36;
  static const double _copyTop = 423;
  static const double _copyWidth = 353;
  static const double _copyGap = 20;
  static const List<String> _bodyLines = [
    'Your ultimate footwear',
    'ecosystem. Do good for the',
    'planet, do wonders for your',
    'wallet.',
  ];
  static const double _bodyLineGap = 6;

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        final scale = math.min(w / _figmaW, h / _figmaH);

        final rehomeLeft = _rehomeLeft / _figmaW * w;
        final rehomeTop = _rehomeTop / _figmaH * h;
        final rehomeW = _rehomeW / _figmaW * w;
        final rehomeH = _rehomeH / _figmaH * h;

        final creditsLeft = _creditsLeft / _figmaW * w;
        final creditsTop = _creditsTop / _figmaH * h;
        final creditsW = _creditsW / _figmaW * w;
        final creditsH = _creditsH / _figmaH * h;

        final copyLeft = _copyLeft / _figmaW * w;
        final copyTop = _copyTop / _figmaH * h;
        final copyWidth = _copyWidth / _figmaW * w;
        final copyGap = _copyGap / _figmaH * h;
        final bodyLineGap = _bodyLineGap / _figmaH * h;

        final titleStyle = GoogleFonts.boldonse(
          fontSize: (48 * scale).clamp(34.0, 52.0),
          fontWeight: FontWeight.w400,
          color: Colors.white,
          height: 1.33,
          letterSpacing: 0,
        );
        final bodyStyle = GoogleFonts.montserrat(
          fontSize: (24 * scale).clamp(16.0, 24.0),
          fontWeight: FontWeight.w400,
          color: Colors.white.withValues(alpha: 0.92),
          height: 1.45,
          letterSpacing: 0,
        );
        const titleHeightBehavior = TextHeightBehavior(
          applyHeightToFirstAscent: false,
          applyHeightToLastDescent: false,
        );
        const bodyHeightBehavior = TextHeightBehavior(
          applyHeightToFirstAscent: false,
          applyHeightToLastDescent: false,
        );

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: rehomeLeft,
              top: rehomeTop,
              width: rehomeW,
              height: rehomeH,
              child: _TiltedBadge(
                angle: _rehomeAngle,
                child: _SharpAsset(
                  asset: _rehomeAsset,
                  width: rehomeW,
                  height: rehomeH,
                  dpr: dpr,
                ),
              ),
            ),
            Positioned(
              left: creditsLeft,
              top: creditsTop,
              width: creditsW,
              height: creditsH,
              child: _TiltedBadge(
                angle: _creditsAngle,
                child: _SharpAsset(
                  asset: _creditsAsset,
                  width: creditsW,
                  height: creditsH,
                  dpr: dpr,
                ),
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
                      'Donate.\nSell.\nRent.\nEarn.',
                      style: titleStyle,
                      textAlign: TextAlign.left,
                      textHeightBehavior: titleHeightBehavior,
                    ),
                  ),
                  SizedBox(height: copyGap),
                  SizedBox(
                    width: copyWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var i = 0; i < _bodyLines.length; i++) ...[
                          if (i > 0) SizedBox(height: bodyLineGap),
                          Text(
                            _bodyLines[i],
                            style: bodyStyle,
                            textAlign: TextAlign.left,
                            textHeightBehavior: bodyHeightBehavior,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Figma `Container.transform` rotates from the top-left corner.
class _TiltedBadge extends StatelessWidget {
  const _TiltedBadge({required this.angle, required this.child});

  final double angle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      alignment: Alignment.topLeft,
      angle: angle,
      filterQuality: FilterQuality.medium,
      child: child,
    );
  }
}

/// Decodes the PNG at device-pixel size so badges stay sharp on high-DPI screens.
class _SharpAsset extends StatelessWidget {
  const _SharpAsset({
    required this.asset,
    required this.width,
    required this.height,
    required this.dpr,
  });

  final String asset;
  final double width;
  final double height;
  final double dpr;

  @override
  Widget build(BuildContext context) {
    final cacheW = (width * dpr).round().clamp(1, 4096);
    final cacheH = (height * dpr).round().clamp(1, 4096);

    return Image.asset(
      asset,
      width: width,
      height: height,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      isAntiAlias: true,
      gaplessPlayback: true,
      cacheWidth: cacheW,
      cacheHeight: cacheH,
    );
  }
}
