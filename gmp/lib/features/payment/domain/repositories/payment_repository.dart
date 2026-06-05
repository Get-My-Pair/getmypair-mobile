import '../entities/payment.dart';

abstract class PaymentRepository {
  Future<PaymentHistoryResult> getPaymentHistory({
    required String accessToken,
    int page = 1,
    int limit = 20,
  });

  Future<Payment> getPaymentDetails({
    required String accessToken,
    required String paymentId,
  });

  Future<PaymentLinkResult> createPaymentLink({
    required String accessToken,
    required String serviceRequestId,
    String? redirectUrl,
  });

  Future<PaymentVerifyResult> verifyPayment({
    required String accessToken,
    required String orderId,
  });

  Future<PaymentVerifyResult> refreshPaymentStatus({
    required String accessToken,
    required String orderId,
    bool refreshFromZoho = false,
  });

  Future<Payment?> getPaymentByServiceRequest({
    required String accessToken,
    required String serviceRequestId,
  });
}
