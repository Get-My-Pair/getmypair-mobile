/// Shared spacing and tap-target scale for consistent layout across the app.
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;

  /// Minimum interactive control size (Material / WCAG-friendly).
  static const double minTapTarget = 44;

  static const double fieldHeight = 48;
  static const double buttonHeight = 52;
  static const double radiusPill = 100;
  static const double radiusCard = 16;
  static const double radiusFrame = 12;

  static const double labelFontSize = 16;
  static const double bodyFontSize = 14;
  static const double titleFontSize = 22;
  static const double inputFontSize = 16;
}
