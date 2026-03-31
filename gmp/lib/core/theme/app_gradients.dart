import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Brand gradients (onboarding, splash, hero surfaces).
class AppGradients {
  AppGradients._();

  /// Full-screen vertical: dark teal → mid teal → cyan (onboarding / splash).
  static const LinearGradient heroVertical = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      AppColors.footwearHeroStart,
      AppColors.footwearHeroMid,
      AppColors.footwearHeroEnd,
    ],
    stops: const [0.0, 0.48, 1.0],
  );

  /// Hero cards / banners (slightly diagonal).
  static const LinearGradient heroDiagonal = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.footwearHeroStart,
      AppColors.footwearHeroMid,
      AppColors.footwearHeroEnd,
    ],
    stops: const [0.0, 0.5, 1.0],
  );
}
