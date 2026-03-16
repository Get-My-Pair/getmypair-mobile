import '../entities/article.dart';
import '../repositories/article_repository.dart';

class UpdateArticle {
  final ArticleRepository repository;

  UpdateArticle(this.repository);

  Future<Article> call(String accessToken, String articleId, {
    String? brand,
    String? model,
    String? category,
    String? color,
    int? purchaseYear,
    String? condition,
    List<Map<String, dynamic>>? materials,
    List<String>? imageUrls,
  }) {
    return repository.updateArticle(accessToken, articleId,
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
}
