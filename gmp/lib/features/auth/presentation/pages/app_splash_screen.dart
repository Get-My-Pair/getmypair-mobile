import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_gradients.dart';
import 'onboarding/onboarding_flow_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;
  static const _figmaHeight = 844.0;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 3), _goNext);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _goNext() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const OnboardingFlowPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
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
    );
  }
}

