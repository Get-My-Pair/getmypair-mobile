import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/bgtheme.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../features/auth/domain/usecases/get_valid_access_token.dart';
import '../../../../injection_container.dart';
import '../../config/payment_config.dart';
import '../../domain/entities/payment.dart';
import '../../domain/usecases/payment_usecases.dart';
import '../bloc/payment_bloc.dart';
import '../bloc/payment_event.dart';
import '../bloc/payment_state.dart';
import '../services/payment_analytics.dart';
import '../services/payment_error_handler.dart';
import '../utils/payment_amount_formatter.dart';
import '../widgets/pay_now_button.dart';
import '../widgets/payment_loader.dart';
import '../widgets/payment_mode_sheet.dart';
import '../widgets/payment_page_shell.dart';
import 'payment_checkout_page.dart';
import 'payment_simulate_checkout_page.dart';

/// Single Purchase Summary screen after approved actual cost (Figma 2851:5207).
/// Replaces the previous Payment → Payment summary two-step flow.
class PaymentRequestPage extends StatefulWidget {
  final String serviceRequestId;
  final double amount;
  final String? serviceType;
  final String? requestLabel;

  const PaymentRequestPage({
    super.key,
    required this.serviceRequestId,
    required this.amount,
    this.serviceType,
    this.requestLabel,
  });

  @override
  State<PaymentRequestPage> createState() => _PaymentRequestPageState();
}

class _PaymentRequestPageState extends State<PaymentRequestPage> {
  static const _gstRate = 0.18;
  static const _titleColor = Color(0xFF062F35);
  static const _accentColor = Color(0xFF12899B);
  static const _valueColor = Color(0xFF5A5A5A);
  static const _dividerColor = Color(0xFFD8D8D8);

  /// Content card sits above the full-bleed white dock (same as Next dock).
  static const BorderRadius _panelRadiusAboveDock = BorderRadius.only(
    topLeft: Radius.circular(20),
    topRight: Radius.circular(20),
  );

  String? _accessToken;
  bool _loadingToken = true;

  /// Approved cost is the total payable (charged as-is). GST rows are derived for UI.
  double get _totalPayable => widget.amount;
  double get _subTotal =>
      double.parse((_totalPayable / (1 + _gstRate)).toStringAsFixed(2));
  double get _tax =>
      double.parse((_totalPayable - _subTotal).toStringAsFixed(2));

  String get _serviceDisplayTitle {
    switch ((widget.serviceType ?? '').trim().toLowerCase()) {
      case 'maintenance':
      case 'maintain':
      case 'maintainmypair':
        return 'MaintainMyPair';
      case 'wash':
      case 'washmypair':
        return 'WashMyPair';
      case 'donate':
      case 'donatemypair':
        return 'DonateMyPair';
      case 'dispose':
      case 'disposemypair':
        return 'DisposeMyPair';
      case 'repair':
      case 'repairmypair':
        return 'RepairMyPair';
      default:
        final raw = widget.serviceType?.trim();
        if (raw == null || raw.isEmpty) return 'Service';
        return raw;
    }
  }

  @override
  void initState() {
    super.initState();
    PaymentAnalytics.paymentRequestViewed(widget.serviceRequestId);
    PaymentAnalytics.paymentSummaryViewed(
      widget.serviceRequestId,
      _totalPayable,
    );
    _loadToken();
  }

  Future<void> _loadToken() async {
    final result = await sl<GetValidAccessToken>().call();
    if (!mounted) return;
    await result.fold(
      (f) async {
        setState(() {
          _loadingToken = false;
          _accessToken = null;
        });
      },
      (token) async {
        // Block re-pay if this request already has a successful payment.
        try {
          final existing = await sl<GetPaymentByServiceRequest>().call(
            accessToken: token,
            serviceRequestId: widget.serviceRequestId,
          );
          if (!mounted) return;
          if (existing != null && existing.isSuccess) {
            setState(() {
              _loadingToken = false;
              _accessToken = token;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('This service request has already been paid.'),
              ),
            );
            Navigator.of(context).pop(true);
            return;
          }
        } catch (_) {
          // Ignore lookup failures — checkout can still proceed.
        }
        if (!mounted) return;
        setState(() {
          _loadingToken = false;
          _accessToken = token;
        });
      },
    );
  }

