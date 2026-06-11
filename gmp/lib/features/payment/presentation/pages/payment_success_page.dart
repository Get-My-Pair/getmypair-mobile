import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../service/presentation/pages/service_request_details_page.dart';
import '../services/payment_analytics.dart';
import '../utils/payment_amount_formatter.dart';
import '../widgets/pay_now_button.dart';
import '../widgets/payment_page_shell.dart';
import '../widgets/payment_status_chip.dart';

class PaymentSuccessPage extends StatelessWidget {
  final String orderId;
  final double amount;
  final String serviceRequestId;
  final DateTime? paidAt;

  const PaymentSuccessPage({
    super.key,
    required this.orderId,
    required this.amount,
    required this.serviceRequestId,
    this.paidAt,
  });

  @override
  Widget build(BuildContext context) {
    PaymentAnalytics.paymentSuccess(orderId, amount);

    return PaymentPageShell(
      title: 'Payment successful',
      subtitle: 'Your service payment was confirmed.',
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          children: [
            const SizedBox(height: 12),
            const PaymentResultIcon(
              icon: Icons.check_circle_rounded,
              color: AppColors.success,
            ),
            const SizedBox(height: 20),
            Text(
              'Thank you!',
              style: GoogleFonts.boldonse(
                fontSize: 24,
                color: PaymentPageTheme.titleColor,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 10),
            PaymentAmountText(
              amount: amount,
              style: GoogleFonts.boldonse(
                fontSize: 28,
                fontWeight: FontWeight.w400,
                color: PaymentPageTheme.accentColor,
              ),
            ),
            const SizedBox(height: 10),
            const PaymentStatusChip(status: 'PAYMENT_SUCCESS'),
            const SizedBox(height: 20),
            PaymentSurfaceCard(
              title: 'Receipt',
              child: Column(
                children: [
                  PaymentDetailRow(label: 'Order ID', value: orderId),
                  if (paidAt != null)
                    PaymentDetailRow(
                      label: 'Paid at',
                      value: PaymentAmountFormatter.formatDate(paidAt),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            PayNowButton(
              label: 'View service request',
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ServiceRequestDetailsPage(
                      requestId: serviceRequestId,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            PaymentSecondaryButton(
              label: 'Back to home',
              onPressed: () =>
                  Navigator.of(context).popUntil((r) => r.isFirst),
            ),
          ],
        ),
      ),
    );
  }
}
