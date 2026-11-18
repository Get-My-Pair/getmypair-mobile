import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gmp/core/bgtheme.dart';
import 'package:gmp/core/constants/api_endpoints.dart';
import 'package:gmp/core/network/dio_client.dart';
import 'package:gmp/features/auth/domain/usecases/get_valid_access_token.dart';
import 'package:gmp/features/payment/config/payment_config.dart';
import 'package:gmp/features/payment/presentation/pages/payment_checkout_page.dart';
import 'package:gmp/features/thrift/thrift_catalog.dart';
import 'package:gmp/injection_container.dart';
import 'package:google_fonts/google_fonts.dart';

/// Delivery details, then the same Zoho checkout used for service payments.
class ThriftCheckoutPage extends StatefulWidget {
  final ThriftProduct product;

  const ThriftCheckoutPage({super.key, required this.product});

  @override
  State<ThriftCheckoutPage> createState() => _ThriftCheckoutPageState();
}

class _ThriftCheckoutPageState extends State<ThriftCheckoutPage> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _line1 = TextEditingController();
  final _line2 = TextEditingController();
  final _city = TextEditingController();
  final _pin = TextEditingController();
  int _qty = 1;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _line1.dispose();
    _line2.dispose();
    _city.dispose();
    _pin.dispose();
    super.dispose();
  }

  double get _total => widget.product.price * _qty;

  Future<void> _pay() async {
    final phone = _phone.text.replaceAll(RegExp(r'\s'), '');
    final pin = _pin.text.trim();
    if (_name.text.trim().isEmpty || _line1.text.trim().isEmpty || _city.text.trim().isEmpty) {
      _toast('Enter name, address and city');
      return;
    }
    if (!RegExp(r'^\d{10}$').hasMatch(phone)) {
      _toast('Enter a 10-digit mobile number');
      return;
    }
    if (!RegExp(r'^\d{6}$').hasMatch(pin)) {
      _toast('Enter a 6-digit pincode');
      return;
    }
    setState(() => _busy = true);
    try {
      final tokenResult = await sl<GetValidAccessToken>().call();
      final token = tokenResult.fold<String?>((_) => null, (value) => value);
      if (token == null) throw Exception('Sign in to pay');
      final res = await sl<DioClient>().post(
        ApiEndpoints.thriftCheckout,
        accessToken: token,
        body: {
          'productId': widget.product.id,
          'qty': _qty,
          'paymentMode': PaymentConfig.defaultMode.apiValue,
          'redirectUrl': PaymentConfig.zohoRedirectUrl,
          'address': {
            'fullName': _name.text.trim(),
            'phone': phone,
            'line1': _line1.text.trim(),
            'line2': _line2.text.trim(),
            'city': _city.text.trim(),
            'pincode': pin,
          },
        },
      );
      final data = (res['data'] as Map?) ?? const {};
      final payment = Map<String, dynamic>.from((data['payment'] as Map?) ?? const {});
      final link = Map<String, dynamic>.from((data['paymentLink'] as Map?) ?? const {});
      final order = Map<String, dynamic>.from((data['order'] as Map?) ?? const {});
      final url = link['url']?.toString() ?? payment['paymentLinkUrl']?.toString() ?? '';
      if (url.isEmpty) throw Exception('Payment link was not created');
      if (!mounted) return;
      final paid = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => PaymentCheckoutPage(
            checkoutUrl: url,
            orderId: payment['orderId']?.toString() ?? '',
            paymentId: payment['_id']?.toString() ?? '',
            serviceRequestId: order['_id']?.toString() ?? widget.product.id,
            amount: (payment['amount'] as num?)?.toDouble() ?? _total,
          ),
        ),
      );
      if (!mounted) return;
      if (paid == true) {
        Navigator.of(context).pop();
        Navigator.of(context).pop();
      }
    } catch (e) {
      _toast(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.product;
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
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF062F35)),
                      ),
                      Text(
                        'Checkout',
                        style: GoogleFonts.boldonse(fontSize: 22, color: const Color(0xFF062F35)),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: SizedBox(width: 72, height: 72, child: ThriftImage(url: item.cover)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.brand, style: GoogleFonts.montserrat(fontSize: 12, color: const Color(0xFF5A5A5A))),
                                  Text(item.title, style: GoogleFonts.montserrat(fontWeight: FontWeight.w700)),
                                  Text(thriftMoney(item.price), style: GoogleFonts.montserrat(fontWeight: FontWeight.w800)),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  onPressed: _qty > 1 ? () => setState(() => _qty -= 1) : null,
                                  icon: const Icon(Icons.remove_circle_outline),
                                ),
                                Text('$_qty', style: GoogleFonts.montserrat(fontWeight: FontWeight.w700)),
                                IconButton(
                                  onPressed: _qty < item.stock && _qty < 5
                                      ? () => setState(() => _qty += 1)
                                      : null,
                                  icon: const Icon(Icons.add_circle_outline),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text('Delivery address', style: GoogleFonts.montserrat(fontWeight: FontWeight.w700, color: const Color(0xFF062F35))),
                      const SizedBox(height: 8),
                      _field(_name, 'Full name'),
                      _field(_phone, 'Mobile', keyboard: TextInputType.phone, digits: 10),
                      _field(_line1, 'Address'),
                      _field(_line2, 'Landmark (optional)'),
                      _field(_city, 'City'),
                      _field(_pin, 'Pincode', keyboard: TextInputType.number, digits: 6),
                      const SizedBox(height: 8),
                      Text(
                        'Total payable ${thriftMoney(_total)}',
                        style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF062F35)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Pay continues in the same secure checkout used for Care My Pair.',
                        style: GoogleFonts.montserrat(fontSize: 12, height: 1.4),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: FilledButton(
                    onPressed: _busy ? null : _pay,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF0F6876),
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(
                      _busy ? 'Opening payment…' : 'Pay ${thriftMoney(_total)}',
                      style: GoogleFonts.montserrat(fontWeight: FontWeight.w700, fontSize: 16),
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

  Widget _field(
    TextEditingController controller,
    String hint, {
    TextInputType keyboard = TextInputType.text,
    int? digits,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: controller,
        keyboardType: keyboard,
        inputFormatters: digits == null
            ? null
            : [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(digits)],
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        ),
      ),
    );
  }
}
