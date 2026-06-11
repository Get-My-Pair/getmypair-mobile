import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../features/auth/domain/usecases/get_valid_access_token.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/payment.dart';
import '../../domain/usecases/payment_usecases.dart';
import '../bloc/payment_bloc.dart';
import '../bloc/payment_event.dart';
import '../bloc/payment_state.dart';
import '../services/payment_analytics.dart';
import '../services/payment_status_poller.dart';
import '../utils/payment_amount_formatter.dart';
import '../widgets/pay_now_button.dart';
import '../widgets/payment_loader.dart';
import '../widgets/payment_page_shell.dart';
import '../widgets/payment_status_chip.dart';
import 'payment_failed_page.dart';
import 'payment_success_page.dart';

class PaymentPendingPage extends StatefulWidget {
  final String orderId;
  final String serviceRequestId;
  final double amount;

  const PaymentPendingPage({
    super.key,
    required this.orderId,
    required this.serviceRequestId,
    required this.amount,
  });

  @override
  State<PaymentPendingPage> createState() => _PaymentPendingPageState();
}

class _PaymentPendingPageState extends State<PaymentPendingPage> {
  late final PaymentStatusPoller _poller;
  bool _refreshing = false;
  String? _accessToken;

  @override
  void initState() {
    super.initState();
    PaymentAnalytics.paymentPending(widget.orderId);
    _poller = PaymentStatusPoller(
      verifyPayment: sl<VerifyPayment>(),
      refreshPaymentStatus: sl<RefreshPaymentStatus>(),
    );
    _init();
  }

  Future<void> _init() async {
    final tokenResult = await sl<GetValidAccessToken>().call();
    if (!mounted) return;
    tokenResult.fold((_) {}, (token) {
      _accessToken = token;
      _startAutoPoll(token);
    });
  }

  void _startAutoPoll(String token) {
    _poller.start(
      accessToken: token,
      orderId: widget.orderId,
      onUpdate: _handlePollResult,
    );
  }

  void _handlePollResult(PaymentVerifyResult result) {
    if (!mounted) return;
    if (result.payment.isSuccess) {
      _poller.stop();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentSuccessPage(
            orderId: widget.orderId,
            amount: widget.amount,
            serviceRequestId: widget.serviceRequestId,
            paidAt: result.payment.paidAt,
          ),
        ),
      );
    } else if (result.payment.isFailed) {
      _poller.stop();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentFailedPage(
            orderId: widget.orderId,
            serviceRequestId: widget.serviceRequestId,
            amount: widget.amount,
            failureReason: result.payment.failureReason,
          ),
        ),
      );
    }
  }

  Future<void> _refreshStatus() async {
    final token = _accessToken;
    if (token == null || _refreshing) return;
    setState(() => _refreshing = true);
    context.read<PaymentBloc>().add(
          PaymentStatusRefreshRequested(
            accessToken: token,
            orderId: widget.orderId,
            refreshFromZoho: true,
          ),
        );
  }

  @override
  void dispose() {
    _poller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PaymentBloc, PaymentState>(
      listener: (context, state) {
        if (state is PaymentVerified) {
          setState(() => _refreshing = false);
          _handlePollResult(state.result);
        } else if (state is PaymentError) {
          setState(() => _refreshing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      child: PaymentPageShell(
        title: 'Payment pending',
        subtitle: 'Waiting for confirmation from Zoho Payments.',
        body: _refreshing
            ? const PaymentLoader(message: 'Checking payment status…')
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    const PaymentResultIcon(
                      icon: Icons.hourglass_top_rounded,
                      color: AppColors.warning,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Almost there',
                      style: GoogleFonts.boldonse(
                        fontSize: 22,
                        color: PaymentPageTheme.titleColor,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const PaymentStatusChip(status: 'PAYMENT_PENDING'),
                    const SizedBox(height: 16),
                    Text(
                      'We are waiting for confirmation from Zoho Payments. '
                      'This usually takes a few seconds.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    PaymentSurfaceCard(
                      child: PaymentDetailRow(
                        label: 'Amount',
                        value: PaymentAmountFormatter.format(widget.amount),
                        bold: true,
                      ),
                    ),
                    const SizedBox(height: 24),
                    PayNowButton(
                      label: 'Refresh payment status',
                      onPressed: _refreshStatus,
                    ),
                    const SizedBox(height: 10),
                    PaymentSecondaryButton(
                      label: 'Go back',
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
