import 'package:flutter/material.dart';

/// App color palette for GetMyPair (2026 brand guidelines — logo colours)
class AppColors {
  AppColors._();

  // Primary — medium teal (logo on teal, UI actions)
  static const Color primary = Color(0xFF15808D);
  static const Color primaryDark = Color(0xFF0A2429); // wordmark / dark teal
  static const Color primaryLight = Color(0xFF3DB9C8); // lighter teal for gradients / highlights
  static const Color onPrimary = Color(0xFFFFFFFF);

  // Secondary / accent — bright cyan (logo accent)
  static const Color secondary = Color(0xFF00E5FF);
  static const Color secondaryLight = Color(0xFFE0FBFF);

  static const Color accent = Color(0xFF00E5FF);

  // Background / surfaces (light gray from guidelines + white)
  static const Color background = Color(0xFFF0F2F3);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF0F0F0);

  // Text — dark teal for primary copy (wordmark colour)
  static const Color textPrimary = Color(0xFF0A2429);
  static const Color textSecondary = Color(0xFF5C6E73);
  static const Color textTertiary = Color(0xFF8A9A9F);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Border Colors
  static const Color border = Color(0xFFC8D8DC);
  static const Color borderFocus = Color(0xFF15808D);
  static const Color divider = Color(0xFFC8D8DC);

  // Shadow (tinted to dark teal)
  static const Color shadow = Color(0x260A2429);

  // Status Colors
  static const Color success = Color(0xFF0D9488); // --success
  static const Color error = Color(0xFFDC2626); // --danger
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF0EA5E9);

  // Disabled
  static const Color disabled = Color(0xFFBDBDBD);

  // Hero gradient (splash / onboarding: dark teal → mid teal → bright cyan)
  static const Color footwearHeroStart = Color(0xFF062F35);
  static const Color footwearHeroMid = Color(0xFF0F6876);
  static const Color footwearHeroEnd = Color(0xFF09E0FF);
  static const Color footwearCardHighlight = Color(0xFFF0F0F0);

  /// Large display / emphasis on teal/cyan gradients (onboarding mint).
  static const Color onGradientDisplay = Color(0xFFA7F3D0);

  /// “Truly fits!” / mint CTA on onboarding (Figma).
  static const Color onboardingTrulyFits = Color(0xFFAFEDD6);

  /// Body / secondary copy on gradients.
  static const Color onGradientBody = Color(0xFFF0FFFF);

  /// Muted line / hint on gradients (~70% white).
  static const Color onGradientMuted = Color(0xB3FFFFFF);

  /// Circular control fill on gradient screens (~45% dark teal).
  static const Color overlayOnGradient = Color(0x730A2429);

  /// Circular “next” / light control on gradients (mint fill).
  static const Color surfaceOnGradient = Color(0xFFD8F8F2);

  /// Icon on [surfaceOnGradient] (dark teal).
  static const Color onSurfaceOnGradient = Color(0xFF0A2429);
}
