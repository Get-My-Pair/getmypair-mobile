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
import '../widgets/payment_page_shell.dart';
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

    return PaymentPageShell(
      title: 'Payment failed',
      subtitle: 'Something went wrong during checkout.',
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          children: [
            const SizedBox(height: 12),
            const PaymentResultIcon(
              icon: Icons.cancel_rounded,
              color: AppColors.error,
            ),
            const SizedBox(height: 20),
            Text(
              'Payment not completed',
              textAlign: TextAlign.center,
              style: GoogleFonts.boldonse(
                fontSize: 22,
                color: PaymentPageTheme.titleColor,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 10),
            const PaymentStatusChip(status: 'PAYMENT_FAILED'),
            const SizedBox(height: 16),
            Text(
              failureReason ??
                  'Your payment could not be processed. Please try again.',
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            PaymentSurfaceCard(
              title: 'Attempt details',
              child: Column(
                children: [
                  PaymentDetailRow(label: 'Order', value: orderId),
                  PaymentDetailRow(
                    label: 'Amount',
                    value: PaymentAmountFormatter.format(amount),
                    bold: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            PayNowButton(
              label: 'Retry payment',
              onPressed: () => _retry(context),
            ),
            const SizedBox(height: 10),
            PaymentSecondaryButton(
              label: 'Go back',
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}
