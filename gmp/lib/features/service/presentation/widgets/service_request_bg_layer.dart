import 'package:flutter/material.dart';

/// Full-screen [assets/images/bg.png] behind the service request list and
/// detail flows only (not [BgTheme] / app-wide theme fills).
abstract class ServiceRequestBgLayer {
  ServiceRequestBgLayer._();

  static const String assetPath = 'assets/images/bg.png';

  /// Place first inside a [Stack] body.
  static List<Widget> stackBehind() {
    return [
      Positioned.fill(
        child: Image.asset(
          assetPath,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          filterQuality: FilterQuality.high,
        ),
      ),
    ];
  }

  /// Frosted panel over the image (replaces solid theme grey).
  static Color get panelFill => Colors.white.withValues(alpha: 0.88);
}

