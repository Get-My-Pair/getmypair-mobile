import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_endpoints.dart';
import '../errors/exceptions.dart';

class DioClient {
  Future<Map<String, dynamic>> get(
    String endpoint, {
    String? accessToken,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(endpoint),
        headers: ApiEndpoints.getHeaders(accessToken: accessToken),
      );

      return _handleResponse(response);
    } catch (e) {
      throw NetworkException('Network error: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? body,
    String? accessToken,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(endpoint),
        headers: ApiEndpoints.getHeaders(accessToken: accessToken),
        body: body != null ? jsonEncode(body) : null,
      );

      return _handleResponse(response);
    } catch (e) {
      throw NetworkException('Network error: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> put(
    String endpoint, {
    Map<String, dynamic>? body,
    String? accessToken,
  }) async {
    try {
      final response = await http.put(
        Uri.parse(endpoint),
        headers: ApiEndpoints.getHeaders(accessToken: accessToken),
        body: body != null ? jsonEncode(body) : null,
      );

      return _handleResponse(response);
    } catch (e) {
      throw NetworkException('Network error: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> delete(
    String endpoint, {
    String? accessToken,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse(endpoint),
        headers: ApiEndpoints.getHeaders(accessToken: accessToken),
      );

      return _handleResponse(response);
    } catch (e) {
      throw NetworkException('Network error: ${e.toString()}');
    }
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
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
          throw ServerException('$message. Errors: $errorMessages');
        }
        
        throw ServerException(message);
      }
    } catch (e) {
      if (e is ServerException) {
        rethrow;
      }
      // If response body is not valid JSON
      throw ServerException('Server error: ${response.statusCode} - ${response.body}');
    }
  }
}

