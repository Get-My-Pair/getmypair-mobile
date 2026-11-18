import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

import '../../../core/constants/active_profile_header.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/exceptions.dart';

class DonateRequestItem {
  final String id;
  final String imageUrl;
  final String note;
  final String status;
  final String? rejectReason;

  const DonateRequestItem({
    required this.id,
    required this.imageUrl,
    required this.note,
    required this.status,
    this.rejectReason,
  });

  factory DonateRequestItem.fromJson(Map<String, dynamic> json) {
    return DonateRequestItem(
      id: (json['_id'] ?? '').toString(),
      imageUrl: (json['imageUrl'] ?? '').toString(),
      note: (json['note'] ?? '').toString(),
      status: (json['status'] ?? 'pending').toString(),
      rejectReason: json['rejectReason']?.toString(),
    );
  }
}

class DonateRemoteDataSource {
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
      if (response.statusCode >= 200 && response.statusCode < 300) return json;
      final message = json['message'] ?? 'Server error: ${response.statusCode}';
      throw ServerException(message.toString(), statusCode: response.statusCode);
    } on FormatException {
      throw const ServerException('Invalid response from server');
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Unexpected error: $e');
    }
  }

  Future<String> uploadImage(
    String accessToken, {
    required List<int> imageBytes,
    required String fileName,
  }) async {
    final request = http.MultipartRequest('POST', Uri.parse(ApiEndpoints.donateUploadImage));
    request.headers['Authorization'] = 'Bearer $accessToken';
    request.headers['X-App-Source'] = AppConstants.appSourceForApi;
    request.headers['X-App-Version'] = AppConstants.appVersion;
    request.headers['Accept'] = 'application/json';
    ActiveProfileHeader.applyTo(request.headers);
    final mimeStr = lookupMimeType(fileName);
    MediaType? contentType;
    if (mimeStr != null && mimeStr.contains('/')) {
      final parts = mimeStr.split('/');
      contentType = MediaType(parts.first, parts.last);
    }
    request.files.add(
      http.MultipartFile.fromBytes('file', imageBytes, filename: fileName, contentType: contentType),
    );
    final streamed = await request.send().timeout(_timeout);
    final response = await http.Response.fromStream(streamed);
    final json = _handleResponse(response);
    final data = json['data'];
    if (data is Map && data['imageUrl'] != null) return data['imageUrl'].toString();
    throw const ServerException('Invalid upload response');
  }

  Future<List<DonateRequestItem>> getMine(String accessToken) async {
    final response = await http
        .get(Uri.parse(ApiEndpoints.donateRequests), headers: _headers(accessToken))
        .timeout(_timeout);
    final json = _handleResponse(response);
    final data = json['data'];
    final raw = data is Map ? data['requests'] : null;
    if (raw is! List) return [];
    return raw.whereType<Map>().map((e) => DonateRequestItem.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<DonateRequestItem> createRequest(
    String accessToken, {
    required String imageUrl,
    String note = '',
  }) async {
    final response = await http
        .post(
          Uri.parse(ApiEndpoints.donateRequests),
          headers: _headers(accessToken),
          body: jsonEncode({'imageUrl': imageUrl, 'note': note}),
        )
        .timeout(_timeout);
    final json = _handleResponse(response);
    final data = json['data'];
    final request = data is Map ? data['request'] : null;
    if (request is! Map) throw const ServerException('Invalid donate response');
    return DonateRequestItem.fromJson(Map<String, dynamic>.from(request));
  }
}
