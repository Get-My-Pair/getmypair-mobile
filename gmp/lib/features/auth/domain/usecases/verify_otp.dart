import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/auth_repository.dart';

class VerifyOTP {
  final AuthRepository repository;

  VerifyOTP(this.repository);

  Future<Either<Failure, Map<String, dynamic>>> call({
    required String mobile,
    required String otp,
  }) async {
    return await repository.verifyOTP(mobile, otp);
  }
}

