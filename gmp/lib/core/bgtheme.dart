import 'package:flutter/material.dart';

/// Full-screen background: [backgroundImageAsset] only (no theme gradient/solid).
/// Use [scaffoldBackgroundColor] on [Scaffold] when the body includes
/// [background] so the image is visible instead of [ThemeData.scaffoldBackgroundColor].
abstract class BgTheme {
  BgTheme._();

  static const String backgroundImageAsset = 'assets/images/bg.png';

  /// Set on [Scaffold.backgroundColor] when layering [background] in the body.
  static const Color scaffoldBackgroundColor = Colors.transparent;

  /// Full background stack (place first inside a [Stack]).
  static List<Widget> background() {
    return [
      Positioned.fill(
        child: Image.asset(
          backgroundImageAsset,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          filterQuality: FilterQuality.high,
        ),
      ),
    ];
  }
}