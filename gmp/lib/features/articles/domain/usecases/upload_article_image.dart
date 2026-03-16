import '../repositories/article_repository.dart';

class UploadArticleImage {
  final ArticleRepository repository;

  UploadArticleImage(this.repository);

  Future<String> call(String accessToken, {
    required List<int> imageBytes,
    required String fileName,
  }) {
    return repository.uploadArticleImage(accessToken,
      imageBytes: imageBytes,
      fileName: fileName,
    );
  }
}
