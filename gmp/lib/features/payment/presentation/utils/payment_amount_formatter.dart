class PaymentAmountFormatter {
  PaymentAmountFormatter._();

  static String format(dynamic value, {String currency = 'INR'}) {
    if (value == null) return '—';
    final num? n = value is num ? value : num.tryParse(value.toString());
    if (n == null) return value.toString();
    final prefix = currency == 'INR' ? '₹' : '$currency ';
    if (n % 1 == 0) return '$prefix${n.toInt()}';
    return '$prefix${n.toStringAsFixed(2)}';
  }

  /// Indian-style grouping for purchase summary (e.g. ₹1,180 / ₹1,000.50).
  static String formatGrouped(dynamic value, {String currency = 'INR'}) {
    if (value == null) return '—';
    final num? n = value is num ? value : num.tryParse(value.toString());
    if (n == null) return value.toString();
    final prefix = currency == 'INR' ? '₹' : '$currency ';
    final negative = n < 0;
    final abs = n.abs();
    final whole = abs.floor();
    final hasFraction = abs % 1 != 0;
    final fraction = hasFraction
        ? abs.toStringAsFixed(2).split('.').last
        : null;
    final grouped = _groupIndian(whole);
    final body = fraction == null ? grouped : '$grouped.$fraction';
    return '$prefix${negative ? '-' : ''}$body';
  }

  static String _groupIndian(int whole) {
    final s = whole.toString();
    if (s.length <= 3) return s;
    final last3 = s.substring(s.length - 3);
    var rest = s.substring(0, s.length - 3);
    final parts = <String>[];
    while (rest.length > 2) {
      parts.insert(0, rest.substring(rest.length - 2));
      rest = rest.substring(0, rest.length - 2);
    }
    if (rest.isNotEmpty) parts.insert(0, rest);
    return '${parts.join(',')},$last3';
  }

  static String formatDate(DateTime? date) {
    if (date == null) return '—';
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }
}
