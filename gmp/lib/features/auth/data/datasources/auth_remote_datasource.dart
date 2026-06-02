import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../models/login_response_model.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<Map<String, dynamic>> sendOTP(String mobile);
  Future<LoginResponseModel> verifyOTP(String mobile, String otp);
  Future<LoginResponseModel> loginWithEmail({
    required String email,
    required String password,
  });
  Future<LoginResponseModel> completeProfile({
    required String mobile,
    required String name,
    required DateTime dateOfBirth,
    required String gender,
    required String householdType,
    Map<String, dynamic>? location,
  });
  Future<UserModel> getCurrentUser(String accessToken);
  Future<void> logout(String refreshToken, String? accessToken);
  Future<String> refreshToken(String refreshToken); // Returns new access token
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final DioClient client;

  AuthRemoteDataSourceImpl({required this.client});

  /// Real device name for the "device-info" header / sessions list.
  /// Examples: "Motorola moto g60", "Samsung SM-G991B", "iPhone 14 Pro".
  Future<String> _deviceInfoHeaderValue() async {
    try {
      final deviceInfo = DeviceInfoPlugin();

      if (kIsWeb) {
        final web = await deviceInfo.webBrowserInfo;
        final browser = web.browserName.name;
        return browser.isNotEmpty ? 'Web ($browser)' : 'Web browser';
      }

      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
          final android = await deviceInfo.androidInfo;
          return _composeName(android.manufacturer, android.model, 'Android');
        case TargetPlatform.iOS:
          final ios = await deviceInfo.iosInfo;
          // utsname.machine -> identifier (e.g. iPhone15,2); name -> user device name.
          final model = ios.name.trim().isNotEmpty ? ios.name : ios.model;
          return model.trim().isNotEmpty ? model.trim() : 'iPhone / iPad';
        default:
          return 'This device';
      }
    } catch (_) {
      // Fallback to platform label if the plugin fails for any reason.
      if (kIsWeb) return 'Web browser';
      return defaultTargetPlatform == TargetPlatform.android
          ? 'Android'
          : defaultTargetPlatform == TargetPlatform.iOS
              ? 'iPhone / iPad'
              : 'This device';
    }
  }

  /// Combine manufacturer + model into a readable name, avoiding duplicates
  /// (e.g. manufacturer "samsung" + model "Galaxy S21" -> "Samsung Galaxy S21").
  String _composeName(String manufacturer, String model, String fallback) {
    final mfr = manufacturer.trim();
    final mdl = model.trim();
    if (mfr.isEmpty && mdl.isEmpty) return fallback;
    if (mfr.isEmpty) return mdl;
    if (mdl.isEmpty) return _capitalize(mfr);

    final mfrCap = _capitalize(mfr);
    // Avoid "Samsung Samsung ..." when model already contains manufacturer.
    if (mdl.toLowerCase().startsWith(mfr.toLowerCase())) {
      return mdl;
    }
    return '$mfrCap $mdl';
  }

  String _capitalize(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }

  @override
  Future<Map<String, dynamic>> sendOTP(String mobile) async {
    try {
      // Ensure mobile has + prefix if it doesn't
      String normalizedMobile = mobile.trim();
      if (normalizedMobile.isNotEmpty && !normalizedMobile.startsWith('+')) {
        // Add country code if missing (assuming India +91)
        normalizedMobile = '+91$normalizedMobile';
      }

      final response = await client.post(
        ApiEndpoints.sendOtp,
        body: {'mobile': normalizedMobile},
      );

      // Return response data which may include OTP in development mode
      final data = response['data'] as Map<String, dynamic>? ?? {};
      
      if (kDebugMode && data.containsKey('otp')) {
        // ignore: avoid_print
        print('DEBUG: OTP received from backend: ${data['otp']}');
      }
      
      return data;
    } catch (e) {
      if (e is NetworkException) {
        throw ServerException(e.message);
      }
      throw ServerException('Failed to send OTP: ${e.toString()}');
    }
  }

  @override
  Future<LoginResponseModel> verifyOTP(String mobile, String otp) async {
    try {
      // Ensure mobile has + prefix if it doesn't (must match the format used in sendOTP)
      String normalizedMobile = mobile.trim();
      if (normalizedMobile.isNotEmpty && !normalizedMobile.startsWith('+')) {
        normalizedMobile = '+91$normalizedMobile';
      }

      // Ensure OTP is a clean 6-digit string (remove any spaces or non-numeric chars)
      final cleanOtp = otp.trim().replaceAll(RegExp(r'[^0-9]'), '');

      final deviceInfo = await _deviceInfoHeaderValue();
      final response = await client.post(
        ApiEndpoints.verifyOtp,
        body: {
          'mobile': normalizedMobile,
          'otp': cleanOtp,
        },
        extraHeaders: {
          'device-info': deviceInfo,
        },
      );

      return LoginResponseModel.fromJson(response);
    } catch (e) {
      // Extract the actual error message from the exception
      String errorMessage = 'Failed to verify OTP';
      if (e.toString().contains('ServerException')) {
        errorMessage = e.toString().replaceFirst('ServerException: ', '');
      } else {
        errorMessage = e.toString();
      }
      throw ServerException(errorMessage);
    }
  }

  @override
  Future<LoginResponseModel> loginWithEmail({
    required String email,
    required String password,
  }) async {
    // Email login is not supported by the backend yet
    // Backend only supports mobile OTP authentication
    throw ServerException('Email login is not supported. Please use mobile OTP authentication.');
  }

  @override
  Future<LoginResponseModel> completeProfile({
    required String mobile,
    required String name,
    required DateTime dateOfBirth,
    required String gender,
    required String householdType,
    Map<String, dynamic>? location,
  }) async {
    try {
      // Ensure mobile has + prefix if it doesn't
      String normalizedMobile = mobile;
      if (mobile.isNotEmpty && !mobile.startsWith('+')) {
        normalizedMobile = '+91$mobile';
      }

      final body = <String, dynamic>{
        'mobile': normalizedMobile,
        'name': name,
        'dateOfBirth': dateOfBirth.toIso8601String().split('T')[0], // YYYY-MM-DD format
        'gender': gender.toLowerCase(),
        'householdType': householdType,
      };
      // Backend auth.validation only allows location: { lat, lng, address }
      if (location != null && location.isNotEmpty) {
        final loc = <String, dynamic>{};
        final lat = location['lat'];
        final lng = location['lng'];
        final address = location['address'];
        if (lat != null) loc['lat'] = lat is num ? lat : num.tryParse(lat.toString());
        if (lng != null) loc['lng'] = lng is num ? lng : num.tryParse(lng.toString());
        if (address != null &&
            address.toString().trim().isNotEmpty &&
            address.toString().trim().length <= 500) {
          loc['address'] = address.toString().trim();
        }
        loc.removeWhere((k, v) => v == null);
        if (loc.isNotEmpty) {
          body['location'] = loc;
        }
      }

      final response = await client.post(
        ApiEndpoints.completeProfile,
        body: body,
      );

      return LoginResponseModel.fromJson(response);
    } catch (e) {
      throw ServerException('Failed to complete profile: ${e.toString()}');
    }
  }

  @override
  Future<UserModel> getCurrentUser(String accessToken) async {
    try {
      final response = await client.get(
        ApiEndpoints.me,
        accessToken: accessToken,
      );

      if (response['success'] == true && response['data'] != null) {
        final userData = response['data']['user'] as Map<String, dynamic>;
        return UserModel.fromJson(userData);
      } else {
        throw ServerException(response['message'] ?? 'Failed to get user');
      }
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed to get user: ${e.toString()}');
    }
  }

  @override
  Future<void> logout(String refreshToken, String? accessToken) async {
    try {
      await client.post(
        ApiEndpoints.logout,
        body: {'refreshToken': refreshToken},
        accessToken: accessToken,
      );
    } catch (e) {
      // Even if logout fails, we should clear local storage
      throw ServerException('Failed to logout: ${e.toString()}');
    }
  }

  @override
  Future<String> refreshToken(String refreshToken) async {
    try {
      final response = await client.post(
        ApiEndpoints.refreshToken,
        body: {'refreshToken': refreshToken},
      );

      if (response['success'] != true) {
        throw ServerException(response['message'] ?? 'Failed to refresh token');
      }
      
      // Backend returns: { success: true, message: string, data: { accessToken: string, expiresIn: string } }
      final data = response['data'] as Map<String, dynamic>?;
      if (data == null || data['accessToken'] == null) {
        throw ServerException('Invalid refresh token response');
      }
      
      return data['accessToken'] as String;
    } catch (e) {
      if (e is ServerException) {
        rethrow;
      }
      throw ServerException('Failed to refresh token: ${e.toString()}');
    }
  }
}

