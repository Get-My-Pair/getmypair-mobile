import 'package:flutter/material.dart';
import 'package:gmp/core/bgtheme.dart';
import 'package:gmp/core/constants/api_endpoints.dart';
import 'package:gmp/core/network/dio_client.dart';
import 'package:gmp/features/auth/domain/usecases/get_valid_access_token.dart';
import 'package:gmp/features/payment/config/payment_config.dart';
import 'package:gmp/features/payment/presentation/pages/payment_checkout_page.dart';
import 'package:gmp/features/payment/presentation/pages/payment_simulate_checkout_page.dart';
import 'package:gmp/features/profile/domain/entities/address.dart';
import 'package:gmp/features/profile/domain/entities/user_profile.dart';
import 'package:gmp/features/profile/domain/usecases/get_user_profile.dart';
import 'package:gmp/features/profile/presentation/pages/saved_addresses_page.dart';
import 'package:gmp/features/service/presentation/pages/select_address_page.dart';
import 'package:gmp/features/thrift/presentation/pages/thrift_order_placed_page.dart';
import 'package:gmp/features/thrift/thrift_catalog.dart';
import 'package:gmp/injection_container.dart';
import 'package:google_fonts/google_fonts.dart';

/// Thrift Store checkout: uses saved profile address (no manual address form).
class ThriftCheckoutPage extends StatefulWidget {
  final ThriftProduct product;

  const ThriftCheckoutPage({super.key, required this.product});

  @override
  State<ThriftCheckoutPage> createState() => _ThriftCheckoutPageState();
}

class _ThriftCheckoutPageState extends State<ThriftCheckoutPage> {
  static const _onBg = Color(0xFFFFFFFF);
  static const _onBgMuted = Color(0xFFE8F4F6);
  static const _ink = Color(0xFF062F35);
  static const _accent = Color(0xFF0F6876);

  UserProfile? _profile;
  Address? _address;
  int _qty = 1;
  bool _loading = true;
  bool _busy = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  double get _total => widget.product.price * _qty;

