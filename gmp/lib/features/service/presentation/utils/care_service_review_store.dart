import 'dart:convert';

import 'package:gmp/injection_container.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      requestId: (json['requestId'] ?? '').toString(),
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      comment: (json['comment'] ?? '').toString(),
      submittedAt: DateTime.tryParse('${json['submittedAt']}') ?? DateTime.now(),
    );
  }
}

/// Local store for Service History “Rate your pair’s glow-up” submissions.
class CareServiceReviewStore {
  CareServiceReviewStore._();

  static const _prefsKey = 'care_service_reviews_v1';

  static Future<SharedPreferences> _prefs() async {
    if (sl.isRegistered<SharedPreferences>()) {
      return sl<SharedPreferences>();
    }
    return SharedPreferences.getInstance();
  }

  static Future<Map<String, CareServiceReview>> loadAll() async {
    final prefs = await _prefs();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      final out = <String, CareServiceReview>{};
      for (final entry in decoded.entries) {
        final value = entry.value;
        if (value is Map) {
          final review = CareServiceReview.fromJson(
            Map<String, dynamic>.from(value),
          );
          if (review.requestId.isNotEmpty) {
            out[review.requestId] = review;
          }
        }
      }
      return out;
    } catch (_) {
      return {};
    }
  }

  static Future<CareServiceReview?> get(String requestId) async {
    final all = await loadAll();
    return all[requestId.trim()];
  }

  static Future<bool> hasReviewed(String requestId) async {
    final review = await get(requestId);
    return review != null && review.rating > 0;
  }

  static Future<void> save(CareServiceReview review) async {
    final id = review.requestId.trim();
    if (id.isEmpty || review.rating < 1) return;
    final prefs = await _prefs();
    final all = await loadAll();
    all[id] = review;
    final encoded = <String, dynamic>{
      for (final e in all.entries) e.key: e.value.toJson(),
    };
    await prefs.setString(_prefsKey, jsonEncode(encoded));
  }
}
