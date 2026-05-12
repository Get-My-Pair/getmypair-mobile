import 'package:equatable/equatable.dart';

/// Material composition entry for an article (shoe).
class ArticleMaterial extends Equatable {
  final String type;
  final int percentage;

  const ArticleMaterial({required this.type, required this.percentage});

  @override
  List<Object?> get props => [type, percentage];
}

/// Article entity – a registered shoe (digital asset).
class Article extends Equatable {
  final String id;
  final String ownerId;
  final String brand;
  final String model;
  final String category;
  final String color;
  final int? purchaseYear;
  final List<ArticleMaterial> materials;
  final String condition;
  final List<String> images;
  final DateTime createdAt;

  /// Shoe size from API when provided (e.g. `"06"`, `"US 9"`).
  final String? shoeSize;
  final DateTime? lastWornAt;
  final DateTime? lastShoeCareAt;

  const Article({
    required this.id,
    required this.ownerId,
    required this.brand,
    required this.model,
    required this.category,
    required this.color,
    this.purchaseYear,
    this.materials = const [],
    required this.condition,
    this.images = const [],
    required this.createdAt,
    this.shoeSize,
    this.lastWornAt,
    this.lastShoeCareAt,
  });

  /// First image URL for list thumbnail, or null if no images.
  String? get thumbnailImage =>
      images.isNotEmpty ? images.first : null;

  /// Same primary photo as rack article details and service flows: latest upload when present.
  String? get rackHeroImagePath =>
      images.isNotEmpty ? images.last : thumbnailImage;

  @override
  List<Object?> get props => [
        id,
        ownerId,
        brand,
        model,
        category,
        color,
        purchaseYear,
        materials,
        condition,
        images,
        createdAt,
        shoeSize,
        lastWornAt,
        lastShoeCareAt,
      ];
}
