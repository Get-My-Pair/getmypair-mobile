import 'package:gmp/core/constants/api_endpoints.dart';
import 'package:gmp/injection_container.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Shared CareMyPair active-job helpers (home card, Active Services, Progress).
class CareActiveJob {
  CareActiveJob._();

  static const Set<String> careTypes = {'repair', 'maintenance', 'wash'};
  static const Set<String> terminalStatuses = {'completed', 'cancelled'};
  static const Set<String> terminalTracking = {'delivered', 'cancelled'};
  static const int defaultEstimateDays = 7;
  static const String _dropOffPrefsKey = 'care_dropoff_confirmed_ids';

  static bool isActiveCareRequest(Map<String, dynamic> r) {
    final type = (r['serviceType'] ?? '').toString().trim().toLowerCase();
    if (!careTypes.contains(type)) return false;
    final status = (r['status'] ?? '').toString().trim().toLowerCase();
    if (terminalStatuses.contains(status)) return false;
    final tracking =
        (r['trackingState'] ?? '').toString().trim().toLowerCase();
    if (terminalTracking.contains(tracking)) return false;
    return true;
  }

  /// Delivered / completed Care jobs for Service History (not Active).
  static bool isHistoryCareRequest(Map<String, dynamic> r) {
    final type = (r['serviceType'] ?? '').toString().trim().toLowerCase();
    if (!careTypes.contains(type)) return false;
    final status = (r['status'] ?? '').toString().trim().toLowerCase();
    if (status == 'completed') return true;
    final tracking =
        (r['trackingState'] ?? '').toString().trim().toLowerCase();
    return tracking == 'delivered';
  }

  static String serviceBadgeAsset(String serviceType) {
    switch (serviceType.trim().toLowerCase()) {
      case 'wash':
        return 'assets/images/icons/caremypair/wmp.svg';
      case 'maintenance':
        return 'assets/images/icons/caremypair/mmp.svg';
      case 'repair':
      default:
        return 'assets/images/icons/caremypair/rmp.svg';
    }
  }

  static String requestId(Map<String, dynamic> r) =>
      (r['_id'] ?? r['id'] ?? '').toString().trim();

