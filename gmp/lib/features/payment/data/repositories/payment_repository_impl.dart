import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/payment.dart';
import '../../domain/entities/zoho_payment_mode.dart';
import '../../domain/repositories/payment_repository.dart';
import '../datasources/payment_remote_datasource.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  final PaymentRemoteDataSource remoteDataSource;

  PaymentRepositoryImpl({required this.remoteDataSource});

  Failure _mapError(Object e) {
    if (e is NetworkException) return NetworkFailure(e.message);
    if (e is ServerException) return ServerFailure(e.message);
    return ServerFailure(e.toString());
  }

  @override
  Future<PaymentHistoryResult> getPaymentHistory({
    required String accessToken,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      return await remoteDataSource.getPaymentHistory(
        accessToken,
        page: page,
        limit: limit,
      );
    } catch (e) {
      throw _mapError(e);
    }
  }

  @override
  Future<Payment> getPaymentDetails({
    required String accessToken,
    required String paymentId,
  }) async {
    try {
      return await remoteDataSource.getPaymentDetails(accessToken, paymentId);
    } catch (e) {
      throw _mapError(e);
    }
  }

  @override
  Future<PaymentLinkResult> createPaymentLink({
    required String accessToken,
    required String serviceRequestId,
    String? redirectUrl,
    ZohoPaymentMode paymentMode = ZohoPaymentMode.live,
  }) async {
    try {
      return await remoteDataSource.createPaymentLink(
        accessToken,
        serviceRequestId: serviceRequestId,
        redirectUrl: redirectUrl,
        paymentMode: paymentMode,
      );
    } catch (e) {
      throw _mapError(e);
    }
  }

  @override
  Future<PaymentVerifyResult> verifyPayment({
    required String accessToken,
    required String orderId,
  }) async {
    try {
      return await remoteDataSource.verifyPayment(accessToken, orderId);
    } catch (e) {
      throw _mapError(e);
    }
  }

  @override
  Future<PaymentVerifyResult> refreshPaymentStatus({
    required String accessToken,
    required String orderId,
    bool refreshFromZoho = false,
  }) async {
    try {
      return await remoteDataSource.refreshPaymentStatus(
        accessToken,
        orderId,
        refreshFromZoho: refreshFromZoho,
      );
    } catch (e) {
      throw _mapError(e);
    }
  }

  @override
  Future<Payment?> getPaymentByServiceRequest({
    required String accessToken,
    required String serviceRequestId,
  }) async {
    try {
      return await remoteDataSource.getPaymentByServiceRequest(
        accessToken,
        serviceRequestId,
      );
    } catch (e) {
      throw _mapError(e);
    }
  }
}
