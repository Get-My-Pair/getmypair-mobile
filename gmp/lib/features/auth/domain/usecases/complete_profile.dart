import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class CompleteProfile {
  final AuthRepository repository;

  CompleteProfile(this.repository);

  Future<Either<Failure, User>> call({
    required String mobile,
    required String name,
    required DateTime dateOfBirth,
    required String gender,
    Map<String, dynamic>? location,
  }) async {
    return await repository.completeProfile(
      mobile: mobile,
      name: name,
      dateOfBirth: dateOfBirth,
      gender: gender,
      location: location,
    );
  }
}

