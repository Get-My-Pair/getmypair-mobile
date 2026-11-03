import '../../../../core/errors/failures.dart';
import '../../../../core/errors/user_facing_error.dart';

class PaymentErrorHandler {
  PaymentErrorHandler._();

  static String messageFrom(Object error) {
    // Never surface raw backend/API payloads in payment UI.
    return UserFacingError.sanitize(error is Failure ? error.message : error);
  }

  static bool isRetryable(Object error) {
    final msg = messageFrom(error).toLowerCase();
    return msg.contains('network') ||
        msg.contains('timeout') ||
        msg.contains('try again') ||
        msg.contains('failed');
  }
}
