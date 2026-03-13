import '../entities/article.dart';

abstract class ArticleRepository {
  Future<List<Article>> getMyArticles(String accessToken);
}
