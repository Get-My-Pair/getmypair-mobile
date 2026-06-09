import 'package:flutter/material.dart';

import 'package:flutter/services.dart';

import 'package:google_fonts/google_fonts.dart';



import '../../../../../core/theme/app_colors.dart';

import '../../widgets/onboarding_surface.dart';

import 'onboarding_bottom_progress.dart';

import 'onboarding_content.dart';

import 'onboarding_slide_four.dart';

import 'onboarding_slide_one.dart';

import 'onboarding_slide_three.dart';

import 'onboarding_slide_two.dart';

import '../mobile_otp_page.dart';



/// Four-step onboarding: rack → AI sizing → cobbler care → rehome & earn.

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

                child: PageView(

                  controller: _pageController,

                  onPageChanged: (i) => setState(() => _index = i),

                  children: [
                    OnboardingSlideOne(),
                    OnboardingSlideTwo(),
                    OnboardingSlideThree(),
                    OnboardingSlideFour(),
                  ],

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
              left: OnboardingContent.figmaLeftInset,
              right: OnboardingContent.figmaRightInset,
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



double _scale(BuildContext context) {
  final sz = MediaQuery.sizeOf(context);
  final sw = sz.width / OnboardingContent.figmaWidth;
  final sh = sz.height /
      (OnboardingContent.figmaContentHeight + 120);
  return sw < sh ? sw : sh;
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



    List<Widget> childrenFor(int current) {

      const total = 4;

      final children = <Widget>[];

      for (var i = 0; i < total; i++) {

        if (i > 0) children.add(const SizedBox(width: 12));

        if (i == current) {

          children.add(

            Text(

              (i + 1).toString().padLeft(2, '0'),

              style: numStyle,

              textHeightBehavior: const TextHeightBehavior(

                applyHeightToFirstAscent: false,

                applyHeightToLastDescent: false,

              ),

            ),

          );

        } else {

          children.add(const _TickDot());

        }

      }

      return children;

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


