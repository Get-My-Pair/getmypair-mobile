import 'dart:async';

import '../../domain/entities/payment.dart';
import '../../domain/usecases/payment_usecases.dart';
import 'payment_analytics.dart';

typedef PaymentPollCallback = void Function(PaymentVerifyResult result);

/// Polls payment status until success, failure, or timeout.
class PaymentStatusPoller {
  PaymentStatusPoller({
    required VerifyPayment verifyPayment,
    required RefreshPaymentStatus refreshPaymentStatus,
  })  : _verifyPayment = verifyPayment,
        _refreshPaymentStatus = refreshPaymentStatus;

  final VerifyPayment _verifyPayment;
  final RefreshPaymentStatus _refreshPaymentStatus;

  Timer? _timer;
  int _attempt = 0;

  static const int maxAttempts = 20;
  static const Duration interval = Duration(seconds: 3);

  void start({
    required String accessToken,
    required String orderId,
    required PaymentPollCallback onUpdate,
    void Function(Object error)? onError,
    void Function()? onTimeout,
    bool useVerify = true,
  }) {
    stop();
    _attempt = 0;
    _poll(
      accessToken: accessToken,
      orderId: orderId,
      onUpdate: onUpdate,
      onError: onError,
      onTimeout: onTimeout,
      useVerify: useVerify,
    );
  }

  Future<void> _poll({
    required String accessToken,
    required String orderId,
    required PaymentPollCallback onUpdate,
    void Function(Object error)? onError,
    void Function()? onTimeout,
    required bool useVerify,
  }) async {
    if (_attempt >= maxAttempts) {
      onTimeout?.call();
      stop();
      return;
    }
    _attempt += 1;
    try {
      final result = useVerify || _attempt % 3 == 0
          ? await _verifyPayment(
              accessToken: accessToken,
              orderId: orderId,
            )
          : await _refreshPaymentStatus(
              accessToken: accessToken,
              orderId: orderId,
            );
      PaymentAnalytics.paymentStatusRefreshed(orderId, result.payment.status);
      onUpdate(result);
      if (result.payment.isSuccess || result.payment.isFailed) {
        stop();
        return;
      }
    } catch (e) {
      onError?.call(e);
    }
    _timer = Timer(interval, () {
      _poll(
        accessToken: accessToken,
        orderId: orderId,
        onUpdate: onUpdate,
        onError: onError,
        onTimeout: onTimeout,
        useVerify: useVerify,
      );
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _attempt = 0;
  }

  void dispose() => stop();
}
