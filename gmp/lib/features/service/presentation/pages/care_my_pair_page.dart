import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gmp/core/bgtheme.dart';
import 'package:gmp/core/constants/api_endpoints.dart';
import 'package:gmp/core/network/dio_client.dart';
import 'package:gmp/core/widgets/app_feedback_alert.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gmp/core/widgets/floating_gradient_bottom_nav.dart';
import 'package:gmp/features/auth/domain/usecases/get_valid_access_token.dart';
import 'package:gmp/injection_container.dart';
import 'package:gmp/features/service/presentation/pages/maintain_my_pair_page.dart';
import 'package:gmp/features/service/presentation/pages/repair_my_pair_page.dart';
import 'package:gmp/features/service/presentation/pages/service_request_details_page.dart';
import 'package:gmp/features/service/presentation/pages/service_request_list_page.dart';
import 'package:gmp/features/service/presentation/pages/wash_my_pair_page.dart';
import 'package:intl/intl.dart';

class CareMyPairPage extends StatelessWidget {
  const CareMyPairPage({super.key});

  /// Flip to `true` when real video/article assets are ready.
  /// Paths and UI below stay in place — only visibility is gated.
  static const bool _showStaticMedia = false;

  static const BorderRadius _panelRadius = BorderRadius.only(
    topLeft: Radius.circular(20),
    topRight: Radius.circular(20),
    bottomLeft: Radius.circular(50),
    bottomRight: Radius.circular(50),
  );

  // --- Static media paths (placeholder assets; enable via _showStaticMedia) ---
  static const List<_VideoCardData> _repairVideos = [
    _VideoCardData(
      title: 'Fix Scuffs Fast: At-Home Sole & Upper Repair',
      image: 'assets/images/img/caremypair/vid13.png',
    ),
    _VideoCardData(
      title: 'Glue & Patch: Save a Separating Sole',
      image: 'assets/images/img/caremypair/vid2.png',
    ),
    _VideoCardData(
      title: 'Stitch-Free Fixes for Everyday Wear',
      image: 'assets/images/img/caremypair/vid13.png',
    ),
  ];

  static const List<_VideoCardData> _maintainVideos = [
    _VideoCardData(
      title: 'Suede Saver: How to Clean and Protect Suede Shoes',
      image: 'assets/images/img/caremypair/vid13.png',
    ),
    _VideoCardData(
      title: 'Everyday Shoe Care Hacks Using Household Items',
      image: 'assets/images/img/caremypair/vid2.png',
    ),
    _VideoCardData(
      title: 'Odor-Free Feet: How to De-Stink Your Shoes Naturally',
      image: 'assets/images/img/caremypair/vid13.png',
    ),
  ];

  static const List<_VideoCardData> _washVideos = [
    _VideoCardData(
      title: 'Deep Clean Sneakers: Brush & Soap Method',
      image: 'assets/images/img/caremypair/vid2.png',
    ),
    _VideoCardData(
      title: 'Refresh White Soles in 10 Minutes',
      image: 'assets/images/img/caremypair/vid13.png',
    ),
    _VideoCardData(
      title: 'Dry & Store: Keep Shape After a Wash',
      image: 'assets/images/img/caremypair/vid2.png',
    ),
  ];

  static const List<_ArticleCardData> _articles = [
    _ArticleCardData(
      title: 'Quick Shoe Refresh: 5-Min DIY Care at Home',
      summary: 'Lorem ipsum dolor sit amet consectetur. Tristique fringilla...',
      image: 'assets/images/img/caremypair/air1.png',
    ),
    _ArticleCardData(
      title: 'Make Your Shoes Last Longer',
      summary: 'Lorem ipsum dolor sit amet consectetur. Tristique fringilla...',
      image: 'assets/images/img/caremypair/air23.png',
    ),
    _ArticleCardData(
      title: 'Revive Old Sneakers: Deep Clean at Home',
      summary: 'Lorem ipsum dolor sit amet consectetur. Tristique fringilla...',
      image: 'assets/images/img/caremypair/air23.png',
    ),
  ];

  static const TextStyle _sectionTitleStyle = TextStyle(
    color: Color(0xFF062F35),
    fontSize: 16,
    fontWeight: FontWeight.w400,
  );

  static TextStyle _sectionTitle(BuildContext context) =>
      GoogleFonts.boldonse(textStyle: _sectionTitleStyle);

