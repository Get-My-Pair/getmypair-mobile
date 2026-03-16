import '../entities/article.dart';

abstract class ArticleRepository {
  Future<List<Article>> getMyArticles(String accessToken);
  Future<Article> getArticleById(String accessToken, String articleId);
  Future<Article> createArticle(String accessToken, {
    required String brand,
    required String model,
    required String category,
    required String color,
    int? purchaseYear,
    required String condition,
    required List<Map<String, dynamic>> materials,
    required List<String> imageUrls,
  });
  Future<String> uploadArticleImage(String accessToken, {
    required List<int> imageBytes,
    required String fileName,
  });
  Future<Article> updateArticle(String accessToken, String articleId, {
    String? brand,
    String? model,
    String? category,
    String? color,
    int? purchaseYear,
    String? condition,
    List<Map<String, dynamic>>? materials,
    List<String>? imageUrls,
  });
  Future<void> deleteArticle(String accessToken, String articleId);
}
