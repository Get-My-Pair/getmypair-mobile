import 'package:equatable/equatable.dart';

class Payment extends Equatable {
  final String id;
  final String orderId;
  final String serviceRequestId;
  final String userId;
  final double amount;
  final String currency;
  final String status;
  final String? providerType;
  final String? paymentLinkUrl;
  final String? zohoPaymentId;
  final String? failureReason;
  final DateTime? paidAt;
  final DateTime? failedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Payment({
    required this.id,
    required this.orderId,
    required this.serviceRequestId,
    required this.userId,
    required this.amount,
    this.currency = 'INR',
    required this.status,
    this.providerType,
    this.paymentLinkUrl,
    this.zohoPaymentId,
    this.failureReason,
    this.paidAt,
    this.failedAt,
    this.createdAt,
    this.updatedAt,
  });

  bool get isSuccess {
    final s = status.trim().toUpperCase();
    return s == 'PAYMENT_SUCCESS' ||
        s == 'PAID' ||
        s == 'SUCCESS' ||
        s == 'COMPLETED' ||
        s == 'CAPTURED';
  }

  bool get isFailed => status.toUpperCase().contains('FAIL');
  bool get isPending {
    final s = status.trim().toUpperCase();
    return s == 'PAYMENT_PENDING' ||
        s == 'PAYMENT_INITIATED' ||
        s == 'PENDING' ||
        s == 'INITIATED';
  }

  bool get isRefunded {
    final s = status.trim().toUpperCase();
    return s == 'REFUNDED' || s == 'PAYMENT_REFUNDED';
  }

  /// True when money was captured (success / refunded / paidAt set).
  bool get countsAsPaid => isSuccess || isRefunded || paidAt != null;

  @override
  List<Object?> get props => [
        id,
        orderId,
        serviceRequestId,
        userId,
        amount,
        currency,
        status,
        providerType,
        paymentLinkUrl,
        zohoPaymentId,
        failureReason,
        paidAt,
        failedAt,
        createdAt,
        updatedAt,
      ];
}

class PaymentHistoryResult extends Equatable {
  final List<Payment> items;
  final int total;
  final int page;
  final int limit;

  const PaymentHistoryResult({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
  });

  bool get hasMore => page * limit < total;

  @override
  List<Object?> get props => [items, total, page, limit];
}

class PaymentLinkResult extends Equatable {
  final Payment payment;
  final String checkoutUrl;

  const PaymentLinkResult({
    required this.payment,
    required this.checkoutUrl,
  });

  @override
  List<Object?> get props => [payment, checkoutUrl];
}

class PaymentVerifyResult extends Equatable {
  final Payment payment;
  final bool verified;

  const PaymentVerifyResult({
    required this.payment,
    required this.verified,
  });

  @override
  List<Object?> get props => [payment, verified];
}
