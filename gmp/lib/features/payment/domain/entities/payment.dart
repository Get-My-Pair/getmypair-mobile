import 'package:equatable/equatable.dart';

class Payment extends Equatable {
  final String id;
  final String orderId;
  final String serviceRequestId;
  /// repair | wash | maintenance | donate | dispose | thrift | rent
  final String? serviceType;
  final String userId;
  final double amount;
  final String currency;
  final String status;
  final String? providerType;
  final String? paymentLinkUrl;
  final String? zohoPaymentId;
  /// How the customer paid: upi | card | netbanking | wallet | emi.
  final String? paymentMethod;
  /// UPI id, "Visa •••• 4242", bank name…
  final String? paymentMethodDetail;
  final String? failureReason;
  final DateTime? paidAt;
  final DateTime? failedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Payment({
    required this.id,
    required this.orderId,
    required this.serviceRequestId,
    this.serviceType,
    required this.userId,
    required this.amount,
    this.currency = 'INR',
    required this.status,
    this.providerType,
    this.paymentLinkUrl,
    this.zohoPaymentId,
    this.paymentMethod,
    this.paymentMethodDetail,
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

  /// When the money actually moved. Never falls back to the *initiated* date.
  DateTime? get completedAt {
    if (paidAt != null) return paidAt;
    if (isSuccess || isRefunded) return updatedAt;
    return null;
  }

  /// Readable service, e.g. RepairMyPair, WashMyPair, Thrift Store.
  String? get serviceName {
    final fromType = _serviceNameFor(serviceType);
    if (fromType != null) return fromType;
    return _serviceNameFromOrderId(orderId);
  }

  static String? _serviceNameFor(String? raw) {
    switch ((raw ?? '').trim().toLowerCase()) {
      case 'repair':
      case 'repairmypair':
        return 'RepairMyPair';
      case 'wash':
      case 'washmypair':
        return 'WashMyPair';
      case 'maintenance':
      case 'maintain':
      case 'maintainmypair':
        return 'MaintainMyPair';
      case 'donate':
      case 'donatemypair':
        return 'DonateMyPair';
      case 'dispose':
      case 'disposemypair':
        return 'DisposeMyPair';
      case 'thrift':
      case 'thrift_store':
      case 'thriftstore':
        return 'Thrift Store';
      case 'rent':
      case 'rentmypair':
        return 'RentMyPair';
      default:
        return null;
    }
  }

  /// Public ids are city + SH + service code + sequence + area (CHSHRE0060GE).
  static String? _serviceNameFromOrderId(String orderId) {
    final id = orderId.trim().toUpperCase();
    if (id.length < 6 || id.substring(2, 4) != 'SH') return null;
    return _serviceNameFor(switch (id.substring(4, 6)) {
      'RE' => 'repair',
      'WA' => 'wash',
      'MA' => 'maintenance',
      'DO' => 'donate',
      'DI' => 'dispose',
      'TS' => 'thrift',
      'RN' => 'rent',
      _ => '',
    });
  }

  /// "UPI", "Card", "Net banking", "Wallet" — null when the gateway did not say.
  String? get paymentMethodLabel {
    switch ((paymentMethod ?? '').trim().toLowerCase()) {
      case '':
        return null;
      case 'upi':
        return 'UPI';
      case 'card':
        return 'Card';
      case 'netbanking':
        return 'Net banking';
      case 'wallet':
        return 'Wallet';
      case 'emi':
        return 'EMI';
      default:
        final m = paymentMethod!.trim().replaceAll('_', ' ');
        return m[0].toUpperCase() + m.substring(1);
    }
  }

  /// One line for the UI, e.g. "UPI · ravi@okicici" or "Card · Visa •••• 4242".
  String? get paymentViaText {
    final label = paymentMethodLabel;
    if (label == null) return null;
    final detail = paymentMethodDetail?.trim() ?? '';
    return detail.isEmpty ? label : '$label · $detail';
  }

  @override
  List<Object?> get props => [
        id,
        orderId,
        serviceRequestId,
        serviceType,
        userId,
        amount,
        currency,
        status,
        providerType,
        paymentLinkUrl,
        zohoPaymentId,
        paymentMethod,
        paymentMethodDetail,
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