  Future<void> _proceedToCheckout() async {
    final token = _accessToken;
    if (token == null) return;

    var mode = PaymentConfig.defaultMode;
    if (PaymentConfig.allowDevModes) {
      final picked = await showPaymentModeSheet(context);
      if (!mounted || picked == null) return;
      mode = picked;
    }

    context.read<PaymentBloc>().add(
          PaymentLinkCreateRequested(
            accessToken: token,
            serviceRequestId: widget.serviceRequestId,
            amount: _totalPayable,
            paymentMode: mode,
            redirectUrl: PaymentConfig.zohoRedirectUrl,
          ),
        );
  }

  Future<void> _openCheckout(PaymentLinkReady state) async {
    final link = state.linkResult;
    final child = state.useSimulatedCheckout
        ? PaymentSimulateCheckoutPage(
            orderId: link.payment.orderId,
            paymentId: link.payment.id,
            serviceRequestId: widget.serviceRequestId,
            amount: link.payment.amount,
            autoPlay: true,
            zohoFallback: state.zohoFallback,
          )
        : PaymentCheckoutPage(
            checkoutUrl: link.checkoutUrl,
            orderId: link.payment.orderId,
            paymentId: link.payment.id,
            serviceRequestId: widget.serviceRequestId,
            amount: link.payment.amount,
            onZohoUnavailable: PaymentConfig.enableSimulateFallback
                ? () => _openSimulateFallback(link)
                : null,
          );

    // Use push (not replacement) so payment success can pop a true result
    // back through this page to Service Request details.
    final paid = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<PaymentBloc>(),
          child: child,
        ),
      ),
    );
    if (!mounted) return;
    if (paid == true) {
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _openSimulateFallback(PaymentLinkResult link) async {
    final paid = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<PaymentBloc>(),
          child: PaymentSimulateCheckoutPage(
            orderId: link.payment.orderId,
            paymentId: link.payment.id,
            serviceRequestId: widget.serviceRequestId,
            amount: link.payment.amount,
            autoPlay: true,
            zohoFallback: true,
          ),
        ),
      ),
    );
    if (!mounted) return;
    if (paid == true) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomSafe = MediaQuery.viewPaddingOf(context).bottom;
    const dockButtonH = 48.0;
    final dockH = 14 + dockButtonH + 14 + bottomSafe;

    return BlocListener<PaymentBloc, PaymentState>(
      listener: (context, state) {
        if (state is PaymentLinkReady) {
          if (state.zohoFallback) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Zoho checkout unavailable — running simulated payment flow.',
                ),
              ),
            );
          }
          _openCheckout(state);
        } else if (state is PaymentError) {
          final msg = state.message;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg)),
          );
          // Backend rejected a second charge — leave the pay screen.
          if (msg.toLowerCase().contains('already been paid') ||
              msg.toLowerCase().contains('already paid')) {
            Navigator.of(context).pop(true);
          }
        }
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          extendBody: true,
          body: Stack(
            fit: StackFit.expand,
            children: [
              ...BgTheme.background(),
              Positioned.fill(
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(10, 52, 10, dockH - 12),
                    child: DecoratedBox(
                      decoration: const ShapeDecoration(
                        color: Color(0xFFF0F0F0),
                        shape: RoundedRectangleBorder(
                          borderRadius: _panelRadiusAboveDock,
                        ),
                        shadows: [
                          BoxShadow(
                            color: Color(0x19000000),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: _panelRadiusAboveDock,
                        child: _buildPanelBody(),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _buildFullBleedPaymentDock(
                  bottomSafe: bottomSafe,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPanelBody() {
    if (_loadingToken) {
      return const PaymentLoader(message: 'Loading…');
    }
    if (_accessToken == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Please sign in again to continue.',
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 8, 0),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.maybePop(context),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(
                  width: 26,
                  height: 26,
                ),
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: _titleColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Purchase Summary',
                  style: GoogleFonts.boldonse(
                    color: _titleColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Close',
                onPressed: () => Navigator.maybePop(context),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(
                  width: 40,
                  height: 40,
                ),
                icon: const Icon(
                  Icons.close_rounded,
                  size: 26,
                  color: _titleColor,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: BlocBuilder<PaymentBloc, PaymentState>(
            builder: (context, state) {
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Payment Details',
                      style: GoogleFonts.boldonse(
                        color: _titleColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 28),
                    _serviceTypeRow(),
                    _amountRow(
                      label: 'Sub Total',
                      value: PaymentAmountFormatter.formatGrouped(_subTotal),
                    ),
                    _amountRow(
                      label: 'Delivery Charges',
                      value: 'FREE',
                    ),
                    _amountRow(
                      label: 'Taxes (18% GST)',
                      value: PaymentAmountFormatter.formatGrouped(_tax),
                    ),
                    _amountRow(
                      label: 'Total Payable Amount',
                      value:
                          PaymentAmountFormatter.formatGrouped(_totalPayable),
                      boldValue: true,
                    ),
                    if (PaymentConfig.allowDevModes) ...[
                      const SizedBox(height: 20),
                      PaymentSurfaceCard(
                        title: 'Checkout methods',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: PaymentConfig.selectableModes.map((mode) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Text(
                                '${mode.methodNumber}. ${mode.title} — ${mode.subtitle}',
                                style: GoogleFonts.montserrat(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                  height: 1.35,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                    if (state is PaymentError) ...[
                      const SizedBox(height: 16),
                      PaymentErrorBanner(
                        message: PaymentErrorHandler.messageFrom(
                          state.message,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Same full-bleed white bottom dock as Repair / Next flow.
  Widget _buildFullBleedPaymentDock({required double bottomSafe}) {
    return BlocBuilder<PaymentBloc, PaymentState>(
      builder: (context, state) {
        final loading = state is PaymentLoading;
        return Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          padding: EdgeInsets.fromLTRB(20, 14, 20, 14 + bottomSafe),
          child: Center(
            child: _makePaymentButton(
              total: _totalPayable,
              loading: loading,
              onPressed: loading || _accessToken == null
                  ? null
                  : _proceedToCheckout,
            ),
          ),
        );
      },
    );
  }

  Widget _serviceTypeRow() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 14),
      margin: const EdgeInsets.only(bottom: 25),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _dividerColor)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 68,
            height: 68,
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: const Color(0x33D9D9D9),
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: _accentColor),
            ),
            alignment: Alignment.center,
            child: SvgPicture.asset(
              'assets/images/noun-shoes-cleaning-7675732 1.svg',
              width: 36,
              height: 42,
              fit: BoxFit.contain,
              colorFilter: const ColorFilter.mode(
                _accentColor,
                BlendMode.srcIn,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Service Type',
                  style: GoogleFonts.montserrat(
                    color: _accentColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _serviceDisplayTitle,
                  style: GoogleFonts.montserrat(
                    color: _valueColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _makePaymentButton({
    required double total,
    required bool loading,
    required VoidCallback? onPressed,
  }) {
    final formatted = PaymentAmountFormatter.formatGrouped(total);
    final rupeeIndex = formatted.indexOf('₹');
    final amountText = rupeeIndex >= 0
        ? formatted.substring(rupeeIndex + 1)
        : formatted;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(100),
        child: Ink(
          width: 336,
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          decoration: ShapeDecoration(
            gradient: onPressed == null && !loading
                ? null
                : const LinearGradient(
                    begin: Alignment(1.00, 0.50),
                    end: Alignment(0.00, 0.50),
                    colors: [Color(0xFF0CADC5), Color(0xFF063239)],
                  ),
            color: onPressed == null && !loading ? AppColors.disabled : null,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(100),
            ),
            shadows: onPressed == null && !loading
                ? const []
                : const [
                    BoxShadow(
                      color: Color(0x19000000),
                      blurRadius: 4,
                      offset: Offset(0, 4),
                    ),
                  ],
          ),
          child: Center(
            child: loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'Make Payment ',
                          style: GoogleFonts.boldonse(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        TextSpan(
                          text: '₹',
                          style: GoogleFonts.boldonse(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        TextSpan(
                          text: amountText,
                          style: GoogleFonts.boldonse(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
          ),
        ),
      ),
    );
  }

  Widget _amountRow({
    required String label,
    required String value,
    bool boldValue = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 14),
      margin: const EdgeInsets.only(bottom: 25),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _dividerColor)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.montserrat(
                color: _accentColor,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.montserrat(
              color: _valueColor,
              fontSize: 18,
              fontWeight: boldValue ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
