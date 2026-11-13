import 'package:gmp/core/constants/api_endpoints.dart';
import 'package:gmp/core/network/dio_client.dart';
import 'package:gmp/features/auth/domain/usecases/get_valid_access_token.dart';
import 'package:gmp/injection_container.dart';

class CareServiceReview {
  final String requestId;
  final int rating;
  final String comment;
  final DateTime submittedAt;

  const CareServiceReview({
    required this.requestId,
    required this.rating,
    required this.comment,
    required this.submittedAt,
  });

  Map<String, dynamic> toJson() => {
        'requestId': requestId,
        'rating': rating,
        'comment': comment,
        'submittedAt': submittedAt.toIso8601String(),
      };

  factory CareServiceReview.fromJson(Map<String, dynamic> json) {
    return CareServiceReview(
      requestId: (json['requestId'] ?? json['_id'] ?? '').toString(),
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      comment: (json['comment'] ?? '').toString(),
      submittedAt: DateTime.tryParse('${json['submittedAt']}') ?? DateTime.now(),
    );
  }

  /// Reads nested `customerReview` from a service request payload.
  static CareServiceReview? fromServiceRequest(Map<String, dynamic> request) {
    final id = (request['_id'] ?? request['id'] ?? '').toString().trim();
    final raw = request['customerReview'];
    if (raw is! Map) return null;
    final rating = (raw['rating'] as num?)?.toInt() ?? 0;
    if (id.isEmpty || rating < 1) return null;
    return CareServiceReview(
      requestId: id,
      rating: rating,
      comment: (raw['comment'] ?? '').toString(),
      submittedAt:
          DateTime.tryParse('${raw['submittedAt']}') ?? DateTime.now(),
    );
  }
}

/// Backend-backed reviews for Service History (“Rate your pair’s glow-up”).
/// Does not use SharedPreferences — source of truth is the service request DB.
class CareServiceReviewStore {
  CareServiceReviewStore._();

  static bool hasReviewedOnRequest(Map<String, dynamic> request) {
    return CareServiceReview.fromServiceRequest(request) != null;
  }

  static Future<CareServiceReview> submit({
    required String requestId,
    required int rating,
    String comment = '',
  }) async {
    final id = requestId.trim();
    if (id.isEmpty || rating < 1 || rating > 5) {
      throw Exception('Invalid review');
    }

    final tokenResult = await sl<GetValidAccessToken>().call();
    final token = tokenResult.fold<String?>(
      (_) => null,
      (t) => t,
    );
    if (token == null || token.isEmpty) {
      throw Exception('Please sign in again');
    }

    final res = await sl<DioClient>().post(
      ApiEndpoints.serviceSubmitReview,
      accessToken: token,
      body: {
        'requestId': id,
        'rating': rating,
        if (comment.trim().isNotEmpty) 'comment': comment.trim(),
      },
    );
    final data = res['data'];
    if (data is Map) {
      final reviewRaw = data['review'];
      if (reviewRaw is Map) {
        return CareServiceReview.fromJson({
          ...Map<String, dynamic>.from(reviewRaw),
          'requestId': id,
        });
      }
      final request = data['request'];
      if (request is Map) {
        final parsed = CareServiceReview.fromServiceRequest(
          Map<String, dynamic>.from(request),
        );
        if (parsed != null) return parsed;
      }
    }
    return CareServiceReview(
      requestId: id,
      rating: rating,
      comment: comment.trim(),
      submittedAt: DateTime.now(),
    );
  }
}
