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
import '../utils/payment_amount_formatter.dart';
import '../widgets/payment_loader.dart';
import '../widgets/payment_status_chip.dart';
import 'transaction_details_page.dart';

class PaymentHistoryPage extends StatefulWidget {
  const PaymentHistoryPage({super.key});

  @override
  State<PaymentHistoryPage> createState() => _PaymentHistoryPageState();
}

class _PaymentHistoryPageState extends State<PaymentHistoryPage> {
  String? _accessToken;
  int _page = 1;
  final List<Payment> _items = [];
  bool _hasMore = true;
  bool _initialLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTokenAndHistory(refresh: true);
  }

  Future<void> _loadTokenAndHistory({bool refresh = false}) async {
    if (refresh) {
      _page = 1;
      _items.clear();
      _hasMore = true;
    }
    final tokenResult = await sl<GetValidAccessToken>().call();
    if (!mounted) return;
    await tokenResult.fold(
      (_) async {
        setState(() => _initialLoading = false);
      },
      (token) async {
        _accessToken = token;
        context.read<PaymentBloc>().add(
              PaymentHistoryLoadRequested(
                accessToken: token,
                page: _page,
                refresh: refresh,
              ),
            );
      },
    );
  }

  void _loadMore() {
    if (!_hasMore || _accessToken == null) return;
    _page += 1;
    context.read<PaymentBloc>().add(
          PaymentHistoryLoadRequested(
            accessToken: _accessToken!,
            page: _page,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PaymentBloc, PaymentState>(
      listener: (context, state) {
        if (state is PaymentHistoryLoaded) {
          setState(() {
            _initialLoading = false;
            if (state.history.page == 1) {
              _items
                ..clear()
                ..addAll(state.history.items);
            } else {
              _items.addAll(state.history.items);
            }
            _hasMore = state.history.hasMore;
          });
        } else if (state is PaymentError) {
          setState(() => _initialLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
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
            'Payment history',
            style: GoogleFonts.montserrat(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          actions: [
            IconButton(
              onPressed: () => _loadTokenAndHistory(refresh: true),
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        body: _initialLoading
            ? const PaymentLoader(message: 'Loading transactions…')
            : _items.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 56,
                            color: AppColors.textTertiary.withValues(alpha: 0.6),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No payments yet',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Completed service payments will appear here.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () => _loadTokenAndHistory(refresh: true),
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _items.length + (_hasMore ? 1 : 0),
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        if (index >= _items.length) {
                          return TextButton(
                            onPressed: _loadMore,
                            child: const Text('Load more'),
                          );
                        }
                        final payment = _items[index];
                        return _PaymentHistoryTile(
                          payment: payment,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BlocProvider.value(
                                  value: context.read<PaymentBloc>(),
                                  child: TransactionDetailsPage(
                                    paymentId: payment.id,
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
      ),
    );
  }
}

class _PaymentHistoryTile extends StatelessWidget {
  final Payment payment;
  final VoidCallback onTap;

  const _PaymentHistoryTile({
    required this.payment,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      PaymentAmountFormatter.format(payment.amount),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      payment.orderId,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (payment.createdAt != null)
                      Text(
                        PaymentAmountFormatter.formatDate(payment.createdAt),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textTertiary,
                        ),
                      ),
                  ],
                ),
              ),
              PaymentStatusChip.fromPayment(payment, compact: true),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
