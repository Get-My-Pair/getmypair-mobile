import '../entities/article.dart';
import '../repositories/article_repository.dart';

class CreateArticle {
  final ArticleRepository repository;

  CreateArticle(this.repository);

  Future<Article> call(String accessToken, {
    required String brand,
    required String model,
    required String category,
    required String color,
    int? purchaseYear,
    required String condition,
    required List<Map<String, dynamic>> materials,
    required List<String> imageUrls,
    String? shoeSize,
  }) {
    return repository.createArticle(accessToken,
      brand: brand,
      model: model,
      category: category,
      color: color,
      purchaseYear: purchaseYear,
      condition: condition,
      materials: materials,
      imageUrls: imageUrls,
      shoeSize: shoeSize,
    );
  }
}
