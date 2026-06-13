import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/payment.dart';
import '../../domain/usecases/payment_usecases.dart';
import '../services/payment_analytics.dart';
import '../services/payment_error_handler.dart';
import 'payment_event.dart';
import 'payment_state.dart';

class PaymentBloc extends Bloc<PaymentEvent, PaymentState> {
  PaymentBloc({
    required GetPaymentHistory getPaymentHistory,
    required GetPaymentDetails getPaymentDetails,
    required CreatePaymentLink createPaymentLink,
    required VerifyPayment verifyPayment,
    required RefreshPaymentStatus refreshPaymentStatus,
  })  : _getPaymentHistory = getPaymentHistory,
        _getPaymentDetails = getPaymentDetails,
        _createPaymentLink = createPaymentLink,
        _verifyPayment = verifyPayment,
        _refreshPaymentStatus = refreshPaymentStatus,
        super(const PaymentInitial()) {
    on<PaymentHistoryLoadRequested>(_onHistoryLoad);
    on<PaymentDetailsLoadRequested>(_onDetailsLoad);
    on<PaymentLinkCreateRequested>(_onLinkCreate);
    on<PaymentVerifyRequested>(_onVerify);
    on<PaymentStatusRefreshRequested>(_onRefresh);
    on<PaymentReset>((_, emit) => emit(const PaymentInitial()));
  }

  final GetPaymentHistory _getPaymentHistory;
  final GetPaymentDetails _getPaymentDetails;
  final CreatePaymentLink _createPaymentLink;
  final VerifyPayment _verifyPayment;
  final RefreshPaymentStatus _refreshPaymentStatus;

  Future<void> _onHistoryLoad(
    PaymentHistoryLoadRequested event,
    Emitter<PaymentState> emit,
  ) async {
    emit(const PaymentLoading(message: 'Loading payment history…'));
    try {
      final history = await _getPaymentHistory(
        accessToken: event.accessToken,
        page: event.page,
      );
      PaymentAnalytics.paymentHistoryViewed();
      emit(PaymentHistoryLoaded(history));
    } catch (e) {
      emit(PaymentError(PaymentErrorHandler.messageFrom(e)));
    }
  }

  Future<void> _onDetailsLoad(
    PaymentDetailsLoadRequested event,
    Emitter<PaymentState> emit,
  ) async {
    emit(const PaymentLoading(message: 'Loading transaction…'));
    try {
      final payment = await _getPaymentDetails(
        accessToken: event.accessToken,
        paymentId: event.paymentId,
      );
      PaymentAnalytics.transactionDetailsViewed(payment.id);
      emit(PaymentDetailsLoaded(payment));
    } catch (e) {
      emit(PaymentError(PaymentErrorHandler.messageFrom(e)));
    }
  }

  Future<void> _onLinkCreate(
    PaymentLinkCreateRequested event,
    Emitter<PaymentState> emit,
  ) async {
    emit(const PaymentLoading(message: 'Preparing secure checkout…'));
    try {
      final link = await _createPaymentLink(
        accessToken: event.accessToken,
        serviceRequestId: event.serviceRequestId,
        redirectUrl: event.redirectUrl,
        paymentMode: event.paymentMode,
      );
      PaymentAnalytics.checkoutOpened(link.payment.orderId);
      emit(PaymentLinkReady(link));
    } catch (e) {
      emit(PaymentError(PaymentErrorHandler.messageFrom(e)));
    }
  }

  Future<void> _onVerify(
    PaymentVerifyRequested event,
    Emitter<PaymentState> emit,
  ) async {
    emit(const PaymentLoading(message: 'Verifying payment…'));
    try {
      final result = await _verifyPayment(
        accessToken: event.accessToken,
        orderId: event.orderId,
      );
      _logVerifyResult(result);
      emit(PaymentVerified(result));
    } catch (e) {
      emit(PaymentError(PaymentErrorHandler.messageFrom(e)));
    }
  }

  Future<void> _onRefresh(
    PaymentStatusRefreshRequested event,
    Emitter<PaymentState> emit,
  ) async {
    emit(const PaymentLoading(message: 'Refreshing payment status…'));
    try {
      final result = await _refreshPaymentStatus(
        accessToken: event.accessToken,
        orderId: event.orderId,
        refreshFromZoho: event.refreshFromZoho,
      );
      _logVerifyResult(result);
      emit(PaymentVerified(result));
    } catch (e) {
      emit(PaymentError(PaymentErrorHandler.messageFrom(e)));
    }
  }

  void _logVerifyResult(PaymentVerifyResult result) {
    PaymentAnalytics.paymentStatusRefreshed(
      result.payment.orderId,
      result.payment.status,
    );
    if (result.payment.isSuccess) {
      PaymentAnalytics.paymentSuccess(
        result.payment.orderId,
        result.payment.amount,
      );
    } else if (result.payment.isFailed) {
      PaymentAnalytics.paymentFailed(
        result.payment.orderId,
        result.payment.failureReason,
      );
    } else {
      PaymentAnalytics.paymentPending(result.payment.orderId);
    }
  }
}
