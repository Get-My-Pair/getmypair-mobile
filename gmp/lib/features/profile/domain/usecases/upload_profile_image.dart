import 'dart:typed_data';
import '../repositories/profile_repository.dart';

class UploadProfileImage {
  final ProfileRepository repository;
  UploadProfileImage(this.repository);

  Future<String> call({
    required String accessToken,
    required Uint8List imageBytes,
    required String fileName,
  }) =>
      repository.uploadProfileImage(
        accessToken: accessToken,
        imageBytes: imageBytes,
        fileName: fileName,
      );
}
