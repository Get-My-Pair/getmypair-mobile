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
import '../widgets/payment_loader.dart';
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
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Spacer(),
                if (_refreshing)
                  const PaymentLoader(message: 'Checking payment status…')
                else ...[
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.hourglass_top_rounded,
                      size: 48,
                      color: AppColors.warning,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Payment pending',
                    style: GoogleFonts.montserrat(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const PaymentStatusChip(status: 'PAYMENT_PENDING'),
                  const SizedBox(height: 16),
                  Text(
                    'We are waiting for confirmation from Zoho Payments. '
                    'This usually takes a few seconds.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    PaymentAmountFormatter.format(widget.amount),
                    style: GoogleFonts.montserrat(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _refreshing ? null : _refreshStatus,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textOnPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Refresh payment status'),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Go back'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
