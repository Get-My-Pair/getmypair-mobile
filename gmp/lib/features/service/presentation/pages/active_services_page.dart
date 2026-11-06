import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gmp/core/bgtheme.dart';
import 'package:gmp/core/constants/api_endpoints.dart';
import 'package:gmp/core/network/dio_client.dart';
import 'package:gmp/core/theme/app_colors.dart';
import 'package:gmp/core/widgets/app_feedback_alert.dart';
import 'package:gmp/core/widgets/app_skeleton.dart';
import 'package:gmp/core/widgets/chevron_screen_back_button.dart';
import 'package:gmp/core/widgets/floating_gradient_bottom_nav.dart';
import 'package:gmp/features/auth/domain/usecases/get_valid_access_token.dart';
import 'package:gmp/features/payment/presentation/bloc/payment_bloc.dart';
import 'package:gmp/features/payment/presentation/pages/payment_request_page.dart';
import 'package:gmp/features/payment/presentation/utils/payment_amount_formatter.dart';
import 'package:gmp/features/payment/presentation/widgets/pay_now_button.dart';
import 'package:gmp/features/service/presentation/pages/pair_progress_page.dart';
import 'package:gmp/features/service/presentation/utils/care_active_job.dart';
import 'package:gmp/injection_container.dart';

/// Active CareMyPair jobs — Cart-style cards; Pay Now opens Purchase Summary.
class ActiveServicesPage extends StatefulWidget {
  const ActiveServicesPage({super.key});

  @override
  State<ActiveServicesPage> createState() => _ActiveServicesPageState();
}

class _ActiveServicesPageState extends State<ActiveServicesPage> {
  static const Color _titleColor = Color(0xFFDFE7E9);

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

