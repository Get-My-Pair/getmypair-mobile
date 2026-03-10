import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/auth_repository.dart';

/// Clears tokens and user data locally only (no logout API call).
/// Use when session has expired (refresh failed); for explicit logout use Logout use case.
class ClearSessionLocally {
  final AuthRepository repository;

  ClearSessionLocally(this.repository);

  Future<Either<Failure, void>> call() async {
    return await repository.clearSessionLocally();
  }
}
