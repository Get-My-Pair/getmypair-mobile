class ApiEndpoints {
  // Base URL Configuration
  // IMPORTANT: Update this based on your environment:
  // 
  // For Web/Chrome: 'http://localhost:3000'
  // For Android Emulator: 'http://10.0.2.2:3000' (maps to host's localhost)
  // For iOS Simulator: 'http://localhost:3000'
  // For Physical Device: 'http://YOUR_COMPUTER_IP:3000' (e.g., 'http://192.168.1.100:3000')
  //   - Find your IP: Windows (ipconfig), Mac/Linux (ifconfig)
  //   - Make sure your device and computer are on the same network
  //   - Make sure your backend server is running and accessible
  // For Production: 'https://your-api-domain.com'
  //
  // NOTE: If you see "No internet connection" error:
  // 1. Check if backend server is running on port 3000
  // 2. Verify the baseUrl matches your platform (see above)
  // 3. For physical devices, ensure firewall allows connections
  static const String baseUrl = 'http://localhost:3000';

  // Live demo: 'http://localhost:3000';
  // static const String baseUrl = 'http://localhost:3000';

  
  static const String apiPrefix = '/api/auth';
  
  // Auth endpoints (matching backend routes)
  static String get sendOtp => '$baseUrl$apiPrefix/send-otp';
  static String get verifyOtp => '$baseUrl$apiPrefix/verify-otp';
  static String get completeProfile => '$baseUrl$apiPrefix/complete-profile';
  static String get refreshToken => '$baseUrl$apiPrefix/refresh-token';
  static String get logout => '$baseUrl$apiPrefix/logout';
  static String get me => '$baseUrl$apiPrefix/me';
  
  // Note: Email login is not supported by backend yet
  // Backend only supports mobile OTP authentication
  // static String get loginWithEmail => '$baseUrl$apiPrefix/login';
  
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

