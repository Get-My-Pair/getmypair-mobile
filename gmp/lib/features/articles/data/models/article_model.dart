import '../../domain/entities/article.dart';

class ArticleModel extends Article {
  const ArticleModel({
    required super.id,
    required super.ownerId,
    required super.brand,
    required super.model,
    required super.category,
    required super.color,
    super.purchaseYear,
    super.materials,
    required super.condition,
    super.images,
    required super.createdAt,
  });

  factory ArticleModel.fromJson(Map<String, dynamic> json) {
    final materialsList = (json['materials'] as List<dynamic>? ?? [])
        .map((m) {
          final map = m as Map<String, dynamic>;
          return ArticleMaterial(
            type: map['type'] as String? ?? '',
            percentage: (map['percentage'] as num?)?.toInt() ?? 0,
          );
        })
        .toList();
    final imagesList =
        (json['images'] as List<dynamic>? ?? []).map((e) => e.toString()).toList();

    return ArticleModel(
      id: json['_id'] ?? json['id'] ?? '',
      ownerId: json['ownerId'] ?? '',
      brand: json['brand'] ?? '',
      model: json['model'] ?? '',
      category: json['category'] ?? '',
      color: json['color'] ?? '',
      purchaseYear: (json['purchaseYear'] as num?)?.toInt(),
      materials: materialsList,
      condition: json['condition'] ?? '',
      images: imagesList,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'ownerId': ownerId,
      'brand': brand,
      'model': model,
      'category': category,
      'color': color,
      'purchaseYear': purchaseYear,
      'materials': materials.map((m) => {'type': m.type, 'percentage': m.percentage}).toList(),
      'condition': condition,
      'images': images,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
