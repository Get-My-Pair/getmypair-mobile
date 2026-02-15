class ApiConfig {
  // Update this with your backend server URL
  // For local development: 'http://localhost:3000'
  // For Android emulator: 'http://10.0.2.2:3000'
  // For iOS simulator: 'http://localhost:3000'
  // For physical device: 'http://YOUR_IP_ADDRESS:3000'
  static const String baseUrl = 'http://localhost:3000';
  
  static const String apiPrefix = '/api/auth';
  
  // Auth endpoints
  static String get sendOtpUrl => '$baseUrl$apiPrefix/send-otp';
  static String get verifyOtpUrl => '$baseUrl$apiPrefix/verify-otp';
  static String get completeProfileUrl => '$baseUrl$apiPrefix/complete-profile';
  static String get refreshTokenUrl => '$baseUrl$apiPrefix/refresh-token';
  static String get logoutUrl => '$baseUrl$apiPrefix/logout';
  static String get meUrl => '$baseUrl$apiPrefix/me';
  
  // Headers
  static Map<String, String> getHeaders({String? accessToken}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    if (accessToken != null) {
      headers['Authorization'] = 'Bearer $accessToken';
    }
    
    return headers;
  }
}
