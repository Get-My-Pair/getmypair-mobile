import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/payment.dart';
import '../../domain/entities/zoho_payment_mode.dart';
import '../models/payment_model.dart';

abstract class PaymentRemoteDataSource {
  Future<PaymentHistoryResult> getPaymentHistory(
    String accessToken, {
    int page = 1,
    int limit = 20,
  });

  Future<PaymentModel> getPaymentDetails(
    String accessToken,
    String paymentId,
  );

  Future<PaymentLinkResult> createPaymentLink(
    String accessToken, {
    required String serviceRequestId,
    String? redirectUrl,
    ZohoPaymentMode paymentMode = ZohoPaymentMode.live,
  });

  Future<PaymentVerifyResult> verifyPayment(
    String accessToken,
    String orderId,
  );

  Future<PaymentVerifyResult> refreshPaymentStatus(
    String accessToken,
    String orderId, {
    bool refreshFromZoho = false,
  });

  Future<PaymentModel?> getPaymentByServiceRequest(
    String accessToken,
    String serviceRequestId,
  );
}

class PaymentRemoteDataSourceImpl implements PaymentRemoteDataSource {
  final DioClient client;

  PaymentRemoteDataSourceImpl({required this.client});

  Map<String, dynamic> _data(Map<String, dynamic> res) =>
      (res['data'] as Map<String, dynamic>?) ?? {};

  @override
  Future<PaymentHistoryResult> getPaymentHistory(
    String accessToken, {
    int page = 1,
    int limit = 20,
  }) async {
    final res = await client.get(
      ApiEndpoints.paymentHistory(page: page, limit: limit),
      accessToken: accessToken,
    );
    final data = _data(res);
    final itemsRaw = data['items'] as List? ?? [];
    final items = itemsRaw
        .map((e) => PaymentModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    return PaymentHistoryResult(
      items: items,
      total: (data['total'] as num?)?.toInt() ?? items.length,
      page: (data['page'] as num?)?.toInt() ?? page,
      limit: (data['limit'] as num?)?.toInt() ?? limit,
    );
  }

  @override
  Future<PaymentModel> getPaymentDetails(
    String accessToken,
    String paymentId,
  ) async {
    final res = await client.get(
      ApiEndpoints.paymentById(paymentId),
      accessToken: accessToken,
    );
    final paymentJson =
        (_data(res)['payment'] as Map?) ?? const <String, dynamic>{};
    return PaymentModel.fromJson(Map<String, dynamic>.from(paymentJson));
  }

  @override
  Future<PaymentLinkResult> createPaymentLink(
    String accessToken, {
    required String serviceRequestId,
    String? redirectUrl,
    ZohoPaymentMode paymentMode = ZohoPaymentMode.live,
  }) async {
    final body = <String, dynamic>{
      'serviceRequestId': serviceRequestId,
      'paymentMode': paymentMode.apiValue,
    };
    if (redirectUrl != null && redirectUrl.isNotEmpty) {
      body['redirectUrl'] = redirectUrl;
    }
    final res = await client.post(
      ApiEndpoints.paymentLink,
      accessToken: accessToken,
      body: body,
    );
    final data = _data(res);
    final paymentJson =
        (data['payment'] as Map?) ?? const <String, dynamic>{};
    final linkJson =
        (data['paymentLink'] as Map?) ?? const <String, dynamic>{};
    final url = linkJson['url']?.toString() ??
        paymentJson['paymentLinkUrl']?.toString() ??
        '';
    if (url.isEmpty) {
      throw ServerException('Payment link URL missing from server response');
    }
    return PaymentLinkResult(
      payment: PaymentModel.fromJson(Map<String, dynamic>.from(paymentJson)),
      checkoutUrl: url,
    );
  }

  @override
  Future<PaymentVerifyResult> verifyPayment(
    String accessToken,
    String orderId,
  ) async {
    final res = await client.post(
      ApiEndpoints.paymentVerify,
      accessToken: accessToken,
      body: {'orderId': orderId},
    );
    return _parseVerifyResult(res);
  }

  @override
  Future<PaymentVerifyResult> refreshPaymentStatus(
    String accessToken,
    String orderId, {
    bool refreshFromZoho = false,
  }) async {
    final res = await client.get(
      ApiEndpoints.paymentStatus(
        orderId,
        refresh: refreshFromZoho,
      ),
      accessToken: accessToken,
    );
    return _parseVerifyResult(res);
  }

  PaymentVerifyResult _parseVerifyResult(Map<String, dynamic> res) {
    final data = _data(res);
    final paymentJson =
        (data['payment'] as Map?) ?? const <String, dynamic>{};
    final verified = data['verified'] == true ||
        paymentJson['status']?.toString() == 'PAYMENT_SUCCESS';
    return PaymentVerifyResult(
      payment: PaymentModel.fromJson(Map<String, dynamic>.from(paymentJson)),
      verified: verified,
    );
  }

  @override
  Future<PaymentModel?> getPaymentByServiceRequest(
    String accessToken,
    String serviceRequestId,
  ) async {
    try {
      final res = await client.get(
        ApiEndpoints.paymentByServiceRequest(serviceRequestId),
        accessToken: accessToken,
      );
      final data = _data(res);
      if (data['serviceRequestFound'] == false) return null;
      final paymentJson = data['payment'];
      if (paymentJson == null) return null;
      return PaymentModel.fromJson(Map<String, dynamic>.from(paymentJson as Map));
    } on ServerException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }
}
