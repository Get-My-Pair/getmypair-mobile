import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class PayNowButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool loading;
  final String label;

  const PayNowButton({
    super.key,
    required this.onPressed,
    this.loading = false,
    this.label = 'Pay now',
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.textOnPrimary,
                ),
              )
            : const Icon(Icons.payment_rounded, size: 20),
        label: Text(
          loading ? 'Preparing…' : label,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
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
            style: const TextStyle(
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
