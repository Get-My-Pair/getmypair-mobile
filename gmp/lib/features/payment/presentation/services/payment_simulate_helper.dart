import '../../data/models/payment_model.dart';
import '../../domain/entities/payment.dart';
import '../../domain/utils/payment_simulate_utils.dart';

/// Builds local mock payment links for simulated checkout UI.
class PaymentSimulateHelper {
  PaymentSimulateHelper._();

  static PaymentLinkResult buildLocalLink({
    required String serviceRequestId,
    required double amount,
  }) {
    final orderId = 'SIM-${DateTime.now().millisecondsSinceEpoch}';
    return PaymentLinkResult(
      payment: PaymentModel(
        id: 'sim-$orderId',
        orderId: orderId,
        serviceRequestId: serviceRequestId,
        userId: 'simulate',
        amount: amount,
        status: 'PAYMENT_INITIATED',
        providerType: 'simulate',
        paymentLinkUrl: PaymentSimulateUtils.simulatedCheckoutScheme,
      ),
      checkoutUrl: PaymentSimulateUtils.simulatedCheckoutScheme,
    );
  }
}
