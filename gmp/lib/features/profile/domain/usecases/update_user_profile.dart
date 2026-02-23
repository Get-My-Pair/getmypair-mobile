import '../entities/user_profile.dart';
import '../repositories/profile_repository.dart';

class UpdateUserProfile {
  final ProfileRepository repository;
  UpdateUserProfile(this.repository);

  Future<UserProfile> call({
    required String accessToken,
    String? name,
    String? email,
  }) =>
      repository.updateProfile(
        accessToken: accessToken,
        name: name,
        email: email,
      );
}
