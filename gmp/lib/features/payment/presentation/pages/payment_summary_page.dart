import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/chevron_screen_back_button.dart';
import '../../../../features/auth/domain/usecases/get_valid_access_token.dart';
import '../../../../injection_container.dart';
import '../bloc/payment_bloc.dart';
import '../bloc/payment_event.dart';
import '../bloc/payment_state.dart';
import '../services/payment_analytics.dart';
import '../services/payment_error_handler.dart';
import '../utils/payment_amount_formatter.dart';
import '../widgets/pay_now_button.dart';
import '../widgets/payment_loader.dart';
import 'payment_checkout_page.dart';

class PaymentSummaryPage extends StatefulWidget {
  final String serviceRequestId;
  final double amount;
  final String? serviceType;
  final String? requestLabel;

  const PaymentSummaryPage({
    super.key,
    required this.serviceRequestId,
    required this.amount,
    this.serviceType,
    this.requestLabel,
  });

  @override
  State<PaymentSummaryPage> createState() => _PaymentSummaryPageState();
}

class _PaymentSummaryPageState extends State<PaymentSummaryPage> {
  String? _accessToken;
  bool _loadingToken = true;

  @override
  void initState() {
    super.initState();
    PaymentAnalytics.paymentSummaryViewed(
      widget.serviceRequestId,
      widget.amount,
    );
    _loadToken();
  }

  Future<void> _loadToken() async {
    final result = await sl<GetValidAccessToken>().call();
    if (!mounted) return;
    result.fold(
      (f) => setState(() {
        _loadingToken = false;
        _accessToken = null;
      }),
      (token) => setState(() {
        _loadingToken = false;
        _accessToken = token;
      }),
    );
  }

  void _proceedToCheckout() {
    final token = _accessToken;
    if (token == null) return;
    context.read<PaymentBloc>().add(
          PaymentLinkCreateRequested(
            accessToken: token,
            serviceRequestId: widget.serviceRequestId,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PaymentBloc, PaymentState>(
      listener: (context, state) {
        if (state is PaymentLinkReady) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: context.read<PaymentBloc>(),
                child: PaymentCheckoutPage(
                  checkoutUrl: state.linkResult.checkoutUrl,
                  orderId: state.linkResult.payment.orderId,
                  paymentId: state.linkResult.payment.id,
                  serviceRequestId: widget.serviceRequestId,
                  amount: state.linkResult.payment.amount,
                ),
              ),
            ),
          );
        } else if (state is PaymentError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          leading: const ChevronScreenBackButton(
            iconColor: AppColors.textPrimary,
          ),
          title: Text(
            'Payment summary',
            style: GoogleFonts.montserrat(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        body: _loadingToken
            ? const PaymentLoader(message: 'Loading…')
            : _accessToken == null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Please sign in again to continue.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  )
                : BlocBuilder<PaymentBloc, PaymentState>(
                    builder: (context, state) {
                      final loading = state is PaymentLoading;
                      return SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _summaryCard(),
                            const SizedBox(height: 16),
                            _row('Service request', widget.serviceRequestId),
                            if (widget.serviceType != null)
                              _row('Service', widget.serviceType!),
                            _row(
                              'Amount due',
                              PaymentAmountFormatter.format(widget.amount),
                              bold: true,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Payments are processed securely via Zoho Checkout. '
                              'GetMyPair does not store your card details.',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 28),
                            PayNowButton(
                              loading: loading,
                              label: 'Proceed to Zoho checkout',
                              onPressed: loading ? null : _proceedToCheckout,
                            ),
                            if (state is PaymentError) ...[
                              const SizedBox(height: 16),
                              Text(
                                PaymentErrorHandler.messageFrom(state.message),
                                style: const TextStyle(color: AppColors.error),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
      ),
    );
  }

  Widget _summaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.95),
            AppColors.primaryDark,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total payable',
            style: TextStyle(color: AppColors.onGradientMuted, fontSize: 13),
          ),
          const SizedBox(height: 6),
          Text(
            PaymentAmountFormatter.format(widget.amount),
            style: GoogleFonts.montserrat(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: AppColors.textOnPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 14,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
