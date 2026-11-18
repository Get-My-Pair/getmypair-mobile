import 'package:flutter/material.dart';

import 'payment_request_page.dart';

/// Kept for existing navigation call sites (retry / transaction details).
/// Renders the same Purchase Summary screen as [PaymentRequestPage].
class PaymentSummaryPage extends StatelessWidget {
  final String serviceRequestId;
  final double amount;
  final String? serviceType;
  final String? requestLabel;

  const PaymentSummaryPage({
    super.key,
    required this.serviceRequestId,
    required this.amount,
    this.serviceType,
    this.requestLabel,
  });

  @override
  Widget build(BuildContext context) {
    return PaymentRequestPage(
      serviceRequestId: serviceRequestId,
      amount: amount,
      serviceType: serviceType,
      requestLabel: requestLabel,
    );
  }
}
