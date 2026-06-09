import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'onboarding_content.dart';

/// Onboarding screen 1 — “Your rack, Digitized!” with tilted phone mockup ([sc1.png]).
///
/// Layout from Figma export frame **430×932** (positions scaled to the slide bounds).
class OnboardingSlideOne extends StatelessWidget {
  const OnboardingSlideOne({super.key});

  static const String _phoneAsset = 'assets/images/onboarding/sc1.png';

  /// Figma export frame (logical px) — same as screens 2–3.
  static const double _figmaW = 430;
  static const double _figmaH = 932;

  /// Phone — large, horizontally centered, nudged up toward top.
  static const double _phoneTop = -28;
  static const double _phoneW = 510;
  static const double _phoneH = 728;

  /// Title — left 37, right 21 (matches bottom progress bar).
  static const double _copyLeft = OnboardingContent.figmaLeftInset;
  static const double _copyRight = OnboardingContent.figmaRightInset;
  /// Body — left aligns with title (37); right stays minimal.
  static const double _bodyLeftInset = OnboardingContent.figmaLeftInset;
  static const double _bodyRightInset = 4;
  /// Figma: Boldonse 48 / Montserrat 17 (body scales up to fill line width).
  static const double _titleFontPx = 48;
  static const double _bodyFontPx = 17;
  static const List<String> _bodyLines = [
    'Scan, upload, and organize',
    'your entire footwear collection',
    'in one smart digital shoe rack.',
  ];
  static const double _titleBodyGap = 14;
  static const double _bodyLineGap = 6;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        final scale = math.min(w / _figmaW, h / _figmaH);

        final phoneTop = _phoneTop / _figmaH * h;
        final phoneW = _phoneW / _figmaW * w;
        final phoneH = _phoneH / _figmaH * h;

        final copyLeft = _copyLeft / _figmaW * w;
        final copyRight = _copyRight / _figmaW * w;
        final bodyLeft = _bodyLeftInset / _figmaW * w;
        final bodyRight = _bodyRightInset / _figmaW * w;
        final titleBodyGap = _titleBodyGap / _figmaH * h;
        final bodyLineGap = _bodyLineGap / _figmaH * h;

        final titleStyle = GoogleFonts.boldonse(
          fontSize: (_titleFontPx * scale).clamp(34.0, 52.0),
          fontWeight: FontWeight.w400,
          color: Colors.white,
          height: 1.5,
          letterSpacing: 0,
        );
        const titleHeightBehavior = TextHeightBehavior(
          applyHeightToFirstAscent: false,
          applyHeightToLastDescent: false,
        );
        final bodyStyle = GoogleFonts.montserrat(
          fontSize: (_bodyFontPx * scale).clamp(14.0, 18.0),
          fontWeight: FontWeight.w400,
          color: Colors.white.withValues(alpha: 0.92),
          height: 1.45,
          letterSpacing: 0,
        );
        const bodyHeightBehavior = TextHeightBehavior(
          applyHeightToFirstAscent: false,
          applyHeightToLastDescent: false,
        );
        final bodyWidth = w - bodyLeft - bodyRight;
        final fittedBodyStyle = bodyStyle.copyWith(
          fontSize: _fitBodyFontSize(bodyStyle, bodyWidth),
        );

        return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                top: phoneTop,
                left: 0,
                right: 0,
                height: phoneH * 1.04,
                child: Center(
                  child: SizedBox(
                    width: phoneW * 1.06,
                    height: phoneH * 1.04,
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        Transform.translate(
                          offset: Offset(10 * scale, 14 * scale),
                          child: _phoneSideShadow(
                            scale: scale,
                            width: phoneW,
                            height: phoneH,
                          ),
                        ),
                        Image.asset(
                          _phoneAsset,
                          width: phoneW,
                          height: phoneH,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                          gaplessPlayback: true,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(left: copyLeft, right: copyRight),
                      child: Text(
                        'Your rack,\nDigitized!',
                        style: titleStyle,
                        textAlign: TextAlign.left,
                        textHeightBehavior: titleHeightBehavior,
                      ),
                    ),
                    SizedBox(height: titleBodyGap),
                    Padding(
                      padding: EdgeInsets.only(left: bodyLeft, right: bodyRight),
                      child: SizedBox(
                        width: bodyWidth,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (var i = 0; i < _bodyLines.length; i++) ...[
                              if (i > 0) SizedBox(height: bodyLineGap),
                              Text(
                                _bodyLines[i],
                                style: fittedBodyStyle,
                                textAlign: TextAlign.left,
                                maxLines: 1,
                                softWrap: false,
                                textHeightBehavior: bodyHeightBehavior,
                              ),
                            ],
                          ],
                        ),
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

  /// Scales body font so the longest line fills the available width.
  static double _fitBodyFontSize(TextStyle base, double maxWidth) {
    final longest = _bodyLines.reduce(
      (a, b) => a.length > b.length ? a : b,
    );
    final baseSize = base.fontSize ?? _bodyFontPx;
    final minSize = baseSize * 0.92;
    final maxSize = baseSize * 1.55;
    var size = baseSize;
    final painter = TextPainter(
      textDirection: TextDirection.ltr,
      maxLines: 1,
    );

    while (size < maxSize) {
      final next = size + 0.5;
      painter.text = TextSpan(
        text: longest,
        style: base.copyWith(fontSize: next),
      );
      painter.layout(maxWidth: maxWidth);
      if (painter.width > maxWidth) break;
      size = next;
    }

    for (final line in _bodyLines) {
      while (size > minSize) {
        painter.text = TextSpan(
          text: line,
          style: base.copyWith(fontSize: size),
        );
        painter.layout(maxWidth: maxWidth);
        if (painter.width <= maxWidth) break;
        size -= 0.5;
      }
    }

    return size.clamp(minSize, maxSize);
  }

  /// Soft drop shadow matching the phone silhouette (not a bottom line).
  static Widget _phoneSideShadow({
    required double scale,
    required double width,
    required double height,
  }) {
    final silhouette = ColorFiltered(
      colorFilter: ColorFilter.mode(
        Colors.black.withValues(alpha: kIsWeb ? 0.30 : 0.38),
        BlendMode.srcIn,
      ),
      child: Image.asset(
        _phoneAsset,
        width: width,
        height: height,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.low,
        gaplessPlayback: true,
      ),
    );
    if (kIsWeb) return silhouette;
    return ImageFiltered(
      imageFilter: ImageFilter.blur(
        sigmaX: 22 * scale,
        sigmaY: 22 * scale,
      ),
      child: silhouette,
    );
  }
}
