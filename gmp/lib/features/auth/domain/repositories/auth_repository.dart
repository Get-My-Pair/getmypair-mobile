import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/user.dart';

abstract class AuthRepository {
  Future<Either<Failure, Map<String, dynamic>>> sendOTP(String mobile);
  Future<Either<Failure, Map<String, dynamic>>> verifyOTP(String mobile, String otp);
  Future<Either<Failure, Map<String, dynamic>>> loginWithEmail({
    required String email,
    required String password,
  });
  Future<Either<Failure, User>> completeProfile({
    required String mobile,
    required String name,
    required DateTime dateOfBirth,
    required String gender,
    Map<String, dynamic>? location,
  });
  Future<Either<Failure, User>> getCurrentUser();
  Future<Either<Failure, void>> logout();
  Future<Either<Failure, bool>> isAuthenticated();
  Future<Either<Failure, void>> refreshToken();
  /// Returns a valid access token, refreshing if expired. Use for API calls to maintain login until refresh token expires.
  Future<Either<Failure, String>> getValidAccessToken();
  /// Clear tokens and user data locally only (no API call). Use on session expired; logout button uses logout().
  Future<Either<Failure, void>> clearSessionLocally();
}

