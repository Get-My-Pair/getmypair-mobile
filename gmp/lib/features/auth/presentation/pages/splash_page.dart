import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:math' as math;
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/responsive.dart';
import '../../../dashboard/presentation/pages/customer_dashboard_page.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_state.dart';
import 'welcome_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _shimmerController;
  late AnimationController _floatController;
  late Animation<double> _logoScale;
  late Animation<double> _logoFade;
  late Animation<double> _textSlide;
  late Animation<double> _textFade;
  late Animation<double> _taglineSlide;
  late Animation<double> _taglineFade;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();

    // Logo animation controller
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Text animation controller
    _textController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Shimmer effect controller
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Floating animation controller
    _floatController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Logo animations - bounce scale effect
    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.7, curve: Curves.elasticOut),
      ),
    );

    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    // Floating animation for logo
    _floatAnimation = Tween<double>(begin: -8.0, end: 8.0).animate(
      CurvedAnimation(
        parent: _floatController,
        curve: Curves.easeInOut,
      ),
    );

    // App name slide up animation
    _textSlide = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
      ),
    );

    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    // Tagline slide up animation
    _taglineSlide = Tween<double>(begin: 20.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.3, 0.9, curve: Curves.easeOutCubic),
      ),
    );

    _taglineFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.3, 0.8, curve: Curves.easeOut),
      ),
    );

    _startAnimationSequence();
  }

  void _startAnimationSequence() async {
    // Start logo animation
    _logoController.forward();

    // Start floating animation (repeating)
    _floatController.repeat(reverse: true);

    // Start text animation after a delay
    await Future.delayed(const Duration(milliseconds: 600));
    _textController.forward();

    // Start shimmer effect
    _shimmerController.repeat();

    // Wait minimum 2 seconds for splash, then navigate based on auth status
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;
    final authState = context.read<AuthBloc>().state;

    if (authState is AuthAuthenticated) {
      Navigator.of(context).pushAndRemoveUntil(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const CustomerDashboardPage(),
          transitionsBuilder:
              (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
        (route) => false,
      );
    } else {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const WelcomePage(),
          transitionsBuilder:
              (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _shimmerController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final shortest = size.width < size.height ? size.width : size.height;
    final logoSize = (shortest * 0.4).clamp(120.0, 220.0);
    final titleFontSize = (Responsive.fontSize(context, 40)).clamp(24.0, 40.0);
    final taglineFontSize = Responsive.fontSize(context, 17);
    final bottomPadding = 48.0 + MediaQuery.paddingOf(context).bottom;
    return Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFFFFFFF),
                Color(0xFFF8F5FF),
                Color(0xFFEDE7F6),
              ],
            ),
          ),
          child: Stack(
            children: [
              // Decorative circles in background
              Positioned(
                top: -100,
                right: -100,
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF6750A4).withOpacity(0.05),
                  ),
                ),
              ),
              Positioned(
                bottom: -80,
                left: -80,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF6750A4).withOpacity(0.08),
                  ),
                ),
              ),

              // Floating shoe icons in background
              ..._buildFloatingShoes(),

              // Main content
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animated Logo with floating effect
                    AnimatedBuilder(
                      animation: Listenable.merge([_logoController, _floatController]),
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, _floatAnimation.value),
                          child: Transform.scale(
                            scale: _logoScale.value,
                            child: Opacity(
                              opacity: _logoFade.value,
                              child: Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(40),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF6750A4)
                                          .withOpacity(0.2),
                                      blurRadius: 50,
                                      spreadRadius: 5,
                                      offset: const Offset(0, 15),
                                    ),
                                  ],
                                ),
                                child: Image.asset(
                                  'assets/images/logo.png',
                                  width: logoSize,
                                  height: logoSize,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 48),

                    // App Name with slide animation
                    AnimatedBuilder(
                      animation: _textController,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, _textSlide.value),
                          child: Opacity(
                            opacity: _textFade.value,
                            child: ShaderMask(
                              shaderCallback: (bounds) {
                                return const LinearGradient(
                                  colors: [
                                    Color(0xFF21005D),
                                    Color(0xFF6750A4),
                                  ],
                                ).createShader(bounds);
                              },
                              child: Text(
                                'Get My Pair',
                                style: TextStyle(
                                  fontSize: titleFontSize,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 16),

                    // Tagline with delayed slide animation
                    AnimatedBuilder(
                      animation: _textController,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, _taglineSlide.value),
                          child: Opacity(
                            opacity: _taglineFade.value,
                            child: Text(
                              'Find shoes. Fix shoes. All in one place.',
                              style: TextStyle(
                                fontSize: taglineFontSize,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF79747E),
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // Bottom loading indicator + app version
              Positioned(
                bottom: bottomPadding,
                left: 0,
                right: 0,
                child: AnimatedBuilder(
                  animation: _textController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _textFade.value,
                      child: Column(
                        children: [
                          _buildLoadingDots(),
                          const SizedBox(height: 12),
                          Text(
                            '${AppConstants.appName} v${AppConstants.appVersion}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF79747E),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
    );
  }

  List<Widget> _buildFloatingShoes() {
    return [
      // Floating shoe icon 1
      AnimatedBuilder(
        animation: _floatController,
        builder: (context, child) {
          return Positioned(
            top: 120,
            left: 30,
            child: Transform.translate(
              offset: Offset(0, _floatAnimation.value * 0.8),
              child: Transform.rotate(
                angle: math.sin(_floatController.value * math.pi * 2) * 0.1,
                child: Opacity(
                  opacity: 0.15,
                  child: Icon(
                    Icons.settings_accessibility_rounded,
                    size: 40,
                    color: const Color(0xFF6750A4),
                  ),
                ),
              ),
            ),
          );
        },
      ),
      // Floating shoe icon 2
      AnimatedBuilder(
        animation: _floatController,
        builder: (context, child) {
          return Positioned(
            top: 180,
            right: 40,
            child: Transform.translate(
              offset: Offset(0, -_floatAnimation.value * 0.6),
              child: Transform.rotate(
                angle: -math.sin(_floatController.value * math.pi * 2) * 0.15,
                child: Opacity(
                  opacity: 0.12,
                  child: Icon(
                    Icons.shopping_bag_outlined,
                    size: 35,
                    color: const Color(0xFF6750A4),
                  ),
                ),
              ),
            ),
          );
        },
      ),
      // Floating shoe icon 3
      AnimatedBuilder(
        animation: _floatController,
        builder: (context, child) {
          return Positioned(
            bottom: 200,
            right: 50,
            child: Transform.translate(
              offset: Offset(_floatAnimation.value * 0.5, 0),
              child: Transform.rotate(
                angle: math.cos(_floatController.value * math.pi * 2) * 0.1,
                child: Opacity(
                  opacity: 0.1,
                  child: Icon(
                    Icons.star_outline_rounded,
                    size: 30,
                    color: const Color(0xFF6750A4),
                  ),
                ),
              ),
            ),
          );
        },
      ),
      // Floating shoe icon 4
      AnimatedBuilder(
        animation: _floatController,
        builder: (context, child) {
          return Positioned(
            bottom: 180,
            left: 40,
            child: Transform.translate(
              offset: Offset(-_floatAnimation.value * 0.4, _floatAnimation.value * 0.3),
              child: Opacity(
                opacity: 0.12,
                child: Icon(
                  Icons.favorite_outline_rounded,
                  size: 28,
                  color: const Color(0xFF6750A4),
                ),
              ),
            ),
          );
        },
      ),
    ];
  }

  Widget _buildLoadingDots() {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            final delay = index * 0.2;
            final progress = (_shimmerController.value + delay) % 1.0;
            final scale = 0.5 + (0.5 * _calculatePulse(progress));
            final opacity = 0.3 + (0.7 * _calculatePulse(progress));

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF6750A4).withOpacity(opacity),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  double _calculatePulse(double progress) {
    // Creates a smooth pulse effect
    if (progress < 0.5) {
      return progress * 2;
    } else {
      return 2 - (progress * 2);
    }
  }
}

