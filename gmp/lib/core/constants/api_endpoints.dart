import 'package:flutter/foundation.dart';
import 'app_constants.dart';

/// API endpoints for getmypair-mobile.
/// Aligned with getmypair-api backend: /api/auth/*, /api/version.
class ApiEndpoints {
  // Base URL — getmypair-api backend
  // Production: Render.com hosted backend
  // Local: 'http://localhost:3000' (Web/iOS) or 'http://10.0.2.2:3000' (Android emulator)
  // Physical device: 'http://YOUR_IP:3000' (same network as backend)
  // Web: browser may block requests (CORS). Prefer device/emulator for auth, or configure backend CORS.
  //
  // If Render still returns 403 on `/api/cobbler/profile/nearby`, deploy latest `getmypair-api` **or**
  // run the API locally and start the app with:
  //   flutter run --dart-define=USE_LOCAL_API=true
  // (Web: use http://localhost:PORT matching your server; configure CORS on the API.)

  static const bool _kUseLocalApi =
      bool.fromEnvironment('USE_LOCAL_API', defaultValue: false);

  /// Get base URL based on environment
  static String get baseUrl {
    if (kDebugMode && _kUseLocalApi) {
      return 'http://localhost:3000';
    }
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

  // Manage Devices (active sessions)
  static String get authSessions => '$baseUrl$apiPrefix/sessions';
  static String authSession(String sessionId) =>
      '$baseUrl$apiPrefix/sessions/$sessionId';

  // User Profile endpoints (getmypair-api: server/src/routes/userProfile.routes.js)
  // Profile row is created by POST /api/auth/complete-profile (see completeProfile above), not here.
  static const String userProfilePrefix = '/api/user/profile';
  static String get userProfileMe => '$baseUrl$userProfilePrefix/me';
  static String get userProfileUpdate => '$baseUrl$userProfilePrefix/update';
  static String get userProfileUploadImage =>
      '$baseUrl$userProfilePrefix/upload-image';
  static String get userProfileAddAddress =>
      '$baseUrl$userProfilePrefix/address/add';
  static String get userProfileUpdateAddress =>
      '$baseUrl$userProfilePrefix/address/update';
  static String userProfileDeleteAddress(String addressId) =>
      '$baseUrl$userProfilePrefix/address/delete/$addressId';

  // Articles (Module 3 – Digital Shoe Passport)
  static const String articlesPrefix = '/api/articles';
  static String get articlesMy => '$baseUrl$articlesPrefix/my';
  static String articleById(String id) => '$baseUrl$articlesPrefix/$id';
  static String get articlesCreate => '$baseUrl$articlesPrefix/create';
  static String articleUpdate(String id) =>
      '$baseUrl$articlesPrefix/update/$id';
  static String articleDelete(String id) =>
      '$baseUrl$articlesPrefix/delete/$id';
  static String get articlesUploadImage =>
      '$baseUrl$articlesPrefix/upload-image';

  // Module 4 – Service Requests
  static const String servicePrefix = '/api/service';
  static String get serviceCreate => '$baseUrl$servicePrefix/create';
  static String get serviceMy => '$baseUrl$servicePrefix/my';
  static String get serviceEstimationDefaults => '$baseUrl$servicePrefix/estimation-defaults';
  static String serviceById(String requestId) =>
      '$baseUrl$servicePrefix/$requestId';
  static String get serviceUpdateStatus =>
      '$baseUrl$servicePrefix/update-status';
  static String serviceCancel(String requestId) =>
      '$baseUrl$servicePrefix/cancel/$requestId';
  static String get serviceUploadMedia => '$baseUrl$servicePrefix/upload-media';
  static String get serviceUploadProofImage =>
      '$baseUrl$servicePrefix/upload-proof/image';
  static String get serviceUploadProofVideo =>
      '$baseUrl$servicePrefix/upload-proof/video';
  static String get serviceRespondActualCost =>
      '$baseUrl$servicePrefix/respond-actual-cost';

  // Cobblers for customer nearby discovery
  /// Query must match backend `GET /api/cobbler/profile/nearby` (auth + role checks on server).
  static String cobblerNearby({
    required double lat,
    required double lng,
    required double radiusKm,
  }) {
    return Uri.parse('$baseUrl/api/cobbler/profile/nearby').replace(
      queryParameters: <String, String>{
        'lat': '$lat',
        'lng': '$lng',
        'radiusKm': '$radiusKm',
      },
    ).toString();
  }

  /// Public reverse geocode (GET) — no auth. Query: lat, lon (matches backend).
  static String geocodeReverse(double lat, double lon) =>
      '$baseUrl/api/geocode/reverse?lat=$lat&lon=$lon';

  /// Optional: list addresses only (`GET /api/user/profile/addresses`).
  static String get userProfileAddresses =>
      '$baseUrl$userProfilePrefix/addresses';

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