  static String serviceLabel(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'repair':
        return 'RepairMyPair';
      case 'maintenance':
        return 'MaintainMyPair';
      case 'wash':
        return 'WashMyPair';
      default:
        if (raw.isEmpty) return 'Service';
        return raw.replaceAll('_', ' ');
    }
  }

  static String serviceOptionLabel(Map<String, dynamic> r) {
    final plan = (r['maintenancePlanLabel'] ?? '').toString().trim();
    if (plan.isNotEmpty) return plan;
    final problem = (r['problemDescription'] ?? '').toString().trim();
    if (problem.isNotEmpty) {
      final first = problem.split(RegExp(r'[\n,]')).first.trim();
      if (first.isNotEmpty) return first;
    }
    return serviceLabel((r['serviceType'] ?? '').toString());
  }

  static bool isSelfDrop(Map<String, dynamic> r) {
    final mode = (r['pickupMode'] ?? '').toString().trim().toLowerCase();
    return mode == 'cobbler_nearby' || mode == 'self_drop' || mode == 'selfdrop';
  }

  static DateTime? createdAt(Map<String, dynamic> r) {
    return DateTime.tryParse((r['createdAt'] ?? '').toString());
  }

  static int estimateDaysFor(
    Map<String, dynamic> r, {
    int? overrideDays,
  }) {
    if (overrideDays != null && overrideDays >= 1) return overrideDays;
    final fromReq = r['estimateDays'];
    if (fromReq is num && fromReq >= 1) return fromReq.round();
    final parsed = int.tryParse(fromReq?.toString() ?? '');
    if (parsed != null && parsed >= 1) return parsed;
    return defaultEstimateDays;
  }

  /// Delivery estimate: create date + estimateDays (local calendar day).
  static DateTime estimatedDelivery(
    Map<String, dynamic> r, {
    int? overrideDays,
  }) {
    final start = createdAt(r)?.toLocal() ?? DateTime.now();
    final day = DateTime(start.year, start.month, start.day);
    return day.add(Duration(days: estimateDaysFor(r, overrideDays: overrideDays)));
  }

  /// Figma-style: `30th Oct 2026`.
  static String formatEstimatePretty(DateTime d) {
    final day = d.day;
    return '$day${_dayOrdinal(day)} ${DateFormat('MMM yyyy').format(d)}';
  }

  static String _dayOrdinal(int day) {
    if (day >= 11 && day <= 13) return 'th';
    switch (day % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }

  static Map<String, dynamic>? articleMap(Map<String, dynamic> r) {
    final a = r['articleId'];
    if (a is Map) return Map<String, dynamic>.from(a);
    return null;
  }

  static String brand(Map<String, dynamic> r) {
    final a = articleMap(r);
    final b = (a?['brand'] ?? '').toString().trim();
    if (b.isNotEmpty) return b;
    final model = (a?['model'] ?? '').toString().trim();
    if (model.isNotEmpty) return model;
    return 'Your pair';
  }

  static String modelLine(Map<String, dynamic> r) {
    final a = articleMap(r);
    final model = (a?['model'] ?? '').toString().trim();
    if (model.isNotEmpty) return model;
    return brand(r);
  }

  static String resolveImageUrl(String path) {
    final p = path.trim();
    if (p.isEmpty) return '';
    if (p.startsWith('http')) return p;
    final base = ApiEndpoints.baseUrl;
    if (p.startsWith('/')) return '$base$p';
    return '$base/uploads/$p';
  }

  static String articleImageUrl(Map<String, dynamic> r) {
    final a = articleMap(r);
    final images = a?['images'];
    if (images is List) {
      for (final img in images) {
        final url = resolveImageUrl(img?.toString() ?? '');
        if (url.isNotEmpty) return url;
      }
    }
    final photos = r['photos'];
    if (photos is List) {
      for (final p in photos) {
        final url = resolveImageUrl(p?.toString() ?? '');
        if (url.isNotEmpty) return url;
      }
    }
    return '';
  }

  static bool hasActualCost(Map<String, dynamic> r) {
    final v = r['actualCost'];
    if (v == null) return false;
    return v.toString().trim().isNotEmpty;
  }

  static String costDecision(Map<String, dynamic> r) =>
      (r['actualCostUserDecision'] ?? '').toString().trim().toLowerCase();

  /// Extra repair-shop charges waiting for user approve/reject.
  static bool needsAdditionalCostApproval(Map<String, dynamic> r) =>
      hasActualCost(r) && costDecision(r) == 'pending';

  static double? actualCostAmount(Map<String, dynamic> r) {
    final v = r['actualCost'];
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '');
  }

  static double? estimatedCostAmount(Map<String, dynamic> r) {
    final v = r['estimatedCost'];
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '');
  }

  static String formatRupees(num? v) {
    if (v == null) return '—';
    if (v % 1 == 0) return v.toInt().toString();
    return v.toStringAsFixed(0);
  }

  static String statusBlurb(Map<String, dynamic> r) {
    if (needsAdditionalCostApproval(r)) return 'Waiting for your approval';
    final tracking =
        (r['trackingState'] ?? '').toString().trim().toLowerCase();
    switch (tracking) {
      case 'request_created':
      case 'pickup_scheduled':
        return isSelfDrop(r) ? 'Awaiting drop off' : 'Pickup scheduled';
      case 'item_picked':
      case 'dark_store_received':
        return 'Received at hub';
      case 'inspection_started':
        return 'Inspection in progress';
      case 'repair_in_progress':
        final type = (r['serviceType'] ?? '').toString().toLowerCase();
        if (type == 'wash') return 'Getting deep cleaned';
        if (type == 'maintenance') return 'Getting maintained';
        return 'Repair in progress';
      case 'repair_completed':
        return 'Work completed';
      case 'dispatch_ready':
        return 'Ready for dispatch';
      case 'out_for_delivery':
        return 'Out for delivery';
      default:
        if (tracking.isEmpty) return 'In progress';
        return tracking.replaceAll('_', ' ');
    }
  }

  /// Backend already past drop-off / pickup.
  static bool handoverCompleteByTracking(Map<String, dynamic> r) {
    const past = {
      'item_picked',
      'dark_store_received',
      'inspection_started',
      'repair_in_progress',
      'repair_completed',
      'dispatch_ready',
      'out_for_delivery',
      'delivered',
    };
    final tracking =
        (r['trackingState'] ?? '').toString().trim().toLowerCase();
    return past.contains(tracking);
  }

  static Future<Set<String>> loadDropOffConfirmedIds() async {
    final prefs = sl.isRegistered<SharedPreferences>()
        ? sl<SharedPreferences>()
        : await SharedPreferences.getInstance();
    final list = prefs.getStringList(_dropOffPrefsKey) ?? const <String>[];
    return list.toSet();
  }

  static Future<void> markDropOffConfirmed(String requestId) async {
    final id = requestId.trim();
    if (id.isEmpty) return;
    final prefs = sl.isRegistered<SharedPreferences>()
        ? sl<SharedPreferences>()
        : await SharedPreferences.getInstance();
    final list = prefs.getStringList(_dropOffPrefsKey) ?? <String>[];
    if (list.contains(id)) return;
    list.add(id);
    await prefs.setStringList(_dropOffPrefsKey, list);
  }

  /// Self-drop still needs "Mark as Dropped off" until confirmed or hub receives.
  static bool needsDropOffConfirm(
    Map<String, dynamic> r, {
    Set<String>? dropOffConfirmedIds,
  }) {
    if (!isSelfDrop(r)) return false;
    if (handoverCompleteByTracking(r)) return false;
    final id = requestId(r);
    if (id.isEmpty) return true;
    if (dropOffConfirmedIds != null && dropOffConfirmedIds.contains(id)) {
      return false;
    }
    return true;
  }

  static String problemCodeOf(Map<String, dynamic> r) {
    final planId = (r['maintenancePlanId'] ?? '').toString().trim();
    if (planId.isNotEmpty) {
      // Multi-select ids are comma-joined — use the first problem for timeline.
      return planId.split(',').first.trim();
    }
    return '';
  }

  /// Fallback steps when Masteradmin content is offline.
  static List<CareProgressStep> fallbackProgressSteps(String serviceType) {
    final label = serviceLabel(serviceType);
    return [
      CareProgressStep(title: 'Order Confirmed', subtitle: label),
      const CareProgressStep(title: 'Work in progress — day 2.'),
      const CareProgressStep(title: 'Work in progress — day 3.'),
      const CareProgressStep(title: 'Work in progress — day 4.'),
      const CareProgressStep(title: 'Work in progress — day 5.'),
      const CareProgressStep(title: 'Quality Check'),
      const CareProgressStep(title: 'Ready for delivery'),
    ];
  }

  static List<CareProgressStep> parseProgressSteps(
    dynamic raw, {
    required String serviceType,
  }) {
    if (raw is! List || raw.isEmpty) {
      return fallbackProgressSteps(serviceType);
    }
    final out = <CareProgressStep>[];
    for (final item in raw) {
      if (item is Map) {
        final title =
            (item['title'] ?? item['label'] ?? item['text'] ?? '').toString().trim();
        if (title.isEmpty) continue;
        final subtitle = (item['subtitle'] ?? '').toString().trim();
        out.add(CareProgressStep(
          title: title,
          subtitle: subtitle.isEmpty && out.isEmpty ? serviceLabel(serviceType) : subtitle,
        ));
      } else {
        final title = item.toString().trim();
        if (title.isEmpty) continue;
        out.add(CareProgressStep(
          title: title,
          subtitle: out.isEmpty ? serviceLabel(serviceType) : null,
        ));
      }
    }
    return out.isEmpty ? fallbackProgressSteps(serviceType) : out;
  }

  /// Current step index. Advances 1 step per day across [estimateDays] / step count.
  static int currentProgressIndex(
    Map<String, dynamic> r, {
    required int stepCount,
    int? estimateDays,
  }) {
    final count = stepCount < 1 ? 1 : stepCount;
    final maxIdx = count - 1;
    final daysWindow = estimateDaysFor(r, overrideDays: estimateDays);
    final start = createdAt(r)?.toLocal() ?? DateTime.now();
    final startDay = DateTime(start.year, start.month, start.day);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final elapsed = today.difference(startDay).inDays;

    // Map elapsed days onto steps: day 0 → step 0, then 1 step / day.
    // If estimateDays != stepCount, scale proportionally.
    int byTime;
    if (daysWindow <= 1 || count <= 1) {
      byTime = elapsed >= 1 ? maxIdx : 0;
    } else {
      final ratio = elapsed / daysWindow;
      byTime = (ratio * maxIdx).floor().clamp(0, maxIdx);
      // Still advance at least one step per full day when possible.
      if (elapsed > 0) {
        byTime = elapsed.clamp(0, maxIdx);
      }
    }

    final tracking =
        (r['trackingState'] ?? '').toString().trim().toLowerCase();
    final byTrack = _trackingToStep(tracking, maxIdx);
    return byTrack > byTime ? byTrack : byTime;
  }

  static int _trackingToStep(String tracking, int maxIdx) {
    switch (tracking) {
      case 'request_created':
      case 'pickup_scheduled':
        return 0;
      case 'item_picked':
      case 'dark_store_received':
        return 1;
      case 'inspection_started':
        return 2;
      case 'repair_in_progress':
        return 3;
      case 'repair_completed':
        return 5;
      case 'dispatch_ready':
        return maxIdx;
      case 'out_for_delivery':
      case 'delivered':
        return maxIdx;
      default:
        return 0;
    }
  }

  static DateTime? stepCompletedAt(
    Map<String, dynamic> r,
    int stepIndex, {
    required int stepCount,
    int? estimateDays,
  }) {
    final start = createdAt(r)?.toLocal();
    if (start == null) return null;
    final current = currentProgressIndex(
      r,
      stepCount: stepCount,
      estimateDays: estimateDays,
    );
    if (stepIndex > current) return null;
    return start.add(Duration(days: stepIndex));
  }

  static String formatStepTime(DateTime? dt) {
    if (dt == null) return '----';
    return DateFormat('d MMM, h:mm a').format(dt);
  }
}

class CareProgressStep {
  final String title;
  final String? subtitle;

  const CareProgressStep({required this.title, this.subtitle});
}
