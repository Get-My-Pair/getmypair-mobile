import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../injection_container.dart';
import '../../../dashboard/presentation/pages/customer_dashboard_page.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_state.dart';
import 'onboarding/onboarding_flow_page.dart';

/// Persistent-login splash screen.
///
/// Local storage is the source of truth for "has this user logged in?".
/// If a cached user and any token are present we route straight to the
/// dashboard. Token expiry / refresh rejection never auto-logout — only
/// manual Logout clears the session.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const _figmaHeight = 844.0;
  static const Duration _minSplashDuration = Duration(milliseconds: 1500);

  bool _navigated = false;
  bool _minDurationElapsed = false;
  bool? _hasLocalSession;
  Timer? _minTimer;

  @override
  void initState() {
    super.initState();
    _resolveLocalSession();
    _minTimer = Timer(_minSplashDuration, () {
      if (!mounted) return;
      setState(() => _minDurationElapsed = true);
      _maybeNavigate(context.read<AuthBloc>().state);
    });
  }

  @override
  void dispose() {
    _minTimer?.cancel();
    super.dispose();
  }

  Future<void> _resolveLocalSession() async {
    bool hasSession = false;
    try {
      final prefs = sl.isRegistered<SharedPreferences>()
          ? sl<SharedPreferences>()
          : await SharedPreferences.getInstance();
      final secure = SecureStorageService();

      // Tokens/user may live in secure storage (current) or SharedPreferences (legacy).
      final refreshToken = await secure.getRefreshToken() ??
          prefs.getString(AppConstants.refreshTokenKey);
      final accessToken = await secure.getAccessToken() ??
          prefs.getString(AppConstants.accessTokenKey);
      final userJson = await secure.read(SecureStorageService.userKey) ??
          prefs.getString(AppConstants.userKey);

      final hasUser = (userJson ?? '').isNotEmpty;
      final hasRefresh = refreshToken != null && refreshToken.isNotEmpty;
      final hasAccess = accessToken != null && accessToken.isNotEmpty;
      // Cached user + any token = stay logged in (ignore JWT expiry).
      hasSession = hasUser && (hasRefresh || hasAccess);
    } catch (_) {
      hasSession = false;
    }
    if (!mounted) return;
    setState(() => _hasLocalSession = hasSession);
    _maybeNavigate(context.read<AuthBloc>().state);
  }

  void _maybeNavigate(AuthState state) {
    if (_navigated) return;
    if (!_minDurationElapsed) return;
    if (_hasLocalSession == null) return;

    // Fast path: trust local storage. If the user logged in before and we
    // have not seen a definitive AuthUnauthenticated yet, go straight to the
    // dashboard. The bloc's background check will redirect to login later
    // only if the backend explicitly rejects the refresh token.
    final goDashboard = state is AuthAuthenticated ||
        (_hasLocalSession == true && state is! AuthUnauthenticated);

    _navigated = true;
    final Widget next = goDashboard
        ? const CustomerDashboardPage()
        : const OnboardingFlowPage();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (context, animation, secondaryAnimation) => next,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) => _maybeNavigate(state),
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: Colors.transparent,
        ),
        child: Scaffold(
          body: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: AppGradients.splashBackground,
            ),
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final sy = constraints.maxHeight / _figmaHeight;
                  final logoW = 116.0 * sy;
                  final logoH = 100.992 * sy;
                  final gap = 9.0 * sy;
                  final titleSize = 36.0 * sy;

                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Image.asset(
                          AppAssets.appLogoWhite1,
                          width: logoW,
                          height: logoH,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                        ),
                        SizedBox(height: gap),
                        Text(
                          'GetMyPair',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.boldonse(
                            color: Colors.white,
                            fontSize: titleSize,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
