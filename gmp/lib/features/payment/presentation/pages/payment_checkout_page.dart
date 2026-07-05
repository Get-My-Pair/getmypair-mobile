import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../features/auth/domain/usecases/get_valid_access_token.dart';
import '../../../../injection_container.dart';
import '../../domain/usecases/payment_usecases.dart';
import '../bloc/payment_bloc.dart';
import '../bloc/payment_event.dart';
import '../bloc/payment_state.dart';
import '../services/payment_analytics.dart';
import '../services/payment_external_launcher.dart';
import '../services/payment_status_poller.dart';
import '../widgets/payment_loader.dart';
import '../widgets/payment_page_shell.dart';
import 'payment_failed_page.dart';
import 'payment_pending_page.dart';
import 'payment_success_page.dart';

/// Zoho Checkout — in-app WebView on mobile, external browser on web.
class PaymentCheckoutPage extends StatefulWidget {
  final String checkoutUrl;
  final String orderId;
  final String paymentId;
  final String serviceRequestId;
  final double amount;
  final VoidCallback? onZohoUnavailable;

  const PaymentCheckoutPage({
    super.key,
    required this.checkoutUrl,
    required this.orderId,
    required this.paymentId,
    required this.serviceRequestId,
    required this.amount,
    this.onZohoUnavailable,
  });

  @override
  State<PaymentCheckoutPage> createState() => _PaymentCheckoutPageState();
}

class _PaymentCheckoutPageState extends State<PaymentCheckoutPage> {
  WebViewController? _webController;
  bool _verifying = false;
  bool _pageLoaded = false;
  bool _zohoFallbackTriggered = false;
  late final PaymentStatusPoller _poller;
  Timer? _loadTimeout;

  @override
  void initState() {
    super.initState();
    PaymentAnalytics.checkoutOpened(widget.orderId);
    _poller = PaymentStatusPoller(
      verifyPayment: sl<VerifyPayment>(),
      refreshPaymentStatus: sl<RefreshPaymentStatus>(),
    );
    if (kIsWeb) {
      _openExternal();
    } else {
      _initWebView();
      _startLoadTimeout();
    }
  }

  void _startLoadTimeout() {
    _loadTimeout = Timer(const Duration(seconds: 12), () {
      if (!mounted || _pageLoaded || _zohoFallbackTriggered) return;
      _triggerZohoFallback();
    });
  }

  void _triggerZohoFallback() {
    if (_zohoFallbackTriggered) return;
    _zohoFallbackTriggered = true;
    _loadTimeout?.cancel();
    PaymentAnalytics.zohoConnectionFallback(widget.orderId);
    final fallback = widget.onZohoUnavailable;
    if (fallback != null) {
      fallback();
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Secure checkout could not load. Check your connection and try again.',
        ),
      ),
    );
  }

  void _initWebView() {
    _webController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            _loadTimeout?.cancel();
            if (mounted) setState(() => _pageLoaded = true);
          },
          onWebResourceError: (_) => _triggerZohoFallback(),
          onHttpError: (_) => _triggerZohoFallback(),
          onNavigationRequest: (request) {
            final url = request.url;
            if (_isReturnUrl(url)) {
              _onCheckoutReturn();
              return NavigationDecision.prevent;
            }
            if (PaymentExternalLauncher.shouldLaunchExternally(url)) {
              PaymentExternalLauncher.launch(url);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.checkoutUrl));
  }

  bool _isReturnUrl(String url) {
    final lower = url.toLowerCase();
    return lower.startsWith('gmp://payment/') ||
        lower.contains('payment/callback') ||
        lower.contains('payment-success') ||
        lower.contains('payment_link_reference=') ||
        lower.contains('payment_link_id=');
  }

  Future<void> _openExternal() async {
    final uri = Uri.parse(widget.checkoutUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    if (mounted) setState(() => _pageLoaded = true);
  }

  Future<void> _onCheckoutReturn() async {
    PaymentAnalytics.checkoutCompleted(widget.orderId);
    await _verifyAndNavigate(refreshFromZoho: true);
  }

  Future<void> _verifyAndNavigate({bool refreshFromZoho = true}) async {
    if (_verifying) return;
    setState(() => _verifying = true);

    final tokenResult = await sl<GetValidAccessToken>().call();
    if (!mounted) return;

    await tokenResult.fold(
      (_) async {
        setState(() => _verifying = false);
      },
      (token) async {
        context.read<PaymentBloc>().add(
              refreshFromZoho
                  ? PaymentStatusRefreshRequested(
                      accessToken: token,
                      orderId: widget.orderId,
                      refreshFromZoho: true,
                    )
                  : PaymentVerifyRequested(
                      accessToken: token,
                      orderId: widget.orderId,
                    ),
            );
      },
    );
  }

  void _navigateByStatus(String status, String? failureReason) {
    _poller.stop();
    if (status == 'PAYMENT_SUCCESS') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentSuccessPage(
            orderId: widget.orderId,
            amount: widget.amount,
            serviceRequestId: widget.serviceRequestId,
            paidAt: DateTime.now(),
          ),
        ),
      );
    } else if (status == 'PAYMENT_FAILED') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentFailedPage(
            orderId: widget.orderId,
            serviceRequestId: widget.serviceRequestId,
            amount: widget.amount,
            failureReason: failureReason,
          ),
        ),
      );
    } else {
      _navigatePending();
    }
  }

  void _navigatePending() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentPendingPage(
          orderId: widget.orderId,
          serviceRequestId: widget.serviceRequestId,
          amount: widget.amount,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _loadTimeout?.cancel();
    _poller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PaymentBloc, PaymentState>(
      listener: (context, state) async {
        if (state is PaymentVerified) {
          setState(() => _verifying = false);
          _navigateByStatus(
            state.result.payment.status,
            state.result.payment.failureReason,
          );
        } else if (state is PaymentError) {
          setState(() => _verifying = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      child: PaymentPageShell(
        title: 'Secure checkout',
        subtitle: 'Complete payment in the window below.',
        actions: [
          if (_verifying)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: PaymentPageTheme.loaderColor,
                ),
              ),
            ),
        ],
        bottomBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: PaymentSecondaryButton(
              label: 'I completed payment — verify',
              onPressed: _verifying ? null : _onCheckoutReturn,
            ),
          ),
        ),
        body: kIsWeb
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Checkout opened in your browser. '
                        'Return here after completing payment.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.montserrat(
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 20),
                      PaymentSecondaryButton(
                        label: 'I completed payment',
                        onPressed: _verifying ? null : _onCheckoutReturn,
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _verifying ? null : _openExternal,
                        child: const Text('Re-open checkout'),
                      ),
                    ],
                  ),
                ),
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: _webController == null || !_pageLoaded
                    ? const PaymentLoader(
                        message: 'Loading Zoho secure checkout…',
                      )
                    : WebViewWidget(controller: _webController!),
              ),
      ),
    );
  }
}
