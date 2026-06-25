import 'package:equatable/equatable.dart';
import '../../domain/entities/payment.dart';
import '../../domain/entities/zoho_payment_mode.dart';

abstract class PaymentState extends Equatable {
  const PaymentState();
  @override
  List<Object?> get props => [];
}

class PaymentInitial extends PaymentState {
  const PaymentInitial();
}

class PaymentLoading extends PaymentState {
  final String? message;
  const PaymentLoading({this.message});
  @override
  List<Object?> get props => [message];
}

class PaymentHistoryLoaded extends PaymentState {
  final PaymentHistoryResult history;
  const PaymentHistoryLoaded(this.history);
  @override
  List<Object?> get props => [history];
}

class PaymentDetailsLoaded extends PaymentState {
  final Payment payment;
  const PaymentDetailsLoaded(this.payment);
  @override
  List<Object?> get props => [payment];
}

class PaymentLinkReady extends PaymentState {
  final PaymentLinkResult linkResult;
  final ZohoPaymentMode paymentMode;
  final bool zohoFallback;

  const PaymentLinkReady(
    this.linkResult, {
    required this.paymentMode,
    this.zohoFallback = false,
  });

  bool get useSimulatedCheckout =>
      paymentMode == ZohoPaymentMode.simulate || zohoFallback;

  @override
  List<Object?> get props => [linkResult, paymentMode, zohoFallback];
}

class PaymentVerified extends PaymentState {
  final PaymentVerifyResult result;
  const PaymentVerified(this.result);
  @override
  List<Object?> get props => [result];
}

class PaymentError extends PaymentState {
  final String message;
  const PaymentError(this.message);
  @override
  List<Object?> get props => [message];
}