  static TextStyle _subsectionLabel(BuildContext context) =>
      GoogleFonts.montserrat(
        color: Colors.black,
        fontSize: 16,
        fontWeight: FontWeight.w400,
      );

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final uiScale = (width / 390).clamp(0.84, 1.12).toDouble();
    final horizontalInset = (10.0 * uiScale).clamp(8.0, 16.0);
    const topInset = 52.0;

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
                padding: EdgeInsets.fromLTRB(
                  horizontalInset,
                  topInset,
                  horizontalInset,
                  0,
                ),
                child: DecoratedBox(
                  decoration: const ShapeDecoration(
                    color: Color(0xFFF0F0F0),
                    shape: RoundedRectangleBorder(borderRadius: _panelRadius),
                    shadows: [
                      BoxShadow(
                        color: Color(0x19000000),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: _panelRadius,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 120),
                      children: [
                        _Header(onBack: () => Navigator.maybePop(context)),
                        const SizedBox(height: 20),
                        const _SearchBar(),
                        const SizedBox(height: 24),
                        Text('Our Services', style: _sectionTitle(context)),
                        const SizedBox(height: 14),
                        _PrimaryServiceCard(
                          label: 'RepairMyPair',
                          onTap: () => _openRepairPage(context),
                        ),
                        const SizedBox(height: 12),
                        IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: _SecondaryServiceCard(
                                  label: 'Maintain MyPair',
                                  iconAsset:
                                      'assets/images/icons/caremypair/mmp.svg',
                                  iconSize: 48,
                                  onTap: () => _openMaintainPage(context),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _SecondaryServiceCard(
                                  label: 'Wash MyPair',
                                  iconAsset:
                                      'assets/images/icons/caremypair/wmp.svg',
                                  iconSize: 48,
                                  onTap: () => _openWashPage(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const _ActiveServiceSection(),
                        const SizedBox(height: 16),
                        _ServiceHistoryButton(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const ServiceRequestListPage(),
                              ),
                            );
                          },
                        ),
                        // Videos + articles hidden until real media is ready.
                        if (_showStaticMedia) ...[
                          const SizedBox(height: 32),
                          ..._buildVideoSections(context),
                          const SizedBox(height: 24),
                          Text('Articles', style: _subsectionLabel(context)),
                          const SizedBox(height: 20),
                          SizedBox(
                            height: 172,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _articles.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(width: 13),
                              itemBuilder: (_, i) => _ArticleCard(
                                data: _articles[i],
                                onTap: () => showComingSoon(
                                  context,
                                  feature: 'Care articles',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
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
    );
  }

  List<Widget> _buildVideoSections(BuildContext context) {
    const sections =
        <({String title, List<_VideoCardData> videos, String feature})>[
      (
        title: 'Repair at Home: Quick Fixes',
        videos: _repairVideos,
        feature: 'Repair DIY videos',
      ),
      (
        title: 'Everyday Care & Maintenance',
        videos: _maintainVideos,
        feature: 'Maintenance DIY videos',
      ),
      (
        title: 'Wash & Restore at Home',
        videos: _washVideos,
        feature: 'Wash DIY videos',
      ),
    ];

    return [
      for (var i = 0; i < sections.length; i++) ...[
        if (i > 0) const SizedBox(height: 24),
        Text(sections[i].title, style: _sectionTitle(context)),
        const SizedBox(height: 14),
        Text('Videos', style: _subsectionLabel(context)),
        const SizedBox(height: 20),
        SizedBox(
          height: 113,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: sections[i].videos.length,
            separatorBuilder: (_, _) => const SizedBox(width: 14),
            itemBuilder: (_, index) => _VideoCard(
              data: sections[i].videos[index],
              onTap: () => showComingSoon(
                context,
                feature: sections[i].feature,
              ),
            ),
          ),
        ),
      ],
    ];
  }

  void _openMaintainPage(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const MaintainMyPairPage(),
      ),
    );
  }

  void _openWashPage(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const WashMyPairPage(),
      ),
    );
  }

  void _openRepairPage(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const RepairMyPairPage()),
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onBack;

  const _Header({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onBack,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints.tightFor(width: 26, height: 26),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF062F35),
            size: 24,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          'CareMyPair',
          style: GoogleFonts.boldonse(
            color: const Color(0xFF062F35),
            fontSize: 24,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar();

  @override
  Widget build(BuildContext context) {
    const searchHeight = 44.0;
    final width = MediaQuery.sizeOf(context).width;
    final uiScale = (width / 390).clamp(0.84, 1.12).toDouble();

    return Container(
      height: searchHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFB7C9CD), width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: [
            SvgPicture.asset(
              'assets/images/search.svg',
              width: 20,
              height: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                textAlignVertical: TextAlignVertical.center,
                style: GoogleFonts.montserrat(
                  fontSize: (15.0 * uiScale).clamp(13.0, 16.0),
                  color: Colors.black87,
                  fontWeight: FontWeight.w400,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  isCollapsed: false,
                  filled: false,
                  fillColor: Colors.transparent,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  hintText: 'Search',
                  hintStyle: GoogleFonts.montserrat(
                    color: Colors.black.withValues(alpha: 0.34),
                    fontSize: (15.0 * uiScale).clamp(13.0, 16.0),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrimaryServiceCard extends StatelessWidget {
  static const double _cardHeight = 86;
  final String label;
  final VoidCallback onTap;

  const _PrimaryServiceCard({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: _cardHeight,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF09DFFF), Color(0xFF063035)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(
                color: Color(0x19000000),
                blurRadius: 4,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                'assets/images/icons/caremypair/rmp.svg',
                width: 42,
                height: 42,
              ),
              const SizedBox(width: 14),
              Text(
                label,
                textAlign: TextAlign.center,
                style: GoogleFonts.boldonse(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SecondaryServiceCard extends StatelessWidget {
  static const double _minCardHeight = 86;
  final String label;
  final String iconAsset;
  final double iconSize;
  final VoidCallback onTap;

  const _SecondaryServiceCard({
    required this.label,
    required this.iconAsset,
    this.iconSize = 42,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      clipBehavior: Clip.none,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: _minCardHeight),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFDFE7E9),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF0F6876), width: 1.2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 4,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SvgPicture.asset(
                iconAsset,
                width: iconSize,
                height: iconSize,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.boldonse(
                    color: const Color(0xFF062F35),
                    fontSize: 13,
                    height: 1.15,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Loads the newest non-terminal care request and shows the Active Service card.
class _ActiveServiceSection extends StatefulWidget {
  const _ActiveServiceSection();

  static const Set<String> _careTypes = {'repair', 'maintenance', 'wash'};
  static const Set<String> _terminalStatuses = {'completed', 'cancelled'};
  static const Set<String> _terminalTracking = {'delivered', 'cancelled'};

  @override
  State<_ActiveServiceSection> createState() => _ActiveServiceSectionState();
}

class _ActiveServiceSectionState extends State<_ActiveServiceSection> {
  Map<String, dynamic>? _active;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final tokenResult = await sl<GetValidAccessToken>().call();
    if (!mounted) return;

    await tokenResult.fold(
      (_) async {},
      (token) async {
        try {
          final res = await sl<DioClient>().get(
            ApiEndpoints.serviceMy,
            accessToken: token,
          );
          final list =
              ((res['data'] as Map<String, dynamic>?)?['requests'] as List?) ??
                  const [];
          final active = list
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .where(_isActiveCareRequest)
              .toList();
          if (!mounted) return;
          setState(() => _active = active.isEmpty ? null : active.first);
        } catch (_) {
          // Keep hidden on failure.
        }
      },
    );
  }

  static bool _isActiveCareRequest(Map<String, dynamic> r) {
    final type = (r['serviceType'] ?? '').toString().trim().toLowerCase();
    if (!_ActiveServiceSection._careTypes.contains(type)) return false;
    final status = (r['status'] ?? '').toString().trim().toLowerCase();
    if (_ActiveServiceSection._terminalStatuses.contains(status)) return false;
    final tracking =
        (r['trackingState'] ?? '').toString().trim().toLowerCase();
    if (_ActiveServiceSection._terminalTracking.contains(tracking)) {
      return false;
    }
    return true;
  }

  static String _serviceLabel(String raw) {
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

  static String _iconAsset(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'maintenance':
        return 'assets/images/icons/caremypair/mmp.svg';
      case 'wash':
        return 'assets/images/icons/caremypair/wmp.svg';
      default:
        return 'assets/images/icons/caremypair/rmp.svg';
    }
  }

  static String _ordinalDay(int day) {
    if (day >= 11 && day <= 13) return '${day}th';
    switch (day % 10) {
      case 1:
        return '${day}st';
      case 2:
        return '${day}nd';
      case 3:
        return '${day}rd';
      default:
        return '${day}th';
    }
  }

  /// Prefer requested pickup; otherwise estimate ~7 days from createdAt.
  static String _estimatedDelivery(Map<String, dynamic> r) {
    DateTime? dt = DateTime.tryParse(
      (r['requestedPickupAt'] ?? '').toString(),
    );
    dt ??= DateTime.tryParse((r['createdAt'] ?? '').toString());
    if (dt == null) return 'TBD';
    // Use pickup window if present; else rough ETA from creation.
    if (r['requestedPickupAt'] == null ||
        (r['requestedPickupAt']?.toString() ?? '').trim().isEmpty) {
      dt = dt.add(const Duration(days: 7));
    }
    final local = dt.toLocal();
    return '${_ordinalDay(local.day)} ${DateFormat('MMM yyyy').format(local)}';
  }

  static String _requestId(Map<String, dynamic> r) {
    return (r['_id'] ?? r['id'] ?? '').toString().trim();
  }

  void _openActive(BuildContext context) {
    final id = _active == null ? '' : _requestId(_active!);
    if (id.isEmpty) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const ServiceRequestListPage(),
        ),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ServiceRequestDetailsPage(requestId: id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_active == null) return const SizedBox.shrink();

    final serviceType = (_active!['serviceType'] ?? '').toString();
    final label = _serviceLabel(serviceType);
    final eta = _estimatedDelivery(_active!);
    final iconAsset = _iconAsset(serviceType);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 28),
        InkWell(
          onTap: () => _openActive(context),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Active Service',
                    style: GoogleFonts.boldonse(
                      color: const Color(0xFF062F35),
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF062F35),
                  size: 28,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        _ActiveServiceCard(
          serviceLabel: label,
          estimatedDelivery: eta,
          iconAsset: iconAsset,
          onTap: () => _openActive(context),
        ),
      ],
    );
  }
}

class _ActiveServiceCard extends StatelessWidget {
  final String serviceLabel;
  final String estimatedDelivery;
  final String iconAsset;
  final VoidCallback onTap;

  const _ActiveServiceCard({
    required this.serviceLabel,
    required this.estimatedDelivery,
    required this.iconAsset,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(12, 14, 14, 14),
          decoration: BoxDecoration(
            color: const Color(0xFFDFE7E9),
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 4,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFDFE7E9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFF0F6876),
                    width: 1.4,
                  ),
                ),
                alignment: Alignment.center,
                child: SvgPicture.asset(
                  iconAsset,
                  width: 30,
                  height: 30,
                  colorFilter: const ColorFilter.mode(
                    Color(0xFF0F6876),
                    BlendMode.srcIn,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: _LabeledValue(
                        label: 'Service Type',
                        value: serviceLabel,
                      ),
                    ),
                    Expanded(
                      child: _LabeledValue(
                        label: 'Estimated Delivery',
                        value: estimatedDelivery,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LabeledValue extends StatelessWidget {
  final String label;
  final String value;

  const _LabeledValue({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.montserrat(
            color: const Color(0xFF11899B),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.montserrat(
            color: const Color(0xFF5A5A5A),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _ServiceHistoryButton extends StatelessWidget {
  final VoidCallback onTap;

  const _ServiceHistoryButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFE8EEEE),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF0F6876), width: 1.2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 4,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.history_rounded,
                color: Color(0xFF062F35),
                size: 26,
              ),
              const SizedBox(width: 10),
              Text(
                'Service History',
                style: GoogleFonts.boldonse(
                  color: const Color(0xFF062F35),
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VideoCardData {
  final String title;
  final String image;

  const _VideoCardData({required this.title, required this.image});
}

class _VideoCard extends StatelessWidget {
  final _VideoCardData data;
  final VoidCallback onTap;

  const _VideoCard({required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 174,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Stack(
              fit: StackFit.expand,
              children: [
                data.image.startsWith('http')
                    ? Image.network(
                        data.image,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            Container(color: Colors.grey.shade400),
                      )
                    : Image.asset(
                        data.image,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            Container(color: Colors.grey.shade400),
                      ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0xCC000000)],
                    ),
                  ),
                ),
                Positioned(
                  left: 8,
                  right: 8,
                  bottom: 8,
                  child: Text(
                    data.title,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.montserrat(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ArticleCardData {
  final String title;
  final String summary;
  final String image;

  const _ArticleCardData({
    required this.title,
    required this.summary,
    required this.image,
  });
}

class _ArticleCard extends StatelessWidget {
  final _ArticleCardData data;
  final VoidCallback onTap;

  const _ArticleCard({required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(5),
        child: Container(
          width: 160,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: const Color(0xFFE2E2E2)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x26000000),
                blurRadius: 4,
                offset: Offset(2, 2),
                spreadRadius: 0,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(5),
                      ),
                      child: data.image.startsWith('http')
                          ? Image.network(
                              data.image,
                              width: 160,
                              height: 86,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Container(
                                width: 160,
                                height: 86,
                                color: Colors.grey.shade300,
                              ),
                            )
                          : Image.asset(
                              data.image,
                              width: 160,
                              height: 86,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Container(
                                width: 160,
                                height: 86,
                                color: Colors.grey.shade300,
                              ),
                            ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(9, 9, 9, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.montserrat(
                                color: Colors.black,
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Expanded(
                              child: Text(
                                data.summary,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.montserrat(
                                  color: const Color(0xFF929292),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
