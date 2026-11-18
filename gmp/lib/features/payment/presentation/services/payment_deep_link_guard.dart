/// `gmp://payment/callback` is registered on Android/iOS for Zoho return URLs.
///
/// Any app can fire this scheme. Do **not** treat an incoming deep link as
/// payment success or mutate payment state from it. Checkout already treats
/// `gmp://payment/...` WebView navigations as a verify trigger only.
class PaymentDeepLinkGuard {
  PaymentDeepLinkGuard._();

  static bool isPaymentCallback(Uri uri) {
    return uri.scheme.toLowerCase() == 'gmp' &&
        uri.host.toLowerCase() == 'payment';
  }

  /// Explicit no-op: deep links must not mark payments successful.
  static void ignoreIncoming(Uri uri) {
    // Intentionally empty — verify only runs from PaymentCheckoutPage after
    // the user is already in an authenticated checkout session.
  }
}
