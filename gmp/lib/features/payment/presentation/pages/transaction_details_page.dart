import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../features/auth/domain/usecases/get_valid_access_token.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/payment.dart';
import '../bloc/payment_bloc.dart';
import '../bloc/payment_event.dart';
import '../bloc/payment_state.dart';
import '../services/payment_error_handler.dart';
import '../utils/payment_amount_formatter.dart';
import '../widgets/pay_now_button.dart';
import '../widgets/payment_loader.dart';
import '../widgets/payment_page_shell.dart';
import '../widgets/payment_status_chip.dart';
import 'payment_summary_page.dart';

class TransactionDetailsPage extends StatefulWidget {
  final String paymentId;

  const TransactionDetailsPage({super.key, required this.paymentId});

  @override
  State<TransactionDetailsPage> createState() => _TransactionDetailsPageState();
}

class _TransactionDetailsPageState extends State<TransactionDetailsPage> {
  Payment? _payment;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final tokenResult = await sl<GetValidAccessToken>().call();
    if (!mounted) return;
    tokenResult.fold(
      (f) => setState(() {
        _loading = false;
        _error = f.message;
      }),
      (token) {
        context.read<PaymentBloc>().add(
              PaymentDetailsLoadRequested(
                accessToken: token,
                paymentId: widget.paymentId,
              ),
            );
      },
    );
  }

  Future<void> _refreshStatus(Payment payment) async {
    final tokenResult = await sl<GetValidAccessToken>().call();
    if (!mounted) return;
    tokenResult.fold((_) {}, (token) {
      context.read<PaymentBloc>().add(
            PaymentStatusRefreshRequested(
              accessToken: token,
              orderId: payment.orderId,
              refreshFromZoho: true,
            ),
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PaymentBloc, PaymentState>(
      listener: (context, state) {
        if (state is PaymentDetailsLoaded) {
          setState(() {
            _payment = state.payment;
            _loading = false;
          });
        } else if (state is PaymentVerified) {
          setState(() {
            _payment = state.result.payment;
            _loading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.result.payment.isSuccess
                    ? 'Payment confirmed'
                    : 'Status: ${state.result.payment.status}',
              ),
            ),
          );
        } else if (state is PaymentError) {
          setState(() {
            _loading = false;
            _error = state.message;
          });
        }
      },
      child: PaymentPageShell(
        title: 'Transaction',
        subtitle: 'Payment details for this service request.',
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(
              Icons.refresh_rounded,
              color: PaymentPageTheme.titleColor,
            ),
          ),
        ],
        body: _loading
            ? const PaymentLoader(message: 'Loading transaction…')
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(PaymentErrorHandler.messageFrom(_error!)),
                          const SizedBox(height: 16),
                          PayNowButton(label: 'Retry', onPressed: _load),
                        ],
                      ),
                    ),
                  )
                : _payment == null
                    ? const SizedBox.shrink()
                    : _buildBody(_payment!),
      ),
    );
  }

  Widget _buildBody(Payment payment) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: PaymentStatusChip.fromPayment(payment)),
          const SizedBox(height: 16),
          PaymentAmountHero(
            label: 'Transaction amount',
            amountText: PaymentAmountFormatter.format(payment.amount),
          ),
          const SizedBox(height: 16),
          PaymentSurfaceCard(
            title: 'Details',
            child: Column(
              children: [
                PaymentDetailRow(label: 'Order ID', value: payment.orderId),
                PaymentDetailRow(label: 'Payment ID', value: payment.id),
                PaymentDetailRow(
                  label: 'Service request',
                  value: payment.serviceRequestId,
                ),
                PaymentDetailRow(label: 'Status', value: payment.status),
                if (payment.paidAt != null)
                  PaymentDetailRow(
                    label: 'Paid at',
                    value: PaymentAmountFormatter.formatDate(payment.paidAt),
                  ),
                if (payment.failedAt != null)
                  PaymentDetailRow(
                    label: 'Failed at',
                    value: PaymentAmountFormatter.formatDate(payment.failedAt),
                  ),
                if (payment.failureReason != null)
                  PaymentDetailRow(
                    label: 'Reason',
                    value: payment.failureReason!,
                  ),
                if (payment.createdAt != null)
                  PaymentDetailRow(
                    label: 'Created',
                    value: PaymentAmountFormatter.formatDate(payment.createdAt),
                  ),
              ],
            ),
          ),
          if (payment.isFailed || payment.isPending) ...[
            const SizedBox(height: 20),
            if (payment.isFailed)
              PayNowButton(
                label: 'Retry payment',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BlocProvider.value(
                        value: context.read<PaymentBloc>(),
                        child: PaymentSummaryPage(
                          serviceRequestId: payment.serviceRequestId,
                          amount: payment.amount,
                        ),
                      ),
                    ),
                  );
                },
              )
            else
              PaymentSecondaryButton(
                label: 'Refresh payment status',
                onPressed: () => _refreshStatus(payment),
              ),
          ],
        ],
      ),
    );
  }
}
