import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/constants/active_profile_header.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/exceptions.dart';

class SellListing {
  final String id;
  final String articleId;
  final String footwearType;
  final num originalRetailPrice;
  final String conditionGrade;
  final num basePrice;
  final String status;
  final String? rejectReason;
  final String brand;
  final String model;
  final String? imageUrl;

  const SellListing({
    required this.id,
    required this.articleId,
    required this.footwearType,
    required this.originalRetailPrice,
    required this.conditionGrade,
    required this.basePrice,
    required this.status,
    this.rejectReason,
    required this.brand,
    required this.model,
    this.imageUrl,
  });

  factory SellListing.fromJson(Map<String, dynamic> json) {
    final article = json['article'];
    final articleMap = article is Map
        ? Map<String, dynamic>.from(article)
        : <String, dynamic>{};
    final images = articleMap['images'];
    String? imageUrl;
    if (images is List && images.isNotEmpty) {
      final last = images.last;
      final value = last?.toString() ?? '';
      if (value.isNotEmpty) imageUrl = value;
    }
    return SellListing(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      articleId: (json['articleId'] ?? '').toString(),
      footwearType: (json['footwearType'] ?? 'everyday').toString(),
      originalRetailPrice: json['originalRetailPrice'] as num? ?? 0,
      conditionGrade: (json['conditionGrade'] ?? '').toString(),
      basePrice: json['basePrice'] as num? ?? 0,
      status: (json['status'] ?? 'pending').toString(),
      rejectReason: json['rejectReason']?.toString(),
      brand: (articleMap['brand'] ?? '').toString(),
      model: (articleMap['model'] ?? '').toString(),
      imageUrl: imageUrl,
    );
  }
}

class SellRemoteDataSource {
  static const Duration _timeout = Duration(seconds: 40);

  Map<String, String> _headers(String accessToken) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $accessToken',
      'X-App-Source': AppConstants.appSourceForApi,
      'X-App-Version': AppConstants.appVersion,
    };
    ActiveProfileHeader.applyTo(headers);
    return headers;
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.body.isEmpty) {
      throw const ServerException('Empty response from server');
    }
    try {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return json;
      }
      final message = json['message'] ?? 'Server error: ${response.statusCode}';
      throw ServerException(message.toString(), statusCode: response.statusCode);
    } on FormatException {
      throw const ServerException('Invalid response from server');
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Unexpected error: $e');
    }
  }

  Future<List<SellListing>> getMyListings(
    String accessToken, {
    String? footwearType,
  }) async {
    try {
      final uri = Uri.parse(ApiEndpoints.sellListings).replace(
        queryParameters: footwearType == null || footwearType.isEmpty
            ? null
            : {'footwearType': footwearType},
      );
      final response = await http
          .get(uri, headers: _headers(accessToken))
          .timeout(_timeout);
      final json = _handleResponse(response);
      final data = json['data'];
      final raw = data is Map ? data['listings'] : null;
      if (raw is! List) return [];
      return raw
          .whereType<Map>()
          .map((e) => SellListing.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Failed to load sell listings: $e');
    }
  }

  Future<String> uploadProof(
    String accessToken, {
    required String proofType,
    required List<int> imageBytes,
    required String fileName,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiEndpoints.sellUploadProof),
      );
      request.headers['Authorization'] = 'Bearer $accessToken';
      request.headers['X-App-Source'] = AppConstants.appSourceForApi;
      request.headers['X-App-Version'] = AppConstants.appVersion;
      request.headers['Accept'] = 'application/json';
      ActiveProfileHeader.applyTo(request.headers);
      request.fields['proofType'] = proofType;
      request.files.add(
        http.MultipartFile.fromBytes('file', imageBytes, filename: fileName),
      );
      final streamed = await request.send().timeout(_timeout);
      final response = await http.Response.fromStream(streamed);
      final json = _handleResponse(response);
      final data = json['data'];
      if (data is Map && data['imageUrl'] != null) {
        return data['imageUrl'].toString();
      }
      throw const ServerException('Invalid upload response');
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Failed to upload image: $e');
    }
  }

  Future<SellListing> createListing(
    String accessToken, {
    required String articleId,
    required String footwearType,
    required int originalRetailPrice,
    required String conditionGrade,
    required Map<String, String> proofs,
    required int basePrice,
    required DateTime auctionStartDate,
    required DateTime auctionEndDate,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse(ApiEndpoints.sellListings),
            headers: _headers(accessToken),
            body: jsonEncode({
              'articleId': articleId,
              'footwearType': footwearType,
              'originalRetailPrice': originalRetailPrice,
              'conditionGrade': conditionGrade,
              'proofs': proofs,
              'basePrice': basePrice,
              'auctionStartDate': auctionStartDate.toUtc().toIso8601String(),
              'auctionEndDate': auctionEndDate.toUtc().toIso8601String(),
            }),
          )
          .timeout(_timeout);
      final json = _handleResponse(response);
      final data = json['data'];
      final raw = data is Map ? data['listing'] : null;
      if (raw is! Map) {
        throw const ServerException('Submit failed');
      }
      return SellListing.fromJson(Map<String, dynamic>.from(raw));
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Failed to submit sell request: $e');
    }
  }
}
