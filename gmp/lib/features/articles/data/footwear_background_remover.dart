import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/constants/active_profile_header.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/constants/app_constants.dart';

/// Footwear background removal via the GetMyPair API (server holds remove.bg key).
///
/// Do not call remove.bg from the app — the API key must never ship in APK/IPA.
class FootwearBackgroundRemover {
  FootwearBackgroundRemover._();

  static const Duration _timeout = Duration(seconds: 90);

  /// Always attempt when the user has a session; server returns 503 if unset.
  static bool get isConfigured => true;

  /// Returns a PNG [File] with transparent background, saved under app temp dir.
  static Future<File> removeBackground(
    File source, {
    required String accessToken,
  }) async {
    if (accessToken.trim().isEmpty) {
      throw FootwearBackgroundRemoverException(
        'Sign in to prepare footwear photos.',
        isUnavailable: true,
      );
    }
    if (!source.existsSync()) {
      throw FootwearBackgroundRemoverException('Image file not found.');
    }

    final request = http.MultipartRequest(
      'POST',
      Uri.parse(ApiEndpoints.articlesRemoveBackground),
    );
    request.headers['Authorization'] = 'Bearer $accessToken';
    request.headers['X-App-Source'] = AppConstants.appSourceForApi;
    request.headers['X-App-Version'] = AppConstants.appVersion;
    request.headers['Accept'] = 'image/png, application/json';
    ActiveProfileHeader.applyTo(request.headers);

    final lower = source.path.toLowerCase();
    final mime = lower.endsWith('.png')
        ? MediaType('image', 'png')
        : MediaType('image', 'jpeg');

    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        source.path,
        contentType: mime,
      ),
    );

    final streamed = await request.send().timeout(_timeout);
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode == 200 &&
        response.bodyBytes.isNotEmpty &&
        _looksLikePng(response.bodyBytes)) {
      final dir = await getTemporaryDirectory();
      final outPath =
          '${dir.path}/footwear_cutout_${DateTime.now().millisecondsSinceEpoch}.png';
      final out = File(outPath);
      await out.writeAsBytes(response.bodyBytes, flush: true);
      return out;
    }

    final message = _parseErrorMessage(response.statusCode, response.body);

    // 404 = route not deployed yet; 501/503 = server feature off.
    // Soft-fail so footwear upload still works without a cutout.
    if (response.statusCode == 404 ||
        response.statusCode == 501 ||
        response.statusCode == 503 ||
        message.toLowerCase().contains('route not found')) {
      throw FootwearBackgroundRemoverException(
        message,
        isUnavailable: true,
      );
    }

    throw FootwearBackgroundRemoverException(message);
  }

  static bool _looksLikePng(List<int> bytes) {
    return bytes.length >= 4 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47;
  }

  static String _parseErrorMessage(int statusCode, String body) {
    try {
      final json = jsonDecode(body);
      if (json is Map<String, dynamic>) {
        final message = json['message'];
        if (message is String && message.isNotEmpty) return message;
      }
    } catch (_) {}
    return 'Background removal failed (HTTP $statusCode).';
  }
}

class FootwearBackgroundRemoverException implements Exception {
  FootwearBackgroundRemoverException(
    this.message, {
    this.isUnavailable = false,
  });

  final String message;
  final bool isUnavailable;

  @override
  String toString() => message;
}
