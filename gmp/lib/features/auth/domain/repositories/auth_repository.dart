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
  });
  Future<Either<Failure, User>> getCurrentUser();
  Future<Either<Failure, void>> logout();
  Future<Either<Failure, bool>> isAuthenticated();
  Future<Either<Failure, void>> refreshToken();
}

