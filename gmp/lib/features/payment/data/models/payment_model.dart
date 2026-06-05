import '../../domain/entities/payment.dart';

class PaymentModel extends Payment {
  const PaymentModel({
    required super.id,
    required super.orderId,
    required super.serviceRequestId,
    required super.userId,
    required super.amount,
    super.currency,
    required super.status,
    super.providerType,
    super.paymentLinkUrl,
    super.zohoPaymentId,
    super.failureReason,
    super.paidAt,
    super.failedAt,
    super.createdAt,
    super.updatedAt,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: _str(json['_id'] ?? json['id']),
      orderId: _str(json['orderId']),
      serviceRequestId: _str(json['serviceRequestId']),
      userId: _str(json['userId']),
      amount: _toDouble(json['amount']),
      currency: _str(json['currency']).isEmpty ? 'INR' : _str(json['currency']),
      status: _str(json['status']),
      providerType: _optionalStr(json['providerType']),
      paymentLinkUrl: _optionalStr(json['paymentLinkUrl']),
      zohoPaymentId: _optionalStr(json['zohoPaymentId']),
      failureReason: _optionalStr(json['failureReason']),
      paidAt: _toDate(json['paidAt']),
      failedAt: _toDate(json['failedAt']),
      createdAt: _toDate(json['createdAt']),
      updatedAt: _toDate(json['updatedAt']),
    );
  }

  static String _str(dynamic v) => v?.toString() ?? '';

  static String? _optionalStr(dynamic v) {
    final s = v?.toString().trim();
    if (s == null || s.isEmpty) return null;
    return s;
  }

  static double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0;
  }

  static DateTime? _toDate(dynamic v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString());
  }
}
