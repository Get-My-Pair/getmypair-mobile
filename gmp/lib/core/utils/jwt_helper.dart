import 'dart:convert';

class JwtHelper {
  static bool isTokenExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;
      
      final payload = parts[1];
      final normalized = base64.normalize(payload);
      final decoded = utf8.decode(base64.decode(normalized));
      final payloadMap = json.decode(decoded) as Map<String, dynamic>;
      
      final exp = payloadMap['exp'] as int?;
      if (exp == null) return true;
      
      final expirationDate = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      return DateTime.now().isAfter(expirationDate);
    } catch (e) {
      return true;
    }
  }
  
  static DateTime? getTokenExpiration(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      
      final payload = parts[1];
      final normalized = base64.normalize(payload);
      final decoded = utf8.decode(base64.decode(normalized));
      final payloadMap = json.decode(decoded) as Map<String, dynamic>;
      
      final exp = payloadMap['exp'] as int?;
      if (exp == null) return null;
      
      return DateTime.fromMillisecondsSinceEpoch(exp * 1000);
    } catch (e) {
      return null;
    }
  }
}

