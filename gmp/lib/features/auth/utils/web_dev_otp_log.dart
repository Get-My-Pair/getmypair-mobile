import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;

/// Dev OTP is only for Flutter web. Android/iOS always use production SMS.
bool get isWebDevOtpEnabled => kIsWeb;

/// Prints Dev OTP to the `flutter run` terminal (Chrome / web only).
void logWebDevOtpToTerminal(String otp, {String? mobile}) {
  if (!isWebDevOtpEnabled) return;
  final code = otp.trim();
  if (code.isEmpty) return;
  final phone = (mobile ?? '').trim();
  final phoneLine = phone.isEmpty ? '' : '  mobile: $phone\n';
  // ignore: avoid_print — intentional: visible in Flutter Chrome run terminal
  print('\n'
      '========================================\n'
      '  WEB DEV OTP: $code\n'
      '$phoneLine'
      '========================================\n');
  debugPrint('[Web Dev OTP] $code${phone.isEmpty ? '' : ' ($phone)'}');
}
