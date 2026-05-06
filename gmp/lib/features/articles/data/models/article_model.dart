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
    super.shoeSize,
    super.lastWornAt,
    super.lastShoeCareAt,
  });

  static String _stringId(dynamic v) {
    if (v == null) return '';
    if (v is String) return v;
    if (v is Map) {
      final o = v[r'$oid'] ?? v['oid'];
      if (o != null) return o.toString();
    }
    return v.toString();
  }

  static DateTime _parseDate(dynamic v) {
    if (v == null) return DateTime.now();
    if (v is Map) {
      final d = v[r'$date'] ?? v['date'];
      if (d != null) {
        return DateTime.tryParse(d.toString()) ?? DateTime.now();
      }
    }
    return DateTime.tryParse(v.toString()) ?? DateTime.now();
  }

  static DateTime? _parseDateNullable(dynamic v) {
    if (v == null) return null;
    if (v is Map) {
      final d = v[r'$date'] ?? v['date'];
      if (d != null) return DateTime.tryParse(d.toString());
    }
    return DateTime.tryParse(v.toString());
  }

  static String? _optionalString(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  static String _imageEntry(dynamic e) {
    if (e is String) return e;
    if (e is Map) {
      return (e['url'] ?? e['path'] ?? e['image'] ?? '').toString();
    }
    return e.toString();
  }

  factory ArticleModel.fromJson(Map<String, dynamic> json) {
    final materialsList = (json['materials'] as List<dynamic>? ?? [])
        .map((m) {
          final map = m is Map<String, dynamic> ? m : <String, dynamic>{};
          return ArticleMaterial(
            type: map['type'] as String? ?? '',
            percentage: (map['percentage'] as num?)?.toInt() ?? 0,
          );
        })
        .toList();
    final imagesList = (json['images'] as List<dynamic>? ?? [])
        .map(_imageEntry)
        .where((s) => s.isNotEmpty)
        .toList();

    return ArticleModel(
      id: _stringId(json['_id'] ?? json['id']),
      ownerId: _stringId(json['ownerId'] ?? json['owner'] ?? ''),
      brand: (json['brand'] ?? '').toString(),
      model: (json['model'] ?? '').toString(),
      category: (json['category'] ?? '').toString(),
      color: (json['color'] ?? '').toString(),
      purchaseYear: (json['purchaseYear'] as num?)?.toInt(),
      materials: materialsList,
      condition: (json['condition'] ?? '').toString(),
      images: imagesList,
      createdAt: _parseDate(json['createdAt']),
      shoeSize: _optionalString(
        json['shoeSize'] ?? json['size'] ?? json['usSize'] ?? json['sizeUs'],
      ),
      lastWornAt: _parseDateNullable(
        json['lastWornAt'] ?? json['lastWear'] ?? json['last_worn_at'],
      ),
      lastShoeCareAt: _parseDateNullable(
        json['lastShoeCareAt'] ??
            json['last_shoe_care_at'] ??
            json['shoeCareAt'] ??
            json['lastSentToShoeCare'],
      ),
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
      if (shoeSize != null) 'shoeSize': shoeSize,
      if (lastWornAt != null) 'lastWornAt': lastWornAt!.toIso8601String(),
      if (lastShoeCareAt != null) 'lastShoeCareAt': lastShoeCareAt!.toIso8601String(),
    };
  }
}
