import 'dart:convert';
import 'dart:math';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/login_response_model.dart';
import '../models/user_model.dart';

abstract class AuthLocalDataSource {
  Future<void> saveTokens(Tokens tokens);
  Future<void> saveAccessToken(String token);
  Future<String?> getAccessToken();
  Future<String?> getRefreshToken();
  Future<void> saveUser(UserModel user);
  Future<UserModel?> getUser();
  /// Clears session tokens/user only. Keeps device trust for silent re-login.
  Future<void> clearAll();
  Future<String> getOrCreateDeviceId();
  Future<void> saveDeviceAuth({
    required String mobile,
    required String deviceId,
    required String deviceAuthToken,
    DateTime? expiresAt,
  });
  Future<DeviceAuthCredential?> getDeviceAuthForMobile(String mobile);
  Future<void> clearDeviceAuth();
}

class DeviceAuthCredential {
  final String mobile;
  final String deviceId;
  final String deviceAuthToken;
  final DateTime? expiresAt;

  const DeviceAuthCredential({
    required this.mobile,
    required this.deviceId,
    required this.deviceAuthToken,
    this.expiresAt,
  });

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final SharedPreferences sharedPreferences;

  AuthLocalDataSourceImpl({required this.sharedPreferences});

  String _normalizeMobileKey(String mobile) {
    final digits = mobile.trim().replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length >= 10) return digits.substring(digits.length - 10);
    return digits;
  }

  @override
  Future<void> saveTokens(Tokens tokens) async {
    try {
      await sharedPreferences.setString(AppConstants.accessTokenKey, tokens.accessToken);
      await sharedPreferences.setString(AppConstants.refreshTokenKey, tokens.refreshToken);
    } catch (e) {
      throw CacheException('Failed to save tokens: ${e.toString()}');
    }
  }

  @override
  Future<void> saveAccessToken(String token) async {
    try {
      await sharedPreferences.setString(AppConstants.accessTokenKey, token);
    } catch (e) {
      throw CacheException('Failed to save access token: ${e.toString()}');
    }
  }

  @override
  Future<String?> getAccessToken() async {
    try {
      return sharedPreferences.getString(AppConstants.accessTokenKey);
    } catch (e) {
      throw CacheException('Failed to get access token: ${e.toString()}');
    }
  }

  @override
  Future<String?> getRefreshToken() async {
    try {
      return sharedPreferences.getString(AppConstants.refreshTokenKey);
    } catch (e) {
      throw CacheException('Failed to get refresh token: ${e.toString()}');
    }
  }

  @override
  Future<void> saveUser(UserModel user) async {
    try {
      await sharedPreferences.setString(AppConstants.userKey, jsonEncode(user.toJson()));
    } catch (e) {
      throw CacheException('Failed to save user: ${e.toString()}');
    }
  }

  @override
  Future<UserModel?> getUser() async {
    try {
      final userJson = sharedPreferences.getString(AppConstants.userKey);
      if (userJson != null) {
        return UserModel.fromJson(jsonDecode(userJson));
      }
      return null;
    } catch (e) {
      throw CacheException('Failed to get user: ${e.toString()}');
    }
  }

  @override
  Future<void> clearAll() async {
    try {
      // Session only — retain deviceId + deviceAuth across logout/login.
      await sharedPreferences.remove(AppConstants.accessTokenKey);
      await sharedPreferences.remove(AppConstants.refreshTokenKey);
      await sharedPreferences.remove(AppConstants.userKey);
    } catch (e) {
      throw CacheException('Failed to clear storage: ${e.toString()}');
    }
  }

  @override
  Future<String> getOrCreateDeviceId() async {
    try {
      final existing = sharedPreferences.getString(AppConstants.deviceIdKey);
      if (existing != null && existing.trim().length >= 8) {
        return existing.trim();
      }

      String generated = '';
      try {
        final plugin = DeviceInfoPlugin();
        if (!kIsWeb) {
          switch (defaultTargetPlatform) {
            case TargetPlatform.android:
              final android = await plugin.androidInfo;
              generated = (android.id).trim();
              break;
            case TargetPlatform.iOS:
              final ios = await plugin.iosInfo;
              generated = (ios.identifierForVendor ?? '').trim();
              break;
            default:
              break;
          }
        }
      } catch (_) {}

      if (generated.length < 8 || generated.toLowerCase() == 'unknown') {
        final rand = Random.secure();
        final bytes = List<int>.generate(16, (_) => rand.nextInt(256));
        generated = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
      }

      await sharedPreferences.setString(AppConstants.deviceIdKey, generated);
      return generated;
    } catch (e) {
      throw CacheException('Failed to get device id: ${e.toString()}');
    }
  }

  @override
  Future<void> saveDeviceAuth({
    required String mobile,
    required String deviceId,
    required String deviceAuthToken,
    DateTime? expiresAt,
  }) async {
    try {
      await sharedPreferences.setString(
        AppConstants.deviceAuthMobileKey,
        _normalizeMobileKey(mobile),
      );
      await sharedPreferences.setString(AppConstants.deviceIdKey, deviceId);
      await sharedPreferences.setString(
        AppConstants.deviceAuthTokenKey,
        deviceAuthToken,
      );
      if (expiresAt != null) {
        await sharedPreferences.setString(
          AppConstants.deviceAuthExpiresAtKey,
          expiresAt.toIso8601String(),
        );
      }
    } catch (e) {
      throw CacheException('Failed to save device auth: ${e.toString()}');
    }
  }

  @override
  Future<DeviceAuthCredential?> getDeviceAuthForMobile(String mobile) async {
    try {
      final storedMobile = sharedPreferences.getString(AppConstants.deviceAuthMobileKey);
      final token = sharedPreferences.getString(AppConstants.deviceAuthTokenKey);
      final deviceId = sharedPreferences.getString(AppConstants.deviceIdKey);
      if (storedMobile == null ||
          token == null ||
          token.isEmpty ||
          deviceId == null ||
          deviceId.isEmpty) {
        return null;
      }
      if (_normalizeMobileKey(storedMobile) != _normalizeMobileKey(mobile)) {
        return null;
      }

      DateTime? expiresAt;
      final expRaw = sharedPreferences.getString(AppConstants.deviceAuthExpiresAtKey);
      if (expRaw != null && expRaw.isNotEmpty) {
        expiresAt = DateTime.tryParse(expRaw);
      }

      final cred = DeviceAuthCredential(
        mobile: storedMobile,
        deviceId: deviceId,
        deviceAuthToken: token,
        expiresAt: expiresAt,
      );
      if (cred.isExpired) return null;
      return cred;
    } catch (e) {
      throw CacheException('Failed to get device auth: ${e.toString()}');
    }
  }

  @override
  Future<void> clearDeviceAuth() async {
    try {
      await sharedPreferences.remove(AppConstants.deviceAuthTokenKey);
      await sharedPreferences.remove(AppConstants.deviceAuthMobileKey);
      await sharedPreferences.remove(AppConstants.deviceAuthExpiresAtKey);
      // Keep deviceId so the same install identity is reused after re-OTP.
    } catch (e) {
      throw CacheException('Failed to clear device auth: ${e.toString()}');
    }
  }
}
