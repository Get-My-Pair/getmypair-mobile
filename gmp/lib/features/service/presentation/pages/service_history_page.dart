import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gmp/core/constants/api_endpoints.dart';
import 'package:gmp/core/network/dio_client.dart';
import 'package:gmp/core/widgets/app_skeleton.dart';
import 'package:gmp/core/widgets/article_rack_shoe_image.dart';
import 'package:gmp/core/widgets/floating_gradient_bottom_nav.dart';
import 'package:gmp/features/auth/domain/usecases/get_valid_access_token.dart';
import 'package:gmp/features/service/presentation/pages/service_review_page.dart';
import 'package:gmp/features/service/presentation/utils/care_active_job.dart';
import 'package:gmp/features/service/presentation/utils/care_service_review_store.dart';
import 'package:gmp/features/service/presentation/widgets/service_request_bg_layer.dart';
import 'package:gmp/injection_container.dart';

/// Delivered / completed Care jobs — Rate your pair’s glow-up.
class ServiceHistoryPage extends StatefulWidget {
  const ServiceHistoryPage({super.key});

  static const BorderRadius _panelRadius = BorderRadius.only(
    topLeft: Radius.circular(20),
    topRight: Radius.circular(20),
    bottomLeft: Radius.circular(50),
    bottomRight: Radius.circular(50),
  );

  @override
  State<ServiceHistoryPage> createState() => _ServiceHistoryPageState();
}

class _ServiceHistoryPageState extends State<ServiceHistoryPage> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _jobs = const [];
  Set<String> _reviewedIds = {};

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

    final reviews = await CareServiceReviewStore.loadAll();
    final tokenResult = await sl<GetValidAccessToken>().call();
    if (!mounted) return;

    await tokenResult.fold(
      (_) async {
        setState(() {
          _loading = false;
          _error = 'Please sign in again';
          _reviewedIds = reviews.keys.toSet();
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
              .where(CareActiveJob.isHistoryCareRequest)
              .toList()
            ..sort((a, b) {
              final da = DateTime.tryParse((a['updatedAt'] ?? a['createdAt'] ?? '').toString()) ??
                  DateTime.fromMillisecondsSinceEpoch(0);
              final db = DateTime.tryParse((b['updatedAt'] ?? b['createdAt'] ?? '').toString()) ??
                  DateTime.fromMillisecondsSinceEpoch(0);
              return db.compareTo(da);
            });
          if (!mounted) return;
          setState(() {
            _jobs = jobs;
            _reviewedIds = reviews.keys.toSet();
            _loading = false;
          });
        } catch (e) {
          if (!mounted) return;
          setState(() {
            _loading = false;
            _reviewedIds = reviews.keys.toSet();
            _error = e.toString().replaceFirst('Exception: ', '');
          });
        }
      },
    );
  }

  Future<void> _openReview(Map<String, dynamic> r) async {
    final submitted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ServiceReviewPage(request: r),
      ),
    );
    if (!mounted) return;
    if (submitted == true) await _load();
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
                    borderRadius: ServiceHistoryPage._panelRadius,
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
                  borderRadius: ServiceHistoryPage._panelRadius,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 12, 8, 8),
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
                                'Service History',
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
                                          'No completed services yet',
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
                                          padding: EdgeInsets.fromLTRB(
                                            16,
                                            8,
                                            16,
                                            120 + bottomSafe,
                                          ),
                                          itemCount: _jobs.length,
                                          separatorBuilder: (_, __) =>
                                              const SizedBox(height: 14),
                                          itemBuilder: (_, i) {
                                            final r = _jobs[i];
                                            final id =
                                                CareActiveJob.requestId(r);
                                            return _HistoryCard(
                                              request: r,
                                              alreadyRated:
                                                  _reviewedIds.contains(id),
                                              onRate: () => _openReview(r),
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
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const DashboardLinkedBottomNav(selectedTabIndex: 1),
                SizedBox(height: bottomSafe > 0 ? 0 : 0),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({
    required this.request,
    required this.alreadyRated,
    required this.onRate,
  });

  final Map<String, dynamic> request;
  final bool alreadyRated;
  final VoidCallback onRate;

  @override
  Widget build(BuildContext context) {
    final brand = CareActiveJob.brand(request);
    final model = CareActiveJob.modelLine(request);
    final option = CareActiveJob.serviceOptionLabel(request);
    final serviceType = (request['serviceType'] ?? '').toString();
    final badge = CareActiveJob.serviceLabel(serviceType);
    final imageUrl = CareActiveJob.articleImageUrl(request);
    final badgeAsset = CareActiveJob.serviceBadgeAsset(serviceType);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF0F6876), width: 1),
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
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      model,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.montserrat(
                        color: const Color(0xFF8A9496),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            option,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.montserrat(
                              color: const Color(0xFF062F35),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF062F35),
                            borderRadius: BorderRadius.circular(6),
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
                              const SizedBox(width: 4),
                              Text(
                                badge,
                                style: GoogleFonts.montserrat(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 72,
                  height: 56,
                  child: imageUrl.isEmpty
                      ? Container(
                          color: const Color(0xFFE8EEEE),
                          child: const Icon(
                            Icons.directions_walk_rounded,
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
          if (alreadyRated)
            Container(
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFE8EEEE),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: const Color(0xFF0F6876)),
              ),
              child: Text(
                'Thanks for rating',
                style: GoogleFonts.boldonse(
                  color: const Color(0xFF062F35),
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
              ),
            )
          else
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onRate,
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
                    child: Text(
                      "Rate your pair's glow-up",
                      style: GoogleFonts.boldonse(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
