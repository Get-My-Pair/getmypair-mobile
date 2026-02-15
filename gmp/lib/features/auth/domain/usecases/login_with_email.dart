import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/auth_repository.dart';

class LoginWithEmail {
  final AuthRepository repository;

  LoginWithEmail(this.repository);

  Future<Either<Failure, Map<String, dynamic>>> call({
    required String email,
    required String password,
  }) async {
    return await repository.loginWithEmail(email: email, password: password);
  }
}

