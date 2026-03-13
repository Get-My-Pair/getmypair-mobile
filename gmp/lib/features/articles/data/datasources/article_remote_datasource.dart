import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/article_model.dart';

abstract class ArticleRemoteDataSource {
  Future<List<ArticleModel>> getMyArticles(String accessToken);
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
}
