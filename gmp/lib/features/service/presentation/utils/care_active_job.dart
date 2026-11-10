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

  /// Known CareMyPair problem codes → display titles (Figma / masteradmin).
  static const Map<String, String> problemTitlesByCode = {
    'sole_bottom_construction': 'Sole & Bottom Construction Repairs',
    'upper_seam_restoration': 'Upper Material & Seam Restoration',
    'hardware_fastener': 'Hardware & Fastener Repairs',
    'fit_structural': 'Fit & Structural Adjustments',
    'protection_conditioning': 'Protection & Conditioning',
    'surface_care_polishing': 'Preventive Surface Care & Polishing',
    'structural_shape': 'Structural & Shape Maintenance',
    'storage_preservation': 'Storage & Preservation Prep',
    'exterior_surface_deep_clean': 'Exterior & Surface Deep Cleaning',
    'interior_care_sanitization': 'Interior Care & Sanitization',
    'detailing_finishing': 'Detailing & Finishing',
  };

  static String serviceOptionLabel(Map<String, dynamic> r) {
    // Prefer canonical title from problem code when available.
    final code = problemCodeOf(r);
    final byCode = problemTitlesByCode[code];
    if (byCode != null && byCode.isNotEmpty) return byCode;

    final plan = (r['maintenancePlanLabel'] ?? r['problemName'] ?? '')
        .toString()
        .trim();
    final problem = (r['problemDescription'] ?? '').toString().trim();
    final raw = plan.isNotEmpty
        ? plan
        : (problem.isNotEmpty
            ? problem.split(RegExp(r'[\n,]')).first.trim()
            : '');
    if (raw.isNotEmpty) return _cleanOptionLabel(raw, r);
    return serviceLabel((r['serviceType'] ?? '').toString());
  }

  /// Drops redundant "Brand: …" prefix so cards don't show "Action: Sole &…".
  static String _cleanOptionLabel(String raw, Map<String, dynamic> r) {
    var text = raw.trim();
    final b = brand(r);
    if (b.isNotEmpty) {
      final prefix = RegExp(
        '^${RegExp.escape(b)}\\s*:\\s*',
        caseSensitive: false,
      );
      text = text.replaceFirst(prefix, '').trim();
    }
    // Short brand-like "Something: rest" → keep rest only.
    final generic = RegExp(r'^([^:]{1,24}):\s+(.+)$');
    final m = generic.firstMatch(text);
    if (m != null) {
      final rest = (m.group(2) ?? '').trim();
      if (rest.isNotEmpty) text = rest;
    }
    return text.isEmpty ? raw.trim() : text;
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

  /// Current / latest timeline step title for Active Services cards.
  static String currentProgressTitle(
    Map<String, dynamic> r, {
    List<CareProgressStep>? steps,
    int? estimateDays,
  }) {
    if (needsAdditionalCostApproval(r)) return 'Waiting for your approval';
    final serviceType = (r['serviceType'] ?? 'repair').toString();
    final list = (steps != null && steps.isNotEmpty)
        ? steps
        : parseProgressSteps(
            r['progressSteps'],
            serviceType: serviceType,
          );
    if (list.isEmpty) return statusBlurb(r);
    final idx = currentProgressIndex(
      r,
      stepCount: list.length,
      estimateDays: estimateDays,
    ).clamp(0, list.length - 1);
    final title = list[idx].title.trim();
    return title.isEmpty ? statusBlurb(r) : title;
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

  static final RegExp _objectIdRe = RegExp(r'^[a-fA-F0-9]{24}$');

  /// First CareMyPair problem code / id from the service request.
  /// Multi-select values are comma-joined — timeline uses the first.
  static String problemCodeOf(Map<String, dynamic> r) {
    for (final key in [
      'maintenancePlanId',
      'problemCode',
      'careProblemCode',
      'careOptionCode',
      'code',
    ]) {
      final raw = (r[key] ?? '').toString().trim();
      if (raw.isEmpty) continue;
      return raw.split(',').first.trim();
    }
    return '';
  }

  /// True when [value] looks like a Mongo ObjectId (Masteradmin problem `_id`).
  static bool isProblemObjectId(String value) =>
      _objectIdRe.hasMatch(value.trim());

  /// Parse Masteradmin `progressSteps` only — no static placeholder steps.
  static List<CareProgressStep> parseProgressSteps(
    dynamic raw, {
    required String serviceType,
  }) {
    if (raw is! List || raw.isEmpty) return const [];
    final out = <CareProgressStep>[];
    final sorted = [...raw];
    sorted.sort((a, b) {
      int orderOf(dynamic item) {
        if (item is Map) {
          final n = item['sortOrder'];
          if (n is num) return n.toInt();
          return int.tryParse(n?.toString() ?? '') ?? 0;
        }
        return 0;
      }

      return orderOf(a).compareTo(orderOf(b));
    });

    for (final item in sorted) {
      if (item is Map) {
        final title = (item['title'] ?? item['label'] ?? item['text'] ?? '')
            .toString()
            .trim();
        if (title.isEmpty) continue;
        final subtitle = (item['subtitle'] ?? '').toString().trim();
        out.add(CareProgressStep(
          title: title,
          subtitle: subtitle.isEmpty && out.isEmpty
              ? serviceLabel(serviceType)
              : (subtitle.isEmpty ? null : subtitle),
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
    return out;
  }

  /// Pull estimateDays from Masteradmin care-progress / problem payload.
  static int? parseEstimateDays(dynamic raw) {
    if (raw is num && raw >= 1) return raw.round();
    final parsed = int.tryParse(raw?.toString() ?? '');
    if (parsed != null && parsed >= 1) return parsed;
    return null;
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
