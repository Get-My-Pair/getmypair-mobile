import 'package:flutter/material.dart';

/// Responsive layout utilities so UI works on all mobile phone screen sizes.
/// Use [Responsive] of(context) or [MediaQuery] for padding, font sizes, and image sizes.
class Responsive {
  Responsive._();

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

  /// Scaled font size (base * scale).
  static double fontSize(BuildContext context, double base) {
    final w = MediaQuery.sizeOf(context).width;
    double scale = 1.0;
    if (w <= breakpointSmall) scale = 0.88;
    else if (w <= breakpointMedium) scale = 0.94;
    return (base * scale).roundToDouble();
  }

  /// Max logo dimension (square) for current screen.
  static double maxLogoSizeOf(BuildContext context, [double factor = 0.35]) {
    final size = MediaQuery.sizeOf(context);
    final shortest = size.width < size.height ? size.width : size.height;
    return (shortest * factor).clamp(80.0, 260.0);
  }

  /// Safe bottom inset (for FAB / bottom bars on notched devices).
  static double bottomInsetOf(BuildContext context) {
    return MediaQuery.paddingOf(context).bottom;
  }
}
