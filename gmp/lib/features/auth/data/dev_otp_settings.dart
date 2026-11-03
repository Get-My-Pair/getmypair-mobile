import 'package:flutter/foundation.dart';
// import 'package:shared_preferences/shared_preferences.dart'; // floating Dev OTP / MSG91 toggle commented out

/// Testing switch: Dev OTP popup vs MSG91/SMS path.
///
/// Floating Dev / MSG91 toggle is commented out — forced OFF (MSG91/SMS only).
/// - ON  → keep OTP in API response and show the in-app popup
/// - OFF → strip OTP from response (SMS / MSG91 only)
class DevOtpSettings {
  DevOtpSettings._();

  // static const String _prefsKey = 'dev_otp_popup_enabled';

  /// Forced OFF: release / MSG91 path only (floating toggle commented out).
  static final ValueNotifier<bool> enabled = ValueNotifier<bool>(false);

  static bool _loaded = false;

  /// Always false while floating Dev OTP / MSG91 toggle is commented out.
  static bool get isEnabled => false;

  static Future<void> ensureLoaded() async {
    if (_loaded) return;
    // Floating Dev OTP / MSG91 toggle commented out — ignore prefs, stay OFF.
    // final prefs = await SharedPreferences.getInstance();
    // enabled.value = prefs.getBool(_prefsKey) ?? true;
    enabled.value = false;
    _loaded = true;
  }

  static Future<void> setEnabled(bool value) async {
    // Floating Dev OTP / MSG91 toggle commented out — no-op.
    // enabled.value = value;
    // final prefs = await SharedPreferences.getInstance();
    // await prefs.setBool(_prefsKey, value);
    enabled.value = false;
    _loaded = true;
  }
}