  Future<void> _openPayNow(Map<String, dynamic> r) async {
    final id = CareActiveJob.requestId(r);
    final amount = _payableAmount(r);
    if (id.isEmpty || amount <= 0) return;

    // Pending extra-cost approval must be accepted before checkout.
    if (CareActiveJob.needsAdditionalCostApproval(r)) {
      await _approveAdditionalCost(r, openPaymentAfter: true);
      return;
    }

    final paid = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => sl<PaymentBloc>(),
          child: PaymentRequestPage(
            serviceRequestId: id,
            amount: amount,
            serviceType: (r['serviceType'] ?? '').toString(),
            requestLabel: _requestLabel(r),
          ),
        ),
      ),
    );
    if (!mounted) return;
    if (paid == true) await _load();
  }

  Future<void> _approveAdditionalCost(
    Map<String, dynamic> r, {
    bool openPaymentAfter = false,
  }) async {
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
          final amount = CareActiveJob.actualCostAmount(r) ?? 0;
          if (openPaymentAfter && amount > 0) {
            await Navigator.of(context).push<bool>(
              MaterialPageRoute(
                builder: (_) => BlocProvider(
                  create: (_) => sl<PaymentBloc>(),
                  child: PaymentRequestPage(
                    serviceRequestId: id,
                    amount: amount,
                    serviceType: (r['serviceType'] ?? '').toString(),
                    requestLabel: _requestLabel(r),
                  ),
                ),
              ),
            );
            if (mounted) _load();
          } else {
            await showAppFeedbackAlert(
              context,
              message: 'Additional charges accepted',
              type: AppFeedbackType.success,
            );
          }
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

  static double _payableAmount(Map<String, dynamic> r) {
    final actual = CareActiveJob.actualCostAmount(r);
    if (actual != null && actual > 0) return actual;
    final estimated = CareActiveJob.estimatedCostAmount(r);
    if (estimated != null && estimated > 0) return estimated;
    return 0;
  }

  static bool _isPaid(Map<String, dynamic> r) {
    final paymentState =
        (r['paymentState'] ?? r['workflowStatus'] ?? '').toString().toUpperCase();
    return r['isPaid'] == true ||
        r['paymentCompleted'] == true ||
        paymentState == 'PAYMENT_SUCCESS' ||
        paymentState == 'PAID' ||
        paymentState == 'PAYMENT_REFUNDED';
  }

  static bool _showPayNow(Map<String, dynamic> r) {
    if (_isPaid(r)) return false;
    return _payableAmount(r) > 0;
  }

  static String _requestLabel(Map<String, dynamic> r) {
    final publicId = (r['publicId'] ?? '').toString().trim();
    if (publicId.isNotEmpty) return 'Request #$publicId';
    final id = CareActiveJob.requestId(r);
    if (id.isEmpty) return 'Request';
    if (id.length <= 10) return 'Request #$id';
    return 'Request #${id.substring(0, 8)}…';
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: BgTheme.scaffoldBackgroundColor,
        body: SafeArea(
          top: false,
          bottom: false,
          child: Column(
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    image: const DecorationImage(
                      image: AssetImage(BgTheme.backgroundImageAsset),
                      fit: BoxFit.cover,
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.22),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: RefreshIndicator(
                    color: AppColors.secondary,
                    backgroundColor: AppColors.footwearHeroStart,
                    onRefresh: _load,
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverPadding(
                          padding: ArticleStyleHeaderInsets.scrollContentPadding(
                            context,
                          ),
                          sliver: SliverList(
                            delegate: SliverChildListDelegate([
                              _buildHeader(),
                              const SizedBox(height: 28),
                              if (_loading)
                                AppSkeletonList(
                                  itemCount: 4,
                                  shrinkWrap: true,
                                  showAvatar: false,
                                  color: Colors.white.withValues(alpha: 0.38),
                                  padding: EdgeInsets.zero,
                                )
                              else if (_error != null)
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 32),
                                  child: Text(
                                    _error!,
                                    style: GoogleFonts.montserrat(
                                      color: AppColors.onGradientMuted,
                                      fontSize: 14,
                                    ),
                                  ),
                                )
                              else if (_jobs.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 48,
                                  ),
                                  child: Center(
                                    child: Text(
                                      'No pairs are currently in treatment',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.montserrat(
                                        color: AppColors.onGradientBody,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                )
                              else ...[
                                Text(
                                  'Active jobs',
                                  style: GoogleFonts.montserrat(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                ..._jobs.map(
                                  (r) => Padding(
                                    padding: const EdgeInsets.only(bottom: 14),
                                    child: _ActiveJobCard(
                                      request: r,
                                      dropOffConfirmed: _dropOffConfirmed,
                                      showPayNow: _showPayNow(r),
                                      amount: _payableAmount(r),
                                      requestLabel: _requestLabel(r),
                                      approving: _approvingIdBusy,
                                      onTap: () => _openProgress(r),
                                      onPayNow: () => _openPayNow(r),
                                    ),
                                  ),
                                ),
                              ],
                            ]),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const DashboardLinkedBottomNav(selectedTabIndex: 1),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ChevronScreenBackButton(iconColor: _titleColor),
        const SizedBox(width: 7),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text(
                'Active Services',
                style: GoogleFonts.boldonse(
                  color: _titleColor,
                  fontSize: 24,
                  fontWeight: FontWeight.w400,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _loading
                    ? 'Loading active jobs…'
                    : _jobs.isEmpty
                        ? 'No active services right now.'
                        : 'You have ${_jobs.length} active service${_jobs.length == 1 ? '' : 's'}.',
                style: GoogleFonts.montserrat(
                  color: AppColors.onGradientBody,
                  fontSize: 13,
                  fontWeight: FontWeight.w300,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActiveJobCard extends StatelessWidget {
  const _ActiveJobCard({
    required this.request,
    required this.dropOffConfirmed,
    required this.showPayNow,
    required this.amount,
    required this.requestLabel,
    required this.approving,
    required this.onTap,
    required this.onPayNow,
  });

  final Map<String, dynamic> request;
  final Set<String> dropOffConfirmed;
  final bool showPayNow;
  final double amount;
  final String requestLabel;
  final bool approving;
  final VoidCallback onTap;
  final VoidCallback onPayNow;

  @override
  Widget build(BuildContext context) {
    final serviceTitle = CareActiveJob.serviceLabel(
      (request['serviceType'] ?? '').toString(),
    );
    final status = CareActiveJob.statusBlurb(request);
    final needsDrop = CareActiveJob.needsDropOffConfirm(
      request,
      dropOffConfirmedIds: dropOffConfirmed,
    );
    final eta = CareActiveJob.formatEstimatePretty(
      CareActiveJob.estimatedDelivery(request),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFF7FD4E0).withValues(alpha: 0.9),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF7FD4E0)),
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                    child: SvgPicture.asset(
                      'assets/images/noun-shoes-cleaning-7675732 1.svg',
                      fit: BoxFit.contain,
                      colorFilter: const ColorFilter.mode(
                        Color(0xFF7FD4E0),
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          serviceTitle,
                          style: GoogleFonts.montserrat(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          requestLabel,
                          style: GoogleFonts.montserrat(
                            color: AppColors.onGradientMuted,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          status,
                          style: GoogleFonts.montserrat(
                            color: AppColors.onGradientBody,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          needsDrop ? 'Drop off: Confirm at hub' : 'ETA: $eta',
                          style: GoogleFonts.montserrat(
                            color: AppColors.onGradientMuted,
                            fontSize: 11,
                          ),
                        ),
                        if (amount > 0) ...[
                          const SizedBox(height: 6),
                          Text(
                            PaymentAmountFormatter.formatGrouped(amount),
                            style: GoogleFonts.montserrat(
                              color: AppColors.secondary,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              if (showPayNow) ...[
                const SizedBox(height: 12),
                PayNowButton(
                  onPressed: approving ? null : onPayNow,
                  loading: approving,
                  label: 'Pay Now',
                  showIcon: false,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
