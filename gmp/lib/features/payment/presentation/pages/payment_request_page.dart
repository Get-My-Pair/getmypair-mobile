import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../bloc/payment_bloc.dart';
import '../services/payment_analytics.dart';
import '../utils/payment_amount_formatter.dart';
import '../widgets/pay_now_button.dart';
import '../widgets/payment_page_shell.dart';
import 'payment_summary_page.dart';

/// Entry screen when user initiates payment for a service request.
class PaymentRequestPage extends StatelessWidget {
  final String serviceRequestId;
  final double amount;
  final String? serviceType;
  final String? requestLabel;

  const PaymentRequestPage({
    super.key,
    required this.serviceRequestId,
    required this.amount,
    this.serviceType,
    this.requestLabel,
  });

  @override
  Widget build(BuildContext context) {
    PaymentAnalytics.paymentRequestViewed(serviceRequestId);

    return PaymentPageShell(
      title: 'Payment',
      subtitle: 'Review the approved service cost before checkout.',
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PaymentAmountHero(
              label: 'Amount due',
              amountText: PaymentAmountFormatter.format(amount),
              caption:
                  'Final approved service cost. You will complete checkout via Zoho secure payments.',
            ),
            const SizedBox(height: 16),
            PaymentSurfaceCard(
              title: 'Service details',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (serviceType != null)
                    Text(
                      serviceType!,
                      style: GoogleFonts.boldonse(
                        fontSize: 16,
                        color: PaymentPageTheme.titleColor,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  if (requestLabel != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      requestLabel!,
                      style: GoogleFonts.montserrat(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  PaymentDetailRow(
                    label: 'Request',
                    value: serviceRequestId.length > 18
                        ? '…${serviceRequestId.substring(serviceRequestId.length - 10)}'
                        : serviceRequestId,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'What happens next',
              style: GoogleFonts.boldonse(
                fontSize: 15,
                color: PaymentPageTheme.titleColor,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 10),
            const PaymentStepRow(step: '1', text: 'Review payment summary'),
            const PaymentStepRow(
              step: '2',
              text: 'Choose checkout: Live, Sandbox, or Simulate',
            ),
            const PaymentStepRow(
              step: '3',
              text: 'Pickup scheduled after successful payment',
            ),
            const SizedBox(height: 28),
            PayNowButton(
              label: 'Continue to summary',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BlocProvider.value(
                      value: context.read<PaymentBloc>(),
                      child: PaymentSummaryPage(
                        serviceRequestId: serviceRequestId,
                        amount: amount,
                        serviceType: serviceType,
                        requestLabel: requestLabel,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
