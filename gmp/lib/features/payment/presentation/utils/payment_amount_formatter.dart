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

  static String formatDate(DateTime? date) {
    if (date == null) return '—';
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }
}
