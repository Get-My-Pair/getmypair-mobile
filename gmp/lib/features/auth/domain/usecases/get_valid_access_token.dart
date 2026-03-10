import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/auth_repository.dart';

/// Returns a valid access token, refreshing if expired.
/// Use for API calls so the user stays logged in until refresh token expires.
class GetValidAccessToken {
  final AuthRepository repository;

  GetValidAccessToken(this.repository);

  Future<Either<Failure, String>> call() async {
    return await repository.getValidAccessToken();
  }
}
