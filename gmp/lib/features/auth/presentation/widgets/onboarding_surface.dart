import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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

/// Full-screen image used by onboarding flows.
class OnboardingGradientBackdrop extends StatelessWidget {
  const OnboardingGradientBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    return const RepaintBoundary(
      child: SizedBox.expand(
        child: Image(
          image: AssetImage('assets/images/bg/onbording.png'),
          fit: BoxFit.cover,
          filterQuality: FilterQuality.high,
        ),
      ),
    );
  }
}

/// Vertical “GetMyPair” behind onboarding copy, **left** side (padded), vertically offset via [_alignY].
///
/// Layout is driven by [TextPainter] with a **finite** max width so the label
/// stays **one horizontal line** before rotation (avoids per-glyph wrapping /
/// clipping when the rotated subtree gets tight constraints).
class OnboardingBrandWatermark extends StatefulWidget {
  const OnboardingBrandWatermark({super.key});

  static const String _label = 'GetMyPair';

  static const double _designFontPx = 100.78;
  static const double _designBorderPx = 3.36;
  /// Large enough for one-line Latin label; keeps [TextPainter] from wrapping.
  static const double _layoutMaxWidth = 4096;

  @override
  State<OnboardingBrandWatermark> createState() =>
      _OnboardingBrandWatermarkState();
}

class _OnboardingBrandWatermarkState extends State<OnboardingBrandWatermark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _float;

  @override
  void initState() {
    super.initState();
    _float = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 28),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _float.dispose();
    super.dispose();
  }

  /// Figma “GetMyPair” watermark: linear gradient #AFEDD6 → #64877A @ ~5% opacity.
  static const LinearGradient _watermarkGradient = LinearGradient(
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
    // Match Figma watermark sizing.
    const fontSize = OnboardingBrandWatermark._designFontPx;
    const strokeW = OnboardingBrandWatermark._designBorderPx;

    final baseStyle = GoogleFonts.boldonse(
      fontSize: fontSize,
      fontWeight: FontWeight.w400,
      height: 1.0,
      letterSpacing: 0,
    );

    final tp = TextPainter(
      text: TextSpan(
        text: OnboardingBrandWatermark._label,
        style: baseStyle,
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      textScaler: TextScaler.noScaling,
    )..layout(maxWidth: OnboardingBrandWatermark._layoutMaxWidth);

    final tw = tp.width;
    final th = tp.height;

    final textBounds = Rect.fromLTWH(0, 0, tw, th);
    final fillPaint = Paint()
      ..shader = _watermarkGradient.createShader(textBounds);

    final fillStyle = baseStyle.copyWith(foreground: fillPaint);

    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..strokeJoin = StrokeJoin.round
      ..shader = _watermarkGradient.createShader(textBounds);

    final strokeStyle = baseStyle.copyWith(foreground: strokePaint);

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _float,
        builder: (context, child) {
          final t = _float.value * 2 * math.pi;
          final drift = Offset(5 * math.sin(t * 0.4), 8 * math.cos(t * 0.35));
          return Transform.translate(offset: drift, child: child);
        },
        child: IgnorePointer(
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final top = (constraints.maxHeight - tw) / 2 + 190;
                final left = -th * 2.50;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      top: top,
                      left: left,
                      child: Transform.rotate(
                        angle: -math.pi / 2,
                        alignment: Alignment.center,
                        child: SizedBox(
                          width: tw,
                          height: th,
                          child: Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.topLeft,
                            children: [
                              Text(
                                OnboardingBrandWatermark._label,
                                maxLines: 1,
                                softWrap: false,
                                textAlign: TextAlign.left,
                                overflow: TextOverflow.visible,
                                style: fillStyle,
                              ),
                              Text(
                                OnboardingBrandWatermark._label,
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
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
