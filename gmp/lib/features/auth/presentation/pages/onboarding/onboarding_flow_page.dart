import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/responsive.dart';
import '../../widgets/onboarding_surface.dart';
import '../welcome_page.dart';
import 'splash_intro_screen_1.dart';
import 'splash_intro_screen_2.dart';
import 'splash_intro_screen_3.dart';
import 'splash_intro_screen_4.dart';

/// Four-step splash / onboarding using the shared teal → cyan theme.
class OnboardingFlowPage extends StatefulWidget {
  const OnboardingFlowPage({super.key});

  @override
  State<OnboardingFlowPage> createState() => _OnboardingFlowPageState();
}

class _OnboardingFlowPageState extends State<OnboardingFlowPage> {
  final PageController _pageController = PageController();
  int _index = 0;

  static const int _total = 4;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goWelcome() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const WelcomePage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  void _next() {
    if (_index < _total - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic,
      );
    } else {
      _goWelcome();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
      ),
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.none,
          children: [
            const OnboardingGradientBackdrop(),
            const Positioned.fill(child: OnboardingDotLayer()),
            Padding(
              padding: EdgeInsets.only(bottom: 128 + bottomInset),
              child: SafeArea(
                bottom: false,
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (i) => setState(() => _index = i),
                  children: const [
                    SplashIntroScreen1(),
                    SplashIntroScreen2(),
                    SplashIntroScreen3(),
                    SplashIntroScreen4(),
                  ],
                ),
              ),
            ),
            // Watermark only on intro slides 2–4; welcome (page 0) stays clean behind centered title.
            if (_index != 0)
              Positioned.fill(child: const OnboardingBrandWatermark()),
            SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: EdgeInsets.only(right: Responsive.horizontalPaddingOf(context)),
                  child: TextButton(
                    onPressed: _goWelcome,
                    child: Text(
                      'Skip',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.95),
                        fontWeight: FontWeight.w600,
                        fontSize: Responsive.fontSize(context, 16),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 12 + bottomInset,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: Responsive.horizontalPaddingOf(context),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ProgressBar(fraction: (_index + 1) / _total),
                    const SizedBox(height: 14),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: _PageTicks(
                            current: _index,
                            total: _total,
                          ),
                        ),
                        Material(
                          color: AppColors.textOnPrimary,
                          shape: const CircleBorder(),
                          elevation: 4,
                          shadowColor: Colors.black26,
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: _next,
                            child: const Padding(
                              padding: EdgeInsets.all(14),
                              child: Icon(
                                Icons.chevron_right_rounded,
                                color: AppColors.primaryDark,
                                size: 28,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.fraction});

  final double fraction;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: SizedBox(
        height: 3,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(
              color: Colors.white.withValues(alpha: 0.22),
            ),
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: fraction.clamp(0.0, 1.0),
              child: const ColoredBox(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageTicks extends StatelessWidget {
  const _PageTicks({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    final tickSize = Responsive.fontSize(context, 15).clamp(13.0, 17.0);
    final sepSize = Responsive.fontSize(context, 13).clamp(11.0, 15.0);
    final dim = TextStyle(
      fontSize: tickSize,
      fontWeight: FontWeight.w500,
      color: Colors.white.withValues(alpha: 0.4),
    );
    final active = TextStyle(
      fontSize: tickSize,
      fontWeight: FontWeight.w800,
      color: Colors.white,
      letterSpacing: 0.5,
    );
    final sep = TextStyle(
      fontSize: sepSize,
      color: Colors.white.withValues(alpha: 0.35),
    );
    return Row(
      children: [
        for (int i = 0; i < total; i++) ...[
          if (i > 0) Text(' • ', style: sep),
          if (i == current)
            Text((i + 1).toString().padLeft(2, '0'), style: active)
          else
            Text('•', style: dim),
        ],
      ],
    );
  }
}
