import '../entities/user_profile.dart';
import '../repositories/profile_repository.dart';

class GetUserProfile {
  final ProfileRepository repository;
  GetUserProfile(this.repository);

  Future<UserProfile> call(String accessToken) =>
      repository.getProfile(accessToken);
}