  String get _phoneDigits {
    final raw = (_profile?.phone ?? '').replaceAll(RegExp(r'\D'), '');
    if (raw.length >= 10) return raw.substring(raw.length - 10);
    return raw;
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final tokenResult = await sl<GetValidAccessToken>().call();
      final token = tokenResult.fold<String?>((_) => null, (value) => value);
      if (token == null) throw Exception('Sign in to continue');
      final profile = await sl<GetUserProfile>().call(token);
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _address = profile.addresses.isNotEmpty ? profile.addresses.first : null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _pickAddress() async {
    final picked = await Navigator.of(context).push<Address>(
      MaterialPageRoute(
        builder: (_) => SelectAddressPage(selectedAddressId: _address?.id),
      ),
    );
    if (picked != null && mounted) {
      setState(() => _address = picked);
      return;
    }
    // Refresh in case user added an address from Profile while this page stayed open.
    if (!mounted) return;
    await _loadProfile();
  }

  Future<void> _openSavedAddresses() async {
    final tokenResult = await sl<GetValidAccessToken>().call();
    final token = tokenResult.fold<String?>((_) => null, (value) => value);
    if (token == null || _profile == null || !mounted) {
      _toast('Sign in to manage addresses');
      return;
    }
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => SavedAddressesPage(profile: _profile!, accessToken: token),
      ),
    );
    if (mounted) await _loadProfile();
  }

  Future<void> _payNow() async {
    if (_busy) return;

    if (_profile?.addresses.isEmpty ?? true) {
      await _openSavedAddresses();
      if (_address == null) {
        _toast('Add a delivery address, then tap Pay now');
        return;
      }
    } else {
      final picked = await Navigator.of(context).push<Address>(
        MaterialPageRoute(
          builder: (_) => SelectAddressPage(selectedAddressId: _address?.id),
        ),
      );
      if (!mounted) return;
      if (picked == null) return;
      setState(() => _address = picked);
    }

    final name = (_profile?.activeDisplayName ?? _profile?.name ?? '').trim();
    final phone = _phoneDigits;
    final line1 = _address!.addressLine1.trim();
    final city = _address!.city.trim();
    final pin = _address!.pincode.trim();
    if (name.isEmpty) {
      _toast('Update your name in Profile before paying');
      return;
    }
    if (!RegExp(r'^\d{10}$').hasMatch(phone)) {
      _toast('Update your mobile number in Profile before paying');
      return;
    }
    if (line1.isEmpty || city.isEmpty || !RegExp(r'^\d{6}$').hasMatch(pin)) {
      _toast('Select a complete delivery address');
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
            'fullName': name,
            'phone': phone,
            'line1': line1,
            'line2': _address!.state.trim(),
            'city': city,
            'pincode': pin,
          },
        },
      );
      final data = (res['data'] as Map?) ?? const {};
      final payment = Map<String, dynamic>.from((data['payment'] as Map?) ?? const {});
      final link = Map<String, dynamic>.from((data['paymentLink'] as Map?) ?? const {});
      final order = Map<String, dynamic>.from((data['order'] as Map?) ?? const {});
      final orderId = order['_id']?.toString() ?? '';
      final paymentOrderId = payment['orderId']?.toString() ?? '';
      final paymentId = payment['_id']?.toString() ?? '';
      final amount = (payment['amount'] as num?)?.toDouble() ?? _total;
      final url = link['url']?.toString() ?? payment['paymentLinkUrl']?.toString() ?? '';
      if (url.isEmpty && !PaymentConfig.enableSimulateFallback) {
        throw Exception('Payment link was not created');
      }
      if (!mounted) return;

      final paid = await _openThriftCheckout(
        checkoutUrl: url,
        orderId: paymentOrderId,
        paymentId: paymentId,
        thriftOrderId: orderId.isNotEmpty ? orderId : widget.product.id,
        amount: amount,
      );
      if (!mounted) return;
      if (paid == true) {
        final customer = [
          name,
          phone,
        ].where((s) => s.trim().isNotEmpty).join(' · ');
        final deliveryLine = [
          _address!.addressLine1.trim(),
          [
            _address!.city.trim(),
            _address!.state.trim(),
            if (_address!.pincode.trim().isNotEmpty) '- ${_address!.pincode.trim()}',
          ].where((s) => s.isNotEmpty).join(' '),
        ].where((s) => s.isNotEmpty).join('\n');

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute<void>(
            settings: const RouteSettings(name: 'thrift_order_placed'),
            builder: (_) => ThriftOrderPlacedPage(
              product: widget.product,
              orderId: orderId,
              paymentOrderId: paymentOrderId,
              amount: amount,
              qty: _qty,
              deliveryLine: deliveryLine,
              customerLabel: customer,
            ),
          ),
          (route) => route.settings.name == 'thrift_store' || route.isFirst,
        );
      }
    } catch (e) {
      _toast(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool?> _openThriftCheckout({
    required String checkoutUrl,
    required String orderId,
    required String paymentId,
    required String thriftOrderId,
    required double amount,
  }) async {
    Future<bool?> openSimulate({required bool zohoFallback}) {
      return Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => PaymentSimulateCheckoutPage(
            orderId: orderId,
            paymentId: paymentId,
            serviceRequestId: thriftOrderId,
            amount: amount,
            autoPlay: true,
            zohoFallback: zohoFallback,
          ),
        ),
      );
    }

    if (checkoutUrl.isEmpty && PaymentConfig.enableSimulateFallback) {
      return openSimulate(zohoFallback: true);
    }

    return Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PaymentCheckoutPage(
          checkoutUrl: checkoutUrl,
          orderId: orderId,
          paymentId: paymentId,
          serviceRequestId: thriftOrderId,
          amount: amount,
          onZohoUnavailable: PaymentConfig.enableSimulateFallback
              ? () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => PaymentSimulateCheckoutPage(
                        orderId: orderId,
                        paymentId: paymentId,
                        serviceRequestId: thriftOrderId,
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
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _onBg),
                      ),
                      Text(
                        'Checkout',
                        style: GoogleFonts.boldonse(fontSize: 22, color: _onBg),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator(color: _onBg))
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                          children: [
                            if (_error.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Text(
                                  _error,
                                  style: GoogleFonts.montserrat(color: _onBgMuted, height: 1.4),
                                ),
                              ),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: SizedBox(
                                      width: 72,
                                      height: 72,
                                      child: ThriftImage(url: item.cover),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.brand,
                                          style: GoogleFonts.montserrat(
                                            fontSize: 12,
                                            color: const Color(0xFF5A5A5A),
                                          ),
                                        ),
                                        Text(
                                          item.title,
                                          style: GoogleFonts.montserrat(
                                            fontWeight: FontWeight.w700,
                                            color: _ink,
                                          ),
                                        ),
                                        Text(
                                          thriftMoney(item.price),
                                          style: GoogleFonts.montserrat(
                                            fontWeight: FontWeight.w800,
                                            color: _ink,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        onPressed: _qty > 1 && !_busy
                                            ? () => setState(() => _qty -= 1)
                                            : null,
                                        icon: const Icon(Icons.remove_circle_outline, color: _ink),
                                      ),
                                      Text(
                                        '$_qty',
                                        style: GoogleFonts.montserrat(
                                          fontWeight: FontWeight.w700,
                                          color: _ink,
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: !_busy &&
                                                _qty < item.stock &&
                                                _qty < 5
                                            ? () => setState(() => _qty += 1)
                                            : null,
                                        icon: const Icon(Icons.add_circle_outline, color: _ink),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              'Delivery address',
                              style: GoogleFonts.montserrat(
                                fontWeight: FontWeight.w700,
                                color: _onBg,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _addressCard(),
                              if (_profile != null) ...[
                              const SizedBox(height: 10),
                              Text(
                                '${_profile!.activeDisplayName.isNotEmpty ? _profile!.activeDisplayName : _profile!.name}'
                                '${_phoneDigits.length == 10 ? ' · $_phoneDigits' : ''}',
                                style: GoogleFonts.montserrat(
                                  fontSize: 12,
                                  color: _onBgMuted,
                                ),
                              ),
                            ],
                            const SizedBox(height: 16),
                            Text(
                              'Total payable ${thriftMoney(_total)}',
                              style: GoogleFonts.montserrat(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: _onBg,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Secure Thrift Store checkout. Your profile and saved address are used automatically.',
                              style: GoogleFonts.montserrat(
                                fontSize: 12,
                                height: 1.4,
                                color: _onBgMuted,
                              ),
                            ),
                          ],
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: FilledButton(
                    onPressed: _loading || _busy ? null : _payNow,
                    style: FilledButton.styleFrom(
                      backgroundColor: _accent,
                      foregroundColor: _onBg,
                      disabledBackgroundColor: _onBg.withValues(alpha: 0.35),
                      disabledForegroundColor: _onBg,
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(
                      _busy
                          ? 'Opening payment…'
                          : 'Pay now · ${thriftMoney(_total)}',
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

  Widget _addressCard() {
    if (_address == null) {
      return Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: _busy
              ? null
              : () async {
                  if (_profile?.addresses.isEmpty ?? true) {
                    await _openSavedAddresses();
                  } else {
                    await _pickAddress();
                  }
                },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                const Icon(Icons.add_location_alt_outlined, color: _accent),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Select a saved delivery address',
                    style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.w600,
                      color: _ink,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right, color: _ink),
              ],
            ),
          ),
        ),
      );
    }

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: _busy ? null : _pickAddress,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on_outlined, color: _accent),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _address!.addressLine1,
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w700,
                        color: _ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_address!.city}, ${_address!.state} - ${_address!.pincode}',
                      style: GoogleFonts.montserrat(
                        fontSize: 13,
                        color: const Color(0xFF5A5A5A),
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Change',
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _accent,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: _ink),
            ],
          ),
        ),
      ),
    );
  }
}
