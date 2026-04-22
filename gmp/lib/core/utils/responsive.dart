import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Responsive layout for **all** phone sizes.
///
/// **Whenever you add or change UI, follow this:**
/// 1. **Horizontal padding** — always [horizontalPaddingOf] (or [Responsive.of] `.horizontalPadding`), never hard-coded `16/20/24`.
/// 2. **Font sizes from design (Figma)** — always [fontSize] with the design’s **logical px** as [base] (e.g. 32, 48), then [.clamp] if you need min/max caps.
/// 3. **Fixed widths from design** (e.g. 234, 368) — use `min(designPx, availableWidth)` or [scaleDesignWidth] from a reference frame (default 390).
/// 4. **Bottom / safe areas** — use [bottomInsetOf] when placing controls above the home indicator.
/// 5. **Onboarding slides** — use that feature’s shared typography / max-width helpers so copy stays consistent.
class Responsive {
  Responsive._();

  /// Default Figma iPhone frame width used for scaling (logical px).
  static const double designFrameWidth = 390;

  /// Breakpoints (logical pixels).
  static const double breakpointSmall = 360;
  static const double breakpointMedium = 400;
  static const double breakpointLarge = 480;

  static BuildContext? _context;

  /// Initialize with current context (e.g. in build). Prefer using of(context) per build.
  static Responsive of(BuildContext context) {
    _context = context;
    return Responsive._();
  }

  double get width {
    final ctx = _context;
    if (ctx == null) return 392;
    return MediaQuery.sizeOf(ctx).width;
  }

  double get height {
    final ctx = _context;
    if (ctx == null) return 784;
    return MediaQuery.sizeOf(ctx).height;
  }

  /// Safe padding for insets (smaller on narrow screens).
  double get horizontalPadding {
    if (width <= breakpointSmall) return 16;
    if (width <= breakpointMedium) return 20;
    return 24;
  }

  double get verticalPadding {
    if (height < 700) return 12;
    return 16;
  }

  /// Scale factor for fonts (0.85 on small, 1.0 on large).
  double get fontScale {
    if (width <= breakpointSmall) return 0.88;
    if (width <= breakpointMedium) return 0.94;
    return 1.0;
  }

  /// Scale factor for large assets (logos, hero images).
  double get assetScale {
    if (width <= breakpointSmall) return 0.65;
    if (width <= breakpointMedium) return 0.8;
    return 1.0;
  }

  /// Max logo size (shortest side of screen * factor).
  double maxLogoSize([double factor = 0.35]) {
    final shortest = width < height ? width : height;
    return (shortest * factor).clamp(100.0, 260.0);
  }

  /// Responsive value: returns [small] when width <= 360, [medium] when <= 400, else [large].
  static T value<T>(BuildContext context, {required T small, T? medium, required T large}) {
    final w = MediaQuery.sizeOf(context).width;
    if (w <= breakpointSmall) return small;
    if (medium != null && w <= breakpointMedium) return medium;
    return large;
  }

  /// Horizontal padding from screen width.
  static double horizontalPaddingOf(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w <= breakpointSmall) return 16;
    if (w <= breakpointMedium) return 20;
    return 24;
  }

  /// Scaled font size (base * scale). Pass Figma **font size in px** as [base].
  static double fontSize(BuildContext context, double base) {
    final w = MediaQuery.sizeOf(context).width;
    double scale = 1.0;
    if (w <= breakpointSmall) {
      scale = 0.88;
    } else if (w <= breakpointMedium) {
      scale = 0.94;
    }
    return (base * scale).roundToDouble();
  }

  /// Scales a horizontal size from a design frame (e.g. Figma at [designFrameWidth]) to the current screen width.
  static double scaleDesignWidth(
    BuildContext context,
    double valueAtDesignFrame, {
    double designFrameWidth = Responsive.designFrameWidth,
  }) {
    final w = MediaQuery.sizeOf(context).width;
    return valueAtDesignFrame * (w / designFrameWidth);
  }

  /// [fontSize] then clamp — use for every text style that must stay within min/max bounds.
  static double fontSizeClamped(
    BuildContext context,
    double base, {
    required double min,
    required double max,
  }) {
    return fontSize(context, base).clamp(min, max);
  }

  /// Max logo dimension (square) for current screen.
  static double maxLogoSizeOf(BuildContext context, [double factor = 0.35]) {
    final size = MediaQuery.sizeOf(context);
    final shortest = size.width < size.height ? size.width : size.height;
    return (shortest * factor).clamp(80.0, 260.0);
  }

  /// Physical bottom inset from the window [View] (gesture bar, home indicator).
  ///
  /// Prefer this over [MediaQuery.padding] alone when building inside a subtree
  /// whose padding was altered (e.g. [Scaffold.extendBody]), which some OEMs
  /// still report differently from Motorola-class devices.
  static double physicalBottomInsetOf(BuildContext context) {
    final fromView = MediaQueryData.fromView(View.of(context));
    return math.max(
      fromView.viewPadding.bottom,
      fromView.systemGestureInsets.bottom,
    );
  }

  /// Safe bottom inset (for FAB / bottom bars on notched devices).
  static double bottomInsetOf(BuildContext context) {
    final pad = MediaQuery.paddingOf(context).bottom;
    final physical = physicalBottomInsetOf(context);
    return math.max(pad, physical);
  }
}
