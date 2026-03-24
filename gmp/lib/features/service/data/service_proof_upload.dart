import 'dart:convert';

import 'package:gmp/core/constants/api_endpoints.dart';
import 'package:gmp/core/constants/app_constants.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

/// Uploads proof media for service requests (Module 4) to getmypair-api Cloudinary.
class ServiceProofUpload {
  ServiceProofUpload._();

  static Future<String> uploadImage(XFile file, String accessToken) async {
    return _upload(
      Uri.parse(ApiEndpoints.serviceUploadProofImage),
      file,
      accessToken,
    );
  }

  static Future<String> uploadVideo(XFile file, String accessToken) async {
    return _upload(
      Uri.parse(ApiEndpoints.serviceUploadProofVideo),
      file,
      accessToken,
    );
  }

  static Future<String> _upload(Uri uri, XFile file, String accessToken) async {
    final bytes = await file.readAsBytes();
    final request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Bearer $accessToken';
    request.headers['X-App-Source'] = AppConstants.appSourceForApi;
    request.headers['X-App-Version'] = AppConstants.appVersion;
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: file.name.isNotEmpty ? file.name : 'upload.bin',
      ),
    );
    final streamed = await request.send().timeout(const Duration(seconds: 120));
    final response = await http.Response.fromStream(streamed);
    final body = response.body.isNotEmpty
        ? jsonDecode(response.body) as Map<String, dynamic>
        : <String, dynamic>{};
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final msg =
          body['message']?.toString() ??
          'Upload failed (${response.statusCode})';
      throw Exception(msg);
    }
    final data = body['data'];
    if (data is Map && data['url'] != null) {
      return data['url'] as String;
    }
    throw Exception('Invalid upload response');
  }
}
