import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../constants/api_endpoints.dart';
import '../errors/exceptions.dart';

class DioClient {
  // Timeout duration for API calls (30 seconds)
  static const Duration _timeoutDuration = Duration(seconds: 30);

  Future<Map<String, dynamic>> get(
    String endpoint, {
    String? accessToken,
    Map<String, String>? extraHeaders,
  }) async {
    try {
      final headers = ApiEndpoints.getHeaders(accessToken: accessToken);
      if (extraHeaders != null) headers.addAll(extraHeaders);

      final response = await http.get(
        Uri.parse(endpoint),
        headers: headers,
      ).timeout(_timeoutDuration, onTimeout: () {
        throw NetworkException(
          'Connection timeout. Please check your internet connection and try again.'
        );
      });

      return _handleResponse(response);
    } on SocketException catch (e) {
      throw NetworkException(
        'No internet connection. Please check:\n'
        '1. Your device is connected to Wi-Fi or mobile data\n'
        '2. Backend server is accessible\n'
        '3. Firewall/VPN is not blocking the connection\n\n'
        'Error: ${e.message}'
      );
    } on HttpException catch (e) {
      throw NetworkException('HTTP error: ${e.message}');
    } on FormatException catch (e) {
      throw NetworkException('Invalid response format: ${e.message}');
    } catch (e) {
      if (e is NetworkException) rethrow;
      if (e is ServerException) rethrow;
      throw NetworkException('Network error: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? body,
    String? accessToken,
    Map<String, String>? extraHeaders,
  }) async {
    try {
      final headers = ApiEndpoints.getHeaders(accessToken: accessToken);
      if (extraHeaders != null) headers.addAll(extraHeaders);

      final response = await http.post(
        Uri.parse(endpoint),
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      ).timeout(_timeoutDuration, onTimeout: () {
        throw NetworkException(
          'Connection timeout. Please check your internet connection and try again.'
        );
      });

      return _handleResponse(response);
    } on SocketException catch (e) {
      throw NetworkException(
        'No internet connection. Please check:\n'
        '1. Your device is connected to Wi-Fi or mobile data\n'
        '2. Backend server is accessible\n'
        '3. Firewall/VPN is not blocking the connection\n\n'
        'Error: ${e.message}'
      );
    } on HttpException catch (e) {
      throw NetworkException('HTTP error: ${e.message}');
    } on FormatException catch (e) {
      throw NetworkException('Invalid response format: ${e.message}');
    } catch (e) {
      if (e is NetworkException) rethrow;
      if (e is ServerException) rethrow;
      final msg = e.toString();
      if (msg.contains('XMLHttpRequest')) {
        throw NetworkException(
          'Request blocked (often in browser: CORS or mixed content). '
          'Try running on a device/emulator or ensure the backend allows your origin.'
        );
      }
      throw NetworkException('Network error: $msg');
    }
  }

  Future<Map<String, dynamic>> put(
    String endpoint, {
    Map<String, dynamic>? body,
    String? accessToken,
    Map<String, String>? extraHeaders,
  }) async {
    try {
      final headers = ApiEndpoints.getHeaders(accessToken: accessToken);
      if (extraHeaders != null) headers.addAll(extraHeaders);

      final response = await http.put(
        Uri.parse(endpoint),
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      ).timeout(_timeoutDuration, onTimeout: () {
        throw NetworkException(
          'Connection timeout. Please check your internet connection and try again.'
        );
      });

      return _handleResponse(response);
    } on SocketException catch (e) {
      throw NetworkException(
        'No internet connection. Please check:\n'
        '1. Your device is connected to Wi-Fi or mobile data\n'
        '2. Backend server is accessible\n'
        '3. Firewall/VPN is not blocking the connection\n\n'
        'Error: ${e.message}'
      );
    } on HttpException catch (e) {
      throw NetworkException('HTTP error: ${e.message}');
    } catch (e) {
      if (e is NetworkException) rethrow;
      if (e is ServerException) rethrow;
      final msg = e.toString();
      if (msg.contains('XMLHttpRequest')) {
        throw NetworkException(
          'Request blocked (often in browser: CORS or mixed content). '
          'Try running on a device/emulator or ensure the backend allows your origin.'
        );
      }
      throw NetworkException('Network error: $msg');
    }
  }

  Future<Map<String, dynamic>> patch(
    String endpoint, {
    Map<String, dynamic>? body,
    String? accessToken,
    Map<String, String>? extraHeaders,
  }) async {
    try {
      final headers = ApiEndpoints.getHeaders(accessToken: accessToken);
      if (extraHeaders != null) headers.addAll(extraHeaders);

      final response = await http.patch(
        Uri.parse(endpoint),
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      ).timeout(_timeoutDuration, onTimeout: () {
        throw NetworkException(
          'Connection timeout. Please check your internet connection and try again.'
        );
      });

      return _handleResponse(response);
    } on SocketException catch (e) {
      throw NetworkException(
        'No internet connection. Please check:\n'
        '1. Your device is connected to Wi-Fi or mobile data\n'
        '2. Backend server is accessible\n'
        '3. Firewall/VPN is not blocking the connection\n\n'
        'Error: ${e.message}'
      );
    } on HttpException catch (e) {
      throw NetworkException('HTTP error: ${e.message}');
    } catch (e) {
      if (e is NetworkException) rethrow;
      if (e is ServerException) rethrow;
      final msg = e.toString();
      if (msg.contains('XMLHttpRequest')) {
        throw NetworkException(
          'Request blocked (often in browser: CORS or mixed content). '
          'Try running on a device/emulator or ensure the backend allows your origin.'
        );
      }
      throw NetworkException('Network error: $msg');
    }
  }

  Future<Map<String, dynamic>> delete(
    String endpoint, {
    String? accessToken,
    Map<String, String>? extraHeaders,
  }) async {
    try {
      final headers = ApiEndpoints.getHeaders(accessToken: accessToken);
      if (extraHeaders != null) headers.addAll(extraHeaders);

      final response = await http.delete(
        Uri.parse(endpoint),
        headers: headers,
      ).timeout(_timeoutDuration, onTimeout: () {
        throw NetworkException(
          'Connection timeout. Please check your internet connection and try again.'
        );
      });

      return _handleResponse(response);
    } on SocketException catch (e) {
      throw NetworkException(
        'No internet connection. Please check:\n'
        '1. Your device is connected to Wi-Fi or mobile data\n'
        '2. Backend server is accessible\n'
        '3. Firewall/VPN is not blocking the connection\n\n'
        'Error: ${e.message}'
      );
    } on HttpException catch (e) {
      throw NetworkException('HTTP error: ${e.message}');
    } catch (e) {
      if (e is NetworkException) rethrow;
      if (e is ServerException) rethrow;
      final msg = e.toString();
      if (msg.contains('XMLHttpRequest')) {
        throw NetworkException(
          'Request blocked (often in browser: CORS or mixed content). '
          'Try running on a device/emulator or ensure the backend allows your origin.'
        );
      }
      throw NetworkException('Network error: $msg');
    }
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    // Handle empty or invalid responses
    if (response.body.isEmpty) {
      throw ServerException(
        'Empty response from server. Please check:\n'
        '1. Backend server is running\n'
        '2. API endpoint is correct\n'
        '3. Network connection is stable'
      );
    }

    try {
      final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonResponse;
      } else {
        // Handle rate limit (429 Too Many Requests) with user-friendly message
        if (response.statusCode == 429) {
          final rateLimitMessage = jsonResponse['message'] as String?;
          if (rateLimitMessage != null && rateLimitMessage.isNotEmpty) {
            throw ServerException(rateLimitMessage);
          }
          throw ServerException(
            'Too many requests. Please wait a few minutes before trying again.'
          );
        }
        
        // Handle 500+ server errors
        if (response.statusCode >= 500) {
          throw ServerException(
            'Backend server error (${response.statusCode}). '
            'Please try again later or contact support if the problem persists.'
          );
        }
        
        // Backend error format: { success: false, message: string, statusCode: number, errors?: array }
        final message = jsonResponse['message'] as String? ??
            'Server error: ${response.statusCode}';

        // Include validation errors if present
        if (jsonResponse['errors'] != null && jsonResponse['errors'] is List) {
          final errors = jsonResponse['errors'] as List;
          final errorMessages = errors.map((e) {
            if (e is Map) {
              return '${e['field'] ?? 'unknown'}: ${e['message'] ?? 'Validation failed'}';
            }
            return e.toString();
          }).join(', ');
          throw ServerException('$message. Errors: $errorMessages', statusCode: response.statusCode);
        }

        throw ServerException(message, statusCode: response.statusCode);
      }
    } on FormatException {
      // If response body is not valid JSON
      throw ServerException(
        'Invalid response from server (${response.statusCode}). '
        'Backend may be unreachable or returning an error page.\n\n'
        'Response: ${response.body.length > 200 ? response.body.substring(0, 200) + "..." : response.body}'
      );
    } catch (e) {
      if (e is ServerException) {
        rethrow;
      }
      // Fallback for any other parsing errors
      throw ServerException(
        'Unexpected error processing server response: ${e.toString()}'
      );
    }
  }
}

