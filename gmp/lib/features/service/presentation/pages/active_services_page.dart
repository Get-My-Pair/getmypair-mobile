import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gmp/core/constants/api_endpoints.dart';
import 'package:gmp/core/network/dio_client.dart';
import 'package:gmp/core/widgets/app_feedback_alert.dart';
import 'package:gmp/core/widgets/app_skeleton.dart';
import 'package:gmp/core/widgets/article_rack_shoe_image.dart';
import 'package:gmp/core/widgets/floating_gradient_bottom_nav.dart';
import 'package:gmp/features/auth/domain/usecases/get_valid_access_token.dart';
import 'package:gmp/features/service/presentation/pages/pair_progress_page.dart';
import 'package:gmp/features/service/presentation/utils/care_active_job.dart';
import 'package:gmp/features/service/presentation/widgets/service_request_bg_layer.dart';
import 'package:gmp/injection_container.dart';

/// Active CareMyPair jobs — light panel + progress-style cards (Figma Active Services).
class ActiveServicesPage extends StatefulWidget {
  const ActiveServicesPage({super.key});

  static const BorderRadius _panelRadius = BorderRadius.only(
    topLeft: Radius.circular(20),
    topRight: Radius.circular(20),
    bottomLeft: Radius.circular(50),
    bottomRight: Radius.circular(50),
  );

  @override
  State<ActiveServicesPage> createState() => _ActiveServicesPageState();
}

class _ActiveServicesPageState extends State<ActiveServicesPage> {
  bool _loading = true;
  bool _approvingIdBusy = false;
  String? _error;
  List<Map<String, dynamic>> _jobs = const [];
  Set<String> _dropOffConfirmed = {};

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
    final confirmed = await CareActiveJob.loadDropOffConfirmedIds();
    final tokenResult = await sl<GetValidAccessToken>().call();
    if (!mounted) return;

