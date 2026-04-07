import 'package:flutter/material.dart';
import 'package:gmp/core/constants/api_endpoints.dart';
import 'package:gmp/core/network/dio_client.dart';
import 'package:gmp/core/theme/app_colors.dart';
import 'package:gmp/core/utils/responsive.dart';
import 'package:gmp/core/widgets/gradient_page_shell.dart';
import 'package:gmp/features/auth/domain/usecases/get_valid_access_token.dart';
import 'package:gmp/injection_container.dart';

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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                decision == 'accept'
                    ? 'You accepted the final service cost'
                    : 'You rejected the final service cost — request cancelled',
              ),
              backgroundColor:
                  decision == 'accept' ? AppColors.success : AppColors.error,
            ),
          );
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
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Request cancelled')));
        } catch (e) {
          if (!mounted) return;
          setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
        } finally {
          if (mounted) setState(() => _cancelling = false);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final horizontal = Responsive.horizontalPaddingOf(context);
    return GradientPageShell(
      appBar: buildGradientAppBar(
        title: 'Request Details',
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh, color: Colors.white),
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
          : _error != null
          ? Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontal),
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
            )
          : _request == null
          ? const Center(
              child: Text(
                'Request not found',
                style: TextStyle(color: AppColors.onGradientBody),
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: EdgeInsets.fromLTRB(horizontal, 8, horizontal, 24),
                children: [
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
                        color: AppColors.warning.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.warning.withOpacity(0.45)),
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
                          color: AppColors.error.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.error.withOpacity(0.35)),
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
    );
  }

  bool _canCancel() {
    final status = (_request?['status'] ?? '').toString();
    return status != 'completed' && status != 'cancelled';
  }

  Widget _workflowProgress() {
    final currentState = (_request?['trackingState'] ?? 'request_created')
        .toString();
    final currentIndex = _workflowStages.indexOf(currentState);
    return Column(
      children: _workflowStages.map((stage) {
        final idx = _workflowStages.indexOf(stage);
        final done = currentIndex >= idx;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Icon(
                done ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 18,
                color: done ? AppColors.success : AppColors.textTertiary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _label(stage),
                  style: TextStyle(
                    color: done
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                    fontWeight: done ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
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
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textTertiary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13.5,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _label(String raw) => raw.replaceAll('_', ' ').trim();
}
