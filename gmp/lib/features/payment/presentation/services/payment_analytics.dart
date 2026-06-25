import 'package:flutter/foundation.dart';

/// Lightweight analytics hook for payment funnel events.
/// Wire to Firebase/Amplitude when available.
class PaymentAnalytics {
  PaymentAnalytics._();

  static void log(String event, [Map<String, Object?> params = const {}]) {
    if (kDebugMode) {
      debugPrint('[PaymentAnalytics] $event ${params.isEmpty ? '' : params}');
    }
  }

  static void paymentRequestViewed(String serviceRequestId) =>
      log('payment_request_viewed', {'serviceRequestId': serviceRequestId});

  static void paymentSummaryViewed(String serviceRequestId, double amount) =>
      log('payment_summary_viewed', {
        'serviceRequestId': serviceRequestId,
        'amount': amount,
      });

  static void checkoutOpened(String orderId) =>
      log('checkout_opened', {'orderId': orderId});

  static void checkoutCompleted(String orderId) =>
      log('checkout_completed', {'orderId': orderId});

  static void paymentSuccess(String orderId, double amount) =>
      log('payment_success', {'orderId': orderId, 'amount': amount});

  static void paymentFailed(String orderId, String? reason) =>
      log('payment_failed', {'orderId': orderId, 'reason': reason ?? ''});

  static void paymentPending(String orderId) =>
      log('payment_pending', {'orderId': orderId});

  static void paymentRetry(String orderId) =>
      log('payment_retry', {'orderId': orderId});

  static void paymentStatusRefreshed(String orderId, String status) =>
      log('payment_status_refreshed', {'orderId': orderId, 'status': status});

  static void paymentHistoryViewed() => log('payment_history_viewed');

  static void transactionDetailsViewed(String paymentId) =>
      log('transaction_details_viewed', {'paymentId': paymentId});

  static void simulateFlowStarted(
    String orderId, {
    required bool autoPlay,
    required bool zohoFallback,
  }) =>
      log('payment_simulate_started', {
        'orderId': orderId,
        'autoPlay': autoPlay,
        'zohoFallback': zohoFallback,
      });

  static void zohoConnectionFallback(String orderId) =>
      log('payment_zoho_fallback', {'orderId': orderId});
}
