import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/auth_repository.dart';

class SendOTP {
  final AuthRepository repository;

  SendOTP(this.repository);

  Future<Either<Failure, void>> call(String mobile) async {
    return await repository.sendOTP(mobile);
  }
}

