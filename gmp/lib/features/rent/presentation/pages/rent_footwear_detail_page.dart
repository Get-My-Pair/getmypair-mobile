import 'package:flutter/material.dart';
import 'package:gmp/core/bgtheme.dart';
import 'package:gmp/core/constants/api_endpoints.dart';
import 'package:gmp/core/network/dio_client.dart';
import 'package:gmp/features/auth/domain/usecases/get_valid_access_token.dart';
import 'package:gmp/features/payment/config/payment_config.dart';
import 'package:gmp/features/payment/presentation/pages/payment_checkout_page.dart';
import 'package:gmp/features/payment/presentation/pages/payment_simulate_checkout_page.dart';
import 'package:gmp/features/rent/data/rent_remote_datasource.dart';
import 'package:gmp/features/thrift/thrift_catalog.dart';
import 'package:gmp/injection_container.dart';
import 'package:google_fonts/google_fonts.dart';

/// Product page for one approved rent listing. Payment is Zoho only.
class RentFootwearDetailPage extends StatefulWidget {
  final RentListing listing;
  final bool mine;

  const RentFootwearDetailPage({super.key, required this.listing, this.mine = false});

  @override
  State<RentFootwearDetailPage> createState() => _RentFootwearDetailPageState();
}

class _RentFootwearDetailPageState extends State<RentFootwearDetailPage> {
  static const _onBg = Color(0xFFFFFFFF);
  static const _onBgMuted = Color(0xFFE8F4F6);
  static const _accent = Color(0xFF0F6876);

  bool _busy = false;

  Future<void> _pay() async {
    if (_busy || widget.mine) return;
    setState(() => _busy = true);
    try {
      final tokenResult = await sl<GetValidAccessToken>().call();
      final token = tokenResult.fold<String?>((_) => null, (value) => value);
      if (token == null) throw Exception('Sign in to pay');
      final res = await sl<DioClient>().post(
        ApiEndpoints.rentCheckout,
        accessToken: token,
        body: {
          'listingId': widget.listing.id,
          'paymentMode': PaymentConfig.defaultMode.apiValue,
          'redirectUrl': PaymentConfig.zohoRedirectUrl,
        },
      );
      final data = (res['data'] as Map?) ?? const {};
      final payment = Map<String, dynamic>.from((data['payment'] as Map?) ?? const {});
      final link = Map<String, dynamic>.from((data['paymentLink'] as Map?) ?? const {});
      final paymentOrderId = payment['orderId']?.toString() ?? '';
      final paymentId = payment['_id']?.toString() ?? '';
      final amount = (payment['amount'] as num?)?.toDouble() ?? widget.listing.price.toDouble();
      final url = link['url']?.toString() ?? payment['paymentLinkUrl']?.toString() ?? '';
      if (url.isEmpty && !PaymentConfig.enableSimulateFallback) {
        throw Exception('Payment link was not created');
      }
      if (!mounted) return;
      final paid = await _openCheckout(
        checkoutUrl: url,
        orderId: paymentOrderId,
        paymentId: paymentId,
        amount: amount,
      );
      if (!mounted || paid != true) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Payment received'),
          content: Text(
            '₹${widget.listing.price} is paid for ${widget.listing.durationLabel}. '
            'The owner can see this payment request.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
          ],
        ),
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool?> _openCheckout({
    required String checkoutUrl,
    required String orderId,
    required String paymentId,
    required double amount,
  }) {
    if (checkoutUrl.isEmpty && PaymentConfig.enableSimulateFallback) {
      return Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => PaymentSimulateCheckoutPage(
            orderId: orderId,
            paymentId: paymentId,
            serviceRequestId: widget.listing.id,
            amount: amount,
            autoPlay: true,
            zohoFallback: true,
          ),
        ),
      );
    }
    return Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PaymentCheckoutPage(
          checkoutUrl: checkoutUrl,
          orderId: orderId,
          paymentId: paymentId,
          serviceRequestId: widget.listing.id,
          amount: amount,
          onZohoUnavailable: PaymentConfig.enableSimulateFallback
              ? () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => PaymentSimulateCheckoutPage(
                        orderId: orderId,
                        paymentId: paymentId,
                        serviceRequestId: widget.listing.id,
                        amount: amount,
                        autoPlay: true,
                        zohoFallback: true,
                      ),
                    ),
                  );
                }
              : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.listing;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          ...BgTheme.background(),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 4, 16, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: _busy ? null : () => Navigator.maybePop(context),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _onBg),
                      ),
                      Expanded(
                        child: Text(
                          'Rent footwear',
                          style: GoogleFonts.boldonse(fontSize: 18, color: _onBg),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: ColoredBox(
                          color: Colors.white,
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: ThriftImage(url: item.imageUrl, fit: BoxFit.contain),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        item.ownerName.isEmpty ? 'Community pair' : item.ownerName,
                        style: GoogleFonts.montserrat(color: _onBgMuted, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        item.title,
                        style: GoogleFonts.montserrat(fontSize: 20, fontWeight: FontWeight.w700, color: _onBg),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        thriftMoney(item.price),
                        style: GoogleFonts.montserrat(fontSize: 24, fontWeight: FontWeight.w800, color: _onBg),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Rent duration · ${item.durationLabel}',
                        style: GoogleFonts.montserrat(color: _onBgMuted, height: 1.4),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: FilledButton(
                    onPressed: widget.mine || _busy ? null : _pay,
                    style: FilledButton.styleFrom(
                      backgroundColor: _accent,
                      foregroundColor: _onBg,
                      disabledBackgroundColor: _onBg.withValues(alpha: 0.35),
                      disabledForegroundColor: _onBg,
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(
                      widget.mine
                          ? 'Your listing'
                          : _busy
                              ? 'Opening payment…'
                              : 'Pay ${thriftMoney(item.price)}',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
