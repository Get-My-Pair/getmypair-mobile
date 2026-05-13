import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:gmp/core/constants/api_endpoints.dart';
import 'package:gmp/core/constants/app_constants.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';

/// Uploads proof media for service requests (Module 4) to getmypair-api Cloudinary.
class ServiceProofUpload {
  ServiceProofUpload._();

  static Future<String> uploadImage(XFile file, String accessToken) async {
    return _upload(
      Uri.parse(ApiEndpoints.serviceUploadProofImage),
      file,
      accessToken,
      isVideo: false,
    );
  }

  static Future<String> uploadVideo(XFile file, String accessToken) async {
    return _upload(
      Uri.parse(ApiEndpoints.serviceUploadProofVideo),
      file,
      accessToken,
      isVideo: true,
    );
  }

  static String _extensionFromMime(String mime, bool isVideo) {
    final m = mime.toLowerCase();
    if (isVideo) {
      if (m.contains('quicktime')) return '.mov';
      if (m.contains('webm')) return '.webm';
      if (m.contains('3gpp')) return '.3gp';
      return '.mp4';
    }
    if (m.contains('png')) return '.png';
    if (m.contains('webp')) return '.webp';
    if (m.contains('gif')) return '.gif';
    if (m.contains('heic')) return '.heic';
    if (m.contains('bmp')) return '.bmp';
    return '.jpg';
  }

  static Future<String> _upload(
    Uri uri,
    XFile file,
    String accessToken, {
    required bool isVideo,
  }) async {
    final bytes = await file.readAsBytes();
    String? mimeStr = file.mimeType?.trim();
    if (mimeStr == null || mimeStr.isEmpty) {
      mimeStr = lookupMimeType(file.path, headerBytes: bytes);
    }
    if (mimeStr == null || mimeStr.isEmpty) {
      mimeStr = isVideo ? 'video/mp4' : 'image/jpeg';
    }

    MediaType contentType;
    try {
      contentType = MediaType.parse(mimeStr);
    } catch (_) {
      contentType = MediaType(
        isVideo ? 'video' : 'image',
        isVideo ? 'mp4' : 'jpeg',
      );
    }

    var filename = file.name.trim();
    if (filename.isEmpty || !filename.contains('.')) {
      filename = 'proof${_extensionFromMime(mimeStr, isVideo)}';
    }

    final request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Bearer $accessToken';
    request.headers['X-App-Source'] = AppConstants.appSourceForApi;
    request.headers['X-App-Version'] = AppConstants.appVersion;
    request.headers['Accept'] = 'application/json';
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: filename,
        contentType: contentType,
      ),
    );
    http.StreamedResponse streamed;
    try {
      streamed =
          await request.send().timeout(const Duration(seconds: 120));
    } catch (e) {
      final s = e.toString();
      if (kIsWeb &&
          (s.contains('XMLHttpRequest') ||
              s.contains('Failed to fetch') ||
              s.contains('NetworkError'))) {
        throw Exception(
          'Upload could not reach the server (often CORS on web). '
          'Use an Android/iOS build, or deploy the API with CORS allowing your web origin.',
        );
      }
      rethrow;
    }
    final response = await http.Response.fromStream(streamed);
    final body = response.body.isNotEmpty
        ? jsonDecode(response.body) as Map<String, dynamic>
        : <String, dynamic>{};
    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (response.statusCode == 401) {
        throw Exception(
          'Session expired or invalid. Please sign in again and retry the upload.',
        );
      }
      var msg =
          body['message']?.toString() ??
          'Upload failed (${response.statusCode})';
      if (msg.contains('Cloudinary is not configured')) {
        msg =
            'Server storage is not configured (Cloudinary). Contact support or try again later.';
      }
      throw Exception(msg);
    }
    final data = body['data'];
    if (data is Map && data['url'] != null) {
      return data['url'] as String;
    }
    throw Exception('Invalid upload response');
  }
}
