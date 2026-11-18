import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gmp/core/bgtheme.dart';

/// Confetti thank-you after Service History review — same shell as payment success.
/// Copy always breaks as (2nd line centered under the 1st):
///   Thank you for your
///        feedback!
class ServiceReviewThanksPage extends StatefulWidget {
  const ServiceReviewThanksPage({super.key});

  @override
  State<ServiceReviewThanksPage> createState() =>
      _ServiceReviewThanksPageState();
}

class _ServiceReviewThanksPageState extends State<ServiceReviewThanksPage>
    with TickerProviderStateMixin {
  static const _checkAsset =
      'assets/images/payment/payment_success_check.png';
  static const _homeDelay = Duration(milliseconds: 2800);

  late final AnimationController _popupController;
  late final AnimationController _confettiController;
  late final Animation<double> _popupScale;
  late final Animation<double> _popupFade;
  late final Animation<double> _checkScale;
  Timer? _homeTimer;

  @override
  void initState() {
    super.initState();

    _popupController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 780),
    );
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    )..repeat();

    _popupScale = CurvedAnimation(
      parent: _popupController,
      curve: Curves.elasticOut,
    );
    _popupFade = CurvedAnimation(
      parent: _popupController,
      curve: const Interval(0, 0.45, curve: Curves.easeOut),
    );
    _checkScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: 1.18), weight: 55),
      TweenSequenceItem(tween: Tween(begin: 1.18, end: 1), weight: 45),
    ]).animate(
      CurvedAnimation(
        parent: _popupController,
        curve: const Interval(0.08, 0.75, curve: Curves.easeOutCubic),
      ),
    );

    _popupController.forward();
    _homeTimer = Timer(_homeDelay, _finish);
  }

  @override
  void dispose() {
    _homeTimer?.cancel();
    _popupController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _finish() {
    if (!mounted) return;
    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.pop(true);
      return;
    }
    nav.popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final contentWidth = (width * 0.82).clamp(260.0, 340.0);
    final titleSize = (width * 0.062).clamp(20.0, 24.0);

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
                  painter: _ConfettiPainter(progress: _confettiController.value),
                  child: const SizedBox.expand(),
                );
              },
            ),
            SafeArea(
              child: Center(
                child: FadeTransition(
                  opacity: _popupFade,
                  child: ScaleTransition(
                    scale: _popupScale,
                    child: SizedBox(
                      width: contentWidth,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ScaleTransition(
                            scale: _checkScale,
                            child: const _SuccessCheckBadge(
                              assetPath: _checkAsset,
                            ),
                          ),
                          const SizedBox(height: 32),
                          // Two separate lines so "feedback!" stays centered
                          // under line 1 with lead-in space on every device.
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  'Thank you for your',
                                  softWrap: false,
                                  style: GoogleFonts.boldonse(
                                    color: Colors.white,
                                    fontSize: titleSize,
                                    fontWeight: FontWeight.w400,
                                    height: 1.35,
                                    letterSpacing: 0,
                                  ),
                                ),
                                Text(
                                  'feedback!',
                                  softWrap: false,
                                  style: GoogleFonts.boldonse(
                                    color: Colors.white,
                                    fontSize: titleSize,
                                    fontWeight: FontWeight.w400,
                                    height: 1.35,
                                    letterSpacing: 0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
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

class _SuccessCheckBadge extends StatelessWidget {
  const _SuccessCheckBadge({required this.assetPath});

  final String assetPath;

  static const double _size = 96;
  static const Color _checkColor = Color(0xFF062F35);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _size,
      height: _size,
      child: Image.asset(
        assetPath,
        width: _size,
        height: _size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => const DecoratedBox(
          decoration: BoxDecoration(
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
          child: Icon(
            Icons.check_rounded,
            size: 56,
            color: _checkColor,
          ),
        ),
      ),
    );
  }
}

class _ConfettiPiece {
  const _ConfettiPiece({
    required this.x,
    required this.delay,
    required this.speed,
    required this.size,
    required this.tilt,
    required this.spin,
    required this.color,
    required this.rect,
  });

  final double x;
  final double delay;
  final double speed;
  final double size;
  final double tilt;
  final double spin;
  final Color color;
  final bool rect;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({required this.progress}) : _pieces = _buildPieces();

  final double progress;
  final List<_ConfettiPiece> _pieces;

  static List<_ConfettiPiece> _buildPieces() {
    final rng = math.Random(42);
    const palette = [
      Color(0xFFFFFFFF),
      Color(0xFFE8EEF0),
      Color(0xFFC9D4D8),
      Color(0xFFB7C4C8),
      Color(0xFF9EB0B6),
      Color(0xFFDCE8EC),
    ];
    return List.generate(56, (i) {
      return _ConfettiPiece(
        x: rng.nextDouble(),
        delay: rng.nextDouble(),
        speed: 0.55 + rng.nextDouble() * 0.85,
        size: 4 + rng.nextDouble() * 9,
        tilt: rng.nextDouble() * math.pi,
        spin: (rng.nextDouble() - 0.5) * 4,
        color: palette[rng.nextInt(palette.length)]
            .withValues(alpha: 0.55 + rng.nextDouble() * 0.4),
        rect: rng.nextBool(),
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
        ..style = PaintingStyle.fill
        ..isAntiAlias = true;

      if (piece.rect) {
        final w = piece.size * (1.2 + (piece.spin.abs() % 1) * 1.6);
        final h = piece.size * 0.45;
        if (piece.size > 9) {
          paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2);
        }
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: w, height: h),
            const Radius.circular(1.5),
          ),
          paint,
        );
      } else {
        canvas.drawCircle(Offset.zero, piece.size * 0.35, paint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
