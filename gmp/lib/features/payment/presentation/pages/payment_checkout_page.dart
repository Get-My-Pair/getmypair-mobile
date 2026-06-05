import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/chevron_screen_back_button.dart';
import '../../../../features/auth/domain/usecases/get_valid_access_token.dart';
import '../../../../injection_container.dart';
import '../bloc/payment_bloc.dart';
import '../bloc/payment_event.dart';
import '../bloc/payment_state.dart';
import '../../domain/usecases/payment_usecases.dart';
import '../services/payment_analytics.dart';
import '../services/payment_status_poller.dart';
import '../widgets/payment_loader.dart';
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

  const PaymentCheckoutPage({
    super.key,
    required this.checkoutUrl,
    required this.orderId,
    required this.paymentId,
    required this.serviceRequestId,
    required this.amount,
  });

  @override
  State<PaymentCheckoutPage> createState() => _PaymentCheckoutPageState();
}

class _PaymentCheckoutPageState extends State<PaymentCheckoutPage> {
  WebViewController? _webController;
  bool _verifying = false;
  bool _pageLoaded = false;
  late final PaymentStatusPoller _poller;

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
    }
  }

  void _initWebView() {
    _webController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) setState(() => _pageLoaded = true);
          },
          onNavigationRequest: (request) {
            if (_isReturnUrl(request.url)) {
              _onCheckoutReturn();
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.checkoutUrl));
  }

  bool _isReturnUrl(String url) {
    return url.contains('mock-checkout') ||
        url.contains('payment-success') ||
        url.contains('payment/callback') ||
        url.contains('orderId=${Uri.encodeComponent(widget.orderId)}');
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
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          leading: const ChevronScreenBackButton(
            iconColor: AppColors.textPrimary,
          ),
          title: const Text(
            'Secure checkout',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          actions: [
            if (_verifying)
              const Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
          ],
        ),
        body: Column(
          children: [
            if (kIsWeb)
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Checkout opened in your browser. '
                          'Return here after completing payment.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _verifying ? null : _onCheckoutReturn,
                          child: const Text('I completed payment'),
                        ),
                        TextButton(
                          onPressed: _verifying ? null : () => _openExternal(),
                          child: const Text('Re-open checkout'),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              Expanded(
                child: _webController == null || !_pageLoaded
                    ? const PaymentLoader(
                        message: 'Loading Zoho secure checkout…',
                      )
                    : WebViewWidget(controller: _webController!),
              ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: _verifying ? null : _onCheckoutReturn,
                    child: const Text('I completed payment — verify'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
