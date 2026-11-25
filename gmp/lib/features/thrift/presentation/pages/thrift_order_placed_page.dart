import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gmp/core/bgtheme.dart';
import 'package:gmp/features/thrift/thrift_catalog.dart';
import 'package:google_fonts/google_fonts.dart';

/// Post-payment confirmation for Thrift Store (same success shell as Care My Pair).
class ThriftOrderPlacedPage extends StatelessWidget {
  final ThriftProduct product;
  final String orderId;
  final String paymentOrderId;
  final double amount;
  final int qty;
  final String deliveryLine;
  final String customerLabel;

  const ThriftOrderPlacedPage({
    super.key,
    required this.product,
    required this.orderId,
    required this.paymentOrderId,
    required this.amount,
    required this.qty,
    required this.deliveryLine,
    required this.customerLabel,
  });

  static const _onBg = Color(0xFFFFFFFF);
  static const _onBgMuted = Color(0xFFE8F4F6);
  static const _ink = Color(0xFF062F35);
  static const _accent = Color(0xFF0F6876);
  static const _checkAsset = 'assets/images/payment/payment_success_check.png';

  String get _displayOrderId {
    final raw = paymentOrderId.trim().isNotEmpty ? paymentOrderId.trim() : orderId.trim();
    if (raw.isEmpty) return '—';
    return raw.length > 14 ? raw.substring(0, 12).toUpperCase() : raw.toUpperCase();
  }

  void _done(BuildContext context) {
    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.pop();
      return;
    }
    nav.popUntil((route) => route.isFirst);
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
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: Column(
                  children: [
                    Expanded(
                      child: ListView(
                        children: [
                          const SizedBox(height: 28),
                          Center(
                            child: SizedBox(
                              width: 96,
                              height: 96,
                              child: Image.asset(
                                _checkAsset,
                                fit: BoxFit.contain,
                                errorBuilder: (_, _, _) => const DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.check_rounded, size: 56, color: _ink),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Order placed!',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.boldonse(
                              color: _onBg,
                              fontSize: 26,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Payment successful. Your Thrift Store\norder is confirmed.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.montserrat(
                              color: _onBg,
                              fontSize: 16,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 22),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Order $_displayOrderId',
                                  style: GoogleFonts.montserrat(
                                    fontWeight: FontWeight.w700,
                                    color: _ink,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: SizedBox(
                                        width: 64,
                                        height: 64,
                                        child: ThriftImage(url: product.cover),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            product.brand,
                                            style: GoogleFonts.montserrat(
                                              fontSize: 12,
                                              color: const Color(0xFF5A5A5A),
                                            ),
                                          ),
                                          Text(
                                            product.title,
                                            style: GoogleFonts.montserrat(
                                              fontWeight: FontWeight.w700,
                                              color: _ink,
                                            ),
                                          ),
                                          Text(
                                            'Qty $qty · ${thriftMoney(amount)}',
                                            style: GoogleFonts.montserrat(
                                              fontWeight: FontWeight.w600,
                                              color: _ink,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 24),
                                Text(
                                  'Delivery',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF5A5A5A),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                if (customerLabel.isNotEmpty)
                                  Text(
                                    customerLabel,
                                    style: GoogleFonts.montserrat(
                                      fontWeight: FontWeight.w600,
                                      color: _ink,
                                    ),
                                  ),
                                Text(
                                  deliveryLine.isEmpty ? 'Saved address' : deliveryLine,
                                  style: GoogleFonts.montserrat(
                                    color: const Color(0xFF5A5A5A),
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'We’ll prepare your pair for delivery. You can track updates from notifications.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.montserrat(
                              color: _onBgMuted,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    FilledButton(
                      onPressed: () => _done(context),
                      style: FilledButton.styleFrom(
                        backgroundColor: _accent,
                        foregroundColor: _onBg,
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(
                        'Done',
                        style: GoogleFonts.montserrat(fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
