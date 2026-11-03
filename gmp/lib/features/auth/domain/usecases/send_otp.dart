import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/auth_repository.dart';

class SendOTP {
  final AuthRepository repository;

  SendOTP(this.repository);

  Future<Either<Failure, Map<String, dynamic>>> call(
    String mobile, {
    String? androidSmsHash,
  }) async {
    return await repository.sendOTP(mobile, androidSmsHash: androidSmsHash);
  }
}

