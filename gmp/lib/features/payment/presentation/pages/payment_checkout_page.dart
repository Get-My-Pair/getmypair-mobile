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
import '../services/payment_analytics.dart';
import '../services/payment_external_launcher.dart';
import '../widgets/payment_loader.dart';
import '../widgets/payment_page_shell.dart';
import 'payment_failed_page.dart';
import 'payment_success_page.dart';

/// Zoho Checkout — in-app WebView on mobile, external browser on web.
/// After GPay / UPI returns to the app, status is checked and success opens
/// with the celebration animation.
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

class _PaymentCheckoutPageState extends State<PaymentCheckoutPage>
    with WidgetsBindingObserver {
  WebViewController? _webController;
  bool _pageLoaded = false;
  bool _zohoFallbackTriggered = false;
  bool _handledSuccess = false;
  bool _launchedExternalWallet = false;
  Timer? _loadTimeout;
  Timer? _statusPollTimer;
  String? _accessToken;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    PaymentAnalytics.checkoutOpened(widget.orderId);
    unawaited(_prepareTokenAndPoll());
    if (kIsWeb) {
      _openExternal();
    } else {
      _initWebView();
      _startLoadTimeout();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // GPay / PhonePe / UPI: user leaves app → pays → returns here.
    if (state == AppLifecycleState.resumed &&
        !_handledSuccess &&
        (_launchedExternalWallet || kIsWeb)) {
      unawaited(_onReturnedFromWallet());
    }
  }

  Future<void> _onReturnedFromWallet() async {
    if (_handledSuccess || !mounted) return;

    // Zoho may already paint success in the WebView after wallet return.
    final looksSuccessful = await _pageShowsZohoSuccess();
    if (looksSuccessful) {
      await _goToAppSuccess();
      return;
    }

    // Faster checks right after resume from GPay.
    for (var i = 0; i < 5; i++) {
      if (!mounted || _handledSuccess) return;
      await _pollPaymentStatus(forceVerify: true);
      if (_handledSuccess) return;
      await Future<void>.delayed(const Duration(milliseconds: 700));
    }
  }

  Future<void> _prepareTokenAndPoll() async {
    final tokenResult = await sl<GetValidAccessToken>().call();
    if (!mounted) return;
    tokenResult.fold((_) {}, (token) {
      _accessToken = token;
      _startStatusPoll();
    });
  }

  void _startStatusPoll({Duration every = const Duration(seconds: 3)}) {
    _statusPollTimer?.cancel();
    _statusPollTimer = Timer.periodic(every, (_) {
      unawaited(_pollPaymentStatus());
    });
  }

  Future<void> _pollPaymentStatus({bool forceVerify = false}) async {
    if (_handledSuccess || !mounted) return;
    final token = _accessToken;
    if (token == null) return;
    try {
      var result = forceVerify
          ? await sl<VerifyPayment>()(
              accessToken: token,
              orderId: widget.orderId,
            )
          : await sl<RefreshPaymentStatus>()(
              accessToken: token,
              orderId: widget.orderId,
              refreshFromZoho: true,
            );

      // If verify failed / pending, one Zoho refresh helps webhook lag.
      if (!result.verified &&
          !result.payment.isSuccess &&
          !result.payment.isFailed) {
        result = await sl<RefreshPaymentStatus>()(
          accessToken: token,
          orderId: widget.orderId,
          refreshFromZoho: true,
        );
      }

      if (!mounted || _handledSuccess) return;
      if (result.verified || result.payment.isSuccess) {
        await _goToAppSuccess();
      } else if (result.payment.isFailed) {
        _goToFailed(result.payment.failureReason);
      }
    } catch (_) {
      // Keep polling; transient network / Zoho lag is expected.
    }
  }

  void _startLoadTimeout() {
    _loadTimeout = Timer(const Duration(seconds: 12), () {
      if (!mounted || _pageLoaded || _zohoFallbackTriggered || _handledSuccess) {
        return;
      }
      _triggerZohoFallback();
    });
  }

  void _triggerZohoFallback() {
    if (_zohoFallbackTriggered || _handledSuccess) return;
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
          onPageFinished: (url) {
            _loadTimeout?.cancel();
            if (mounted) setState(() => _pageLoaded = true);
            unawaited(_onWebPageFinished(url));
          },
          onUrlChange: (change) {
            final url = change.url;
            if (url == null) return;
            if (_isReturnUrl(url) || _isZohoSuccessUrl(url)) {
              unawaited(_goToAppSuccess());
            }
          },
          onWebResourceError: (error) {
            if (_pageLoaded || _handledSuccess) return;
            if (error.isForMainFrame == true) _triggerZohoFallback();
          },
          onHttpError: (error) {
            if (_pageLoaded || _handledSuccess) return;
            final code = error.response?.statusCode ?? 0;
            if (code >= 500) _triggerZohoFallback();
          },
          onNavigationRequest: (request) {
            final url = request.url;
            if (_isReturnUrl(url) || _isZohoSuccessUrl(url)) {
              unawaited(_goToAppSuccess());
              return NavigationDecision.prevent;
            }
            if (PaymentExternalLauncher.shouldLaunchExternally(url)) {
              _launchedExternalWallet = true;
              // Poll faster while user is in GPay.
              _startStatusPoll(every: const Duration(seconds: 2));
              PaymentExternalLauncher.launch(url);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.checkoutUrl));
  }

  Future<void> _onWebPageFinished(String url) async {
    if (_handledSuccess || !mounted) return;

    if (_isReturnUrl(url) || _isZohoSuccessUrl(url)) {
      await _goToAppSuccess();
      return;
    }

    final looksSuccessful = await _pageShowsZohoSuccess();
    if (looksSuccessful) {
      await _goToAppSuccess();
    }
  }

  Future<bool> _pageShowsZohoSuccess() async {
    final controller = _webController;
    if (controller == null) return false;
    try {
      final raw = await controller.runJavaScriptReturningResult(r'''
        (function () {
          var text = ((document.body && document.body.innerText) || '').toLowerCase();
          if (text.indexOf('payment successful') !== -1) return true;
          if (text.indexOf('payment success') !== -1) return true;
          if (text.indexOf('paid successfully') !== -1) return true;
          if (text.indexOf('transaction successful') !== -1) return true;
          return false;
        })();
      ''');
      return _jsTruthy(raw);
    } catch (_) {
      return false;
    }
  }

  bool _jsTruthy(Object? raw) {
    if (raw == true || raw == 1) return true;
    final s = raw?.toString().toLowerCase().trim() ?? '';
    return s == 'true' || s == '1' || s == '"true"';
  }

  bool _isReturnUrl(String url) {
    final lower = url.toLowerCase();
    return lower.startsWith('gmp://payment/') ||
        lower.contains('payment/callback') ||
        lower.contains('payment-success') ||
        lower.contains('payment_link_reference=') ||
        lower.contains('payment_link_id=');
  }

  bool _isZohoSuccessUrl(String url) {
    final lower = url.toLowerCase();
    if (lower.contains('status=success') ||
        lower.contains('payment_status=success') ||
        lower.contains('/payment/success') ||
        lower.contains('paymentsuccess') ||
        lower.contains('payment_success')) {
      return true;
    }
    if ((lower.contains('zoho') || lower.contains('zohopayments')) &&
        (lower.contains('success') || lower.contains('thank'))) {
      return true;
    }
    return false;
  }

  Future<void> _openExternal() async {
    _launchedExternalWallet = true;
    final uri = Uri.parse(widget.checkoutUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    if (mounted) setState(() => _pageLoaded = true);
  }

  Future<void> _goToAppSuccess() async {
    if (_handledSuccess || !mounted) return;
    _handledSuccess = true;
    _loadTimeout?.cancel();
    _statusPollTimer?.cancel();
    PaymentAnalytics.checkoutCompleted(widget.orderId);
    PaymentAnalytics.paymentSuccess(widget.orderId, widget.amount);

    unawaited(_syncBackendStatus());

    if (!mounted) return;
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
  }

  void _goToFailed(String? failureReason) {
    if (_handledSuccess || !mounted) return;
    _handledSuccess = true;
    _statusPollTimer?.cancel();
    PaymentAnalytics.paymentFailed(widget.orderId, failureReason);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => sl<PaymentBloc>(),
          child: PaymentFailedPage(
            orderId: widget.orderId,
            serviceRequestId: widget.serviceRequestId,
            amount: widget.amount,
            failureReason: failureReason,
          ),
        ),
      ),
    );
  }

  Future<void> _syncBackendStatus() async {
    try {
      final token = _accessToken;
      if (token == null) return;
      try {
        await sl<VerifyPayment>()(
          accessToken: token,
          orderId: widget.orderId,
        );
      } catch (_) {
        await sl<RefreshPaymentStatus>()(
          accessToken: token,
          orderId: widget.orderId,
          refreshFromZoho: true,
        );
      }
    } catch (_) {
      // Success UI already shown; backend can catch up via webhook/poll.
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _loadTimeout?.cancel();
    _statusPollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PaymentPageShell(
      title: 'Secure checkout',
      subtitle: 'Complete payment in the window below.',
      body: kIsWeb
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Checkout opened in your browser. '
                      'This screen will update automatically after payment.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: _openExternal,
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
    );
  }
}
