import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../widgets/onboarding_surface.dart';
import 'onboarding_bottom_progress.dart';
import '../mobile_otp_page.dart';

/// Three-step onboarding matching Figma nodes:
/// 335:1135, 335:1162, 335:1189.
class OnboardingFlowPage extends StatefulWidget {
  const OnboardingFlowPage({super.key});

  @override
  State<OnboardingFlowPage> createState() => _OnboardingFlowPageState();
}

class _OnboardingFlowPageState extends State<OnboardingFlowPage> {
  final PageController _pageController = PageController();
  int _index = 0;

  static const int _total = 3;
  static const List<_OnboardingSlide> _slides = [
    _OnboardingSlide(
      body: 'Scan your feet to find your\nperfect size and discover\nfootwear that',
      accent: 'truly fits!',
      textTop: 506,
      textLeft: 37,
      textWidth: 318,
      textAlign: TextAlign.left,
    ),
    _OnboardingSlide(
      body: 'Try your footwear',
      accent: 'virtually!',
      textTop: 491,
      textLeft: 37,
      textWidth: 328,
      textAlign: TextAlign.end,
      accentAlign: TextAlign.center,
    ),
    _OnboardingSlide(
      body: 'Extend the life of\nevery pair',
      stacked: ['repair', 'maintain', 'donate', 'sell!'],
      textTop: 419,
      textLeft: 35,
      textWidth: 264,
      textAlign: TextAlign.start,
    ),
  ];

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
    final scale = _scale(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
      ),
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            const OnboardingGradientBackdrop(),
            Padding(
              padding: EdgeInsets.only(bottom: 120 + bottomInset),
              child: SafeArea(
                bottom: false,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final sx = constraints.maxWidth / _figmaW;
                    final sy = constraints.maxHeight / _figmaH;
                    return PageView(
                      controller: _pageController,
                      onPageChanged: (i) => setState(() => _index = i),
                      children: _slides
                          .map((s) => _OnboardingSlideView(slide: s, sx: sx, sy: sy))
                          .toList(growable: false),
                    );
                  },
                ),
              ),
            ),
            SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 18, top: 24),
                  child: TextButton(
                    onPressed: _goWelcome,
                    style: TextButton.styleFrom(
                      minimumSize: const Size(0, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Skip',
                      style: GoogleFonts.montserrat(
                        color: Colors.white,
                        fontSize: 18 * scale.clamp(0.86, 1.1),
                        fontWeight: FontWeight.w400,
                        height: 1.0,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 37,
              right: 21,
              bottom: 26 + bottomInset,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _PageTicks(current: _index),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: OnboardingBottomProgress(
                        currentIndex: _index,
                        totalSteps: _total,
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  _NextButton(onTap: _next),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const double _figmaW = 390;
const double _figmaH = 844;

double _scale(BuildContext context) {
  final sz = MediaQuery.sizeOf(context);
  final sw = sz.width / _figmaW;
  final sh = sz.height / _figmaH;
  return sw < sh ? sw : sh;
}

class _OnboardingSlide {
  const _OnboardingSlide({
    required this.body,
    required this.textTop,
    required this.textLeft,
    required this.textWidth,
    this.accent,
    this.stacked,
    required this.textAlign,
    this.accentAlign,
  });

  final String body;
  final String? accent;
  final List<String>? stacked;
  final double textTop;
  final double textLeft;
  final double textWidth;
  final TextAlign textAlign;
  final TextAlign? accentAlign;
}

class _OnboardingSlideView extends StatelessWidget {
  const _OnboardingSlideView({
    required this.slide,
    required this.sx,
    required this.sy,
  });

  final _OnboardingSlide slide;
  final double sx;
  final double sy;

  @override
  Widget build(BuildContext context) {
    // Typography must follow the tighter of width/height scale; using [sy] alone
    // makes tall narrow phones clip horizontally while short wide layouts stay OK.
    final s = math.min(sx, sy);
    final bodyStyle = GoogleFonts.montserrat(
      fontSize: (30 * s).clamp(16.0, 28.0),
      fontWeight: FontWeight.w300,
      color: Colors.white,
      height: 1.2,
      letterSpacing: 0,
    );
    final accentStyle = GoogleFonts.boldonse(
      fontSize: (48 * s).clamp(26.0, 52.0),
      fontWeight: FontWeight.w400,
      color: const Color(0xFFEDEEEF),
      height: 1.0,
      letterSpacing: 0,
    );

    final rightPad =
        (_figmaW - slide.textLeft - slide.textWidth) * sx;

    return Stack(
      children: [
        Positioned(
          top: slide.textTop * sy,
          left: slide.textLeft * sx,
          right: rightPad,
          child: Column(
            crossAxisAlignment: slide.textAlign == TextAlign.end
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              Text(
                slide.body,
                textAlign: slide.textAlign,
                style: bodyStyle,
                softWrap: true,
              ),
              if (slide.accent != null) ...[
                SizedBox(height: 8 * s),
                Text(
                  slide.accent!,
                  textAlign: slide.accentAlign ?? slide.textAlign,
                  style: accentStyle,
                  softWrap: true,
                ),
              ],
              if (slide.stacked != null) ...[
                SizedBox(height: 12 * s),
                for (final word in slide.stacked!)
                  Text(
                    word,
                    textAlign: TextAlign.start,
                    style: accentStyle.copyWith(height: 1.4),
                    softWrap: true,
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _PageTicks extends StatelessWidget {
  const _PageTicks({required this.current});

  final int current;

  @override
  Widget build(BuildContext context) {
    final numStyle = GoogleFonts.boldonse(
      fontSize: 14,
      fontWeight: FontWeight.w700,
      color: const Color(0xFFDDE6E9),
      height: 1.0,
    );

    List<Widget> childrenFor(int i) {
      final label = Text(
        (i + 1).toString().padLeft(2, '0'),
        style: numStyle,
        textHeightBehavior: const TextHeightBehavior(
          applyHeightToFirstAscent: false,
          applyHeightToLastDescent: false,
        ),
      );
      const dot = _TickDot();
      if (i == 0) {
        return [label, const SizedBox(width: 12), dot, const SizedBox(width: 12), dot];
      }
      if (i == 1) {
        return [dot, const SizedBox(width: 12), label, const SizedBox(width: 12), dot];
      }
      return [dot, const SizedBox(width: 12), dot, const SizedBox(width: 12), label];
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: Row(
        key: ValueKey(current),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: childrenFor(current),
      ),
    );
  }
}

class _TickDot extends StatelessWidget {
  const _TickDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
        color: Color(0xFFDDE6E9),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _NextButton extends StatelessWidget {
  const _NextButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFFDDE6E9),
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFF09DFFF),
            width: 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x19000000),
              blurRadius: 4,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.chevron_right_rounded,
          color: AppColors.primaryDark,
          size: 28,
        ),
      ),
    );
  }
}
