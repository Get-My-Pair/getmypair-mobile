import 'package:flutter/material.dart';

/// App color palette for GetMyPair
class AppColors {
  AppColors._();

  // Primary Colors (synced with admin.css teal palette)
  static const Color primary = Color(0xFF137C84); // --primary / --teal-mid
  static const Color primaryDark = Color(0xFF0F5C63); // --primary-dark / --teal-dark
  static const Color primaryLight = Color(0xFF1FB5C1); // --teal-light
  static const Color onPrimary = Color(0xFFFFFFFF);

  // Secondary / Accent Colors
  static const Color secondary = Color(0xFF3ED6C4); // --accent
  static const Color secondaryLight = Color(0xFFCCF5F1);

  // Accent
  static const Color accent = Color(0xFF3ED6C4); // --accent

  // Background Colors
  static const Color background = Color(0xFFF4F6F7); // --bg
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFFBFCFC); // --surface-elevated

  // Text Colors
  static const Color textPrimary = Color(0xFF1E2A2F); // --text
  static const Color textSecondary = Color(0xFF7A8A8F); // --muted
  static const Color textTertiary = Color(0xFF94A3A8);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Border Colors
  static const Color border = Color(0xFFD5E0E3); // --border
  static const Color borderFocus = Color(0xFF137C84); // --teal-mid
  static const Color divider = Color(0xFFD5E0E3);

  // Shadow
  static const Color shadow = Color(0x26115C63);

  // Status Colors
  static const Color success = Color(0xFF0D9488); // --success
  static const Color error = Color(0xFFDC2626); // --danger
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF0EA5E9);

  // Disabled
  static const Color disabled = Color(0xFFBDBDBD);

  // Footwear theme (hero, accents) mapped to new gradient
  static const Color footwearHeroStart = Color(0xFF0F5C63);
  static const Color footwearHeroEnd = Color(0xFF1FB5C1);
  static const Color footwearCardHighlight = Color(0xFFFBFCFC);
}
