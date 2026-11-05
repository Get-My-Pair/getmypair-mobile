import 'package:flutter/foundation.dart' show debugPrint, kDebugMode, kIsWeb;

/// Dev OTP UI: Flutter web always, plus debug mobile builds when API returns `otp`.
bool get isWebDevOtpEnabled => kIsWeb || kDebugMode;

/// Prints Dev OTP to the `flutter run` terminal.
void logWebDevOtpToTerminal(String otp, {String? mobile}) {
  if (!isWebDevOtpEnabled) return;
  final code = otp.trim();
  if (code.isEmpty) return;
  final phone = (mobile ?? '').trim();
  final phoneLine = phone.isEmpty ? '' : '  mobile: $phone\n';
  // ignore: avoid_print — intentional: visible in Flutter run terminal
  print('\n'
      '========================================\n'
      '  DEV OTP: $code\n'
      '$phoneLine'
      '========================================\n');
  debugPrint('[Dev OTP] $code${phone.isEmpty ? '' : ' ($phone)'}');
}
