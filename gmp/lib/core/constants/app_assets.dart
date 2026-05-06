/// Central paths for bundled brand images under `assets/images/logo/`.
///
/// Place files:
/// - [appIcon] — square mark (1024×1024 PNG recommended) for `flutter_launcher_icons`
/// - [appLogo] — wordmark / full logo for splash and auth UI
class AppAssets {
  AppAssets._();

  static const String appIcon = 'assets/images/logo/app_icon.png';
  static const String appLogo = 'assets/images/logo/app_logo.png';

  /// White mark for splash (Figma: GMP APP LOGO WHITE 1). Web-safe name — no spaces.
  static const String appLogoWhite1 = 'assets/images/logo/gmp_app_logo_white_1.png';
}
