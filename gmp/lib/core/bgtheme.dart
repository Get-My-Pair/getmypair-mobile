import 'package:flutter/material.dart';

/// Premium gradient background (matches given image)
abstract class BgTheme {
  BgTheme._();

  /// Base fallback color
  static const Color baseDeepTeal = Color(0xFF062F35);

  /// Auth panel color
  static const Color authPanel = Color(0xFFD9D9D9);
  static const double authPanelTopRadius = 28;

  /// 🔹 Main Gradient (exact requested palette split)
  static const LinearGradient authMarketingSweep = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0xFF062F35),
      Color(0xFF062F35),
      Color(0xFF0F6876),
      Color(0xFF09E0FF),
    ],
    stops: [0.0, 0.28, 0.66, 1.0],
  );

  /// 🔹 Soft horizontal vignette (keeps left side deeper)
  static const LinearGradient centerShadowOverlay = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0x33001116),
      Color(0x18001A21),
      Colors.transparent,
      Color(0x08009CB4),
    ],
    stops: [0.0, 0.32, 0.72, 1.0],
  );

  /// 🔹 Subtle top-left dark shade
  static const RadialGradient topLeftShade = RadialGradient(
    center: Alignment(-0.72, -1.08),
    radius: 1.08,
    colors: [
      Color(0x78000910),
      Color(0x3A012028),
      Color(0x16085A66),
      Colors.transparent,
    ],
    stops: [0.0, 0.34, 0.62, 1.0],
  );

  /// 🔹 Broad top-right glow highlight
  static const RadialGradient cornerGlow = RadialGradient(
    center: Alignment(1.0, -0.95),
    radius: 1.35,
    colors: [
      Color(0x8A09E0FF),
      Color(0x3F09E0FF),
      Color(0x1209E0FF),
      Colors.transparent,
    ],
    stops: [0.0, 0.24, 0.56, 1.0],
  );

  /// 🔹 Full background stack
  static List<Widget> background() {
    return [
      /// Base color
      const Positioned.fill(
        child: DecoratedBox(
          decoration: BoxDecoration(color: baseDeepTeal),
        ),
      ),

      /// Main gradient
      const Positioned.fill(
        child: DecoratedBox(
          decoration: BoxDecoration(gradient: authMarketingSweep),
        ),
      ),

      /// Center shadow
      const Positioned.fill(
        child: DecoratedBox(
          decoration: BoxDecoration(gradient: centerShadowOverlay),
        ),
      ),

      /// Top-left shade
      const Positioned.fill(
        child: DecoratedBox(
          decoration: BoxDecoration(gradient: topLeftShade),
        ),
      ),

      /// Corner glow
      const Positioned.fill(
        child: DecoratedBox(
          decoration: BoxDecoration(gradient: cornerGlow),
        ),
      ),
    ];
  }
}