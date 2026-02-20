class AppConstants {
  // App Info (align with pubspec.yaml version)
  static const String appName = 'GetMyPair';
  static const String appVersion = '1.0.0';

  /// Sent as X-App-Source to backend for role assignment (USER_APP -> user role).
  static const String appSourceForApi = 'USER_APP';
  
  // Storage Keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'user_data';
  
  // Validation
  static const int minNameLength = 2;
  static const int maxNameLength = 100;
  static const int minMobileLength = 10;
  static const int otpLength = 6;
  static const int resendOtpDelaySeconds = 60;
  
  // Date
  static const int minAge = 18;
  static const int maxAge = 100;
  
  // API Configuration
  // Backend server runs on port 3000 by default
  // Update ApiEndpoints.baseUrl for different environments
  static const String defaultApiBaseUrl = 'https://getmypair-api.onrender.com';
  
  // Backend API Response Format
  // Success: { success: true, message: string, data?: object }
  // Error: { success: false, message: string, statusCode: number, errors?: array }
}
