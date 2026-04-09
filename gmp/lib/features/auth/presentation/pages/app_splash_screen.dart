import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'onboarding/onboarding_flow_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;
  static const _figmaWidth = 390.0;
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
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(0.82, 0.05),
              end: Alignment(-0.17, 1.22),
              colors: [
                Color(0xFF062F35),
                Color(0xFF0F6876),
                Color(0xFF09E0FF),
              ],
            ),
          ),
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final sx = constraints.maxWidth / _figmaWidth;
                final sy = constraints.maxHeight / _figmaHeight;

                final left = 98.0 * sx;
                final top = 311.0 * sy;
                final textWidth = 234.0 * sx;
                final gap = 9.0 * sy;
                return Stack(
                  children: [
                    Positioned(
                      left: left,
                      top: top,
                      width: textWidth,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Welcome to',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                          SizedBox(height: gap),
                          Text(
                            'GetMyPair',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontFamily: 'Boldonse',
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

