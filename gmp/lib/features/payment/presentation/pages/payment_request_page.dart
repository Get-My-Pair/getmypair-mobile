import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/chevron_screen_back_button.dart';
import '../bloc/payment_bloc.dart';
import '../services/payment_analytics.dart';
import '../utils/payment_amount_formatter.dart';
import '../widgets/pay_now_button.dart';
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

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: const ChevronScreenBackButton(
          iconColor: AppColors.textPrimary,
        ),
        title: Text(
          'Payment request',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Service payment',
                    style: GoogleFonts.boldonse(
                      fontSize: 14,
                      color: const Color(0xFF12899B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (serviceType != null)
                    Text(
                      serviceType!,
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  if (requestLabel != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      requestLabel!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    PaymentAmountFormatter.format(amount),
                    style: GoogleFonts.montserrat(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Final approved service cost. You will be redirected to Zoho secure checkout.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'What happens next',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            _step('1', 'Review payment summary'),
            _step('2', 'Complete checkout via Zoho Payments'),
            _step('3', 'Pickup scheduled after successful payment'),
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

  Widget _step(String num, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            child: Text(
              num,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
