import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/exceptions.dart';

import '../models/article_model.dart';

abstract class ArticleRemoteDataSource {
  Future<List<ArticleModel>> getMyArticles(String accessToken);
  Future<ArticleModel> getArticleById(String accessToken, String articleId);
  Future<ArticleModel> createArticle(String accessToken, {
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
  Future<ArticleModel> updateArticle(String accessToken, String articleId, {
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

class ArticleRemoteDataSourceImpl implements ArticleRemoteDataSource {
  static const Duration _timeout = Duration(seconds: 30);

  Map<String, String> _headers(String accessToken) => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $accessToken',
        'X-App-Source': AppConstants.appSourceForApi,
        'X-App-Version': AppConstants.appVersion,
      };

  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.body.isEmpty) {
      throw ServerException('Empty response from server');
    }
    try {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return json;
      }
      final message = json['message'] ?? 'Server error: ${response.statusCode}';
      throw ServerException(message, statusCode: response.statusCode);
    } on FormatException {
      throw ServerException('Invalid response from server');
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Unexpected error: $e');
    }
  }

  @override
  Future<List<ArticleModel>> getMyArticles(String accessToken) async {
    try {
      final response = await http
          .get(
            Uri.parse(ApiEndpoints.articlesMy),
            headers: _headers(accessToken),
          )
          .timeout(_timeout);
      final json = _handleResponse(response);

      // Backend may return { data: { articles: [...] } } or { data: [...] }
      final data = json['data'];
      if (data == null) return [];

      List<dynamic> list;
      if (data is List) {
        list = data;
      } else if (data is Map && data['articles'] != null) {
        list = data['articles'] as List<dynamic>;
      } else {
        list = [];
      }

      return list
          .map((e) => ArticleModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Failed to get articles: $e');
    }
  }

  @override
  Future<ArticleModel> getArticleById(String accessToken, String articleId) async {
    try {
      final response = await http
          .get(
            Uri.parse(ApiEndpoints.articleById(articleId)),
            headers: _headers(accessToken),
          )
          .timeout(_timeout);
      final json = _handleResponse(response);
      final data = json['data'];
      if (data == null) throw ServerException('Article not found');
      final article = data is Map
          ? Map<String, dynamic>.from(data as Map)
          : data['article'] as Map<String, dynamic>?;
      if (article == null) throw ServerException('Article not found');
      return ArticleModel.fromJson(article);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Failed to get article: $e');
    }
  }

  @override
  Future<ArticleModel> createArticle(String accessToken, {
    required String brand,
    required String model,
    required String category,
    required String color,
    int? purchaseYear,
    required String condition,
    required List<Map<String, dynamic>> materials,
    required List<String> imageUrls,
  }) async {
    try {
      final body = <String, dynamic>{
        'brand': brand,
        'model': model,
        'category': category,
        'color': color,
        'condition': condition,
        'materials': materials,
        'images': imageUrls,
      };
      if (purchaseYear != null) body['purchaseYear'] = purchaseYear;
      final response = await http
          .post(
            Uri.parse(ApiEndpoints.articlesCreate),
            headers: _headers(accessToken),
            body: jsonEncode(body),
          )
          .timeout(_timeout);
      final json = _handleResponse(response);
      final data = json['data'];
      if (data == null) throw ServerException('Create article failed');
      final article = data is Map
          ? Map<String, dynamic>.from(data as Map)
          : data['article'] as Map<String, dynamic>?;
      if (article == null) throw ServerException('Create article failed');
      return ArticleModel.fromJson(article);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Failed to create article: $e');
    }
  }

  @override
  Future<String> uploadArticleImage(String accessToken, {
    required List<int> imageBytes,
    required String fileName,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiEndpoints.articlesUploadImage),
      );
      request.headers['Authorization'] = 'Bearer $accessToken';
      request.headers['X-App-Source'] = AppConstants.appSourceForApi;
      request.headers['X-App-Version'] = AppConstants.appVersion;
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        imageBytes,
        filename: fileName,
      ));
      final streamedResponse = await request.send().timeout(_timeout);
      final response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final json = response.body.isNotEmpty
            ? (jsonDecode(response.body) as Map<String, dynamic>)
            : <String, dynamic>{};
        final message = json['message'] ?? 'Upload failed: ${response.statusCode}';
        throw ServerException(message, statusCode: response.statusCode);
      }
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final data = json['data'];
      if (data is String) return data;
      if (data is Map && data['url'] != null) return data['url'] as String;
      if (data is Map && data['image'] != null) return data['image'] as String;
      throw ServerException('Invalid upload response');
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Failed to upload image: $e');
    }
  }

  @override
  Future<ArticleModel> updateArticle(String accessToken, String articleId, {
    String? brand,
    String? model,
    String? category,
    String? color,
    int? purchaseYear,
    String? condition,
    List<Map<String, dynamic>>? materials,
    List<String>? imageUrls,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (brand != null) body['brand'] = brand;
      if (model != null) body['model'] = model;
      if (category != null) body['category'] = category;
      if (color != null) body['color'] = color;
      if (purchaseYear != null) body['purchaseYear'] = purchaseYear;
      if (condition != null) body['condition'] = condition;
      if (materials != null) body['materials'] = materials;
      if (imageUrls != null) body['images'] = imageUrls;
      final response = await http
          .put(
            Uri.parse(ApiEndpoints.articleUpdate(articleId)),
            headers: _headers(accessToken),
            body: jsonEncode(body),
          )
          .timeout(_timeout);
      final json = _handleResponse(response);
      final data = json['data'];
      if (data == null) throw ServerException('Update article failed');
      final article = data is Map
          ? Map<String, dynamic>.from(data as Map)
          : data['article'] as Map<String, dynamic>?;
      if (article == null) throw ServerException('Update article failed');
      return ArticleModel.fromJson(article);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Failed to update article: $e');
    }
  }

  @override
  Future<void> deleteArticle(String accessToken, String articleId) async {
    try {
      final response = await http
          .delete(
            Uri.parse(ApiEndpoints.articleDelete(articleId)),
            headers: _headers(accessToken),
          )
          .timeout(_timeout);
      _handleResponse(response);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Failed to delete article: $e');
    }
  }
}
