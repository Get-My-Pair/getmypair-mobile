import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/responsive.dart';
/// Shared layout + type scale for onboarding slides (consistent alignment on all phones).
class OnboardingContent {
  OnboardingContent._();

  /// Inner max width (parent already applies horizontal padding).
  static double maxContentWidth(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final pad = Responsive.horizontalPaddingOf(context);
    final inner = w - 2 * pad;
    return inner.clamp(0.0, 420.0);
  }

  static EdgeInsets horizontalPadding(BuildContext context) {
    return EdgeInsets.symmetric(horizontal: Responsive.horizontalPaddingOf(context));
  }
}

/// Onboarding screens 2–4: **centered** copy in the **lower third**, max width 368 (design).
class OnboardingCopyPanel extends StatelessWidget {
  const OnboardingCopyPanel({
    super.key,
    required this.child,
  });

  final Widget child;

  static const double _maxBlock = 368;

  @override
  Widget build(BuildContext context) {
    final inner = OnboardingContent.maxContentWidth(context);
    final maxW = math.max(240.0, math.min(_maxBlock, inner));
    final pad = Responsive.horizontalPaddingOf(context);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: pad),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final rowW = constraints.hasBoundedWidth
              ? constraints.maxWidth
              : MediaQuery.sizeOf(context).width - 2 * pad;
          final blockW = math.min(maxW, rowW);
          return SizedBox(
            width: rowW,
            height: constraints.maxHeight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(flex: 5),
                Align(
                  alignment: Alignment.center,
                  child: SizedBox(
                    width: blockW,
                    child: DefaultTextStyle.merge(
                      textAlign: TextAlign.center,
                      child: child,
                    ),
                  ),
                ),
                const Spacer(flex: 2),
              ],
            ),
          );
        },
      ),
    );
  }
}
/// Responsive font sizes shared across onboarding copy.
///
/// Body: **Montserrat**. Display accents: **Boldonse** 400 / 48px (scaled) / line-height 100% / letter-spacing 0.
class OnboardingTypography {
  OnboardingTypography._();

  /// Boldonse Regular 48px, line-height 100%, letter-spacing 0 (responsive clamp).
  static TextStyle boldonseDisplay48(BuildContext context, {required Color color}) {
    final size = Responsive.fontSizeClamped(context, 48, min: 36, max: 56);
    return GoogleFonts.boldonse(
      fontSize: size,
      fontWeight: FontWeight.w400,
      fontStyle: FontStyle.normal,
      color: color,
      height: 1.0,
      letterSpacing: 0,
    );
  }

  static TextStyle montserratBody(BuildContext context, {Color? color}) {
    final size = Responsive.fontSize(context, 17).clamp(15.0, 19.0);
    return GoogleFonts.montserrat(
      fontSize: size,
      fontWeight: FontWeight.w500,
      color: color ?? Colors.white,
      height: 1.45,
    );
  }

  static TextStyle boldonseAccent(BuildContext context, {required Color color, double? height}) {
    final size = Responsive.fontSize(context, 30).clamp(24.0, 34.0);
    return GoogleFonts.boldonse(
      fontSize: size,
      color: color,
      height: height ?? 1.12,
    );
  }

  /// Welcome slide line 1 — Montserrat Light 32 / line-height 100% (design).
  static TextStyle welcomeSubtitle(BuildContext context) {
    final size = Responsive.fontSize(context, 32).clamp(26.0, 36.0);
    return GoogleFonts.montserrat(
      fontSize: size,
      fontWeight: FontWeight.w300,
      color: Colors.white,
      height: 1.0,
      letterSpacing: 0,
    );
  }

  /// Screen 2 — body paragraph (Montserrat 32 / Regular / 100% / white).
  static TextStyle scanIntroBody(BuildContext context) {
    final size = Responsive.fontSize(context, 32).clamp(26.0, 36.0);
    return GoogleFonts.montserrat(
      fontSize: size,
      fontWeight: FontWeight.w400,
      color: Colors.white,
      height: 1.0,
      letterSpacing: 0,
    );
  }

  /// Boldonse 48 highlight (mint) — “truly fits!”, “virtually!”, screen 4 stack lines.
  static TextStyle scanIntroAccent(BuildContext context) {
    return boldonseDisplay48(context, color: AppColors.onboardingTrulyFits);
  }

  /// Welcome slide line 2 — Boldonse Regular 36 / line-height 100% (design).
  static TextStyle welcomeTitle(BuildContext context) {
    final size = Responsive.fontSize(context, 36).clamp(28.0, 40.0);
    return GoogleFonts.boldonse(
      fontSize: size,
      fontWeight: FontWeight.w400,
      color: Colors.white,
      height: 1.0,
      letterSpacing: 0,
    );
  }

  /// Screen 3 — e.g. “virtually!” (same Boldonse 48 display spec).
  static TextStyle boldonseAccentLarge(BuildContext context, {required Color color}) {
    return boldonseDisplay48(context, color: color);
  }

  /// Screen 4 — stacked highlight words (Boldonse ~40, same mint as other accents).
  static TextStyle stackWord(BuildContext context, {required Color color}) {
    final size = Responsive.fontSizeClamped(context, 40, min: 28, max: 48);
    return GoogleFonts.boldonse(
      fontSize: size,
      fontWeight: FontWeight.w400,
      fontStyle: FontStyle.normal,
      color: color,
      height: 1.0,
      letterSpacing: 0,
    );
  }
}
