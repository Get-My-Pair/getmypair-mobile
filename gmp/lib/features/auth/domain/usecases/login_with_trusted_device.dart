import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/auth_repository.dart';

class LoginWithTrustedDevice {
  final AuthRepository repository;

  LoginWithTrustedDevice(this.repository);

  Future<Either<Failure, Map<String, dynamic>>> call(String mobile) {
    return repository.loginWithTrustedDevice(mobile);
  }
}
