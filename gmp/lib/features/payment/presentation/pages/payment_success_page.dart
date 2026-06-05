import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../service/presentation/pages/service_request_details_page.dart';
import '../services/payment_analytics.dart';
import '../utils/payment_amount_formatter.dart';
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
                  color: AppColors.success.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  size: 52,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Payment successful',
                style: GoogleFonts.montserrat(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              PaymentAmountText(amount: amount),
              const SizedBox(height: 8),
              const PaymentStatusChip(status: 'PAYMENT_SUCCESS'),
              const SizedBox(height: 20),
              _detailRow('Order ID', orderId),
              if (paidAt != null)
                _detailRow('Paid at', PaymentAmountFormatter.formatDate(paidAt)),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textOnPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('View service request'),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                child: const Text('Back to home'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
