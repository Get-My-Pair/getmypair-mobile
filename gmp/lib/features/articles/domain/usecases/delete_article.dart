import '../repositories/article_repository.dart';

class DeleteArticle {
  final ArticleRepository repository;

  DeleteArticle(this.repository);

  Future<void> call(String accessToken, String articleId) {
    return repository.deleteArticle(accessToken, articleId);
  }
}
