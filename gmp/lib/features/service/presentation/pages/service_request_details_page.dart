import 'package:flutter/material.dart';
import 'package:gmp/core/constants/api_endpoints.dart';
import 'package:gmp/core/network/dio_client.dart';
import 'package:gmp/core/theme/app_colors.dart';
import 'package:gmp/core/widgets/app_feedback_alert.dart';
import 'package:gmp/core/widgets/floating_gradient_bottom_nav.dart';
import 'package:gmp/features/auth/domain/usecases/get_valid_access_token.dart';
import 'package:gmp/features/service/presentation/widgets/service_request_bg_layer.dart';
import 'package:gmp/injection_container.dart';
import 'package:google_fonts/google_fonts.dart';

class ServiceRequestDetailsPage extends StatefulWidget {
  final String requestId;

  const ServiceRequestDetailsPage({super.key, required this.requestId});

  @override
  State<ServiceRequestDetailsPage> createState() =>
      _ServiceRequestDetailsPageState();
}

class _ServiceRequestDetailsPageState extends State<ServiceRequestDetailsPage> {
  bool _loading = true;
  bool _cancelling = false;
  bool _responding = false;
  String? _error;
  Map<String, dynamic>? _request;
  static const List<String> _workflowStages = [
    'request_created',
    'pickup_scheduled',
    'item_picked',
    'dark_store_received',
    'inspection_started',
    'repair_in_progress',
    'repair_completed',
    'dispatch_ready',
    'out_for_delivery',
    'delivered',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final tokenResult = await sl<GetValidAccessToken>().call();
    if (!mounted) return;

    await tokenResult.fold(
      (_) async {
        setState(() {
          _loading = false;
          _error = 'Please sign in again';
        });
      },
      (token) async {
        try {
          final res = await sl<DioClient>().get(
            ApiEndpoints.serviceById(widget.requestId),
            accessToken: token,
          );
          final req =
              ((res['data'] as Map<String, dynamic>?)?['request'] as Map?) ??
              const {};
          if (!mounted) return;
          setState(() {
            _request = Map<String, dynamic>.from(req);
            _loading = false;
          });
        } catch (e) {
          if (!mounted) return;
          setState(() {
            _loading = false;
            _error = e.toString().replaceFirst('Exception: ', '');
          });
        }
      },
    );
  }

  String _str(dynamic v) => v?.toString() ?? '';

  bool _hasActualCost(Map<String, dynamic> r) {
    final v = r['actualCost'];
    if (v == null) return false;
    return _str(v).trim().isNotEmpty;
  }

  String _decisionStr(Map<String, dynamic> r) =>
      _str(r['actualCostUserDecision']).trim().toLowerCase();

  bool _pendingUserCost(Map<String, dynamic> r) =>
      _hasActualCost(r) && _decisionStr(r) == 'pending';

  bool _acceptedUserCost(Map<String, dynamic> r) =>
      _hasActualCost(r) && _decisionStr(r) == 'accepted';

  bool _rejectedUserCost(Map<String, dynamic> r) =>
      _hasActualCost(r) && _decisionStr(r) == 'rejected';

  String _fmtAmount(dynamic v) {
    if (v == null) return '—';
    if (v is num) {
      if (v % 1 == 0) return v.toInt().toString();
      return v.toString();
    }
    final s = v.toString();
    return s.isEmpty ? '—' : s;
  }

  Future<void> _respondActualCost(String decision) async {
    if (_responding || _request == null) return;
    setState(() {
      _responding = true;
      _error = null;
    });
    final tokenResult = await sl<GetValidAccessToken>().call();
    if (!mounted) return;
    await tokenResult.fold(
      (_) async {
        if (!mounted) return;
        setState(() {
          _responding = false;
          _error = 'Please sign in again';
        });
      },
      (token) async {
        try {
          await sl<DioClient>().post(
            ApiEndpoints.serviceRespondActualCost,
            accessToken: token,
            body: {
              'requestId': widget.requestId,
              'decision': decision,
            },
          );
          if (!mounted) return;
          await _load();
          if (!mounted) return;
          if (decision == 'accept') {
            await showAppFeedbackAlert(
              context,
              message: 'You accepted the final service cost',
              type: AppFeedbackType.success,
            );
          } else {
            await showAppFeedbackAlert(
              context,
              message:
                  'You rejected the final service cost — request cancelled',
              type: AppFeedbackType.warning,
            );
          }
        } catch (e) {
          if (!mounted) return;
          setState(() {
            _error = e.toString().replaceFirst('Exception: ', '');
          });
        } finally {
          if (mounted) setState(() => _responding = false);
        }
      },
    );
  }

