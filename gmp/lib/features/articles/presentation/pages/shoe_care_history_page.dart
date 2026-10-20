import 'package:flutter/material.dart';
import 'package:gmp/core/bgtheme.dart';
import 'package:gmp/core/constants/api_endpoints.dart';
import 'package:gmp/core/network/dio_client.dart';
import 'package:gmp/core/theme/app_colors.dart';
import 'package:gmp/core/widgets/floating_gradient_bottom_nav.dart';
import 'package:gmp/features/articles/domain/entities/article.dart';
import 'package:gmp/features/auth/domain/usecases/get_valid_access_token.dart';
import 'package:gmp/features/service/presentation/pages/service_request_details_page.dart';
import 'package:gmp/injection_container.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

/// Care history for one article — repair / maintenance / wash requests.
class ShoeCareHistoryPage extends StatefulWidget {
  final String articleId;
  final Article? article;

  const ShoeCareHistoryPage({
    super.key,
    required this.articleId,
    this.article,
  });

  static const Color _teal = Color(0xFF11899B);
  static const Color _panelBg = Color(0xFFF0F0F0);
  static const BorderRadius _panelRadius = BorderRadius.only(
    topLeft: Radius.circular(20),
    topRight: Radius.circular(20),
    bottomLeft: Radius.circular(50),
    bottomRight: Radius.circular(50),
  );

  static const Set<String> _careTypes = {
    'repair',
    'maintenance',
    'wash',
  };

  @override
  State<ShoeCareHistoryPage> createState() => _ShoeCareHistoryPageState();
}

class _ShoeCareHistoryPageState extends State<ShoeCareHistoryPage> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _entries = const [];

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
          final targetId = widget.articleId.trim();
          final filtered = list
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .where((r) {
                final type =
                    (r['serviceType'] ?? '').toString().trim().toLowerCase();
                if (!ShoeCareHistoryPage._careTypes.contains(type)) {
                  return false;
                }
                return _articleIdOf(r) == targetId;
              })
              .toList();

          if (!mounted) return;
          setState(() {
            _entries = filtered;
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

  static String _articleIdOf(Map<String, dynamic> r) {
    final raw = r['articleId'];
    if (raw is Map) {
      return (raw['_id'] ?? raw['id'] ?? '').toString();
    }
    return (raw ?? '').toString();
  }

  static String _serviceLabel(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'repair':
        return 'Repair My Pair';
      case 'maintenance':
        return 'Maintain My Pair';
      case 'wash':
        return 'Wash My Pair';
      default:
        if (raw.isEmpty) return 'Shoe care';
        return raw.replaceAll('_', ' ');
    }
  }

  static String? _formatDate(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return null;
    final dt = DateTime.tryParse(t);
    if (dt == null) return t;
    return DateFormat('d MMM yyyy').format(dt.toLocal());
  }

  static String? _formatTime(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return null;
    final dt = DateTime.tryParse(t);
    if (dt == null) return null;
    return DateFormat('h:mm a').format(dt.toLocal());
  }

  String get _subtitle {
    final a = widget.article;
    if (a == null) return 'Past care visits for this pair';
    final brand = a.brand.trim();
    final model = a.model.trim();
    if (brand.isEmpty && model.isEmpty) {
      return 'Past care visits for this pair';
    }
    if (model.isEmpty) return brand;
    if (brand.isEmpty) return model;
    return '$brand · $model';
  }

  @override
  Widget build(BuildContext context) {
    final bottomSafe = MediaQuery.viewPaddingOf(context).bottom;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.none,
        children: [
          ...BgTheme.background(),
          Positioned.fill(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 30, 10, 0),
                child: DecoratedBox(
                  decoration: const ShapeDecoration(
                    color: ShoeCareHistoryPage._panelBg,
                    shape: RoundedRectangleBorder(
                      borderRadius: ShoeCareHistoryPage._panelRadius,
                    ),
                    shadows: [
                      BoxShadow(
                        color: Color(0x19000000),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: ShoeCareHistoryPage._panelRadius,
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
                                  'Shoe care history',
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
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                          child: Text(
                            _subtitle,
                            style: GoogleFonts.montserrat(
                              color: Colors.black.withValues(alpha: 0.55),
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                        Expanded(child: _buildBody()),
                      ],
                    ),
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

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: ShoeCareHistoryPage._teal),
      );
    }
    if (_error != null) {
      return Center(
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
                  backgroundColor: ShoeCareHistoryPage._teal,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (_entries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.spa_outlined,
                size: 52,
                color: ShoeCareHistoryPage._teal.withValues(alpha: 0.45),
              ),
              const SizedBox(height: 16),
              Text(
                'No care history yet',
                style: GoogleFonts.boldonse(
                  fontSize: 18,
                  color: const Color(0xFF062F35),
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'When this pair is sent for repair, wash, or maintenance, visits will show up here.',
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  color: const Color(0xFF5C5C5C),
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: ShoeCareHistoryPage._teal,
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 120),
        itemCount: _entries.length,
        itemBuilder: (context, index) {
          final r = _entries[index];
          final isLast = index == _entries.length - 1;
          return _CareTimelineTile(
            request: r,
            isLast: isLast,
            serviceLabel: _serviceLabel(
              (r['serviceType'] ?? '').toString(),
            ),
            dateLabel: _formatDate((r['createdAt'] ?? '').toString()),
            timeLabel: _formatTime((r['createdAt'] ?? '').toString()),
            onTap: () async {
              final id = (r['_id'] ?? '').toString();
              if (id.isEmpty) return;
              await Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => ServiceRequestDetailsPage(requestId: id),
                ),
              );
              if (mounted) _load();
            },
          );
        },
      ),
    );
  }
}

class _CareTimelineTile extends StatelessWidget {
  final Map<String, dynamic> request;
  final bool isLast;
  final String serviceLabel;
  final String? dateLabel;
  final String? timeLabel;
  final VoidCallback onTap;

  const _CareTimelineTile({
    required this.request,
    required this.isLast,
    required this.serviceLabel,
    required this.dateLabel,
    required this.timeLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final status = (request['status'] ?? '').toString();
    final tracking = (request['trackingState'] ?? '').toString();

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 22,
            child: Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: ShoeCareHistoryPage._teal,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x220F6876),
                        blurRadius: 4,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: const Color(0xFF0F6876).withValues(alpha: 0.22),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: onTap,
                  child: Ink(
                    padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color:
                            const Color(0xFF0F6876).withValues(alpha: 0.28),
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
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                serviceLabel,
                                style: GoogleFonts.boldonse(
                                  color: const Color(0xFF062F35),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                            _StatusChip(status),
                          ],
                        ),
                        if (dateLabel != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            timeLabel == null
                                ? dateLabel!
                                : '$dateLabel · $timeLabel',
                            style: GoogleFonts.montserrat(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.black.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                        if (tracking.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            tracking.replaceAll('_', ' '),
                            style: GoogleFonts.montserrat(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: ShoeCareHistoryPage._teal,
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              'View details',
                              style: GoogleFonts.montserrat(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF0F6876),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 12,
                              color: Color(0xFF0F6876),
                            ),
                          ],
                        ),
                      ],
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
