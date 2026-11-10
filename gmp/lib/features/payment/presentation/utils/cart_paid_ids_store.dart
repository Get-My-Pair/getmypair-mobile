import 'package:shared_preferences/shared_preferences.dart';

import '../../../../injection_container.dart';

/// Local paid markers so Cart shows **Payment Paid** even when the service
/// request `paymentState` lags behind Zoho / webhook sync.
class CartPaidIdsStore {
  CartPaidIdsStore._();

  static const prefsKey = 'cart_paid_service_request_ids';

  static Future<SharedPreferences> _prefs() async {
    if (sl.isRegistered<SharedPreferences>()) {
      return sl<SharedPreferences>();
    }
    return SharedPreferences.getInstance();
  }

  /// Lowercased ids for case-insensitive matching against request ids.
  static Future<Set<String>> loadNormalized() async {
    final prefs = await _prefs();
    return {
      for (final id in prefs.getStringList(prefsKey) ?? const <String>[])
        id.trim().toLowerCase(),
    }..removeWhere((id) => id.isEmpty);
  }

  static Future<void> remember(String serviceRequestId) async {
    final id = serviceRequestId.trim();
    if (id.isEmpty) return;
    final prefs = await _prefs();
    final list = prefs.getStringList(prefsKey) ?? <String>[];
    final lower = id.toLowerCase();
    final already = list.any((e) => e.trim().toLowerCase() == lower);
    if (already) return;
    list.add(id);
    await prefs.setStringList(prefsKey, list);
  }
}
