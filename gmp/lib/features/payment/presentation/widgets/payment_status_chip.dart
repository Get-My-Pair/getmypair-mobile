import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/payment.dart';
import '../utils/payment_amount_formatter.dart';

class PaymentStatusChip extends StatelessWidget {
  final String status;
  final bool compact;

  const PaymentStatusChip({
    super.key,
    required this.status,
    this.compact = false,
  });

  factory PaymentStatusChip.fromPayment(Payment payment, {bool compact = false}) {
    return PaymentStatusChip(status: payment.status, compact: compact);
  }

  @override
  Widget build(BuildContext context) {
    final (label, color, bg) = _style();
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: compact ? 11 : 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  (String, Color, Color) _style() {
    switch (status) {
      case 'PAYMENT_SUCCESS':
        return ('Paid', AppColors.success, AppColors.success.withValues(alpha: 0.12));
      case 'PAYMENT_FAILED':
        return ('Failed', AppColors.error, AppColors.error.withValues(alpha: 0.12));
      case 'PAYMENT_INITIATED':
        return ('In checkout', AppColors.info, AppColors.info.withValues(alpha: 0.12));
      case 'REFUNDED':
        return ('Refunded', AppColors.warning, AppColors.warning.withValues(alpha: 0.12));
      default:
        return ('Pending', AppColors.warning, AppColors.warning.withValues(alpha: 0.12));
    }
  }
}

class PaymentAmountText extends StatelessWidget {
  final double amount;
  final String currency;
  final TextStyle? style;

  const PaymentAmountText({
    super.key,
    required this.amount,
    this.currency = 'INR',
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      PaymentAmountFormatter.format(amount, currency: currency),
      style: style ??
          const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
          ),
    );
  }
}
