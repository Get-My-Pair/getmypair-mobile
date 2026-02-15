import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/auth_response_model.dart';
import '../models/user_model.dart';
import 'storage_service.dart';

class AuthService {
  final StorageService _storageService = StorageService();

  // Send OTP to mobile number
  Future<AuthResponse> sendOTP(String mobile) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.sendOtpUrl),
        headers: ApiConfig.getHeaders(),
        body: jsonEncode({'mobile': mobile}),
      );

      final jsonResponse = jsonDecode(response.body);
      return AuthResponse.fromJson(jsonResponse);
    } catch (e) {
      throw Exception('Failed to send OTP: ${e.toString()}');
    }
  }

  // Verify OTP
  Future<AuthResponse> verifyOTP(String mobile, String otp) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.verifyOtpUrl),
        headers: ApiConfig.getHeaders(),
        body: jsonEncode({
          'mobile': mobile,
          'otp': otp,
        }),
      );

      final jsonResponse = jsonDecode(response.body);
      final authResponse = AuthResponse.fromJson(jsonResponse);

      // If existing user, save tokens
      if (authResponse.data?.tokens != null) {
        await _storageService.saveTokens(authResponse.data!.tokens!);
        if (authResponse.data?.user != null) {
          await _storageService.saveUser(authResponse.data!.user!);
        }
      }

      return authResponse;
    } catch (e) {
      throw Exception('Failed to verify OTP: ${e.toString()}');
    }
  }

  // Complete profile for new user
  Future<AuthResponse> completeProfile({
    required String mobile,
    required String name,
    required DateTime dateOfBirth,
    required String gender,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.completeProfileUrl),
        headers: ApiConfig.getHeaders(),
        body: jsonEncode({
          'mobile': mobile,
          'name': name,
          'dateOfBirth': dateOfBirth.toIso8601String().split('T')[0], // YYYY-MM-DD format
          'gender': gender.toLowerCase(),
        }),
      );

      final jsonResponse = jsonDecode(response.body);
      final authResponse = AuthResponse.fromJson(jsonResponse);

      // Save tokens and user data
      if (authResponse.data?.tokens != null) {
        await _storageService.saveTokens(authResponse.data!.tokens!);
        if (authResponse.data?.user != null) {
          await _storageService.saveUser(authResponse.data!.user!);
        }
      }

      return authResponse;
    } catch (e) {
      throw Exception('Failed to complete profile: ${e.toString()}');
    }
  }

  // Get current user
  Future<User?> getCurrentUser() async {
    try {
      final accessToken = await _storageService.getAccessToken();
      if (accessToken == null) return null;

      final response = await http.get(
        Uri.parse(ApiConfig.meUrl),
        headers: ApiConfig.getHeaders(accessToken: accessToken),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          final user = User.fromJson(jsonResponse['data']['user']);
          await _storageService.saveUser(user);
          return user;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Refresh token
  Future<bool> refreshToken() async {
    try {
      final refreshToken = await _storageService.getRefreshToken();
      if (refreshToken == null) return false;

      final response = await http.post(
        Uri.parse(ApiConfig.refreshTokenUrl),
        headers: ApiConfig.getHeaders(),
        body: jsonEncode({'refreshToken': refreshToken}),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          final newAccessToken = jsonResponse['data']['accessToken'];
          await _storageService.saveAccessToken(newAccessToken);
          return true;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Logout
  Future<bool> logout() async {
    try {
      final accessToken = await _storageService.getAccessToken();
      final refreshToken = await _storageService.getRefreshToken();

      if (accessToken != null) {
        await http.post(
          Uri.parse(ApiConfig.logoutUrl),
          headers: ApiConfig.getHeaders(accessToken: accessToken),
          body: jsonEncode({'refreshToken': refreshToken}),
        );
      }

      await _storageService.clearAll();
      return true;
    } catch (e) {
      await _storageService.clearAll();
      return true; // Clear local storage even if API call fails
    }
  }

  // Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final accessToken = await _storageService.getAccessToken();
    return accessToken != null;
  }
}
