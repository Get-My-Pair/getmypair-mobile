class ServerException implements Exception {
  final String message;
  /// HTTP status code when exception is from an API response (e.g. 401, 403).
  final int? statusCode;

  const ServerException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class NetworkException implements Exception {
  final String message;
  
  const NetworkException(this.message);
  
  @override
  String toString() => message;
}

class CacheException implements Exception {
  final String message;
  
  const CacheException(this.message);
  
  @override
  String toString() => message;
}

class ValidationException implements Exception {
  final String message;
  
  const ValidationException(this.message);
  
  @override
  String toString() => message;
}

