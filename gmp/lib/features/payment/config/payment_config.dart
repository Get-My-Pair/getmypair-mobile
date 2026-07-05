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
  static const zohoRedirectUrl = 'gmp://payment/callback';

  /// Modes shown in the bottom-sheet picker (live only in production).
  static List<ZohoPaymentMode> get selectableModes => allowDevModes
      ? ZohoPaymentMode.orderedMethods
      : const [ZohoPaymentMode.live];
}
