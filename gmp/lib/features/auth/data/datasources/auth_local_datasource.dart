import 'dart:convert';
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
  Future<void> clearAll();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final SharedPreferences sharedPreferences;

  AuthLocalDataSourceImpl({required this.sharedPreferences});

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
      await sharedPreferences.remove(AppConstants.accessTokenKey);
      await sharedPreferences.remove(AppConstants.refreshTokenKey);
      await sharedPreferences.remove(AppConstants.userKey);
    } catch (e) {
      throw CacheException('Failed to clear storage: ${e.toString()}');
    }
  }
}

