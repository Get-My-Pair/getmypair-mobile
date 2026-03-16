import '../repositories/article_repository.dart';

class UploadArticleImage {
  final ArticleRepository repository;

  UploadArticleImage(this.repository);

  Future<String> call(String accessToken, {
    required String articleId,
    required List<int> imageBytes,
    required String fileName,
  }) {
    return repository.uploadArticleImage(accessToken,
      articleId: articleId,
      imageBytes: imageBytes,
      fileName: fileName,
    );
  }
}
