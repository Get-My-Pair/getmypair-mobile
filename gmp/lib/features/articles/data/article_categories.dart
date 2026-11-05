import 'package:gmp/core/constants/api_endpoints.dart';
import 'package:gmp/core/network/dio_client.dart';
import 'package:gmp/injection_container.dart';

/// Fallback when Article DB API is unavailable (matches Masteradmin list).
const List<Map<String, String>> kDefaultArticleCategories = [
  {'value': 'formal_shoes', 'label': 'Formal Shoes'},
  {'value': 'casual_shoes', 'label': 'Casual Shoes'},
  {'value': 'sports_shoes', 'label': 'Sports Shoes'},
  {'value': 'safety_shoes', 'label': 'Safety Shoes'},
  {'value': 'leather_sandals', 'label': 'Leather Sandals'},
  {'value': 'flip_flops', 'label': 'Flip Flops'},
  {'value': 'womens_heels', 'label': "Women's Heels"},
  {'value': 'boots', 'label': 'Boots'},
  {'value': 'childrens_shoes', 'label': "Children's Shoes"},
  {'value': 'orthopedic_shoes', 'label': 'Orthopedic Shoes'},
  {'value': 'traditional_footwear', 'label': 'Traditional Footwear'},
];

/// Loads active categories from Masteradmin Article DB.
Future<List<Map<String, String>>> fetchArticleCategories(String accessToken) async {
  try {
    final json = await sl<DioClient>().get(
      ApiEndpoints.articlesCategories,
      accessToken: accessToken,
    );
    final data = (json['data'] is Map<String, dynamic>)
        ? json['data'] as Map<String, dynamic>
        : <String, dynamic>{};
    final list = (data['items'] ?? json['items']) as List<dynamic>? ?? const [];
    final out = <Map<String, String>>[];
    for (final raw in list.whereType<Map>()) {
      final map = Map<String, dynamic>.from(raw);
      if (map['isActive'] == false) continue;
      final value = (map['code'] ?? map['value'] ?? '').toString().trim().toLowerCase();
      final label = (map['label'] ?? map['name'] ?? value).toString().trim();
      if (value.isEmpty || label.isEmpty) continue;
      out.add({'value': value, 'label': label});
    }
    if (out.isNotEmpty) return out;
  } catch (_) {}
  return List<Map<String, String>>.from(kDefaultArticleCategories);
}
