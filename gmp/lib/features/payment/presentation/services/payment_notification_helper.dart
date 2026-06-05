import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_feedback_alert.dart';
import '../../domain/entities/payment.dart';

class PaymentNotificationHelper {
  PaymentNotificationHelper._();

  static Future<void> showPaymentResult(
    BuildContext context, {
    required Payment payment,
  }) async {
    if (payment.isSuccess) {
      await showAppFeedbackAlert(
        context,
        title: 'Payment received',
        message:
            'Your payment of ₹${payment.amount.toStringAsFixed(0)} was successful.',
        type: AppFeedbackType.success,
      );
      return;
    }
    if (payment.isFailed) {
      await showAppFeedbackAlert(
        context,
        title: 'Payment failed',
        message: payment.failureReason ??
            'Your payment could not be processed. Please try again.',
        type: AppFeedbackType.failure,
      );
      return;
    }
    if (payment.isPending) {
      await showAppFeedbackAlert(
        context,
        title: 'Payment pending',
        message:
            'We are waiting for confirmation from the payment provider.',
        type: AppFeedbackType.info,
      );
    }
  }

  static void showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primaryDark,
      ),
    );
  }
}
