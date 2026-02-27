import 'package:dio/dio.dart';

/// API Response wrapper
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final int? statusCode;
  final ApiError? error;

  ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.statusCode,
    this.error,
  });

  factory ApiResponse.success(T data, {String? message, int? statusCode}) {
    return ApiResponse(
      success: true,
      data: data,
      message: message,
      statusCode: statusCode,
    );
  }

  factory ApiResponse.failure(ApiError error) {
    return ApiResponse(
      success: false,
      error: error,
      statusCode: error.statusCode,
      message: error.message,
    );
  }

  factory ApiResponse.fromDioError(DioException e) {
    return ApiResponse(
      success: false,
      error: ApiError.fromDioException(e),
      statusCode: e.response?.statusCode,
    );
  }
}

/// API Error model
class ApiError {
  final String message;
  final int? statusCode;
  final String? errorCode;
  final Map<String, dynamic>? errors;

  ApiError({
    required this.message,
    this.statusCode,
    this.errorCode,
    this.errors,
  });

  factory ApiError.fromDioException(DioException e) {
    String message;
    String? errorCode;
    Map<String, dynamic>? errors;

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        message = 'Connection timeout. Please check your internet.';
        errorCode = 'CONNECTION_TIMEOUT';
        break;
      case DioExceptionType.sendTimeout:
        message = 'Send timeout. Please try again.';
        errorCode = 'SEND_TIMEOUT';
        break;
      case DioExceptionType.receiveTimeout:
        message = 'Server took too long to respond.';
        errorCode = 'RECEIVE_TIMEOUT';
        break;
      case DioExceptionType.badResponse:
        final response = e.response;
        if (response != null) {
          final data = response.data;
          if (data is Map<String, dynamic>) {
            message = data['message'] ?? 'Something went wrong';
            errorCode = data['error_code'];
            errors = data['errors'];
          } else {
            message = _getStatusMessage(response.statusCode);
          }
        } else {
          message = 'Bad response from server';
        }
        errorCode = 'BAD_RESPONSE';
        break;
      case DioExceptionType.cancel:
        message = 'Request cancelled';
        errorCode = 'CANCELLED';
        break;
      case DioExceptionType.connectionError:
        message = 'No internet connection';
        errorCode = 'NO_INTERNET';
        break;
      default:
        message = e.message ?? 'An unexpected error occurred';
        errorCode = 'UNKNOWN';
    }

    return ApiError(
      message: message,
      statusCode: e.response?.statusCode,
      errorCode: errorCode,
      errors: errors,
    );
  }

  static String _getStatusMessage(int? statusCode) {
    switch (statusCode) {
      case 400:
        return 'Bad request';
      case 401:
        return 'Unauthorized. Please login again.';
      case 403:
        return 'Access denied';
      case 404:
        return 'Resource not found';
      case 409:
        return 'Conflict occurred';
      case 422:
        return 'Validation failed';
      case 500:
        return 'Internal server error';
      case 502:
        return 'Bad gateway';
      case 503:
        return 'Service unavailable';
      default:
        return 'Something went wrong';
    }
  }
}
