import '../../../core/constants/api_endpoints.dart';
import '../domain/entities/zoho_payment_mode.dart';

/// Payment environment flags. Sandbox/simulate code remains in the repo but is
/// hidden from production builds unless [allowDevModes] is enabled at compile time.
///
/// QA / internal testing:
/// `flutter run --dart-define=PAYMENT_DEV_MODES=true`
class PaymentConfig {
  PaymentConfig._();

  /// When false (default), only live Zoho checkout is exposed in the UI.
  static const allowDevModes =
      bool.fromEnvironment('PAYMENT_DEV_MODES', defaultValue: false);

  static bool get isProductionFlow => !allowDevModes;

  static ZohoPaymentMode get defaultMode => ZohoPaymentMode.live;

  /// Auto-fallback to simulated checkout when Zoho fails (dev/QA only).
  static bool get enableSimulateFallback => allowDevModes;

  /// Passed to POST /api/payment/link for Zoho post-payment redirect.
  /// Must be a valid HTTPS URL (API validates with isURL); the checkout WebView
  /// intercepts this path when Zoho redirects after payment.
  static String get zohoRedirectUrl => ApiEndpoints.paymentCallback;

  /// Modes shown in the bottom-sheet picker (live only in production).
  static List<ZohoPaymentMode> get selectableModes => allowDevModes
      ? ZohoPaymentMode.orderedMethods
      : const [ZohoPaymentMode.live];
}
