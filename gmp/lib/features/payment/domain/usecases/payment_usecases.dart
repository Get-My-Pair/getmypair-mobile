import '../entities/payment.dart';
import '../repositories/payment_repository.dart';

class GetPaymentHistory {
  final PaymentRepository repository;
  GetPaymentHistory(this.repository);

  Future<PaymentHistoryResult> call({
    required String accessToken,
    int page = 1,
    int limit = 20,
  }) =>
      repository.getPaymentHistory(
        accessToken: accessToken,
        page: page,
        limit: limit,
      );
}

class GetPaymentDetails {
  final PaymentRepository repository;
  GetPaymentDetails(this.repository);

  Future<Payment> call({
    required String accessToken,
    required String paymentId,
  }) =>
      repository.getPaymentDetails(
        accessToken: accessToken,
        paymentId: paymentId,
      );
}

class CreatePaymentLink {
  final PaymentRepository repository;
  CreatePaymentLink(this.repository);

  Future<PaymentLinkResult> call({
    required String accessToken,
    required String serviceRequestId,
    String? redirectUrl,
  }) =>
      repository.createPaymentLink(
        accessToken: accessToken,
        serviceRequestId: serviceRequestId,
        redirectUrl: redirectUrl,
      );
}

class VerifyPayment {
  final PaymentRepository repository;
  VerifyPayment(this.repository);

  Future<PaymentVerifyResult> call({
    required String accessToken,
    required String orderId,
  }) =>
      repository.verifyPayment(
        accessToken: accessToken,
        orderId: orderId,
      );
}

class RefreshPaymentStatus {
  final PaymentRepository repository;
  RefreshPaymentStatus(this.repository);

  Future<PaymentVerifyResult> call({
    required String accessToken,
    required String orderId,
    bool refreshFromZoho = false,
  }) =>
      repository.refreshPaymentStatus(
        accessToken: accessToken,
        orderId: orderId,
        refreshFromZoho: refreshFromZoho,
      );
}

class GetPaymentByServiceRequest {
  final PaymentRepository repository;
  GetPaymentByServiceRequest(this.repository);

  Future<Payment?> call({
    required String accessToken,
    required String serviceRequestId,
  }) =>
      repository.getPaymentByServiceRequest(
        accessToken: accessToken,
        serviceRequestId: serviceRequestId,
      );
}
