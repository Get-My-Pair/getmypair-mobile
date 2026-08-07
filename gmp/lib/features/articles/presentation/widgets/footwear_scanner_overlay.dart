import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gmp/features/articles/presentation/widgets/footwear_angle_overlay.dart';

/// Scanner-style overlay for footwear camera: optional corners/frame/shoe guide,
/// red/green alignment rails, scan line, and right-foot ("R") watermark.
class FootwearScannerOverlay extends StatefulWidget {
  const FootwearScannerOverlay({
    super.key,
    this.shoeGuideOpacity = 0.72,
    this.showScanLine = true,
    this.borderColor = const Color(0xFF09DFFF),
    this.captureReady = false,
    this.misaligned = false,
    this.showRightWatermark = true,
    this.showShoeGuide = true,
    this.showDashedFrame = true,
    this.showCorners = true,
    this.showVignette = true,
    this.showAlignmentRails = true,
  });

  final double shoeGuideOpacity;
  final bool showScanLine;
  final Color borderColor;

  /// Green guides when footwear is correctly aligned / detected.
  final bool captureReady;

  /// Red guides when footwear is present but not correctly aligned.
  final bool misaligned;

  /// Persistent "R" badge indicating right-side footwear capture.
  final bool showRightWatermark;

  /// When false, keeps the host screen's own shoe guide (e.g. Figma shoe.png).
  final bool showShoeGuide;
  final bool showDashedFrame;
  final bool showCorners;
  final bool showVignette;
  final bool showAlignmentRails;

  static const Color guideGreen = Color(0xFF4CAF50);
  static const Color guideRed = Color(0xFFE53935);

  @override
  State<FootwearScannerOverlay> createState() => _FootwearScannerOverlayState();
}

class _FootwearScannerOverlayState extends State<FootwearScannerOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scanController;

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _scanController.dispose();
    super.dispose();
  }

  Color get _activeGuideColor {
    if (widget.captureReady) return FootwearScannerOverlay.guideGreen;
    if (widget.misaligned) return FootwearScannerOverlay.guideRed;
    return widget.borderColor;
  }

  @override
  Widget build(BuildContext context) {
    final activeBorderColor = _activeGuideColor;
    final needsPaint = widget.showScanLine ||
        widget.showDashedFrame ||
        widget.showCorners ||
        widget.showVignette ||
        widget.showAlignmentRails;

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        final guideW = w * 0.78;
        final guideH = h * 0.68;

        return Stack(
          fit: StackFit.expand,
          children: [
            if (needsPaint)
              AnimatedBuilder(
                animation: _scanController,
                builder: (context, _) {
                  return CustomPaint(
                    size: Size(w, h),
                    painter: _FootwearScannerPainter(
                      scanProgress: widget.showScanLine && !widget.captureReady
                          ? _scanController.value
                          : 0,
                      borderColor: activeBorderColor,
                      cornerColor: widget.captureReady
                          ? FootwearScannerOverlay.guideGreen
                          : (widget.misaligned
                              ? FootwearScannerOverlay.guideRed
                              : Colors.white),
                      captureReady: widget.captureReady,
                      misaligned: widget.misaligned,
                      guideColor: activeBorderColor,
                      showDashedFrame: widget.showDashedFrame,
                      showCorners: widget.showCorners,
                      showVignette: widget.showVignette,
                      showAlignmentRails: widget.showAlignmentRails,
                    ),
                  );
                },
              ),
            if (widget.showShoeGuide)
              Center(
                child: FootwearSideProfileGuide(
                  width: guideW,
                  height: guideH,
                  opacity: widget.shoeGuideOpacity,
                  outlineOnly: true,
                  guideColor: activeBorderColor,
                ),
              ),
            if (widget.showRightWatermark)
              Positioned(
                top: 10,
                right: 12,
                child: _RightFootWatermark(
                  color: widget.captureReady
                      ? FootwearScannerOverlay.guideGreen
                      : Colors.white,
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Persistent "R" badge for right footwear capture screens.
class _RightFootWatermark extends StatelessWidget {
  const _RightFootWatermark({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.95), width: 2),
      ),
      child: Text(
        'R',
        style: GoogleFonts.boldonse(
          color: color,
          fontSize: 18,
          fontWeight: FontWeight.w400,
          height: 1,
        ),
      ),
    );
  }
}

/// Public right-foot watermark for camera screens that do not use the full overlay.
class FootwearRightWatermark extends StatelessWidget {
  const FootwearRightWatermark({
    super.key,
    this.color = Colors.white,
    this.size = 44,
  });

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.95), width: 2),
      ),
      child: Text(
        'R',
        style: GoogleFonts.boldonse(
          color: color,
          fontSize: size * 0.45,
          fontWeight: FontWeight.w400,
          height: 1,
        ),
      ),
    );
  }
}

class _FootwearScannerPainter extends CustomPainter {
  _FootwearScannerPainter({
    required this.scanProgress,
    required this.borderColor,
    required this.cornerColor,
    required this.guideColor,
    this.captureReady = false,
    this.misaligned = false,
    this.showDashedFrame = true,
    this.showCorners = true,
    this.showVignette = true,
    this.showAlignmentRails = true,
  });

  final double scanProgress;
  final Color borderColor;
  final Color cornerColor;
  final Color guideColor;
  final bool captureReady;
  final bool misaligned;
  final bool showDashedFrame;
  final bool showCorners;
  final bool showVignette;
  final bool showAlignmentRails;

