import '../entities/article.dart';
import '../repositories/article_repository.dart';

class GetMyArticles {
  final ArticleRepository repository;

  GetMyArticles(this.repository);

  Future<List<Article>> call(String accessToken) {
    return repository.getMyArticles(accessToken);
  }
}
