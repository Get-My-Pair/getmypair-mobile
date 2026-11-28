import 'package:flutter_test/flutter_test.dart';
import 'package:gmp/features/payment/data/models/payment_model.dart';
import 'package:gmp/features/payment/presentation/utils/payment_amount_formatter.dart';

void main() {
  Map<String, dynamic> json(Map<String, dynamic> extra) => {
        '_id': 'p1',
        'orderId': 'GMP-ORD-1',
        'serviceRequestId': 'r1',
        'userId': 'u1',
        'amount': 500,
        'createdAt': '2026-11-28T10:00:00.000Z',
        'updatedAt': '2026-11-28T10:05:00.000Z',
        ...extra,
      };

  test('paid payment uses paid time and shows how it was paid', () {
    final p = PaymentModel.fromJson(json({
      'status': 'PAYMENT_SUCCESS',
      'paidAt': '2026-11-28T10:04:00.000Z',
      'paymentMethod': 'upi',
      'paymentMethodDetail': 'ravi@okicici',
      'zohoPaymentId': 'pay_123',
    }));
    expect(p.countsAsPaid, isTrue);
    expect(p.completedAt, DateTime.parse('2026-11-28T10:04:00.000Z'));
    expect(p.paymentMethodLabel, 'UPI');
    expect(p.paymentViaText, 'UPI · ravi@okicici');
  });

  test('initiated payment has no completed date and no method', () {
    final p = PaymentModel.fromJson(json({'status': 'PAYMENT_INITIATED'}));
    expect(p.isPending, isTrue);
    expect(p.completedAt, isNull);
    expect(p.paymentViaText, isNull);
  });

  test('success without paidAt falls back to updatedAt, never createdAt', () {
    final p = PaymentModel.fromJson(json({'status': 'PAYMENT_SUCCESS'}));
    expect(p.completedAt, DateTime.parse('2026-11-28T10:05:00.000Z'));
  });

  test('friendly date is local time, 12-hour', () {
    final d = DateTime(2026, 11, 28, 19, 45);
    expect(PaymentAmountFormatter.formatFriendly(d), '28 Nov 2026, 7:45 PM');
    expect(PaymentAmountFormatter.formatFriendly(DateTime(2026, 1, 5, 0, 5)),
        '5 Jan 2026, 12:05 AM');
    expect(PaymentAmountFormatter.formatFriendly(null), '—');
  });
}
