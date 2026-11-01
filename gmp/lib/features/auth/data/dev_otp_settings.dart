import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Testing switch: Dev OTP popup vs MSG91/SMS path.
///
/// - ON  → keep OTP in API response and show the in-app popup
/// - OFF → strip OTP from response (SMS / MSG91 only)
class DevOtpSettings {
  DevOtpSettings._();

  static const String _prefsKey = 'dev_otp_popup_enabled';

  /// Default ON so local/QA testing works before MSG91 is live.
  static final ValueNotifier<bool> enabled = ValueNotifier<bool>(true);

  static bool _loaded = false;

  static bool get isEnabled => enabled.value;

  static Future<void> ensureLoaded() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    enabled.value = prefs.getBool(_prefsKey) ?? true;
    _loaded = true;
  }

  static Future<void> setEnabled(bool value) async {
    enabled.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, value);
    _loaded = true;
  }
}
