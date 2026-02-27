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
    Map<String, dynamic>? location,
  });
  Future<UserModel> getCurrentUser(String accessToken);
  Future<void> logout(String refreshToken, String? accessToken);
  Future<String> refreshToken(String refreshToken); // Returns new access token
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final DioClient client;

  AuthRemoteDataSourceImpl({required this.client});

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
      
      // Debug: Print OTP if available
      if (data.containsKey('otp')) {
        print('DEBUG: OTP received from backend: ${data['otp']}');
      }
      
      return data;
    } catch (e) {
<<<<<<< HEAD
=======
      if (e is NetworkException) {
        throw ServerException(e.message);
      }
>>>>>>> bc228505e51176217cbf52c32eac7f3f24271590
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

      final response = await client.post(
        ApiEndpoints.verifyOtp,
        body: {
          'mobile': normalizedMobile,
          'otp': cleanOtp,
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
      };
      if (location != null && location.isNotEmpty) {
        body['location'] = location;
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
      throw ServerException('Failed to refresh token: ${e.toString()}');
    }
  }
}