    await tokenResult.fold(
      (_) async {
        setState(() {
          _loading = false;
          _error = 'Please sign in again';
          _dropOffConfirmed = confirmed;
        });
      },
      (token) async {
        try {
          final res = await sl<DioClient>().get(
            ApiEndpoints.serviceMy,
            accessToken: token,
          );
          final list =
              ((res['data'] as Map<String, dynamic>?)?['requests'] as List?) ??
                  const [];
          final jobs = list
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .where(CareActiveJob.isActiveCareRequest)
              .toList();
          if (!mounted) return;
          setState(() {
            _jobs = jobs;
            _dropOffConfirmed = confirmed;
            _loading = false;
          });
        } catch (e) {
          if (!mounted) return;
          setState(() {
            _loading = false;
            _dropOffConfirmed = confirmed;
            _error = e.toString().replaceFirst('Exception: ', '');
          });
        }
      },
    );
  }

  Future<void> _openProgress(Map<String, dynamic> r) async {
    final id = CareActiveJob.requestId(r);
    if (id.isEmpty) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => PairProgressPage(requestId: id, initialRequest: r),
      ),
    );
    if (mounted) _load();
  }

  Future<void> _approveAdditionalCost(Map<String, dynamic> r) async {
    final id = CareActiveJob.requestId(r);
    if (id.isEmpty || _approvingIdBusy) return;
    setState(() => _approvingIdBusy = true);
    final tokenResult = await sl<GetValidAccessToken>().call();
    if (!mounted) return;
    await tokenResult.fold(
      (_) async {
        setState(() => _approvingIdBusy = false);
        await showAppFeedbackAlert(
          context,
          message: 'Please sign in again',
          type: AppFeedbackType.failure,
        );
      },
      (token) async {
        try {
          await sl<DioClient>().post(
            ApiEndpoints.serviceRespondActualCost,
            accessToken: token,
            body: {'requestId': id, 'decision': 'accept'},
          );
          if (!mounted) return;
          await _load();
          if (!mounted) return;
          await showAppFeedbackAlert(
            context,
            message: 'Additional charges accepted',
            type: AppFeedbackType.success,
          );
        } catch (e) {
          if (!mounted) return;
          await showAppFeedbackAlert(
            context,
            message: e.toString().replaceFirst('Exception: ', ''),
            type: AppFeedbackType.failure,
          );
        } finally {
          if (mounted) setState(() => _approvingIdBusy = false);
        }
      },
    );
  }

  static String _deliveryLabel(Map<String, dynamic> r, Set<String> confirmed) {
    if (CareActiveJob.needsDropOffConfirm(r, dropOffConfirmedIds: confirmed)) {
      return 'Confirm at hub';
    }
    final d = CareActiveJob.estimatedDelivery(r);
    final day = d.day;
    final ordinal = (day >= 11 && day <= 13)
        ? 'th'
        : switch (day % 10) {
            1 => 'st',
            2 => 'nd',
            3 => 'rd',
            _ => 'th',
          };
    final month = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ][d.month - 1];
    return '$day$ordinal $month\' ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final bottomSafe = MediaQuery.viewPaddingOf(context).bottom;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
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
                      borderRadius: ActiveServicesPage._panelRadius,
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
                    borderRadius: ActiveServicesPage._panelRadius,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
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
                                  'Active Services',
                                  style: GoogleFonts.boldonse(
                                    color: const Color(0xFF062F35),
                                    fontSize: 22,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: _loading
                              ? const AppSkeletonList(itemCount: 3)
                              : _error != null
                                  ? Center(
                                      child: Padding(
                                        padding: const EdgeInsets.all(24),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              _error!,
                                              textAlign: TextAlign.center,
                                              style: GoogleFonts.montserrat(
                                                color: const Color(0xFFB00020),
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            FilledButton(
                                              onPressed: _load,
                                              style: FilledButton.styleFrom(
                                                backgroundColor:
                                                    const Color(0xFF11999E),
                                              ),
                                              child: const Text('Retry'),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                  : _jobs.isEmpty
                                      ? Center(
                                          child: Text(
                                            'No pairs are currently in treatment',
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.montserrat(
                                              color: const Color(0xFF9AA4A6),
                                              fontSize: 15,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        )
                                      : RefreshIndicator(
                                          color: const Color(0xFF11999E),
                                          onRefresh: _load,
                                          child: ListView.separated(
                                            physics:
                                                const AlwaysScrollableScrollPhysics(),
                                            padding: EdgeInsets.fromLTRB(
                                              16,
                                              8,
                                              16,
                                              120 + bottomSafe,
                                            ),
                                            itemCount: _jobs.length,
                                            separatorBuilder: (_, _) =>
                                                const SizedBox(height: 14),
                                            itemBuilder: (_, i) {
                                              final r = _jobs[i];
                                              return _ActiveJobCard(
                                                request: r,
                                                deliveryLabel: _deliveryLabel(
                                                  r,
                                                  _dropOffConfirmed,
                                                ),
                                                showExtraCostApprove:
                                                    CareActiveJob
                                                        .needsAdditionalCostApproval(
                                                  r,
                                                ),
                                                approving: _approvingIdBusy,
                                                onOpenProgress: () =>
                                                    _openProgress(r),
                                                onApprove: () =>
                                                    _approveAdditionalCost(r),
                                              );
                                            },
                                          ),
                                        ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: DashboardLinkedBottomNav(selectedTabIndex: 1),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveJobCard extends StatelessWidget {
  const _ActiveJobCard({
    required this.request,
    required this.deliveryLabel,
    required this.showExtraCostApprove,
    required this.approving,
    required this.onOpenProgress,
    required this.onApprove,
  });

  final Map<String, dynamic> request;
  final String deliveryLabel;
  final bool showExtraCostApprove;
  final bool approving;
  final VoidCallback onOpenProgress;
  final VoidCallback onApprove;

  String get _actionMessage {
    final note = (request['actualCostNote'] ??
            request['additionalCostNote'] ??
            request['inspectionNote'] ??
            request['problemDescription'] ??
            '')
        .toString()
        .trim();
    final cost = CareActiveJob.actualCostAmount(request);
    final rupees = cost != null ? CareActiveJob.formatRupees(cost) : null;
    final finding = note.isNotEmpty
        ? note.split(RegExp(r'[\n,]')).first.trim()
        : 'We found an extra repair need.';
    if (rupees != null) {
      return '$finding\nApprove ₹$rupees repair?';
    }
    return '$finding\nAdditional charges need your approval.';
  }

  @override
  Widget build(BuildContext context) {
    final brand = CareActiveJob.brand(request);
    final model = CareActiveJob.modelLine(request);
    final serviceType = (request['serviceType'] ?? '').toString();
    final badge = CareActiveJob.serviceLabel(serviceType);
    final problemTitle = CareActiveJob.serviceOptionLabel(request);
    final imageUrl = CareActiveJob.articleImageUrl(request);
    final badgeAsset = CareActiveJob.serviceBadgeAsset(serviceType);
    final progressTitle = CareActiveJob.currentProgressTitle(request);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onOpenProgress,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF12899B), width: 1),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          brand,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.montserrat(
                            color: const Color(0xFF12899B),
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          model,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.montserrat(
                            color: const Color(0xFF062F35),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      width: 92,
                      height: 72,
                      child: imageUrl.isEmpty
                          ? Container(
                              color: const Color(0xFFE8EEEE),
                              child: const Icon(
                                Icons.directions_walk_rounded,
                                size: 28,
                                color: Color(0xFF12899B),
                              ),
                            )
                          : ArticleRackShoeImage(
                              imageUrl: imageUrl,
                              fit: BoxFit.contain,
                            ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Left: problem / service option title. Right: service type badge.
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      problemTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.montserrat(
                        color: const Color(0xFF062F35),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF062F35),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SvgPicture.asset(
                          badgeAsset,
                          width: 14,
                          height: 14,
                          colorFilter: const ColorFilter.mode(
                            Color(0xFF0CADC5),
                            BlendMode.srcIn,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          badge,
                          style: GoogleFonts.montserrat(
                            color: const Color(0xFF0CADC5),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8EA)),
              const SizedBox(height: 12),
              _MetaRow(label: 'Service Status:', value: progressTitle),
              const SizedBox(height: 8),
              _MetaRow(label: 'Expected Delivery:', value: deliveryLabel),
              // Only when shop adds extra cost pending user approval.
              if (showExtraCostApprove) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFE11D48),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            decoration: const BoxDecoration(
                              color: Color(0xFFE11D48),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              '!',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                height: 1,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Action Required',
                            style: GoogleFonts.montserrat(
                              color: const Color(0xFFE11D48),
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _actionMessage,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.montserrat(
                          color: const Color(0xFF062F35),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _GradientPillButton(
                        label: 'Approve',
                        loading: approving,
                        onPressed: approving ? null : onApprove,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.montserrat(
            color: const Color(0xFF8A9496),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: GoogleFonts.montserrat(
              color: const Color(0xFF062F35),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _GradientPillButton extends StatelessWidget {
  const _GradientPillButton({
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(100),
        child: Ink(
          height: 44,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.centerRight,
              end: Alignment.centerLeft,
              colors: [Color(0xFF0CADC5), Color(0xFF063239)],
            ),
            borderRadius: BorderRadius.circular(100),
            boxShadow: const [
              BoxShadow(
                color: Color(0x19000000),
                blurRadius: 4,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    label,
                    style: GoogleFonts.boldonse(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
