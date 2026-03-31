import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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

/// Vertical “GetMyPair” behind onboarding copy, **left** side (padded), vertically offset via [_alignY].
///
/// Layout is driven by [TextPainter] with a **finite** max width so the label
/// stays **one horizontal line** before rotation (avoids per-glyph wrapping /
/// clipping when the rotated subtree gets tight constraints).
class OnboardingBrandWatermark extends StatelessWidget {
  const OnboardingBrandWatermark({super.key});

  static const String _label = 'GetMyPair';

  static const double _designFrameW = 390;
  static const double _designFrameH = 812;
  static const double _designFontPx = 120.78;
  static const double _designBorderPx = 3.36;
  /// Extra inset from the padded left edge so the full word stays on-screen.
  static const double _insetFromPadLeft = 12;
  /// Left side; Y in [-1,1]: negative = higher, positive = lower. Center = 0.
  static const double _alignY = 0.12;
  /// Extra tracking for the watermark (scaled with type size).
  static const double _letterSpacingFactor = 0.045;

  /// Large enough for one-line Latin label; keeps [TextPainter] from wrapping.
  static const double _layoutMaxWidth = 4096;

  /// Figma: `border: 3.36px solid` + `border-image` linear-gradient 180deg.
  static const LinearGradient _strokeBorderGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0.0, 0.181, 0.8341, 1.0],
    colors: [
      Color.fromRGBO(175, 237, 214, 0.05),
      Color.fromRGBO(175, 237, 214, 0.05),
      Color.fromRGBO(100, 135, 122, 0.05),
      Color.fromRGBO(100, 135, 122, 0.05),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final sz = MediaQuery.sizeOf(context);
    final w = sz.width;
    final h = sz.height;

    final scaleX = w / _designFrameW;
    final shortest = math.min(w, h);
    final refShortest = math.min(_designFrameW, _designFrameH);
    final scaleUniform = (shortest / refShortest).clamp(0.68, 1.45);
    final leftNudge = _insetFromPadLeft * scaleX;

    final fontSize =
        (_designFontPx * scaleUniform * 0.5).clamp(32.0, 68.0);
    final letterSpacing =
        (fontSize * _letterSpacingFactor).clamp(1.0, 5.0);
    final strokeW =
        (_designBorderPx * scaleUniform * 0.9).clamp(0.85, 3.5);

    final baseStyle = GoogleFonts.boldonse(
      fontSize: fontSize,
      fontWeight: FontWeight.w400,
      height: 1.0,
      letterSpacing: letterSpacing,
    );

    final tp = TextPainter(
      text: TextSpan(text: _label, style: baseStyle),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      textScaler: TextScaler.noScaling,
    )..layout(maxWidth: _layoutMaxWidth);

    final tw = tp.width;
    final th = tp.height;

    final strokeRect = Rect.fromLTWH(0, 0, tw, th);
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..strokeJoin = StrokeJoin.round
      ..shader = _strokeBorderGradient.createShader(strokeRect);

    final strokeStyle = baseStyle.copyWith(foreground: strokePaint);

    final fillStyle = baseStyle.copyWith(
      color: Colors.white.withValues(alpha: 0.2),
    );

    return IgnorePointer(
      child: MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Align(
            alignment: Alignment(-1, _alignY),
            child: Transform.translate(
              offset: Offset(leftNudge, 0),
              child: Transform.rotate(
                angle: -math.pi / 2,
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: tw,
                  height: th,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.topLeft,
                    children: [
                      Text(
                        _label,
                        maxLines: 1,
                        softWrap: false,
                        textAlign: TextAlign.left,
                        overflow: TextOverflow.visible,
                        style: fillStyle,
                      ),
                      Text(
                        _label,
                        maxLines: 1,
                        softWrap: false,
                        textAlign: TextAlign.left,
                        overflow: TextOverflow.visible,
                        style: strokeStyle,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
