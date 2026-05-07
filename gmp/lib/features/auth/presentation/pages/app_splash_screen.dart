import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/utils/jwt_helper.dart';
import '../../../../injection_container.dart';
import '../../../dashboard/presentation/pages/customer_dashboard_page.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_state.dart';
import 'onboarding/onboarding_flow_page.dart';

/// Persistent-login splash screen.
///
/// We deliberately treat **local storage** (SharedPreferences) as the source
/// of truth for "has this user logged in before?". If a refresh token is
/// present and not JWT-expired we route the user directly to the dashboard,
/// **without waiting for the network round-trip**. The [AuthBloc] keeps doing
/// its background `/me` check; if the backend later rejects the refresh
/// token, [AuthUnauthenticated] is emitted and the dashboard's existing
/// listener bounces the user to the login screen.
///
/// This makes Chrome refresh / cold start behave correctly even when:
/// - the backend is sleeping (Render.com cold start),
/// - the network is offline,
/// - or the access token has expired (refresh happens lazily, in background).
///
/// Login state is therefore governed by ONLY:
///   1. Refresh token expiry / rejection by the backend.
///   2. Manual logout (clears local storage explicitly).
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
      final refreshToken = prefs.getString(AppConstants.refreshTokenKey);
      final accessToken = prefs.getString(AppConstants.accessTokenKey);
      final hasUser = (prefs.getString(AppConstants.userKey) ?? '').isNotEmpty;
      final hasUsableRefresh =
          refreshToken != null &&
          refreshToken.isNotEmpty &&
          !_isJwtDefinitelyExpired(refreshToken);
      final hasUsableAccess =
          accessToken != null && accessToken.isNotEmpty;
      // Either token + cached user is enough to consider the session live.
      // We only require *some* token because the bloc's background refresh
      // will rotate access tokens as needed.
      hasSession = hasUser && (hasUsableRefresh || hasUsableAccess);
    } catch (_) {
      hasSession = false;
    }
    if (!mounted) return;
    setState(() => _hasLocalSession = hasSession);
    _maybeNavigate(context.read<AuthBloc>().state);
  }

  /// Returns true only when the token is a JWT *and* its `exp` claim is in
  /// the past. Opaque (non-JWT) tokens are treated as still usable – let the
  /// backend make the final call via 401.
  bool _isJwtDefinitelyExpired(String token) {
    if (!JwtHelper.isTokenExpired(token)) return false;
    return JwtHelper.getTokenExpiration(token) != null;
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
