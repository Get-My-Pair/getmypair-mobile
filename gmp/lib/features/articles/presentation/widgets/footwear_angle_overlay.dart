import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Dashed frame + side-profile shoe guide for footwear camera capture.
class FootwearAngleOverlay extends StatelessWidget {
  const FootwearAngleOverlay({
    super.key,
    this.angleLabel,
    this.compact = false,
    this.showShoeGuide = true,
    this.fillParent = false,
    this.shoeGuideOpacity = 0.85,
    this.lightLineGuide = false,
    this.frameStrokeWidth = 2,
    this.frameStrokeOpacity = 0.9,
  });

  final String? angleLabel;
  final bool compact;

  /// When false, only the dashed frame is shown (for live camera preview).
  final bool showShoeGuide;

  /// When true, dashed frame uses the full [LayoutBuilder] size (camera slot).
  final bool fillParent;

  final double shoeGuideOpacity;

  /// Figma upload screen: thin white/cyan dashed frame + light shoe outline.
  final bool lightLineGuide;

  final double frameStrokeWidth;
  final double frameStrokeOpacity;

  /// Figma upload-footwear frame proportions (compact).
  static Size figmaFrameSize(Size parent) {
    return Size(parent.width * 0.88, parent.height * 0.55);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        final frameW = fillParent ? w : (compact ? w * 0.88 : w * 0.82);
        final frameH = fillParent ? h : (compact ? h * 0.55 : h * 0.48);
        final strokeWidth = lightLineGuide ? 1.5 : frameStrokeWidth;
        final frameAlpha = lightLineGuide ? 0.92 : frameStrokeOpacity;
        final frameColor = lightLineGuide
            ? const Color(0xFF09DFFF)
            : Colors.white;
        final dashW = lightLineGuide ? 8.0 : 10.0;
        final dashGap = lightLineGuide ? 6.0 : 7.0;
        final shoeAlpha = lightLineGuide
            ? shoeGuideOpacity.clamp(0.55, 0.85)
            : shoeGuideOpacity;

        return Stack(
          alignment: Alignment.center,
          children: [
            if (angleLabel != null)
              Positioned(
                top: compact ? 8 : 24,
                child: Text(
                  angleLabel!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Montserrat',
                  ),
                ),
              ),
            CustomPaint(
              size: Size(frameW, frameH),
              painter: _DashedRectPainter(
                color: frameColor.withValues(alpha: frameAlpha),
                strokeWidth: strokeWidth,
                dashWidth: dashW,
                dashGap: dashGap,
                borderRadius: 12,
              ),
              child: SizedBox(
                width: frameW,
                height: frameH,
                child: showShoeGuide
                    ? Center(
                        child: _LightShoeGuide(
                          width: frameW * 0.72,
                          height: frameH * 0.55,
                          opacity: shoeAlpha,
                          outlineOnly: lightLineGuide,
                        ),
                      )
                    : null,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DashedRectPainter extends CustomPainter {
  _DashedRectPainter({
    required this.color,
    required this.strokeWidth,
    required this.dashWidth,
    required this.dashGap,
    required this.borderRadius,
  });

  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashGap;
  final double borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(borderRadius),
    );
    final path = Path()..addRRect(rrect);
    _drawDashedPath(canvas, path, paint, dashWidth, dashGap);
  }

  static void _drawDashedPath(
    Canvas canvas,
    Path path,
    Paint paint,
    double dashWidth,
    double dashGap,
  ) {
    final metrics = path.computeMetrics().toList();
    for (final metric in metrics) {
      double distance = 0;
      while (distance < metric.length) {
        final next = (distance + dashWidth).clamp(0, metric.length);
        final extract = metric.extractPath(distance, next.toDouble());
        canvas.drawPath(extract, paint);
        distance += dashWidth + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRectPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.dashWidth != dashWidth ||
      oldDelegate.dashGap != dashGap;
}

/// Side-profile shoe guide for camera overlay.
class _LightShoeGuide extends StatelessWidget {
  const _LightShoeGuide({
    required this.width,
    required this.height,
    required this.opacity,
    required this.outlineOnly,
  });

  final double width;
  final double height;
  final double opacity;
  final bool outlineOnly;

  @override
  Widget build(BuildContext context) {
    final lineColor = Colors.white.withValues(alpha: opacity);

    if (outlineOnly) {
      return CustomPaint(
        size: Size(width, height),
        painter: _DashedShoeOutlinePainter(
          color: lineColor,
          strokeWidth: 1.5,
          dashWidth: 7,
          dashGap: 5,
        ),
      );
    }

    return SvgPicture.asset(
      'assets/images/icons/shoe.svg',
      width: width,
      height: height,
      colorFilter: ColorFilter.mode(lineColor, BlendMode.srcIn),
    );
  }
}

/// Dashed side-profile shoe silhouette (Figma light line drawing).
class _DashedShoeOutlinePainter extends CustomPainter {
  _DashedShoeOutlinePainter({
    required this.color,
    required this.strokeWidth,
    required this.dashWidth,
    required this.dashGap,
  });

  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashGap;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(w * 0.1, h * 0.58)
      ..lineTo(w * 0.14, h * 0.38)
      ..quadraticBezierTo(w * 0.2, h * 0.22, w * 0.38, h * 0.18)
      ..quadraticBezierTo(w * 0.62, h * 0.14, w * 0.82, h * 0.28)
      ..quadraticBezierTo(w * 0.94, h * 0.38, w * 0.9, h * 0.52)
      ..quadraticBezierTo(w * 0.86, h * 0.68, w * 0.62, h * 0.74)
      ..lineTo(w * 0.22, h * 0.78)
      ..quadraticBezierTo(w * 0.12, h * 0.76, w * 0.1, h * 0.58)
      ..close();

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    _DashedRectPainter._drawDashedPath(canvas, path, paint, dashWidth, dashGap);
  }

  @override
  bool shouldRepaint(covariant _DashedShoeOutlinePainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Dashed guide frame only — for live [CameraPreview] (no shoe illustration).
class FootwearCameraFrameOnly extends StatelessWidget {
  const FootwearCameraFrameOnly({super.key, this.label});

  final String? label;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          if (label != null)
            Positioned(
              top: 10,
              left: 12,
              right: 12,
              child: Text(
                label!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Montserrat',
                  shadows: [
                    Shadow(
                      color: Colors.black54,
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
            ),
          Positioned(
            left: 20,
            right: 20,
            top: 40,
            bottom: 72,
            child: CustomPaint(
              painter: _DashedRectPainter(
                color: Colors.white.withValues(alpha: 0.95),
                strokeWidth: 2,
                dashWidth: 10,
                dashGap: 7,
                borderRadius: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
