enum ZohoPaymentMode {
  sandbox('sandbox'),
  live('live');

  const ZohoPaymentMode(this.apiValue);

  final String apiValue;

  String get title {
    switch (this) {
      case ZohoPaymentMode.sandbox:
        return 'Sandbox Testing Mode';
      case ZohoPaymentMode.live:
        return 'Live Zoho payment';
    }
  }

  String get subtitle {
    switch (this) {
      case ZohoPaymentMode.sandbox:
        return 'Test cards and UPI on Zoho sandbox — no real money.';
      case ZohoPaymentMode.live:
        return 'Real Zoho checkout with live payment processing.';
    }
  }
}
