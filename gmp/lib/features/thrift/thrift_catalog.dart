import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

class ThriftProduct {
  final String id;
  final String title;
  final String brand;
  final String model;
  final String category;
  final String gender;
  final String color;
  final String size;
  final String condition;
  final String description;
  final double mrp;
  final double price;
  final double officePercent;
  final int discountPercent;
  final int stock;
  final List<String> images;

  const ThriftProduct({
    required this.id,
    required this.title,
    required this.brand,
    required this.model,
    required this.category,
    required this.gender,
    required this.color,
    required this.size,
    required this.condition,
    required this.description,
    required this.mrp,
    required this.price,
    required this.officePercent,
    required this.discountPercent,
    required this.stock,
    required this.images,
  });

  factory ThriftProduct.fromJson(Map<String, dynamic> json) {
    final rawImages = json['images'];
    return ThriftProduct(
      id: json['_id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Footwear',
      brand: json['brand']?.toString() ?? '',
      model: json['model']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      gender: json['gender']?.toString() ?? '',
      color: json['color']?.toString() ?? '',
      size: json['size']?.toString() ?? '',
      condition: json['condition']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      mrp: (json['mrp'] as num?)?.toDouble() ?? 0,
      price: (json['price'] as num?)?.toDouble() ?? 0,
      officePercent: (json['officePercent'] as num?)?.toDouble() ?? 0,
      discountPercent: (json['discountPercent'] as num?)?.toInt() ?? 0,
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      images: rawImages is List
          ? rawImages.map((e) => e.toString()).where((e) => e.isNotEmpty).toList()
          : const [],
    );
  }

  String get cover => images.isEmpty ? '' : images.first;

  String get conditionLabel {
    switch (condition) {
      case 'like_new':
        return 'Like new';
      case 'new':
        return 'New';
      case 'fair':
        return 'Fair';
      default:
        return 'Good';
    }
  }
}

class ThriftImage extends StatelessWidget {
  final String url;
  final BoxFit fit;

  const ThriftImage({super.key, required this.url, this.fit = BoxFit.cover});

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return const ColoredBox(
        color: Color(0xFFE6E6E6),
        child: Center(child: Icon(Icons.hiking, color: Color(0xFF0F6876))),
      );
    }
    if (url.startsWith('data:image')) {
      final comma = url.indexOf(',');
      if (comma < 0) return const SizedBox.shrink();
      try {
        final bytes = base64Decode(url.substring(comma + 1));
        return Image.memory(Uint8List.fromList(bytes), fit: fit, gaplessPlayback: true);
      } catch (_) {
        return const ColoredBox(color: Color(0xFFE6E6E6));
      }
    }
    return Image.network(
      url,
      fit: fit,
      errorBuilder: (_, _, _) => const ColoredBox(
        color: Color(0xFFE6E6E6),
        child: Center(child: Icon(Icons.image_not_supported)),
      ),
    );
  }
}

String thriftMoney(num value) {
  final rounded = value.round();
  return '₹$rounded';
}
