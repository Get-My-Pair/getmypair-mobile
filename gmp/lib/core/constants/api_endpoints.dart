import 'package:flutter/foundation.dart';
import 'app_constants.dart';

/// API endpoints for getmypair-mobile.
/// Aligned with getmypair-api backend: /api/auth/*, /api/version.
class ApiEndpoints {
  // Base URL — getmypair-api backend
  // Production: Render.com hosted backend
  // Local: 'http://localhost:3000' (Web/iOS) or 'http://10.0.2.2:3000' (Android emulator)
  // Physical device: 'http://YOUR_IP:3000' (same network as backend)
  
  /// Get base URL based on environment
  static String get baseUrl {
    // In debug mode, you can use local backend for testing
    if (kDebugMode) {
      // Uncomment and set your local IP for testing on physical device:
      // return 'http://192.168.1.100:3000';
      // For emulator use: 'http://10.0.2.2:3000';
    }
    // Production backend (Render.com)
    return 'https://getmypair-api.onrender.com';
  }

  static const String apiPrefix = '/api/auth';

  /// Backend version (GET /api/version) — for display or compatibility checks.
  static String get version => '$baseUrl/api/version';

  // Auth endpoints (getmypair-api: server/src/routes/auth.routes.js)
  static String get sendOtp => '$baseUrl$apiPrefix/send-otp';
  static String get verifyOtp => '$baseUrl$apiPrefix/verify-otp';
  static String get completeProfile => '$baseUrl$apiPrefix/complete-profile';
  static String get refreshToken => '$baseUrl$apiPrefix/refresh-token';
  static String get logout => '$baseUrl$apiPrefix/logout';
  static String get me => '$baseUrl$apiPrefix/me';

  /// Headers for API calls. Includes app version and role (X-App-Source) for backend.
  static Map<String, String> getHeaders({String? accessToken}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'X-App-Source': AppConstants.appSourceForApi,
      'X-App-Version': AppConstants.appVersion,
    };

    if (accessToken != null) {
      headers['Authorization'] = 'Bearer $accessToken';
    }

    return headers;
  }
}

