import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/chevron_screen_back_button.dart';
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
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          leading: const ChevronScreenBackButton(
            iconColor: AppColors.textPrimary,
          ),
          title: Text(
            'Transaction details',
            style: GoogleFonts.montserrat(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          actions: [
            IconButton(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
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
                          ElevatedButton(
                            onPressed: _load,
                            child: const Text('Retry'),
                          ),
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
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: PaymentStatusChip.fromPayment(payment)),
          const SizedBox(height: 16),
          Center(
            child: Text(
              PaymentAmountFormatter.format(payment.amount),
              style: GoogleFonts.montserrat(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 24),
          _detailCard(payment),
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
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () => _refreshStatus(payment),
                  child: const Text('Refresh payment status'),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _detailCard(Payment payment) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          _row('Order ID', payment.orderId),
          _row('Payment ID', payment.id),
          _row('Service request', payment.serviceRequestId),
          _row('Status', payment.status),
          if (payment.paidAt != null)
            _row('Paid at', PaymentAmountFormatter.formatDate(payment.paidAt)),
          if (payment.failedAt != null)
            _row(
              'Failed at',
              PaymentAmountFormatter.formatDate(payment.failedAt),
            ),
          if (payment.failureReason != null)
            _row('Reason', payment.failureReason!),
          if (payment.createdAt != null)
            _row(
              'Created',
              PaymentAmountFormatter.formatDate(payment.createdAt),
            ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
