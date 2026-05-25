import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path_provider/path_provider.dart';

/// remove.bg background removal for footwear photos.
///
/// API key via [dart_defines.local.json] (gitignored) or:
/// `flutter run --dart-define-from-file=dart_defines.local.json`
/// `flutter run --dart-define=REMOVE_BG_API_KEY=your_key_here`
class FootwearBackgroundRemover {
  FootwearBackgroundRemover._();

  static const String _endpoint = 'https://api.remove.bg/v1.0/removebg';
  static const Duration _timeout = Duration(seconds: 90);

  static const String apiKey = String.fromEnvironment(
    'REMOVE_BG_API_KEY',
    defaultValue: '',
  );

  static bool get isConfigured => apiKey.isNotEmpty;

  /// Returns a PNG [File] with transparent background, saved under app temp dir.
  static Future<File> removeBackground(File source) async {
    if (!isConfigured) {
      throw FootwearBackgroundRemoverException(
        'Background removal is not configured. '
        'Run the app with --dart-define=REMOVE_BG_API_KEY=your_remove_bg_key',
      );
    }
    if (!source.existsSync()) {
      throw FootwearBackgroundRemoverException('Image file not found.');
    }

    final request = http.MultipartRequest('POST', Uri.parse(_endpoint));
    request.headers['X-Api-Key'] = apiKey;
    request.fields['size'] = 'auto';
    request.fields['format'] = 'png';
    request.fields['type'] = 'product';

    final lower = source.path.toLowerCase();
    final mime = lower.endsWith('.png')
        ? MediaType('image', 'png')
        : MediaType('image', 'jpeg');

    request.files.add(
      await http.MultipartFile.fromPath(
        'image_file',
        source.path,
        contentType: mime,
      ),
    );

    final streamed = await request.send().timeout(_timeout);
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode == 200) {
      final dir = await getTemporaryDirectory();
      final outPath =
          '${dir.path}/footwear_cutout_${DateTime.now().millisecondsSinceEpoch}.png';
      final out = File(outPath);
      await out.writeAsBytes(response.bodyBytes, flush: true);
      return out;
    }

    throw FootwearBackgroundRemoverException(
      _parseErrorMessage(response.statusCode, response.body),
    );
  }

  static String _parseErrorMessage(int statusCode, String body) {
    try {
      final json = jsonDecode(body);
      if (json is Map<String, dynamic>) {
        final errors = json['errors'];
        if (errors is List && errors.isNotEmpty) {
          final first = errors.first;
          if (first is Map && first['title'] != null) {
            return '${first['title']}${first['detail'] != null ? ': ${first['detail']}' : ''}';
          }
        }
        if (json['message'] is String) return json['message'] as String;
      }
    } catch (_) {}
    return 'Background removal failed (HTTP $statusCode).';
  }
}

class FootwearBackgroundRemoverException implements Exception {
  FootwearBackgroundRemoverException(this.message);

  final String message;

  @override
  String toString() => message;
}