  static const double _radius = 12;
  static const double _cornerLen = 22;
  static const double _cornerStroke = 3;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(_radius));

    if (showVignette) _paintEdgeVignette(canvas, size, rrect);
    if (showAlignmentRails) _paintAlignmentGuides(canvas, size);
    if (showDashedFrame) _paintDashedBorder(canvas, rrect);
    if (showCorners) _paintCornerBrackets(canvas, size);
    if (scanProgress > 0) {
      _paintScanLine(canvas, size);
    }
  }

  /// Vertical red/green alignment rails that bookend the shoe guide.
  void _paintAlignmentGuides(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = guideColor.withValues(alpha: captureReady ? 0.95 : 0.75)
      ..strokeWidth = captureReady || misaligned ? 3 : 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final leftX = size.width * 0.12;
    final rightX = size.width * 0.88;
    final top = size.height * 0.18;
    final bottom = size.height * 0.82;

    canvas.drawLine(Offset(leftX, top), Offset(leftX, bottom), paint);
    canvas.drawLine(Offset(rightX, top), Offset(rightX, bottom), paint);

    final midY = size.height * 0.5;
    final tick = size.width * 0.04;
    canvas.drawLine(Offset(leftX, midY), Offset(leftX + tick, midY), paint);
    canvas.drawLine(Offset(rightX, midY), Offset(rightX - tick, midY), paint);

    if (captureReady || misaligned) {
      final glow = Paint()
        ..color = guideColor.withValues(alpha: 0.28)
        ..strokeWidth = 8
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6)
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(leftX, top), Offset(leftX, bottom), glow);
      canvas.drawLine(Offset(rightX, top), Offset(rightX, bottom), glow);
    }
  }

  void _paintEdgeVignette(Canvas canvas, Size size, RRect rrect) {
    final bandH = size.height * 0.14;
    final topGrad = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.black.withValues(alpha: 0.45),
          Colors.black.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, bandH));
    final bottomGrad = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          Colors.black.withValues(alpha: 0.45),
          Colors.black.withValues(alpha: 0),
        ],
      ).createShader(
        Rect.fromLTWH(0, size.height - bandH, size.width, bandH),
      );

    canvas.save();
    canvas.clipRRect(rrect);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, bandH), topGrad);
    canvas.drawRect(
      Rect.fromLTWH(0, size.height - bandH, size.width, bandH),
      bottomGrad,
    );
    canvas.restore();
  }

  void _paintDashedBorder(Canvas canvas, RRect rrect) {
    final paint = Paint()
      ..color = borderColor.withValues(alpha: captureReady ? 1.0 : 0.92)
      ..style = PaintingStyle.stroke
      ..strokeWidth = captureReady ? 2.5 : 1.5;
    final path = Path()..addRRect(rrect);
    if (captureReady) {
      canvas.drawPath(path, paint);
    } else {
      _drawDashedPath(canvas, path, paint, 8, 6);
    }
  }

  void _paintCornerBrackets(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = cornerColor.withValues(alpha: 0.95)
      ..style = PaintingStyle.stroke
      ..strokeWidth = _cornerStroke
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;
    const inset = 6.0;
    const len = _cornerLen;

    canvas.drawLine(Offset(inset, inset), Offset(inset + len, inset), paint);
    canvas.drawLine(Offset(inset, inset), Offset(inset, inset + len), paint);
    canvas.drawLine(Offset(w - inset, inset), Offset(w - inset - len, inset), paint);
    canvas.drawLine(Offset(w - inset, inset), Offset(w - inset, inset + len), paint);
    canvas.drawLine(Offset(inset, h - inset), Offset(inset + len, h - inset), paint);
    canvas.drawLine(Offset(inset, h - inset), Offset(inset, h - inset - len), paint);
    canvas.drawLine(
      Offset(w - inset, h - inset),
      Offset(w - inset - len, h - inset),
      paint,
    );
    canvas.drawLine(
      Offset(w - inset, h - inset),
      Offset(w - inset, h - inset - len),
      paint,
    );
  }

  void _paintScanLine(Canvas canvas, Size size) {
    final y = size.height * (0.12 + scanProgress * 0.76);
    final linePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          borderColor.withValues(alpha: 0),
          borderColor.withValues(alpha: 0.85),
          borderColor.withValues(alpha: 0),
        ],
        stops: const [0, 0.5, 1],
      ).createShader(Rect.fromLTWH(0, y - 1, size.width, 3))
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(size.width * 0.08, y), Offset(size.width * 0.92, y), linePaint);

    final glow = Paint()
      ..color = borderColor.withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawLine(Offset(size.width * 0.08, y), Offset(size.width * 0.92, y), glow);
  }

  static void _drawDashedPath(
    Canvas canvas,
    Path path,
    Paint paint,
    double dashWidth,
    double dashGap,
  ) {
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = (distance + dashWidth).clamp(0.0, metric.length);
        canvas.drawPath(
          metric.extractPath(distance, next),
          paint,
        );
        distance += dashWidth + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _FootwearScannerPainter oldDelegate) =>
      oldDelegate.scanProgress != scanProgress ||
      oldDelegate.borderColor != borderColor ||
      oldDelegate.guideColor != guideColor ||
      oldDelegate.misaligned != misaligned ||
      oldDelegate.captureReady != captureReady ||
      oldDelegate.showAlignmentRails != showAlignmentRails ||
      oldDelegate.showDashedFrame != showDashedFrame ||
      oldDelegate.showCorners != showCorners;
}
