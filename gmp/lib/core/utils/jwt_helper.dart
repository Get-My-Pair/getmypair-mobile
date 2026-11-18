import 'dart:convert';

class JwtHelper {
  static bool isTokenExpired(String token) {
    try {
      final payloadMap = _decodePayload(token);
      if (payloadMap == null) return true;

      final exp = payloadMap['exp'];
      final expSeconds = exp is int ? exp : (exp is num ? exp.toInt() : null);
      if (expSeconds == null) return true;

      final expirationDate =
          DateTime.fromMillisecondsSinceEpoch(expSeconds * 1000);
      return DateTime.now().isAfter(expirationDate);
    } catch (e) {
      return true;
    }
  }

  static DateTime? getTokenExpiration(String token) {
    try {
      final payloadMap = _decodePayload(token);
      if (payloadMap == null) return null;

      final exp = payloadMap['exp'];
      final expSeconds = exp is int ? exp : (exp is num ? exp.toInt() : null);
      if (expSeconds == null) return null;

      return DateTime.fromMillisecondsSinceEpoch(expSeconds * 1000);
    } catch (e) {
      return null;
    }
  }

  static Map<String, dynamic>? _decodePayload(String token) {
    final parts = token.split('.');
    if (parts.length != 3) return null;

    // JWTs use base64url (RFC 7515), not standard base64.
    final normalized = base64Url.normalize(parts[1]);
    final decoded = utf8.decode(base64Url.decode(normalized));
    final payloadMap = json.decode(decoded);
    if (payloadMap is Map<String, dynamic>) return payloadMap;
    if (payloadMap is Map) {
      return payloadMap.map((key, value) => MapEntry(key.toString(), value));
    }
    return null;
  }
}
