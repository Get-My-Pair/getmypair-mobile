import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
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
  bool _checking = false;
  bool _manualCheck = false;
  bool _autoChecked = false;
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

  /// Asks the server to confirm the payment with the gateway. When the app was
  /// closed mid-payment the stored status can still say "in checkout".
  Future<void> _refreshStatus(Payment payment, {bool manual = true}) async {
    if (_checking) return;
    final tokenResult = await sl<GetValidAccessToken>().call();
    if (!mounted) return;
    tokenResult.fold((_) {}, (token) {
      setState(() {
        _checking = true;
        _manualCheck = manual;
      });
      context.read<PaymentBloc>().add(
            PaymentStatusRefreshRequested(
              accessToken: token,
              orderId: payment.orderId,
              refreshFromZoho: true,
            ),
          );
    });
  }

  void _copy(String label, String value) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('$label copied'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
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
          // Stale "in checkout" rows: confirm once, quietly.
          final p = state.payment;
          if (!_autoChecked && (p.isPending || p.status.isEmpty)) {
            _autoChecked = true;
            _refreshStatus(p, manual: false);
          }
        } else if (state is PaymentVerified) {
          final manual = _manualCheck;
          setState(() {
            _payment = state.result.payment;
            _loading = false;
            _checking = false;
            _manualCheck = false;
          });
          if (manual) {
            final p = state.result.payment;
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  behavior: SnackBarBehavior.floating,
                  content: Text(
                    p.isSuccess
                        ? 'Payment confirmed'
                        : p.isFailed
                            ? 'This payment failed'
                            : 'Still waiting for the bank to confirm',
                  ),
                ),
              );
          }
        } else if (state is PaymentError) {
          final hadPayment = _payment != null;
          setState(() {
            _loading = false;
            _checking = false;
            _manualCheck = false;
            if (!hadPayment) _error = state.message;
          });
        }
      },
      child: PaymentPageShell(
        title: 'Transaction',
        subtitle: 'Receipt and payment details.',
        actions: [
          IconButton(
            onPressed: _checking ? null : _load,
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

  // ---- body ---------------------------------------------------------------

  Widget _buildBody(Payment payment) {
    final paid = payment.isSuccess || payment.isRefunded;
    final failed = payment.isFailed;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StatusHero(payment: payment),
          if (!paid && !failed) ...[
            const SizedBox(height: 12),
            _InfoNote(
              checking: _checking,
              text: 'This payment is not confirmed yet. If you already paid, '
                  'tap “Check payment status” — we confirm it with the payment '
                  'gateway.',
            ),
          ],
          const SizedBox(height: 14),
          PaymentSurfaceCard(
            title: 'PAYMENT DETAILS',
            child: Column(
              children: [
                if (paid)
                  _MethodRow(payment: payment),
                if (payment.serviceName != null)
                  PaymentDetailRow(
                    label: 'Service',
                    value: payment.serviceName!,
                  ),
                PaymentDetailRow(
                  label: 'Amount',
                  value: PaymentAmountFormatter.format(
                    payment.amount,
                    currency: payment.currency,
                  ),
                  bold: true,
                ),
                PaymentDetailRow(
                  label: 'Status',
                  value: _statusText(payment),
                ),
                if (paid)
                  PaymentDetailRow(
                    label: 'Paid on',
                    value: PaymentAmountFormatter.formatFriendly(
                      payment.completedAt,
                    ),
                  )
                else if (failed)
                  PaymentDetailRow(
                    label: 'Failed on',
                    value: PaymentAmountFormatter.formatFriendly(
                      payment.failedAt ?? payment.updatedAt,
                    ),
                  )
                else
                  PaymentDetailRow(
                    label: 'Started on',
                    value: PaymentAmountFormatter.formatFriendly(
                      payment.createdAt,
                    ),
                  ),
                if (failed && (payment.failureReason ?? '').isNotEmpty)
                  PaymentDetailRow(
                    label: 'Reason',
                    value: _friendlyReason(payment.failureReason!),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          PaymentSurfaceCard(
            title: 'REFERENCE NUMBERS',
            child: Column(
              children: [
                _CopyRow(
                  label: 'Order ID',
                  hint: 'Quote this when you contact support',
                  value: payment.orderId,
                  onCopy: () => _copy('Order ID', payment.orderId),
                ),
                if ((payment.zohoPaymentId ?? '').isNotEmpty) ...[
                  const Divider(height: 18, color: Color(0xFFE2E8EA)),
                  _CopyRow(
                    label: 'Transaction ID',
                    hint: 'Reference from the payment gateway',
                    value: payment.zohoPaymentId!,
                    onCopy: () =>
                        _copy('Transaction ID', payment.zohoPaymentId!),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          _Timeline(payment: payment),
          if (!paid) ...[
            const SizedBox(height: 20),
            if (failed)
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
                label: 'Check payment status',
                loading: _checking,
                onPressed: () => _refreshStatus(payment),
              ),
          ],
        ],
      ),
    );
  }

  static String _statusText(Payment p) {
    if (p.isRefunded) return 'Refunded';
    if (p.isSuccess) return 'Paid';
    if (p.isFailed) return 'Failed';
    return 'Waiting for payment';
  }

  static String _friendlyReason(String raw) {
    final r = raw.trim();
    if (r.isEmpty) return 'Payment failed';
    final lower = r.toLowerCase();
    if (lower == 'failed' || lower == 'failure') return 'Payment failed';
    if (lower == 'canceled' || lower == 'cancelled') return 'Cancelled by you';
    if (lower == 'expired') return 'Payment link expired';
    if (lower == 'declined') return 'Declined by the bank';
    return r.replaceAll('_', ' ');
  }
}

// ---- widgets ---------------------------------------------------------------

class _StatusHero extends StatelessWidget {
  const _StatusHero({required this.payment});

  final Payment payment;

  @override
  Widget build(BuildContext context) {
    final paid = payment.isSuccess || payment.isRefunded;
    final failed = payment.isFailed;

    final Color accent;
    final IconData icon;
    final String title;
    final String subtitle;
    if (payment.isRefunded) {
      accent = AppColors.warning;
      icon = Icons.undo_rounded;
      title = 'Payment refunded';
      subtitle = 'Paid on ${PaymentAmountFormatter.formatFriendly(payment.completedAt)}';
    } else if (paid) {
      accent = AppColors.success;
      icon = Icons.check_circle_rounded;
      title = 'Payment successful';
      subtitle = payment.paymentViaText != null
          ? 'Paid via ${payment.paymentViaText}'
          : 'Paid online';
    } else if (failed) {
      accent = AppColors.error;
      icon = Icons.cancel_rounded;
      title = 'Payment failed';
      subtitle =
          'Failed on ${PaymentAmountFormatter.formatFriendly(payment.failedAt ?? payment.updatedAt)}';
    } else {
      accent = AppColors.warning;
      icon = Icons.hourglass_top_rounded;
      title = 'Waiting for payment';
      subtitle =
          'Started on ${PaymentAmountFormatter.formatFriendly(payment.createdAt)}';
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      decoration: BoxDecoration(
        gradient: paid
            ? PaymentPageTheme.heroGradient
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  accent.withValues(alpha: 0.16),
                  accent.withValues(alpha: 0.06),
                ],
              ),
        borderRadius: BorderRadius.circular(18),
        border: paid ? null : Border.all(color: accent.withValues(alpha: 0.35)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: paid
                  ? Colors.white.withValues(alpha: 0.18)
                  : accent.withValues(alpha: 0.18),
            ),
            child: Icon(icon, size: 34, color: paid ? Colors.white : accent),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: paid ? Colors.white : PaymentPageTheme.titleColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            PaymentAmountFormatter.format(
              payment.amount,
              currency: payment.currency,
            ),
            style: GoogleFonts.boldonse(
              fontSize: 30,
              fontWeight: FontWeight.w400,
              color: paid ? Colors.white : PaymentPageTheme.titleColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              fontSize: 12.5,
              height: 1.35,
              color: paid
                  ? AppColors.onGradientMuted
                  : Colors.black.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoNote extends StatelessWidget {
  const _InfoNote({required this.text, required this.checking});

  final String text;
  final bool checking;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          checking
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.info_outline_rounded, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              checking ? 'Checking with the payment gateway…' : text,
              style: GoogleFonts.montserrat(
                fontSize: 12,
                height: 1.4,
                color: PaymentPageTheme.titleColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MethodRow extends StatelessWidget {
  const _MethodRow({required this.payment});

  final Payment payment;

  static IconData _iconFor(String? method) {
    switch ((method ?? '').toLowerCase()) {
      case 'upi':
        return Icons.phone_android_rounded;
      case 'card':
        return Icons.credit_card_rounded;
      case 'netbanking':
        return Icons.account_balance_rounded;
      case 'wallet':
        return Icons.account_balance_wallet_rounded;
      default:
        return Icons.payments_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = payment.paymentMethodLabel ?? 'Online payment';
    final detail = (payment.paymentMethodDetail ?? '').trim();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              'Paid via',
              style: GoogleFonts.montserrat(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(
                  _iconFor(payment.paymentMethod),
                  size: 18,
                  color: PaymentPageTheme.accentColor,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        label,
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: PaymentPageTheme.titleColor,
                        ),
                      ),
                      if (detail.isNotEmpty)
                        Text(
                          detail,
                          textAlign: TextAlign.end,
                          style: GoogleFonts.montserrat(
                            fontSize: 11.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CopyRow extends StatelessWidget {
  const _CopyRow({
    required this.label,
    required this.hint,
    required this.value,
    required this.onCopy,
  });

  final String label;
  final String hint;
  final String value;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              SelectableText(
                value,
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: PaymentPageTheme.titleColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                hint,
                style: GoogleFonts.montserrat(
                  fontSize: 11,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Copy $label',
          onPressed: onCopy,
          icon: const Icon(
            Icons.copy_rounded,
            size: 20,
            color: PaymentPageTheme.accentColor,
          ),
        ),
      ],
    );
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.payment});

  final Payment payment;

  @override
  Widget build(BuildContext context) {
    final paid = payment.isSuccess || payment.isRefunded;
    final failed = payment.isFailed;

    final endTitle = paid
        ? 'Payment received'
        : failed
            ? 'Payment failed'
            : 'Waiting for payment';
    final endTime = paid
        ? payment.completedAt
        : failed
            ? (payment.failedAt ?? payment.updatedAt)
            : null;
    final endColor = paid
        ? AppColors.success
        : failed
            ? AppColors.error
            : AppColors.warning;

    return PaymentSurfaceCard(
      title: 'TIMELINE',
      child: Column(
        children: [
          _TimelineStep(
            title: 'Checkout started',
            time: PaymentAmountFormatter.formatFriendly(payment.createdAt),
            color: PaymentPageTheme.accentColor,
            done: true,
            showLine: true,
          ),
          _TimelineStep(
            title: endTitle,
            time: endTime != null
                ? PaymentAmountFormatter.formatFriendly(endTime)
                : 'Not completed yet',
            color: endColor,
            done: paid || failed,
            showLine: false,
          ),
        ],
      ),
    );
  }
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
    required this.title,
    required this.time,
    required this.color,
    required this.done,
    required this.showLine,
  });

  final String title;
  final String time;
  final Color color;
  final bool done;
  final bool showLine;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  margin: const EdgeInsets.only(top: 3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: done ? color : Colors.white,
                    border: Border.all(color: color, width: 2),
                  ),
                ),
                if (showLine)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: color.withValues(alpha: 0.35),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: showLine ? 14 : 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.montserrat(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: PaymentPageTheme.titleColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    time,
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
