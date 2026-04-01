import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/responsive.dart';
import '../../widgets/onboarding_surface.dart';
import '../mobile_otp_page.dart';
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
            const MobileOTPPage(),
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
    final horizontalPad = Responsive.horizontalPaddingOf(context);
    final progressFraction = (_index + 1) / _total;
    final isLastPage = _index == _total - 1;
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
                  padding: EdgeInsets.only(right: horizontalPad, top: 8),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    child: TextButton(
                      onPressed: _goWelcome,
                      style: TextButton.styleFrom(
                        shape: const StadiumBorder(),
                        minimumSize: const Size(0, 40),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Skip',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.96),
                          fontWeight: FontWeight.w700,
                          fontSize: Responsive.fontSize(context, 14),
                          letterSpacing: 0.2,
                        ),
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
                  horizontal: horizontalPad,
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.16),
                        blurRadius: 16,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _ProgressBar(fraction: progressFraction),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: _PageTicks(
                                current: _index,
                                total: _total,
                              ),
                            ),
                            const SizedBox(width: 10),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 240),
                              curve: Curves.easeOutCubic,
                              decoration: BoxDecoration(
                                color: AppColors.textOnPrimary,
                                borderRadius: BorderRadius.circular(999),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(999),
                                onTap: _next,
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isLastPage ? 16 : 12,
                                    vertical: 12,
                                  ),
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 220),
                                    switchInCurve: Curves.easeOut,
                                    switchOutCurve: Curves.easeIn,
                                    transitionBuilder: (child, animation) {
                                      return FadeTransition(
                                        opacity: animation,
                                        child: ScaleTransition(
                                          scale: animation,
                                          child: child,
                                        ),
                                      );
                                    },
                                    child: isLastPage
                                        ? Text(
                                            'Start',
                                            key: const ValueKey('start'),
                                            style: TextStyle(
                                              color: AppColors.primaryDark,
                                              fontSize: Responsive.fontSize(context, 13),
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 0.2,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.chevron_right_rounded,
                                            key: ValueKey('next'),
                                            color: AppColors.primaryDark,
                                            size: 28,
                                          ),
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
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: 4,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(
              color: Colors.white.withValues(alpha: 0.18),
            ),
            AnimatedFractionallySizedBox(
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutCubic,
              alignment: Alignment.centerLeft,
              widthFactor: fraction.clamp(0.0, 1.0),
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.white, Color(0xFFD5FFF2)],
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
      color: Colors.white.withValues(alpha: 0.36),
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
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            style: i == current ? active : dim,
            child: Text(
              i == current ? (i + 1).toString().padLeft(2, '0') : '•',
            ),
                          ),
        ],
      ],
    );
  }
}
