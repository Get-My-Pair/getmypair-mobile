import 'package:url_launcher/url_launcher.dart';

/// Opens UPI / Google Pay / wallet apps from Zoho Checkout WebView navigations.
class PaymentExternalLauncher {
  PaymentExternalLauncher._();

  static bool shouldLaunchExternally(String url) {
    final lower = url.trim().toLowerCase();
    if (lower.isEmpty) return false;

    if (lower.startsWith('intent:') ||
        lower.startsWith('tez:') ||
        lower.startsWith('gpay:') ||
        lower.startsWith('googlepay:') ||
        lower.startsWith('upi:') ||
        lower.startsWith('paytmmp:') ||
        lower.startsWith('phonepe:') ||
        lower.startsWith('bhim:') ||
        lower.startsWith('credpay:') ||
        lower.startsWith('amazonpay:') ||
        lower.startsWith('android-app:')) {
      return true;
    }

    return lower.contains('pay.google.com') ||
        lower.contains('google.com/pay');
  }

  static Future<bool> launch(String url) async {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return false;

    if (trimmed.toLowerCase().startsWith('intent:')) {
      final scheme = _extractIntentScheme(trimmed);
      if (scheme != null) {
        final direct = _intentToAppUrl(trimmed, scheme);
        if (direct != null && await _tryLaunch(Uri.parse(direct))) {
          return true;
        }
      }

      final fallback = _extractIntentFallback(trimmed);
      if (fallback != null && await _tryLaunch(Uri.parse(fallback))) {
        return true;
      }

      return _tryLaunch(Uri.parse(trimmed));
    }

    return _tryLaunch(Uri.parse(trimmed));
  }

  static Future<bool> _tryLaunch(Uri uri) async {
    try {
      if (await canLaunchUrl(uri)) {
        return launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      // Ignore — WebView may still complete via another method.
    }
    return false;
  }

  static String? _extractIntentScheme(String intentUrl) {
    final match = RegExp(r'scheme=([^;&]+)', caseSensitive: false)
        .firstMatch(intentUrl);
    return match?.group(1)?.trim();
  }

  static String? _extractIntentFallback(String intentUrl) {
    final match = RegExp(
      r'S\.browser_fallback_url=([^;]+)',
      caseSensitive: false,
    ).firstMatch(intentUrl);
    if (match == null) return null;
    return Uri.decodeComponent(match.group(1)!.trim());
  }

  static String? _intentToAppUrl(String intentUrl, String scheme) {
    final match = RegExp(r'intent://([^#]+)', caseSensitive: false)
        .firstMatch(intentUrl);
    if (match == null) return null;
    final path = match.group(1)!;
    return '$scheme://$path';
  }
}
