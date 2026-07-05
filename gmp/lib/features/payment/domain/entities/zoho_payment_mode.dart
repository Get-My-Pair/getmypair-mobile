enum ZohoPaymentMode {
  /// Production — real charges via Zoho Checkout.
  live('live'),

  /// Dev/QA only — enable with --dart-define=PAYMENT_DEV_MODES=true
  sandbox('sandbox'),

  /// Dev/QA only — local simulated flow when Zoho is offline.
  simulate('simulate');

  const ZohoPaymentMode(this.apiValue);

  final String apiValue;

  bool get requiresZohoCheckout => this != ZohoPaymentMode.simulate;

  /// Short label for UI lists (Method 1 / 2 / 3).
  int get methodNumber {
    switch (this) {
      case ZohoPaymentMode.live:
        return 1;
      case ZohoPaymentMode.sandbox:
        return 2;
      case ZohoPaymentMode.simulate:
        return 3;
    }
  }

  String get title {
    switch (this) {
      case ZohoPaymentMode.live:
        return 'Live Zoho payment';
      case ZohoPaymentMode.sandbox:
        return 'Zoho sandbox';
      case ZohoPaymentMode.simulate:
        return 'Simulate flow';
    }
  }

  String get subtitle {
    switch (this) {
      case ZohoPaymentMode.live:
        return 'Real payment — charges your card or UPI.';
      case ZohoPaymentMode.sandbox:
        return 'Zoho test mode — no real money.';
      case ZohoPaymentMode.simulate:
        return 'Auto demo when Zoho is offline or for preview.';
    }
  }

  static const orderedMethods = [
    ZohoPaymentMode.live,
    ZohoPaymentMode.sandbox,
    ZohoPaymentMode.simulate,
  ];
}
