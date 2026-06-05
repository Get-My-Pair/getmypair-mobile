import '../../../../core/errors/failures.dart';

class PaymentErrorHandler {
  PaymentErrorHandler._();

  static String messageFrom(Object error) {
    if (error is Failure) return error.message;
    final raw = error.toString().replaceFirst('Exception: ', '');
    if (raw.contains('already paid')) {
      return 'This service request has already been paid.';
    }
    if (raw.contains('accept the final service cost')) {
      return 'Please accept the final service cost before paying.';
    }
    if (raw.contains('Connection timeout') || raw.contains('internet')) {
      return 'Network issue. Check your connection and try again.';
    }
    if (raw.contains('Payment not found')) {
      return 'Payment record not found. Try refreshing or contact support.';
    }
    return raw.isNotEmpty ? raw : 'Something went wrong with your payment.';
  }

  static bool isRetryable(Object error) {
    final msg = messageFrom(error).toLowerCase();
    return msg.contains('network') ||
        msg.contains('timeout') ||
        msg.contains('try again') ||
        msg.contains('failed');
  }
}
