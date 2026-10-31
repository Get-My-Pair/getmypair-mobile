import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../service/presentation/pages/service_request_details_page.dart';
import '../services/payment_analytics.dart';

/// Full-screen Zoho payment success celebration (Figma success popup).
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
  static const _sweep = SweepGradient(
    center: Alignment(0.22, -1.07),
    startAngle: -0.55,
    endAngle: 5.73,
    colors: [
      Color(0xFF09E0FF),
      Color(0xFF0F6876),
      Color(0xFF062F35),
      Color(0xFF062F35),
    ],
    stops: [0.05, 0.44, 0.57, 1],
    transform: GradientRotation(-0.55),
  );

  late final AnimationController _popupController;
  late final AnimationController _confettiController;
  late final AnimationController _actionsController;
  late final Animation<double> _popupScale;
  late final Animation<double> _popupFade;
  late final Animation<double> _checkScale;

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
    _actionsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );

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
    Future<void>.delayed(const Duration(milliseconds: 1100), () {
      if (mounted) _actionsController.forward();
    });
  }

  @override
  void dispose() {
    _popupController.dispose();
    _confettiController.dispose();
    _actionsController.dispose();
    super.dispose();
  }

  void _viewRequest() {
    Navigator.of(context).popUntil((route) => route.isFirst);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ServiceRequestDetailsPage(
          requestId: widget.serviceRequestId,
        ),
      ),
    );
  }

  void _goHome() {
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFFAFAFA),
        body: Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(decoration: BoxDecoration(gradient: _sweep)),
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
              child: Column(
                children: [
                  Expanded(
                    child: Center(
                      child: FadeTransition(
                        opacity: _popupFade,
                        child: ScaleTransition(
                          scale: _popupScale,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 48),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ScaleTransition(
                                  scale: _checkScale,
                                  child: Container(
                                    width: 72,
                                    height: 72,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Color(0x33000000),
                                          blurRadius: 16,
                                          offset: Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.check_rounded,
                                      size: 40,
                                      color: Color(0xFF062F35),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 18),
                                Text(
                                  'Payment Successful!',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.boldonse(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                const SizedBox(height: 18),
                                Text(
                                  'Your transaction was completed successfully. Order is confirmed!',
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
                  FadeTransition(
                    opacity: _actionsController,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.25),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent: _actionsController,
                          curve: Curves.easeOutCubic,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                        child: Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(100),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x19000000),
                                      blurRadius: 4,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: TextButton(
                                  onPressed: _viewRequest,
                                  style: TextButton.styleFrom(
                                    foregroundColor: const Color(0xFF062F35),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(100),
                                    ),
                                  ),
                                  child: Text(
                                    'View service request',
                                    style: GoogleFonts.boldonse(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextButton(
                              onPressed: _goHome,
                              child: Text(
                                'Back to home',
                                style: GoogleFonts.montserrat(
                                  color: Colors.white.withValues(alpha: 0.92),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
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
        // Motion-blur streak for some pieces.
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
