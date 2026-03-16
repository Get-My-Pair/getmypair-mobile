import '../../domain/entities/article.dart';
import '../../domain/repositories/article_repository.dart';
import '../datasources/article_remote_datasource.dart';

class ArticleRepositoryImpl implements ArticleRepository {
  final ArticleRemoteDataSource remoteDataSource;

  ArticleRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<Article>> getMyArticles(String accessToken) async {
    return remoteDataSource.getMyArticles(accessToken);
  }

  @override
  Future<Article> getArticleById(String accessToken, String articleId) async {
    return remoteDataSource.getArticleById(accessToken, articleId);
  }

  @override
  Future<Article> createArticle(String accessToken, {
    required String brand,
    required String model,
    required String category,
    required String color,
    int? purchaseYear,
    required String condition,
    required List<Map<String, dynamic>> materials,
    required List<String> imageUrls,
  }) async {
    return remoteDataSource.createArticle(accessToken,
      brand: brand,
      model: model,
      category: category,
      color: color,
      purchaseYear: purchaseYear,
      condition: condition,
      materials: materials,
      imageUrls: imageUrls,
    );
  }

  @override
  Future<String> uploadArticleImage(String accessToken, {
    required String articleId,
    required List<int> imageBytes,
    required String fileName,
  }) async {
    return remoteDataSource.uploadArticleImage(accessToken,
      articleId: articleId,
      imageBytes: imageBytes,
      fileName: fileName,
    );
  }

  @override
  Future<Article> updateArticle(String accessToken, String articleId, {
    String? brand,
    String? model,
    String? category,
    String? color,
    int? purchaseYear,
    String? condition,
    List<Map<String, dynamic>>? materials,
    List<String>? imageUrls,
  }) async {
    return remoteDataSource.updateArticle(accessToken, articleId,
      brand: brand,
      model: model,
      category: category,
      color: color,
      purchaseYear: purchaseYear,
      condition: condition,
      materials: materials,
      imageUrls: imageUrls,
    );
  }

  @override
  Future<void> deleteArticle(String accessToken, String articleId) async {
    return remoteDataSource.deleteArticle(accessToken, articleId);
  }
}
