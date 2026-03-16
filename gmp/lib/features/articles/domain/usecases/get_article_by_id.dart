import '../entities/article.dart';
import '../repositories/article_repository.dart';

class GetArticleById {
  final ArticleRepository repository;

  GetArticleById(this.repository);

  Future<Article> call(String accessToken, String articleId) {
    return repository.getArticleById(accessToken, articleId);
  }
}
