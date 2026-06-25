import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../features/auth/domain/usecases/get_valid_access_token.dart';
import '../../../../injection_container.dart';
import '../bloc/payment_bloc.dart';
import '../bloc/payment_event.dart';
import '../bloc/payment_state.dart';
import '../services/payment_analytics.dart';
import '../../domain/utils/payment_simulate_utils.dart';
import '../utils/payment_amount_formatter.dart';
import '../widgets/payment_loader.dart';
import '../widgets/payment_page_shell.dart';
import 'payment_failed_page.dart';
import 'payment_pending_page.dart';
import 'payment_success_page.dart';

enum _SimulateStage { loading, checkout, processing, done }

/// In-app Zoho-style checkout preview — runs automatically or on user tap.
class PaymentSimulateCheckoutPage extends StatefulWidget {
  final String orderId;
  final String paymentId;
  final String serviceRequestId;
  final double amount;
  final bool autoPlay;
  final bool zohoFallback;

  const PaymentSimulateCheckoutPage({
    super.key,
    required this.orderId,
    required this.paymentId,
    required this.serviceRequestId,
    required this.amount,
    this.autoPlay = true,
    this.zohoFallback = false,
  });

  @override
  State<PaymentSimulateCheckoutPage> createState() =>
      _PaymentSimulateCheckoutPageState();
}

class _PaymentSimulateCheckoutPageState extends State<PaymentSimulateCheckoutPage> {
  _SimulateStage _stage = _SimulateStage.loading;
  int _methodIndex = 0;
  bool _verifying = false;
  Timer? _autoTimer;

  @override
  void initState() {
    super.initState();
    PaymentAnalytics.checkoutOpened(widget.orderId);
    PaymentAnalytics.simulateFlowStarted(
      widget.orderId,
      autoPlay: widget.autoPlay,
      zohoFallback: widget.zohoFallback,
    );
    _startLoading();
  }

  void _startLoading() {
    final delay = widget.autoPlay ? const Duration(milliseconds: 1400) : const Duration(milliseconds: 800);
    _autoTimer = Timer(delay, () {
      if (!mounted) return;
      setState(() => _stage = _SimulateStage.checkout);
      if (widget.autoPlay) _scheduleAutoPay();
    });
  }

  void _scheduleAutoPay() {
    _autoTimer?.cancel();
    _autoTimer = Timer(const Duration(milliseconds: 2200), () {
      if (!mounted || _stage != _SimulateStage.checkout) return;
      _onPayPressed();
    });
  }

  Future<void> _onPayPressed() async {
    if (_stage == _SimulateStage.processing || _stage == _SimulateStage.done) {
      return;
    }
    _autoTimer?.cancel();
    setState(() => _stage = _SimulateStage.processing);

    await Future<void>.delayed(
      widget.autoPlay
          ? const Duration(milliseconds: 1800)
          : const Duration(milliseconds: 1200),
    );
    if (!mounted) return;

    PaymentAnalytics.checkoutCompleted(widget.orderId);
    setState(() {
      _stage = _SimulateStage.done;
      _verifying = true;
    });

    if (PaymentSimulateUtils.isSimulatedOrder(widget.orderId)) {
      _navigateSuccess();
      return;
    }

    final tokenResult = await sl<GetValidAccessToken>().call();
    if (!mounted) return;
    await tokenResult.fold(
      (_) async => _navigateSuccess(),
      (token) async {
        context.read<PaymentBloc>().add(
              PaymentStatusRefreshRequested(
                accessToken: token,
                orderId: widget.orderId,
                refreshFromZoho: false,
              ),
            );
      },
    );
  }

  void _navigateByStatus(String status, String? failureReason) {
    if (status == 'PAYMENT_SUCCESS') {
      _navigateSuccess();
    } else if (status == 'PAYMENT_FAILED') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentFailedPage(
            orderId: widget.orderId,
            serviceRequestId: widget.serviceRequestId,
            amount: widget.amount,
            failureReason: failureReason,
          ),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentPendingPage(
            orderId: widget.orderId,
            serviceRequestId: widget.serviceRequestId,
            amount: widget.amount,
          ),
        ),
      );
    }
  }

  void _navigateSuccess() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentSuccessPage(
          orderId: widget.orderId,
          amount: widget.amount,
          serviceRequestId: widget.serviceRequestId,
          paidAt: DateTime.now(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PaymentBloc, PaymentState>(
      listener: (context, state) {
        if (state is PaymentVerified) {
          setState(() => _verifying = false);
          _navigateByStatus(
            state.result.payment.status,
            state.result.payment.failureReason,
          );
        } else if (state is PaymentError) {
          setState(() => _verifying = false);
          _navigateSuccess();
        }
      },
      child: PaymentPageShell(
        title: 'Secure checkout',
        subtitle: widget.zohoFallback
            ? 'Zoho is unreachable — showing a simulated checkout preview.'
            : 'Simulated Zoho checkout — no real charge.',
        body: _verifying
            ? const PaymentLoader(message: 'Confirming payment…')
            : switch (_stage) {
                _SimulateStage.loading => const PaymentLoader(
                    message: 'Connecting to Zoho secure checkout…',
                  ),
                _SimulateStage.processing => _ProcessingView(
                    amount: widget.amount,
                  ),
                _ => _CheckoutView(
                    amount: widget.amount,
                    orderId: widget.orderId,
                    methodIndex: _methodIndex,
                    autoPlay: widget.autoPlay,
                    onMethodSelected: (i) => setState(() => _methodIndex = i),
                    onPay: _onPayPressed,
                  ),
              },
        bottomBar: _stage == _SimulateStage.checkout
            ? SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: PaymentSecondaryButton(
                    label: widget.autoPlay ? 'Pay now (auto in a moment)' : 'Pay now',
                    onPressed: _onPayPressed,
                  ),
                ),
              )
            : null,
      ),
    );
  }
}

