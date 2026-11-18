import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

import '../../../core/constants/active_profile_header.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/exceptions.dart';

const List<({String value, String label})> kRentDurations = [
  (value: 'week', label: '1 week'),
  (value: 'month', label: '1 month'),
  (value: '3month', label: '3 months'),
  (value: '6month', label: '6 months'),
  (value: '1year', label: '1 year'),
];

String rentDurationLabel(String value) {
  for (final item in kRentDurations) {
    if (item.value == value) return item.label;
  }
  return value;
}

class RentListing {
  final String id;
  final String ownerId;
  final String title;
  final String imageUrl;
  final String duration;
  final String durationLabel;
  final num price;
  final String status;
  final String? rejectReason;
  final String ownerName;
  final int requestCount;

  const RentListing({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.imageUrl,
    required this.duration,
    required this.durationLabel,
    required this.price,
    required this.status,
    this.rejectReason,
    this.ownerName = '',
    this.requestCount = 0,
  });

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';

  factory RentListing.fromJson(Map<String, dynamic> json) {
    final owner = json['owner'];
    final ownerMap = owner is Map
        ? Map<String, dynamic>.from(owner)
        : <String, dynamic>{};
    final duration = (json['duration'] ?? '').toString();
    return RentListing(
      id: (json['_id'] ?? '').toString(),
      ownerId: (json['ownerId'] ?? ownerMap['_id'] ?? '').toString(),
      title: (json['title'] ?? 'Footwear').toString(),
      imageUrl: (json['imageUrl'] ?? '').toString(),
      duration: duration,
      durationLabel: (json['durationLabel'] ?? rentDurationLabel(duration)).toString(),
      price: json['price'] as num? ?? 0,
      status: (json['status'] ?? 'pending').toString(),
      rejectReason: json['rejectReason']?.toString(),
      ownerName: (ownerMap['name'] ?? '').toString(),
      requestCount: json['requestCount'] is num ? (json['requestCount'] as num).toInt() : 0,
    );
  }
}

class RentRequestItem {
  final String id;
  final String listingId;
  final String renterName;
  final String ownerName;
  final String listingTitle;
  final String imageUrl;
  final String durationLabel;
  final num paidAmount;

  const RentRequestItem({
    required this.id,
    required this.listingId,
    required this.renterName,
    required this.ownerName,
    required this.listingTitle,
    required this.imageUrl,
    required this.durationLabel,
    required this.paidAmount,
  });

  factory RentRequestItem.fromJson(Map<String, dynamic> json) {
    final renter = json['renter'];
    final owner = json['owner'];
    final listing = json['listing'];
    final renterMap = renter is Map ? Map<String, dynamic>.from(renter) : <String, dynamic>{};
    final ownerMap = owner is Map ? Map<String, dynamic>.from(owner) : <String, dynamic>{};
    final listingMap = listing is Map ? Map<String, dynamic>.from(listing) : <String, dynamic>{};
    final duration = (json['duration'] ?? listingMap['duration'] ?? '').toString();
    return RentRequestItem(
      id: (json['_id'] ?? '').toString(),
      listingId: (json['listingId'] ?? listingMap['_id'] ?? '').toString(),
      renterName: (renterMap['name'] ?? renterMap['mobile'] ?? 'Renter').toString(),
      ownerName: (ownerMap['name'] ?? '').toString(),
      listingTitle: (listingMap['title'] ?? 'Footwear').toString(),
      imageUrl: (listingMap['imageUrl'] ?? '').toString(),
      durationLabel: (json['durationLabel'] ?? rentDurationLabel(duration)).toString(),
      paidAmount: json['paidAmount'] as num? ?? json['price'] as num? ?? 0,
    );
  }
}

class RentRemoteDataSource {
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

  Future<String> uploadImage(
    String accessToken, {
    required List<int> imageBytes,
    required String fileName,
  }) async {
    final request = http.MultipartRequest('POST', Uri.parse(ApiEndpoints.rentUploadImage));
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

  Future<RentListing> createListing(
    String accessToken, {
    required String title,
    required String imageUrl,
    required String duration,
    required num price,
  }) async {
    final response = await http
        .post(
          Uri.parse(ApiEndpoints.rentListings),
          headers: _headers(accessToken),
          body: jsonEncode({
            'title': title,
            'imageUrl': imageUrl,
            'duration': duration,
            'price': price,
          }),
        )
        .timeout(_timeout);
    final json = _handleResponse(response);
    final data = json['data'];
    final listing = data is Map ? data['listing'] : null;
    if (listing is! Map) throw const ServerException('Invalid listing response');
    return RentListing.fromJson(Map<String, dynamic>.from(listing));
  }

  Future<List<RentListing>> _listings(String accessToken, Uri uri) async {
    final response = await http.get(uri, headers: _headers(accessToken)).timeout(_timeout);
    final json = _handleResponse(response);
    final data = json['data'];
    final raw = data is Map ? data['listings'] : null;
    if (raw is! List) return [];
    return raw.whereType<Map>().map((e) => RentListing.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<List<RentListing>> getMyListings(String accessToken) =>
      _listings(accessToken, Uri.parse(ApiEndpoints.rentListings));

  Future<List<RentListing>> getAvailable(String accessToken) =>
      _listings(accessToken, Uri.parse(ApiEndpoints.rentAvailable));

  Future<RentRequestItem> createPaidRequest(
    String accessToken, {
    required String listingId,
  }) async {
    final response = await http
        .post(
          Uri.parse(ApiEndpoints.rentRequests),
          headers: _headers(accessToken),
          body: jsonEncode({
            'listingId': listingId,
            'paymentConfirmed': true,
          }),
        )
        .timeout(_timeout);
    final json = _handleResponse(response);
    final data = json['data'];
    final request = data is Map ? data['request'] : null;
    if (request is! Map) throw const ServerException('Invalid rent request response');
    return RentRequestItem.fromJson(Map<String, dynamic>.from(request));
  }

  Future<List<RentRequestItem>> getIncomingRequests(String accessToken) async {
    final response = await http
        .get(Uri.parse(ApiEndpoints.rentIncomingRequests), headers: _headers(accessToken))
        .timeout(_timeout);
    final json = _handleResponse(response);
    final data = json['data'];
    final raw = data is Map ? data['requests'] : null;
    if (raw is! List) return [];
    return raw.whereType<Map>().map((e) => RentRequestItem.fromJson(Map<String, dynamic>.from(e))).toList();
  }
}
