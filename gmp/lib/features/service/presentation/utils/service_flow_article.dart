/// Footwear selected at the start of a service request flow.
class ServiceFlowArticle {
  final String id;
  final String name;
  final String? subtitle;
  final String imageUrl;

  /// Article DB category code (e.g. boot, sandal) for CareMyPair filtering.
  final String category;

  const ServiceFlowArticle({
    required this.id,
    required this.name,
    this.subtitle,
    this.imageUrl = '',
    this.category = '',
  });
}
