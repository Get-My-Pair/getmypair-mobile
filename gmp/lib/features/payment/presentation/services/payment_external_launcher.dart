import 'package:url_launcher/url_launcher.dart';

/// Opens UPI / Google Pay / wallet apps from Zoho Checkout WebView navigations.
///
/// Only allowlisted schemes are launched. Arbitrary `intent:` schemes from a
/// remote page are rejected so they cannot open unexpected apps.
class PaymentExternalLauncher {
  PaymentExternalLauncher._();

  static const Set<String> allowedSchemes = {
    'upi',
    'tez',
    'gpay',
    'googlepay',
    'paytmmp',
    'phonepe',
    'bhim',
    'credpay',
  };

  static bool shouldLaunchExternally(String url) {
    final lower = url.trim().toLowerCase();
    if (lower.isEmpty) return false;

    if (lower.startsWith('intent:')) return true;

    for (final scheme in allowedSchemes) {
      if (lower.startsWith('$scheme:')) return true;
    }

    return lower.contains('pay.google.com') ||
        lower.contains('google.com/pay');
  }

  static Future<bool> launch(String url) async {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return false;

    if (trimmed.toLowerCase().startsWith('intent:')) {
      final scheme = _extractIntentScheme(trimmed);
      if (scheme != null && allowedSchemes.contains(scheme.toLowerCase())) {
        final direct = _intentToAppUrl(trimmed, scheme);
        if (direct != null && await _tryLaunch(Uri.parse(direct))) {
          return true;
        }
      }

      final fallback = _extractIntentFallback(trimmed);
      if (fallback != null) {
        final fallbackUri = Uri.tryParse(fallback);
        if (fallbackUri != null &&
            (fallbackUri.scheme == 'https' || fallbackUri.scheme == 'http') &&
            await _tryLaunch(fallbackUri)) {
          return true;
        }
      }

      // Do not launch raw intent: or unknown schemes.
      return false;
    }

    final uri = Uri.tryParse(trimmed);
    if (uri == null) return false;
    final scheme = uri.scheme.toLowerCase();
    if (scheme == 'https' || scheme == 'http') {
      return _tryLaunch(uri);
    }
    if (!allowedSchemes.contains(scheme)) return false;
    return _tryLaunch(uri);
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
