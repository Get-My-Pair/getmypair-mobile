import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../features/auth/domain/usecases/get_valid_access_token.dart';
import '../../../../injection_container.dart';
import '../bloc/payment_bloc.dart';
import '../services/payment_analytics.dart';
import '../utils/payment_amount_formatter.dart';
import '../widgets/pay_now_button.dart';
import '../widgets/payment_status_chip.dart';
import 'payment_summary_page.dart';

class PaymentFailedPage extends StatelessWidget {
  final String orderId;
  final String serviceRequestId;
  final double amount;
  final String? failureReason;

  const PaymentFailedPage({
    super.key,
    required this.orderId,
    required this.serviceRequestId,
    required this.amount,
    this.failureReason,
  });

  Future<void> _retry(BuildContext context) async {
    PaymentAnalytics.paymentRetry(orderId);
    final tokenResult = await sl<GetValidAccessToken>().call();
    if (!context.mounted) return;
    tokenResult.fold(
      (_) {},
      (_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => BlocProvider.value(
              value: context.read<PaymentBloc>(),
              child: PaymentSummaryPage(
                serviceRequestId: serviceRequestId,
                amount: amount,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    PaymentAnalytics.paymentFailed(orderId, failureReason);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.cancel_rounded,
                  size: 52,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Payment failed',
                style: GoogleFonts.montserrat(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              const PaymentStatusChip(status: 'PAYMENT_FAILED'),
              const SizedBox(height: 16),
              Text(
                failureReason ??
                    'Your payment could not be processed. Please try again.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Order: $orderId',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textTertiary,
                ),
              ),
              Text(
                PaymentAmountFormatter.format(amount),
                style: GoogleFonts.montserrat(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              const Spacer(),
              PayNowButton(
                label: 'Retry payment',
                onPressed: () => _retry(context),
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
    );
  }
}
