import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Scanner-style overlay for footwear camera: corners, dashed frame, shoe guide, scan line.
class FootwearScannerOverlay extends StatefulWidget {
  const FootwearScannerOverlay({
    super.key,
    this.shoeGuideOpacity = 0.72,
    this.showScanLine = true,
    this.borderColor = const Color(0xFF09DFFF),
  });

  final double shoeGuideOpacity;
  final bool showScanLine;
  final Color borderColor;

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

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        return AnimatedBuilder(
          animation: _scanController,
          builder: (context, child) {
            return CustomPaint(
              size: Size(w, h),
              painter: _FootwearScannerPainter(
                scanProgress: widget.showScanLine ? _scanController.value : 0,
                borderColor: widget.borderColor,
                cornerColor: Colors.white,
              ),
              child: child,
            );
          },
          child: Center(
            child: SvgPicture.asset(
              'assets/images/icons/shoe.svg',
              width: w * 0.72,
              height: h * 0.55,
              colorFilter: ColorFilter.mode(
                Colors.white.withValues(alpha: widget.shoeGuideOpacity),
                BlendMode.srcIn,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FootwearScannerPainter extends CustomPainter {
  _FootwearScannerPainter({
    required this.scanProgress,
    required this.borderColor,
    required this.cornerColor,
  });

  final double scanProgress;
  final Color borderColor;
  final Color cornerColor;

  static const double _radius = 12;
  static const double _cornerLen = 22;
  static const double _cornerStroke = 3;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(_radius));

    _paintEdgeVignette(canvas, size, rrect);
    _paintDashedBorder(canvas, rrect);
    _paintCornerBrackets(canvas, size);
    if (scanProgress > 0) {
      _paintScanLine(canvas, size);
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
      ..color = borderColor.withValues(alpha: 0.92)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final path = Path()..addRRect(rrect);
    _drawDashedPath(canvas, path, paint, 8, 6);
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

    // Top-left
    canvas.drawLine(Offset(inset, inset), Offset(inset + len, inset), paint);
    canvas.drawLine(Offset(inset, inset), Offset(inset, inset + len), paint);
    // Top-right
    canvas.drawLine(Offset(w - inset, inset), Offset(w - inset - len, inset), paint);
    canvas.drawLine(Offset(w - inset, inset), Offset(w - inset, inset + len), paint);
    // Bottom-left
    canvas.drawLine(Offset(inset, h - inset), Offset(inset + len, h - inset), paint);
    canvas.drawLine(Offset(inset, h - inset), Offset(inset, h - inset - len), paint);
    // Bottom-right
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
      oldDelegate.borderColor != borderColor;
}
