import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure Storage Service for tokens and sensitive data
class SecureStorageService {
  static final SecureStorageService _instance =
      SecureStorageService._internal();
  factory SecureStorageService() => _instance;

  SecureStorageService._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  // Keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'user_data';
  static const String deviceIdKey = 'device_id';
  static const String deviceAuthTokenKey = 'device_auth_token';
  static const String deviceAuthMobileKey = 'device_auth_mobile';
  static const String deviceAuthExpiresAtKey = 'device_auth_expires_at';
  static const String _userIdKey = 'user_id';
  static const String _userRoleKey = 'user_role';
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _isProfileCompleteKey = 'is_profile_complete';
  static const String _phoneNumberKey = 'phone_number';

  Future<void> write(String key, String? value) async {
    if (value == null) {
      await _storage.delete(key: key);
      return;
    }
    await _storage.write(key: key, value: value);
  }

  Future<String?> read(String key) async {
    return _storage.read(key: key);
  }

  Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }

  // Token Management
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      _storage.write(key: accessTokenKey, value: accessToken),
      _storage.write(key: refreshTokenKey, value: refreshToken),
      _storage.write(key: _isLoggedInKey, value: 'true'),
    ]);
  }

  Future<String?> getAccessToken() async {
    return await _storage.read(key: accessTokenKey);
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: refreshTokenKey);
  }

  Future<bool> hasValidToken() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  // User Info
  Future<void> saveUserInfo({
    required String userId,
    required String role,
    required bool isProfileComplete,
  }) async {
    await Future.wait([
      _storage.write(key: _userIdKey, value: userId),
      _storage.write(key: _userRoleKey, value: role),
      _storage.write(
          key: _isProfileCompleteKey, value: isProfileComplete.toString()),
    ]);
  }

  Future<String?> getUserId() async {
    return await _storage.read(key: _userIdKey);
  }

  Future<String?> getUserRole() async {
    return await _storage.read(key: _userRoleKey);
  }

  Future<bool> isProfileComplete() async {
    final value = await _storage.read(key: _isProfileCompleteKey);
    return value == 'true';
  }

  Future<void> setProfileComplete(bool value) async {
    await _storage.write(key: _isProfileCompleteKey, value: value.toString());
  }

  // Phone Number (for OTP flow)
  Future<void> savePhoneNumber(String phone) async {
    await _storage.write(key: _phoneNumberKey, value: phone);
  }

  Future<String?> getPhoneNumber() async {
    return await _storage.read(key: _phoneNumberKey);
  }

  // Auth Status
  Future<bool> isLoggedIn() async {
    final value = await _storage.read(key: _isLoggedInKey);
    return value == 'true';
  }

  // Clear all data (logout)
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  // Clear only auth tokens
  Future<void> clearTokens() async {
    await Future.wait([
      _storage.delete(key: accessTokenKey),
      _storage.delete(key: refreshTokenKey),
      _storage.write(key: _isLoggedInKey, value: 'false'),
    ]);
  }
}
