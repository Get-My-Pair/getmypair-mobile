import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/bgtheme.dart';
import '../services/payment_analytics.dart';

/// Full-screen Zoho payment success celebration.
class PaymentSuccessPage extends StatefulWidget {
  final String orderId;
  final double amount;
  final String serviceRequestId;
  final DateTime? paidAt;

  const PaymentSuccessPage({
    super.key,
    required this.orderId,
    required this.amount,
    required this.serviceRequestId,
    this.paidAt,
  });

  @override
  State<PaymentSuccessPage> createState() => _PaymentSuccessPageState();
}

class _PaymentSuccessPageState extends State<PaymentSuccessPage>
    with TickerProviderStateMixin {
  static const _checkAsset =
      'assets/images/payment/payment_success_check.png';
  static const _homeDelay = Duration(seconds: 6);

  late final AnimationController _popupController;
  late final AnimationController _confettiController;
  late final Animation<double> _popupScale;
  late final Animation<double> _popupFade;
  late final Animation<double> _checkScale;
  Timer? _homeTimer;

  @override
  void initState() {
    super.initState();
    PaymentAnalytics.paymentSuccess(widget.orderId, widget.amount);

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
    _homeTimer = Timer(_homeDelay, _goHome);
  }

  @override
  void dispose() {
    _homeTimer?.cancel();
    _popupController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _goHome() {
    if (!mounted) return;
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final contentWidth = (width * 0.78).clamp(260.0, 340.0);

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
                            child: Image.asset(
                              _checkAsset,
                              width: 72,
                              height: 72,
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.high,
                            ),
                          ),
                          const SizedBox(height: 22),
                          Text(
                            'Payment Successful!',
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            softWrap: false,
                            overflow: TextOverflow.visible,
                            style: GoogleFonts.boldonse(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w400,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'Your transaction was\n'
                            'completed successfully. Order\n'
                            'is confirmed!',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.montserrat(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w400,
                              height: 1.35,
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
