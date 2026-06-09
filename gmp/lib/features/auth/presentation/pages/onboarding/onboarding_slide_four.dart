import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Onboarding screen 4 — “Donate. Sell. Rent. Earn.” with rehome + carbon badges.
///
/// Layout from Figma frame **430×932** ([node 1676-143]). Exported PNGs
/// ([sc4.1.png], [sc4.2.png]) already include tilt — positions are derived by
/// centering each asset on the Figma component bounding box (no extra rotation).
class OnboardingSlideFour extends StatelessWidget {
  const OnboardingSlideFour({super.key});

  static const String _rehomeAsset = 'assets/images/onboarding/sc4.1.png';
  static const String _creditsAsset = 'assets/images/onboarding/sc4.2.png';

  /// Figma export frame (logical px).
  static const double _figmaW = 430;
  static const double _figmaH = 932;

  /// Native export sizes (pre-rotated PNGs).
  static const double _rehomeAssetW = 244;
  static const double _rehomeAssetH = 142;
  static const double _creditsAssetW = 338;
  static const double _creditsAssetH = 105;

  // Figma component boxes (vector layers before raster export).
  static const double _rehomeBoxLeft = 100.60;
  static const double _rehomeBoxTop = 163;
  static const double _rehomeBoxW = 230;
  static const double _rehomeBoxH = 110;

  static const double _creditsBoxLeft = 45;
  static const double _creditsBoxTop = 341.14;
  static const double _creditsBoxW = 334;
  static const double _creditsBoxH = 49;

  // Copy — Figma: left 36, top 423, width 353, gap 20.
  static const double _copyLeft = 36;
  static const double _copyTop = 423;
  static const double _copyWidth = 353;
  static const double _copyGap = 20;

  /// Centers a raster asset on a Figma component rect.
  static double _assetLeft(double boxLeft, double boxW, double assetW) =>
      boxLeft + (boxW - assetW) / 2;

  static double _assetTop(double boxTop, double boxH, double assetH) =>
      boxTop + (boxH - assetH) / 2;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        final scale = math.min(w / _figmaW, h / _figmaH);

        final rehomeLeft = _assetLeft(
              _rehomeBoxLeft,
              _rehomeBoxW,
              _rehomeAssetW,
            ) /
            _figmaW *
            w;
        final rehomeTop = _assetTop(
              _rehomeBoxTop,
              _rehomeBoxH,
              _rehomeAssetH,
            ) /
            _figmaH *
            h;
        final rehomeW = _rehomeAssetW / _figmaW * w;
        final rehomeH = _rehomeAssetH / _figmaH * h;

        final creditsLeft = _assetLeft(
              _creditsBoxLeft,
              _creditsBoxW,
              _creditsAssetW,
            ) /
            _figmaW *
            w;
        final creditsTop = _assetTop(
              _creditsBoxTop,
              _creditsBoxH,
              _creditsAssetH,
            ) /
            _figmaH *
            h;
        final creditsW = _creditsAssetW / _figmaW * w;
        final creditsH = _creditsAssetH / _figmaH * h;

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
        const titleHeightBehavior = TextHeightBehavior(
          applyHeightToFirstAscent: false,
          applyHeightToLastDescent: false,
        );

        return ClipRect(
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned(
                left: rehomeLeft,
                top: rehomeTop,
                width: rehomeW,
                height: rehomeH,
                child: Image.asset(
                  _rehomeAsset,
                  fit: BoxFit.fill,
                  filterQuality: FilterQuality.high,
                  gaplessPlayback: true,
                ),
              ),
              Positioned(
                left: creditsLeft,
                top: creditsTop,
                width: creditsW,
                height: creditsH,
                child: Image.asset(
                  _creditsAsset,
                  fit: BoxFit.fill,
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
                        'Donate.\nSell.\nRent.\nEarn.',
                        style: titleStyle,
                        textAlign: TextAlign.left,
                        textHeightBehavior: titleHeightBehavior,
                      ),
                    ),
                    SizedBox(height: copyGap),
                    SizedBox(
                      width: copyWidth,
                      child: Text(
                        'Your ultimate footwear ecosystem. Do good for the '
                        'planet, do wonders for your wallet.',
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
