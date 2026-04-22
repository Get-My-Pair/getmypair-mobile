import 'package:flutter/material.dart';

/// Background theme used across auth screens.
abstract class BgTheme {
  BgTheme._();

  static const String backgroundImageAsset = 'assets/images/bg.png';

  /// Full background stack.
  static List<Widget> background() {
    return [
      const Positioned.fill(
        child: DecoratedBox(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(backgroundImageAsset),
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    ];
  }
}