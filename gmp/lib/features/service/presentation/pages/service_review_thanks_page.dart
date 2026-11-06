import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gmp/core/bgtheme.dart';

/// Confetti thank-you after Service History review submit.
class ServiceReviewThanksPage extends StatefulWidget {
  const ServiceReviewThanksPage({super.key});

  @override
  State<ServiceReviewThanksPage> createState() =>
      _ServiceReviewThanksPageState();
}

class _ServiceReviewThanksPageState extends State<ServiceReviewThanksPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    Future<void>.delayed(const Duration(milliseconds: 2200), () {
      if (!mounted) return;
      Navigator.of(context).pop(true);
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: BgTheme.scaffoldBackgroundColor,
        body: Stack(
          fit: StackFit.expand,
          children: [
            ...BgTheme.background(),
            AnimatedBuilder(
              animation: _confettiController,
              builder: (context, _) {
                return CustomPaint(
                  painter: _SilverConfettiPainter(
                    progress: _confettiController.value,
                  ),
                  child: const SizedBox.expand(),
                );
              },
            ),
            SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 88,
                        height: 88,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x33000000),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          size: 52,
                          color: Color(0xFF0F6876),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        'Thank you for\nyour feedback!',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.boldonse(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w400,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SilverConfettiPainter extends CustomPainter {
  _SilverConfettiPainter({required this.progress}) : _pieces = _buildPieces();

  final double progress;
  final List<_Piece> _pieces;

  static List<_Piece> _buildPieces() {
    final rng = math.Random(21);
    const palette = [
      Color(0xFFFFFFFF),
      Color(0xFFE8EEF0),
      Color(0xFFC9D4D8),
      Color(0xFFB7C4C8),
      Color(0xFF9EB0B6),
    ];
    return List.generate(64, (i) {
      return _Piece(
        x: rng.nextDouble(),
        delay: rng.nextDouble(),
        speed: 0.5 + rng.nextDouble() * 0.9,
        size: 4 + rng.nextDouble() * 10,
        tilt: rng.nextDouble() * math.pi,
        spin: (rng.nextDouble() - 0.5) * 4,
        color: palette[rng.nextInt(palette.length)]
            .withValues(alpha: 0.55 + rng.nextDouble() * 0.4),
      );
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final piece in _pieces) {
      final t = ((progress + piece.delay) * piece.speed) % 1.0;
      final y = -40 + t * (size.height + 80);
      final x = piece.x * size.width +
          math.sin((progress + piece.delay) * math.pi * 2 * piece.spin) * 18;
      final rotation = piece.tilt + progress * piece.spin * math.pi;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation);
      final paint = Paint()
        ..color = piece.color
        ..style = PaintingStyle.fill;
      final w = piece.size * 1.8;
      final h = piece.size * 0.4;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: w, height: h),
          const Radius.circular(1.2),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _SilverConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _Piece {
  const _Piece({
    required this.x,
    required this.delay,
    required this.speed,
    required this.size,
    required this.tilt,
    required this.spin,
    required this.color,
  });

  final double x;
  final double delay;
  final double speed;
  final double size;
  final double tilt;
  final double spin;
  final Color color;
}