class _CheckoutView extends StatelessWidget {
  const _CheckoutView({
    required this.amount,
    required this.orderId,
    required this.methodIndex,
    required this.autoPlay,
    required this.onMethodSelected,
    required this.onPay,
  });

  final double amount;
  final String orderId;
  final int methodIndex;
  final bool autoPlay;
  final ValueChanged<int> onMethodSelected;
  final VoidCallback onPay;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ZohoHeaderBanner(autoPlay: autoPlay),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0F000000),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'GetMyPair',
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  PaymentAmountFormatter.format(amount),
                  style: GoogleFonts.montserrat(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1A2B3C),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Order ${orderId.length > 16 ? '…${orderId.substring(orderId.length - 10)}' : orderId}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Payment method',
            style: GoogleFonts.montserrat(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: PaymentPageTheme.titleColor,
            ),
          ),
          const SizedBox(height: 10),
          ...List.generate(_SimulateCheckoutMethods.values.length, (i) {
            final method = _SimulateCheckoutMethods.values[i];
            final selected = methodIndex == i;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: selected
                    ? const Color(0xFF0F4C75).withValues(alpha: 0.08)
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: () => onMethodSelected(i),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected
                            ? const Color(0xFF0F4C75)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(method.icon, color: const Color(0xFF0F4C75)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            method.label,
                            style: GoogleFonts.montserrat(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        if (selected)
                          const Icon(
                            Icons.check_circle,
                            color: Color(0xFF0F4C75),
                            size: 20,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 12),
          _MethodFields(method: _SimulateCheckoutMethods.values[methodIndex]),
        ],
      ),
    );
  }
}

enum _SimulateCheckoutMethods {
  upi('UPI', Icons.qr_code_2_rounded),
  card('Credit / Debit Card', Icons.credit_card_rounded),
  netBanking('Net Banking', Icons.account_balance_rounded);

  const _SimulateCheckoutMethods(this.label, this.icon);
  final String label;
  final IconData icon;
}

class _MethodFields extends StatelessWidget {
  const _MethodFields({required this.method});

  final _SimulateCheckoutMethods method;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: switch (method) {
        _SimulateCheckoutMethods.upi => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _fakeField('UPI ID', 'demo@upi'),
              const SizedBox(height: 10),
              const Text(
                'Test UPI — simulation only',
                style: TextStyle(fontSize: 11, color: AppColors.textTertiary),
              ),
            ],
          ),
        _SimulateCheckoutMethods.card => Column(
            children: [
              _fakeField('Card number', '4111 1111 1111 1111'),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _fakeField('Expiry', '12/28')),
                  const SizedBox(width: 10),
                  Expanded(child: _fakeField('CVV', '•••')),
                ],
              ),
            ],
          ),
        _SimulateCheckoutMethods.netBanking => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _fakeField('Bank', 'Demo Bank Ltd.'),
              const SizedBox(height: 10),
              const Text(
                'Redirect simulation — no bank login required',
                style: TextStyle(fontSize: 11, color: AppColors.textTertiary),
              ),
            ],
          ),
      },
    );
  }

  Widget _fakeField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Text(
            value,
            style: GoogleFonts.montserrat(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _ZohoHeaderBanner extends StatelessWidget {
  const _ZohoHeaderBanner({required this.autoPlay});

  final bool autoPlay;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F4C75), Color(0xFF1B6CA8)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.lock_rounded, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Zoho Payments',
                  style: GoogleFonts.montserrat(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                Text(
                  autoPlay
                      ? 'Simulation — flow will run automatically'
                      : 'Simulation — tap Pay when ready',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.amber.shade600,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'DEMO',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProcessingView extends StatelessWidget {
  const _ProcessingView({required this.amount});

  final double amount;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 56,
              height: 56,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: Color(0xFF0F4C75),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Processing payment…',
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: PaymentPageTheme.titleColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              PaymentAmountFormatter.format(amount),
              style: GoogleFonts.montserrat(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: PaymentPageTheme.accentColor,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Please wait while we simulate the Zoho authorization step.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
