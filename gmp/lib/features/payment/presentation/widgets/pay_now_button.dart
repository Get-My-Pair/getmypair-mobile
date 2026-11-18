import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import 'payment_page_shell.dart';

class PayNowButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool loading;
  final String label;
  final bool showIcon;

  /// Green disabled “Payment Paid” style after successful payment.
  final bool paid;

  const PayNowButton({
    super.key,
    required this.onPressed,
    this.loading = false,
    this.label = 'Pay now',
    this.showIcon = true,
    this.paid = false,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = paid || (onPressed == null && !loading);
    final Color? solidColor = paid
        ? const Color(0xFF16A34A) // clear green for paid/disabled state
        : (onPressed == null && !loading ? AppColors.disabled : null);
    final useGradient = !paid && (onPressed != null || loading);

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: useGradient && !paid ? PaymentPageTheme.buttonGradient : null,
          color: solidColor,
          borderRadius: BorderRadius.circular(100),
          boxShadow: disabled
              ? null
              : const [
                  BoxShadow(
                    color: Color(0x19000000),
                    blurRadius: 4,
                    offset: Offset(0, 4),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: (loading || paid) ? null : onPressed,
            borderRadius: BorderRadius.circular(100),
            child: Center(
              child: loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (showIcon) ...[
                          Icon(
                            paid
                                ? Icons.check_circle_rounded
                                : Icons.payment_rounded,
                            size: 20,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          label,
                          style: GoogleFonts.montserrat(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class PaymentErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const PaymentErrorBanner({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.error_outline, color: AppColors.error, size: 20),
              SizedBox(width: 8),
              Text(
                'Payment error',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: GoogleFonts.montserrat(
              fontSize: 13,
              color: AppColors.textPrimary,
              height: 1.35,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 10),
            TextButton(
              onPressed: onRetry,
              child: const Text('Try again'),
            ),
          ],
        ],
      ),
    );
  }
}
