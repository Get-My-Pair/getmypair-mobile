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
        throw const NetworkException('Connection timeout');
      });

      return _handleResponse(response);
    } on SocketException {
      throw const NetworkException('No internet connection');
    } on HttpException {
      throw const NetworkException('Network error');
    } on FormatException {
      throw const NetworkException('Network error');
    } catch (e) {
      if (e is NetworkException) rethrow;
      if (e is ServerException) rethrow;
      throw const NetworkException('Network error');
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
        throw const NetworkException('Connection timeout');
      });

      return _handleResponse(response);
    } on SocketException {
      throw const NetworkException('No internet connection');
    } on HttpException {
      throw const NetworkException('Network error');
    } on FormatException {
      throw const NetworkException('Network error');
    } catch (e) {
      if (e is NetworkException) rethrow;
      if (e is ServerException) rethrow;
      throw const NetworkException('Network error');
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
        throw const NetworkException('Connection timeout');
      });

      return _handleResponse(response);
    } on SocketException {
      throw const NetworkException('No internet connection');
    } on HttpException {
      throw const NetworkException('Network error');
    } catch (e) {
      if (e is NetworkException) rethrow;
      if (e is ServerException) rethrow;
      throw const NetworkException('Network error');
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
        throw const NetworkException('Connection timeout');
      });

      return _handleResponse(response);
    } on SocketException {
      throw const NetworkException('No internet connection');
    } on HttpException {
      throw const NetworkException('Network error');
    } catch (e) {
      if (e is NetworkException) rethrow;
      if (e is ServerException) rethrow;
      throw const NetworkException('Network error');
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
        throw const NetworkException('Connection timeout');
      });

      return _handleResponse(response);
    } on SocketException {
      throw const NetworkException('No internet connection');
    } on HttpException {
      throw const NetworkException('Network error');
    } catch (e) {
      if (e is NetworkException) rethrow;
      if (e is ServerException) rethrow;
      throw const NetworkException('Network error');
    }
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    // Handle empty or invalid responses
    if (response.body.isEmpty) {
      throw const ServerException('Empty response from server');
    }

    try {
      final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonResponse;
      } else {
        // Handle rate limit (429 Too Many Requests)
        if (response.statusCode == 429) {
          throw const ServerException(
            'Too many requests. Please wait a few minutes before trying again.',
          );
        }
        
        // Handle 500+ server errors
        if (response.statusCode >= 500) {
          throw ServerException(
            'Server error',
            statusCode: response.statusCode,
          );
        }
        
        // Backend error format: { success: false, message: string, statusCode: number, errors?: array }
        // Keep message for logs/statusCode mapping; UI sanitizes via UserFacingError.
        final message = jsonResponse['message'] as String? ?? 'Server error';
        throw ServerException(message, statusCode: response.statusCode);
      }
    } on FormatException {
      // If response body is not valid JSON
      throw ServerException(
        'Invalid response from server',
        statusCode: response.statusCode,
      );
    } catch (e) {
      if (e is ServerException) {
        rethrow;
      }
      // Fallback for any other parsing errors
      throw const ServerException('Unexpected server response');
    }
  }
}

