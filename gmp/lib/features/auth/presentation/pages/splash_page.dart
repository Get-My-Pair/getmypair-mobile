import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import 'welcome_page.dart';
import 'package:gmp/features/dashboard/presentation/pages/customer_dashboard_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late Animation<double> _logoFade;
  late Animation<double> _logoScale;
  late Animation<double> _textFade;

  @override
  void initState() {
    super.initState();

    // Logo animation controller (0-1.5 seconds)
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Text animation controller (starts after logo, 1.5-2.5 seconds)
    _textController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Logo fade animation
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeIn),
    );

    // Logo scale animation
    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeInOutBack),
    );

    // Text fade animation
    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeIn),
    );

    // Start animation sequence
    _startAnimationSequence();
  }

  void _startAnimationSequence() async {
    // Play logo animation
    await _logoController.forward();

    // Play text animation
    await _textController.forward();

    // Wait 1 second, then check auth and navigate
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      // Trigger auth check
      context.read<AuthBloc>().add(const AuthCheckStatus());
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          // User is authenticated, go to dashboard
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const CustomerDashboardPage(),
            ),
          );
        } else if (state is AuthUnauthenticated) {
          // User is not authenticated, go to welcome screen
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const WelcomePage(),
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFDFDFD),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // GMP Logo with fade and scale animation
              FadeTransition(
                opacity: _logoFade,
                child: ScaleTransition(
                  scale: _logoScale,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        'GMP',
                        style: Theme.of(context).textTheme.displayLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 60,
                            ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 50),
              // GetMyPair Text with fade animation
              FadeTransition(
                opacity: _textFade,
                child: Column(
                  children: [
                    Text(
                      'GetMyPair',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: const Color(0xFF333333),
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Find Your Perfect Match',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF999999),
                            fontWeight: FontWeight.w400,
                            letterSpacing: 0.3,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

