/// API Configuration Constants
class ApiConfig {
  ApiConfig._();

  // Base URLs
  static const String baseUrl = 'https://api.getmypair.com/v1';
  static const String devBaseUrl = 'https://dev-api.getmypair.com/v1';

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);

  // Endpoints - Auth
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String sendOtp = '/auth/send-otp';
  static const String verifyOtp = '/auth/verify-otp';
  static const String resendOtp = '/auth/resend-otp';
  static const String refreshToken = '/auth/refresh-token';
  static const String logout = '/auth/logout';

  // Endpoints - Profile
  static const String profile = '/profile';
  static const String updateProfile = '/profile/update';
  static const String uploadDocument = '/profile/upload-document';

  // Endpoints - Customer
  static const String customerProfile = '/customer/profile';
  
  // Endpoints - Cobbler
  static const String cobblerProfile = '/cobbler/profile';
  static const String cobblerSkills = '/cobbler/skills';
  
  // Endpoints - Delivery
  static const String deliveryProfile = '/delivery/profile';
  static const String deliveryVehicleTypes = '/delivery/vehicle-types';

  // Endpoints - Admin
  static const String adminInvite = '/admin/invite';
  static const String adminVerifyInvite = '/admin/verify-invite';
}
