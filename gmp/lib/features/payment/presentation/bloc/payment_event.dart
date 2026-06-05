import 'package:equatable/equatable.dart';

abstract class PaymentEvent extends Equatable {
  const PaymentEvent();
  @override
  List<Object?> get props => [];
}

class PaymentHistoryLoadRequested extends PaymentEvent {
  final String accessToken;
  final int page;
  final bool refresh;

  const PaymentHistoryLoadRequested({
    required this.accessToken,
    this.page = 1,
    this.refresh = false,
  });

  @override
  List<Object?> get props => [accessToken, page, refresh];
}

class PaymentDetailsLoadRequested extends PaymentEvent {
  final String accessToken;
  final String paymentId;

  const PaymentDetailsLoadRequested({
    required this.accessToken,
    required this.paymentId,
  });

  @override
  List<Object?> get props => [accessToken, paymentId];
}

class PaymentLinkCreateRequested extends PaymentEvent {
  final String accessToken;
  final String serviceRequestId;
  final String? redirectUrl;

  const PaymentLinkCreateRequested({
    required this.accessToken,
    required this.serviceRequestId,
    this.redirectUrl,
  });

  @override
  List<Object?> get props => [accessToken, serviceRequestId, redirectUrl];
}

class PaymentVerifyRequested extends PaymentEvent {
  final String accessToken;
  final String orderId;

  const PaymentVerifyRequested({
    required this.accessToken,
    required this.orderId,
  });

  @override
  List<Object?> get props => [accessToken, orderId];
}

class PaymentStatusRefreshRequested extends PaymentEvent {
  final String accessToken;
  final String orderId;
  final bool refreshFromZoho;

  const PaymentStatusRefreshRequested({
    required this.accessToken,
    required this.orderId,
    this.refreshFromZoho = true,
  });

  @override
  List<Object?> get props => [accessToken, orderId, refreshFromZoho];
}

class PaymentReset extends PaymentEvent {
  const PaymentReset();
}
