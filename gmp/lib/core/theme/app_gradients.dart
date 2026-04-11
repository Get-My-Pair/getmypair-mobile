import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Shared marketing / profile gradients (dark teal → cyan).
abstract class AppGradients {
  AppGradients._();

  /// Splash screen + onboarding backdrop (same gradient).
  static const LinearGradient splashBackground = LinearGradient(
    begin: Alignment(0.82, 0.05),
    end: Alignment(-0.17, 1.22),
    colors: [
      Color(0xFF062F35),
      Color(0xFF0F6876),
      Color(0xFF09E0FF),
    ],
  );

  /// Login / hero screens: same palette on a diagonal.
  static const LinearGradient heroDiagonal = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.footwearHeroEnd,
      AppColors.footwearHeroMid,
      AppColors.footwearHeroStart,
    ],
    stops: [0.0, 0.48, 1.0],
  );

  /// Bottom-left dark teal → top-right luminous cyan (profile / settings shell).
  static const LinearGradient screenTealCyan = LinearGradient(
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
    colors: [
      Color(0xFF004D40),
      Color(0xFF0F6876),
      Color(0xFF00BCD4),
    ],
    stops: [0.0, 0.45, 1.0],
  );
}
