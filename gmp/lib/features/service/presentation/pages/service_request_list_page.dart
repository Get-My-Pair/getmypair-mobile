import 'package:flutter/material.dart';
import 'package:gmp/core/constants/api_endpoints.dart';
import 'package:gmp/core/network/dio_client.dart';
import 'package:gmp/core/theme/app_colors.dart';
import 'package:gmp/core/widgets/article_rack_shoe_image.dart';
import 'package:gmp/core/widgets/floating_gradient_bottom_nav.dart';
import 'package:gmp/features/auth/domain/usecases/get_valid_access_token.dart';
import 'package:gmp/injection_container.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:gmp/features/service/presentation/widgets/service_request_bg_layer.dart';
import 'service_request_details_page.dart';

/// Same workflow order as [ServiceRequestDetailsPage] — used for list progress preview.
const List<String> _kWorkflowStages = [
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

class ServiceRequestListPage extends StatefulWidget {
  const ServiceRequestListPage({super.key});

  static const BorderRadius _panelRadius = BorderRadius.only(
    topLeft: Radius.circular(20),
    topRight: Radius.circular(20),
    bottomLeft: Radius.circular(50),
    bottomRight: Radius.circular(50),
  );

  @override
  State<ServiceRequestListPage> createState() => _ServiceRequestListPageState();
}

class _ServiceRequestListPageState extends State<ServiceRequestListPage> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _requests = const [];

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
            ApiEndpoints.serviceMy,
            accessToken: token,
          );
          final list =
              ((res['data'] as Map<String, dynamic>?)?['requests'] as List?) ??
                  const [];
          if (!mounted) return;
          setState(() {
            _requests = list
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList();
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

  static String _serviceLabel(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'repair':
        return 'Repair My Pair';
      case 'maintenance':
        return 'Maintain My Pair';
      case 'wash':
        return 'Wash My Pair';
      case 'donate':
        return 'Donate My Pair';
      case 'dispose':
        return 'Dispose My Pair';
      default:
        if (raw.isEmpty) return 'Service';
        return raw.replaceAll('_', ' ');
    }
  }

  static String _shortId(String id) {
    if (id.length <= 10) return id;
    return '…${id.substring(id.length - 6)}';
  }

  static String? _formatCreated(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return null;
    final dt = DateTime.tryParse(t);
    if (dt == null) return t;
    return DateFormat('d MMM yyyy · h:mm a').format(dt.toLocal());
  }

  static double _progressValue(Map<String, dynamic> r) {
    final tracking = (r['trackingState'] ?? 'request_created').toString();
    var idx = _kWorkflowStages.indexOf(tracking);
    if (idx < 0) idx = 0;
    return ((idx + 1) / _kWorkflowStages.length).clamp(0.0, 1.0);
  }

  static String _trackingLabel(Map<String, dynamic> r) {
    final tracking = (r['trackingState'] ?? '').toString();
    if (tracking.isEmpty) return 'Progress';
    return tracking.replaceAll('_', ' ');
  }

  /// Resolves a usable image URL from a raw upload path.
  static String _resolveImageUrl(String path) {
    final p = path.trim();
    if (p.isEmpty) return '';
    if (p.startsWith('http')) return p;
    final base = ApiEndpoints.baseUrl;
    if (p.startsWith('/')) return '$base$p';
    return '$base/uploads/$p';
  }

  /// Picks one article image for the request thumbnail.
  ///
  /// `articleId` is populated by the API as an object with an `images` list.
  /// When multiple articles/images exist we just show the first available one.
  static String _articleImageUrl(Map<String, dynamic> r) {
    final article = r['articleId'];
    if (article is Map) {
      final images = article['images'];
      if (images is List) {
        for (final img in images) {
          final url = _resolveImageUrl(img?.toString() ?? '');
          if (url.isNotEmpty) return url;
        }
      }
    }
    // Fallback: first proof photo if the article has no image.
    final photos = r['photos'];
    if (photos is List) {
      for (final p in photos) {
        final url = _resolveImageUrl(p?.toString() ?? '');
        if (url.isNotEmpty) return url;
      }
    }
    return '';
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
                    borderRadius: ServiceRequestListPage._panelRadius,
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
                  borderRadius: ServiceRequestListPage._panelRadius,
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
                                'My Services',
                                style: GoogleFonts.boldonse(
                                  color: const Color(0xFF062F35),
                                  fontSize: 24,
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
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                        child: Text(
                          'Tap a request to view full progress and updates.',
                          style: GoogleFonts.montserrat(
                            color: Colors.black.withValues(alpha: 0.55),
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                          ),
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
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            _error!,
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.montserrat(
                                              color: const Color(0xFFB00020),
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 16),
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
                                : _requests.isEmpty
                                    ? Center(
                                        child: Padding(
                                          padding: const EdgeInsets.all(32),
                                          child: Text(
                                            'No service requests yet.\n'
                                            'Start from Care My Pair or Rehome.',
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.montserrat(
                                              color: const Color(0xFF5C5C5C),
                                              fontSize: 15,
                                              height: 1.4,
                                            ),
                                          ),
                                        ),
                                      )
                                    : RefreshIndicator(
                                        color: const Color(0xFF11999E),
                                        onRefresh: _load,
                                        child: ListView.builder(
                                          padding: const EdgeInsets.fromLTRB(
                                            14,
                                            4,
                                            14,
                                            120,
                                          ),
                                          itemCount: _requests.length,
                                          itemBuilder: (_, index) {
                                            final r = _requests[index];
                                            final id =
                                                (r['_id'] ?? '').toString();
                                            final serviceType =
                                                (r['serviceType'] ?? '')
                                                    .toString();
                                            final status =
                                                (r['status'] ?? '').toString();
                                            final createdRaw =
                                                (r['createdAt'] ?? '')
                                                    .toString();
                                            final created =
                                                _formatCreated(createdRaw);
                                            final progress =
                                                _progressValue(r);
                                            final trackLabel =
                                                _trackingLabel(r);
                                            final imageUrl =
                                                _articleImageUrl(r);

                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                bottom: 12,
                                              ),
                                              child: Material(
                                                color: Colors.transparent,
                                                child: InkWell(
                                                  borderRadius:
                                                      BorderRadius.circular(14),
                                                  onTap: () async {
                                                    await Navigator.of(context)
                                                        .push<void>(
                                                      MaterialPageRoute<void>(
                                                        builder: (_) =>
                                                            ServiceRequestDetailsPage(
                                                          requestId: id,
                                                        ),
                                                      ),
                                                    );
                                                    if (mounted) _load();
                                                  },
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.all(
                                                      14,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.white
                                                          .withValues(
                                                        alpha: 0.72,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                        14,
                                                      ),
                                                      border: Border.all(
                                                        color: const Color(
                                                          0xFF0F6876,
                                                        ).withValues(
                                                          alpha: 0.35,
                                                        ),
                                                      ),
                                                      boxShadow: const [
                                                        BoxShadow(
                                                          color: Color(
                                                            0x12000000,
                                                          ),
                                                          blurRadius: 8,
                                                          offset: Offset(0, 3),
                                                        ),
                                                      ],
                                                    ),
                                                    child: Row(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        _ArticleThumb(
                                                          imageUrl: imageUrl,
                                                        ),
                                                        const SizedBox(
                                                          width: 12,
                                                        ),
                                                        Expanded(
                                                          child: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                        Row(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Expanded(
                                                              child: Text(
                                                                _serviceLabel(
                                                                  serviceType,
                                                                ),
                                                                style: GoogleFonts
                                                                    .boldonse(
                                                                  color: const Color(
                                                                    0xFF062F35,
                                                                  ),
                                                                  fontSize: 16,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w400,
                                                                ),
                                                              ),
                                                            ),
                                                            _StatusChip(
                                                                status),
                                                          ],
                                                        ),
                                                        const SizedBox(
                                                          height: 10,
                                                        ),
                                                        Text(
                                                          'Progress · $trackLabel',
                                                          style: GoogleFonts
                                                              .montserrat(
                                                            fontSize: 12,
                                                            fontWeight:
                                                                FontWeight
                                                                    .w600,
                                                            color: const Color(
                                                              0xFF12899B,
                                                            ),
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          height: 6,
                                                        ),
                                                        ClipRRect(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                            100,
                                                          ),
                                                          child:
                                                              LinearProgressIndicator(
                                                            value: progress,
                                                            minHeight: 6,
                                                            backgroundColor:
                                                                const Color(
                                                              0xFFDFE7E9,
                                                            ),
                                                            valueColor:
                                                                const AlwaysStoppedAnimation<
                                                                    Color>(
                                                              Color(
                                                                0xFF0F6876,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          height: 10,
                                                        ),
                                                        Row(
                                                          children: [
                                                            Text(
                                                              'ID ${_shortId(id)}',
                                                              style: GoogleFonts
                                                                  .montserrat(
                                                                fontSize: 11,
                                                                color: Colors
                                                                    .black
                                                                    .withValues(
                                                                  alpha: 0.45,
                                                                ),
                                                              ),
                                                            ),
                                                            if (created !=
                                                                null) ...[
                                                              Text(
                                                                ' · ',
                                                                style: GoogleFonts
                                                                    .montserrat(
                                                                  fontSize: 11,
                                                                  color: Colors
                                                                      .black
                                                                      .withValues(
                                                                    alpha:
                                                                        0.35,
                                                                  ),
                                                                ),
                                                              ),
                                                              Expanded(
                                                                child: Text(
                                                                  created,
                                                                  maxLines: 1,
                                                                  overflow:
                                                                      TextOverflow
                                                                          .ellipsis,
                                                                  style: GoogleFonts
                                                                      .montserrat(
                                                                    fontSize:
                                                                        11,
                                                                    color: Colors
                                                                        .black
                                                                        .withValues(
                                                                      alpha:
                                                                          0.45,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ],
                                                        ),
                                                        const SizedBox(
                                                          height: 4,
                                                        ),
                                                        Row(
                                                          children: [
                                                            Text(
                                                              'View progress',
                                                              style: GoogleFonts
                                                                  .montserrat(
                                                                fontSize: 13,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                color: const Color(
                                                                  0xFF0F6876,
                                                                ),
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                              width: 4,
                                                            ),
                                                            const Icon(
                                                              Icons
                                                                  .arrow_forward_ios_rounded,
                                                              size: 12,
                                                              color: Color(
                                                                0xFF0F6876,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
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
                SizedBox(height: bottomSafe),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Square article thumbnail shown on the left of each service request card.
class _ArticleThumb extends StatelessWidget {
  final String imageUrl;

  const _ArticleThumb({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    const double size = 92;
    final placeholder = Container(
      color: const Color(0xFFEAF3F4),
      alignment: Alignment.center,
      child: Icon(
        Icons.checkroom_rounded,
        size: 34,
        color: const Color(0xFF0F6876).withValues(alpha: 0.45),
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: const Color(0xFFEAF3F4),
          border: Border.all(
            color: const Color(0xFF0F6876).withValues(alpha: 0.18),
          ),
        ),
        child: imageUrl.isEmpty
            ? placeholder
            : Padding(
                padding: const EdgeInsets.all(6),
                child: ArticleRackShoeImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.contain,
                  borderRadius: BorderRadius.circular(8),
                  placeholder: placeholder,
                  errorPlaceholder: placeholder,
                ),
              ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip(this.status);

  @override
  Widget build(BuildContext context) {
    final v = status.trim().toLowerCase();
    Color bg = AppColors.info.withValues(alpha: 0.12);
    Color fg = AppColors.info;
    if (v == 'completed') {
      bg = AppColors.success.withValues(alpha: 0.12);
      fg = AppColors.success;
    } else if (v == 'cancelled') {
      bg = AppColors.error.withValues(alpha: 0.12);
      fg = AppColors.error;
    } else if (v == 'in_service') {
      bg = AppColors.primary.withValues(alpha: 0.12);
      fg = AppColors.primary;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.replaceAll('_', ' ').toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}
