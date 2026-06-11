import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/widgets/app_feedback_alert.dart';
import '../../../../features/auth/domain/usecases/get_valid_access_token.dart';
import '../../../../features/payment/domain/entities/payment.dart';
import '../../../../features/payment/domain/usecases/payment_usecases.dart';
import '../../../../features/payment/presentation/bloc/payment_bloc.dart';
import '../../../../features/payment/presentation/pages/payment_failed_page.dart';
import '../../../../features/payment/presentation/pages/payment_request_page.dart';
import '../../../../features/payment/presentation/pages/transaction_details_page.dart';
import '../../../../features/service/presentation/pages/service_request_details_page.dart';
import '../../../../injection_container.dart';
import 'user_notifications.dart';

Future<void> navigateFromUserNotification(
  BuildContext context,
  UserNotificationItem item,
) async {
  final serviceRequestId = item.serviceRequestId;
  if (serviceRequestId == null || serviceRequestId.isEmpty) return;

  if (item.isCostApproval) {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => ServiceRequestDetailsPage(requestId: serviceRequestId),
      ),
    );
    return;
  }

  if (item.isPaymentRelated) {
    await _openPaymentPage(context, item, serviceRequestId);
    return;
  }

  await Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => ServiceRequestDetailsPage(requestId: serviceRequestId),
    ),
  );
}

Future<void> _openPaymentPage(
  BuildContext context,
  UserNotificationItem item,
  String serviceRequestId,
) async {
  final tokenResult = await sl<GetValidAccessToken>().call();
  if (!context.mounted) return;

  await tokenResult.fold(
    (failure) async {
      await showAppFeedbackAlert(
        context,
        message: failure.message,
        type: AppFeedbackType.failure,
      );
    },
    (token) async {
      Payment? payment;
      try {
        payment = await sl<GetPaymentByServiceRequest>().call(
          accessToken: token,
          serviceRequestId: serviceRequestId,
        );
      } catch (_) {
        payment = null;
      }

      if (!context.mounted) return;

      final resolvedPayment = payment;
      if (resolvedPayment != null) {
        if (item.isPaymentSuccess || resolvedPayment.isSuccess) {
          final paymentId = resolvedPayment.id;
          await Navigator.of(context).push<void>(
            MaterialPageRoute(
              builder: (_) => BlocProvider(
                create: (_) => sl<PaymentBloc>(),
                child: TransactionDetailsPage(paymentId: paymentId),
              ),
            ),
          );
          return;
        }

        if (item.isPaymentFailed || resolvedPayment.isFailed) {
          final orderId = resolvedPayment.orderId;
          final paidAmount = resolvedPayment.amount;
          final failureReason = resolvedPayment.failureReason;
          await Navigator.of(context).push<void>(
            MaterialPageRoute(
              builder: (_) => BlocProvider(
                create: (_) => sl<PaymentBloc>(),
                child: PaymentFailedPage(
                  orderId: orderId,
                  serviceRequestId: serviceRequestId,
                  amount: paidAmount,
                  failureReason: failureReason,
                ),
              ),
            ),
          );
          return;
        }
      }

      final amount = await _resolvePayableAmount(token, item, serviceRequestId);
      if (!context.mounted) return;

      if (amount == null || amount <= 0) {
        await showAppFeedbackAlert(
          context,
          message:
              'This service request is no longer available or has no approved cost yet.',
          type: AppFeedbackType.failure,
        );
        return;
      }

      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => sl<PaymentBloc>(),
            child: PaymentRequestPage(
              serviceRequestId: serviceRequestId,
              amount: amount,
              requestLabel: 'Request #${serviceRequestId.substring(0, 8)}…',
            ),
          ),
        ),
      );
    },
  );
}

Future<double?> _resolvePayableAmount(
  String token,
  UserNotificationItem item,
  String serviceRequestId,
) async {
  final fromNotification = item.payableAmount;
  if (fromNotification != null && fromNotification > 0) {
    return fromNotification;
  }

  try {
    final res = await sl<DioClient>().get(
      ApiEndpoints.serviceById(serviceRequestId),
      accessToken: token,
    );
    final request = (res['data'] as Map<String, dynamic>?)?['request'];
    if (request is! Map) return null;
    final actualCost = request['actualCost'];
    if (actualCost is num) return actualCost.toDouble();
    return double.tryParse('$actualCost');
  } catch (_) {
    return null;
  }
}