  Future<void> _cancelRequest() async {
    if (_cancelling || _request == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel request'),
        content: const Text('Do you want to cancel this service request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes, cancel'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    setState(() => _cancelling = true);
    final tokenResult = await sl<GetValidAccessToken>().call();
    if (!mounted) return;
    await tokenResult.fold(
      (_) async {
        if (!mounted) return;
        setState(() {
          _cancelling = false;
          _error = 'Please sign in again';
        });
      },
      (token) async {
        try {
          await sl<DioClient>().put(
            ApiEndpoints.serviceCancel((_request!['_id'] ?? '').toString()),
            accessToken: token,
          );
          if (!mounted) return;
          await _load();
          if (!mounted) return;
          await showAppFeedbackAlert(
            context,
            message: 'Request cancelled',
            type: AppFeedbackType.success,
          );
        } catch (e) {
          if (!mounted) return;
          setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
        } finally {
          if (mounted) setState(() => _cancelling = false);
        }
      },
    );
  }

  static const BorderRadius _panelRadius = BorderRadius.only(
    topLeft: Radius.circular(20),
    topRight: Radius.circular(20),
    bottomLeft: Radius.circular(50),
    bottomRight: Radius.circular(50),
  );

  double _progressFractionForRequest() {
    if (_request == null) return 0;
    final tracking =
        (_request!['trackingState'] ?? 'request_created').toString();
    var idx = _workflowStages.indexOf(tracking);
    if (idx < 0) idx = 0;
    return ((idx + 1) / _workflowStages.length).clamp(0.0, 1.0);
  }

  Widget _progressHero() {
    final r = _request!;
    final tracking = (r['trackingState'] ?? 'request_created').toString();
    final label = _label(tracking);
    final progress = _progressFractionForRequest();
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF0F6876).withValues(alpha: 0.35),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current stage',
            style: GoogleFonts.montserrat(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF12899B),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label.isEmpty ? '—' : label,
            style: GoogleFonts.boldonse(
              fontSize: 18,
              color: const Color(0xFF062F35),
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: const Color(0xFFDFE7E9),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF0F6876),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomSafe = MediaQuery.viewPaddingOf(context).bottom;
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: Stack(
        children: [
          ...ServiceRequestBgLayer.stackBehind(),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 30, 10, 0),
              child: DecoratedBox(
                decoration: ShapeDecoration(
                  color: ServiceRequestBgLayer.panelFill,
                  shape: const RoundedRectangleBorder(
                    borderRadius: _panelRadius,
                  ),
                  shadows: const [
                    BoxShadow(
                      color: Color(0x19000000),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: _panelRadius,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 12, 8, 0),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: () => Navigator.maybePop(context),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints.tightFor(
                                width: 26,
                                height: 26,
                              ),
                              icon: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: Color(0xFF062F35),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Service progress',
                                style: GoogleFonts.boldonse(
                                  color: const Color(0xFF062F35),
                                  fontSize: 22,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: _loading ? null : _load,
                              icon: const Icon(
                                Icons.refresh_rounded,
                                color: Color(0xFF062F35),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: _loading
                            ? const Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFF11999E),
                                ),
                              )
                            : _error != null
                                ? Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(24),
                                      child: Text(
                                        _error!,
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.montserrat(
                                          color: AppColors.error,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  )
                                : _request == null
                                    ? Center(
                                        child: Text(
                                          'Request not found',
                                          style: GoogleFonts.montserrat(
                                            color: const Color(0xFF5C5C5C),
                                          ),
                                        ),
                                      )
                                    : RefreshIndicator(
                                        color: const Color(0xFF11999E),
                                        onRefresh: _load,
                                        child: ListView(
                                          padding: const EdgeInsets.fromLTRB(
                                            14,
                                            8,
                                            14,
                                            120,
                                          ),
                                          children: [
                                            _progressHero(),
                                            _card(
                    title: 'Overview',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _row('Request ID', (_request!['_id'] ?? '').toString()),
                        _row(
                          'Service Type',
                          (_request!['serviceType'] ?? '')
                              .toString()
                              .toUpperCase(),
                        ),
                        _row(
                          'Status',
                          _label((_request!['status'] ?? '').toString()),
                        ),
                        _row(
                          'Tracking',
                          _label((_request!['trackingState'] ?? '').toString()),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_pendingUserCost(_request!)) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.warning.withValues(alpha: 0.45),
                        ),
                      ),
                      child: const Text(
                        'Review the final service cost from the team. Accept to continue the workflow, or reject to cancel this request.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textPrimary,
                          height: 1.35,
                        ),
                      ),
                    ),
                    _card(
                      title: 'Final service cost',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Proposed amount: ${_fmtAmount(_request!['actualCost'])}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Same units as shown in your estimate (e.g. rupees / minor units).',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _responding
                                      ? null
                                      : () => _respondActualCost('reject'),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                      color: AppColors.error,
                                    ),
                                    foregroundColor: AppColors.error,
                                  ),
                                  child: const Text('Reject'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _responding
                                      ? null
                                      : () => _respondActualCost('accept'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.success,
                                    foregroundColor: AppColors.textOnPrimary,
                                  ),
                                  child: _responding
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: AppColors.textOnPrimary,
                                          ),
                                        )
                                      : const Text('Accept'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    if (_rejectedUserCost(_request!)) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.error.withValues(alpha: 0.35),
                          ),
                        ),
                        child: const Text(
                          'You rejected the final service cost. This service request has been cancelled.',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.error,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                    _card(
                      title: 'Costs',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _row(
                            'Estimated',
                            _fmtAmount(_request!['estimatedCost']),
                          ),
                          if (_hasActualCost(_request!)) ...[
                            _row(
                              'Actual (quoted)',
                              _fmtAmount(_request!['actualCost']),
                            ),
                          ],
                          if (_acceptedUserCost(_request!)) ...[
                            const SizedBox(height: 10),
                            Text(
                              'Final Service Cost: ${_fmtAmount(_request!['actualCost'])} (accepted)',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                            if (_request!['actualCostAcceptedAt'] != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  'Accepted at: ${_str(_request!['actualCostAcceptedAt'])}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _card(
                      title: 'Assignment',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _row(
                            'Delivery Partner',
                            _request!['deliveryPartnerId']?.toString() ??
                                'Not assigned',
                          ),
                          _row(
                            'Cobbler',
                            _request!['cobblerId']?.toString() ?? 'Not assigned',
                          ),
                          _row(
                            'Dark Store',
                            _request!['darkStoreName']?.toString() ??
                                _request!['darkStoreId']?.toString() ??
                                'Not assigned',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _card(title: 'Workflow Progress', child: _workflowProgress()),
                    const SizedBox(height: 12),
                    _card(title: 'Status Timeline', child: _timeline()),
                  ],
                  const SizedBox(height: 16),
                  if (_canCancel())
                    SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        onPressed: (_cancelling || _pendingUserCost(_request!))
                            ? null
                            : _cancelRequest,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.error),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _cancelling
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Cancel Request',
                                style: TextStyle(
                                  color: AppColors.error,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                                          ],
                                        ),
                                      ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const DashboardLinkedBottomNav(selectedTabIndex: 1),
                SizedBox(height: bottomSafe),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _canCancel() {
    final status = (_request?['status'] ?? '').toString();
    return status != 'completed' && status != 'cancelled';
  }

  Widget _workflowProgress() {
    final currentState = (_request?['trackingState'] ?? 'request_created')
        .toString();
    var currentIndex = _workflowStages.indexOf(currentState);
    if (currentIndex < 0) currentIndex = 0;
    final total = _workflowStages.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Follow your pair’s journey',
          style: GoogleFonts.montserrat(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        ...List.generate(_workflowStages.length, (idx) {
          final stage = _workflowStages[idx];
          final done = currentIndex > idx;
          final isCurrent = currentIndex == idx;
          final isLast = idx == total - 1;

          Color bubbleColor;
          Gradient? bubbleGradient;
          Color cardColor;
          Color borderColor;
          Color titleColor;
          FontWeight titleWeight;

          if (done) {
            bubbleColor = AppColors.success;
            cardColor = AppColors.success.withValues(alpha: 0.06);
            borderColor = AppColors.success.withValues(alpha: 0.55);
            titleColor = AppColors.textPrimary;
            titleWeight = FontWeight.w600;
          } else if (isCurrent) {
            bubbleColor = AppColors.primary;
            bubbleGradient = const LinearGradient(
              colors: [
                Color(0xFF14B8C4),
                Color(0xFF0F8792),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            );
            cardColor = const Color(0xFFE9F8FA);
            borderColor = const Color(0xFF0F8792).withValues(alpha: 0.65);
            titleColor = const Color(0xFF0B555F);
            titleWeight = FontWeight.w700;
          } else {
            bubbleColor = AppColors.border;
            cardColor = AppColors.surfaceVariant;
            borderColor = AppColors.border;
            titleColor = AppColors.textSecondary;
            titleWeight = FontWeight.w400;
          }

          final label = _label(stage);

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 26,
                  child: Column(
                    children: [
                      Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: bubbleGradient,
                          color: bubbleGradient == null ? bubbleColor : null,
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x22000000),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: done
                            ? const Icon(
                                Icons.check_rounded,
                                size: 12,
                                color: Colors.white,
                              )
                            : isCurrent
                                ? const Icon(
                                    Icons.directions_walk_rounded,
                                    size: 12,
                                    color: Colors.white,
                                  )
                                : const Icon(
                                    Icons.circle_outlined,
                                    size: 10,
                                    color: Colors.white,
                                  ),
                      ),
                      if (!isLast)
                        Container(
                          width: 2,
                          height: 42,
                          margin: const EdgeInsets.only(top: 2),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: done || isCurrent
                                  ? [
                                      bubbleColor.withValues(alpha: 0.85),
                                      bubbleColor.withValues(alpha: 0.15),
                                    ]
                                  : [
                                      AppColors.border,
                                      AppColors.border.withValues(alpha: 0.0),
                                    ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: GoogleFonts.montserrat(
                            fontSize: 13.5,
                            fontWeight: titleWeight,
                            color: titleColor,
                          ),
                        ),
                        if (isCurrent) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Step ${idx + 1} of $total • in progress',
                            style: GoogleFonts.montserrat(
                              fontSize: 11.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ] else if (done) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Completed',
                            style: GoogleFonts.montserrat(
                              fontSize: 11.5,
                              color: AppColors.success,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _timeline() {
    final raw = _request?['lifecycleEvents'];
    final events =
        (raw is List ? raw : const [])
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList()
          ..sort((a, b) {
            final at =
                DateTime.tryParse((a['timestamp'] ?? '').toString()) ??
                DateTime(1970);
            final bt =
                DateTime.tryParse((b['timestamp'] ?? '').toString()) ??
                DateTime(1970);
            return at.compareTo(bt);
          });

    if (events.isEmpty) {
      return const Text(
        'No lifecycle events yet.',
        style: TextStyle(color: AppColors.textSecondary),
      );
    }

    return Column(
      children: List.generate(events.length, (index) {
        final event = events[index];
        final isLast = index == events.length - 1;
        final state = _label((event['state'] ?? '').toString());
        final status = (event['status'] ?? '').toString();
        final actor = _label((event['actorType'] ?? 'system').toString());
        final note = (event['note'] ?? '').toString();
        final time = (event['timestamp'] ?? '').toString();

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 22,
              child: Column(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  if (!isLast)
                    Container(width: 2, height: 46, color: AppColors.border),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      state,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Status: ${status.isEmpty ? '—' : _label(status)}  •  By: $actor',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (note.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        note,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                    if (time.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        time,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _card({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF0F6876).withValues(alpha: 0.22),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.boldonse(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF062F35),
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _row(String key, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              key,
              style: GoogleFonts.montserrat(
                fontSize: 13,
                color: AppColors.textTertiary,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.montserrat(
                fontSize: 13.5,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _label(String raw) => raw.replaceAll('_', ' ').trim();
}
