import '../entities/payment.dart';

/// Shared simulate-payment identifiers (domain layer — no Flutter/data deps).
class PaymentSimulateUtils {
  PaymentSimulateUtils._();

  static const simulatedCheckoutScheme = 'gmp://payment/simulate';

  static bool isSimulatedCheckoutUrl(String url) =>
      url.startsWith(simulatedCheckoutScheme);

  static bool isSimulatedOrder(String orderId) => orderId.startsWith('SIM-');

  static bool isSimulatedPayment(Payment payment) =>
      payment.providerType == 'simulate' || isSimulatedOrder(payment.orderId);
}
