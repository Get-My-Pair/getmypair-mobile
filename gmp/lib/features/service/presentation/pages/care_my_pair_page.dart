import 'dart:math' as math;

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
import 'package:gmp/features/service/presentation/pages/active_services_page.dart';
import 'package:gmp/features/service/presentation/pages/maintain_my_pair_page.dart';
import 'package:gmp/features/service/presentation/pages/pair_progress_page.dart';
import 'package:gmp/features/service/presentation/pages/repair_my_pair_page.dart';
import 'package:gmp/features/service/presentation/pages/service_history_page.dart';
import 'package:gmp/features/service/presentation/pages/wash_my_pair_page.dart';
import 'package:gmp/features/service/presentation/utils/care_active_job.dart';
import 'package:gmp/features/service/presentation/widgets/hub_gradient_search_bar.dart';
import 'package:gmp/features/service/presentation/widgets/hub_scoped_search_results.dart';

class CareMyPairPage extends StatefulWidget {
  const CareMyPairPage({super.key});

  @override
  State<CareMyPairPage> createState() => _CareMyPairPageState();
}

class _CareMyPairPageState extends State<CareMyPairPage> {
  /// Flip to `true` when real video/article assets are ready.
  /// Paths and UI below stay in place — only visibility is gated.
  static const bool _showStaticMedia = false;
  String _searchQuery = '';

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

  TextStyle _sectionTitle(BuildContext context) =>
      GoogleFonts.boldonse(textStyle: _sectionTitleStyle);

  TextStyle _subsectionLabel(BuildContext context) =>
      GoogleFonts.montserrat(
        color: Colors.black,
        fontSize: 16,
        fontWeight: FontWeight.w400,
      );

  List<HubSearchHit> _careSearchHits(BuildContext context) {
    final hits = <HubSearchHit>[
      HubSearchHit(
        title: 'RepairMyPair',
        subtitle: 'Professional repair & restoration',
        keywords: ['repair', 'fix', 'cobbler', 'care', 'caremypair', 'service'],
        icon: Icons.build_outlined,
        onTap: () => _openRepairPage(context),
      ),
      HubSearchHit(
        title: 'MaintainMyPair',
        subtitle: 'Routine care & maintenance',
        keywords: [
          'maintain',
          'maintenance',
          'care',
          'caremypair',
          'service',
        ],
        icon: Icons.handyman_outlined,
        onTap: () => _openMaintainPage(context),
      ),
      HubSearchHit(
        title: 'WashMyPair',
        subtitle: 'Deep wash & refresh',
        keywords: [
          'wash',
          'clean',
          'cleaning',
          'care',
          'caremypair',
          'service',
        ],
        icon: Icons.local_laundry_service_outlined,
        onTap: () => _openWashPage(context),
      ),
      HubSearchHit(
        title: 'Active Service',
        subtitle: 'Track your current Care request',
        keywords: ['active', 'track', 'status', 'ongoing', 'care', 'jobs'],
        icon: Icons.timelapse_rounded,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const ActiveServicesPage(),
            ),
          );
        },
      ),
      HubSearchHit(
        title: 'Service History',
        subtitle: 'Past CareMyPair requests',
        keywords: ['history', 'past', 'requests', 'orders', 'care', 'review'],
        icon: Icons.history_rounded,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const ServiceHistoryPage(),
            ),
          );
        },
      ),
    ];

    if (_showStaticMedia) {
      for (final article in _articles) {
        hits.add(
          HubSearchHit(
            title: article.title,
            subtitle: 'Care article',
            keywords: ['article', 'guide', 'diy', 'care', ...article.title.toLowerCase().split(' ')],
            icon: Icons.article_outlined,
            onTap: () => showComingSoon(context, feature: 'Care articles'),
          ),
        );
      }
      for (final video in [..._repairVideos, ..._maintainVideos, ..._washVideos]) {
        hits.add(
          HubSearchHit(
            title: video.title,
            subtitle: 'Care video',
            keywords: ['video', 'diy', 'care', ...video.title.toLowerCase().split(' ')],
            icon: Icons.play_circle_outline,
            onTap: () => showComingSoon(context, feature: 'Care DIY videos'),
          ),
        );
      }
    }

    return hits;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final uiScale = (width / 390).clamp(0.84, 1.12).toDouble();
    final horizontalInset = (10.0 * uiScale).clamp(8.0, 16.0);
    const topInset = 52.0;
    final searching = _searchQuery.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      resizeToAvoidBottomInset: false,
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
                      padding: const EdgeInsets.fromLTRB(8, 12, 6, 120),
                      children: [
                        _Header(onBack: () => Navigator.maybePop(context)),
                        const SizedBox(height: 24),
                        HubGradientSearchBar(
                          hintText: 'Search CareMyPair',
                          showClear: true,
                          onChanged: (value) =>
                              setState(() => _searchQuery = value),
                        ),
                        const SizedBox(height: 28),
                        if (searching)
                          HubScopedSearchResults(
                            query: _searchQuery,
                            hubName: 'CareMyPair',
                            hits: _careSearchHits(context),
                          )
                        else ...[
                          Text('Our Services', style: _sectionTitle(context)),
                          const SizedBox(height: 14),
                          _PrimaryServiceCard(
                            label: 'RepairMyPair',
                            onTap: () => _openRepairPage(context),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _SecondaryServiceCard(
                                  firstLine: 'Maintain',
                                  secondLine: 'MyPair',
                                  iconAsset:
                                      'assets/images/icons/caremypair/mmp.svg',
                                  iconScale: 1.12,
                                  onTap: () => _openMaintainPage(context),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _SecondaryServiceCard(
                                  firstLine: 'Wash',
                                  secondLine: 'MyPair',
                                  iconAsset:
                                      'assets/images/icons/caremypair/wmp.svg',
                                  onTap: () => _openWashPage(context),
                                ),
                              ),
                            ],
                          ),
                          const _ActiveServiceSection(),
                          const SizedBox(height: 16),
                          _ServiceHistoryButton(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const ServiceHistoryPage(),
                                ),
                              );
                            },
                          ),
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

/// Matches Rehome Sell/Rent tile proportions (~2.25× wide as tall).
class _ServiceCardMetrics {
  final double height;
  final double padH;
  final double padV;
  final double iconSize;
  final double gap;
  final double fontSize;
  final double lineGap;

  const _ServiceCardMetrics({
    required this.height,
    required this.padH,
    required this.padV,
    required this.iconSize,
    required this.gap,
    required this.fontSize,
    required this.lineGap,
  });

  /// Same content metrics as home hub action cards — scales with card/screen.
  static _ServiceCardMetrics fromWidth(double cardWidth) {
    final height = (cardWidth / 2.25).clamp(64.0, 100.0);
    final padH = (cardWidth * 0.10).clamp(10.0, 20.0);
    final padV = (height * 0.12).clamp(6.0, 14.0);
    final innerH = (height - padV * 2).clamp(18.0, height);
    final innerW = (cardWidth - padH * 2).clamp(18.0, cardWidth);
    // Track card size; keep room for the two-line label.
    final iconSize = math
        .min(innerH * 0.82, innerW * 0.42)
        .clamp(28.0, 64.0)
        .toDouble();
    final gap = (innerW * 0.06).clamp(6.0, 14.0);
    final fontSize = (innerH * 0.30).clamp(11.0, 17.0);
    final lineGap = (innerH * 0.08).clamp(4.0, 12.0);
    return _ServiceCardMetrics(
      height: height,
      padH: padH,
      padV: padV,
      iconSize: iconSize,
      gap: gap,
      fontSize: fontSize,
      lineGap: lineGap,
    );
  }
}

class _TwoLineLabel extends StatelessWidget {
  final String first;
  final String second;
  final Color color;
  final double fontSize;
  final double lineGap;

  const _TwoLineLabel({
    required this.first,
    required this.second,
    required this.color,
    this.fontSize = 15,
    this.lineGap = 5,
  });

  @override
  Widget build(BuildContext context) {
    final style = GoogleFonts.boldonse(
      color: color,
      fontSize: fontSize,
      height: 1.28,
      fontWeight: FontWeight.w400,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(first, maxLines: 1, softWrap: false, style: style),
        ),
        SizedBox(height: lineGap),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(second, maxLines: 1, softWrap: false, style: style),
        ),
      ],
    );
  }
}

class _PrimaryServiceCard extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _PrimaryServiceCard({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Full-width card: use half-width metrics so height matches side tiles.
        final m = _ServiceCardMetrics.fromWidth(constraints.maxWidth / 2);

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              height: m.height,
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: m.padH,
                vertical: m.padV,
              ),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF09DFFF), Color(0xFF063035)],
                  begin: Alignment.bottomRight,
                  end: Alignment.topLeft,
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x19000000),
                    blurRadius: 4,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Align(
                alignment: Alignment.center,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: m.iconSize,
                      height: m.iconSize,
                      child: SvgPicture.asset(
                        'assets/images/icons/caremypair/rmp.svg',
                        fit: BoxFit.contain,
                      ),
                    ),
                    SizedBox(width: m.gap),
                    Flexible(
                      fit: FlexFit.loose,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          label,
                          maxLines: 1,
                          softWrap: false,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.boldonse(
                            color: Colors.white,
                            fontSize: m.fontSize,
                            height: 1.28,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SecondaryServiceCard extends StatelessWidget {
  final String firstLine;
  final String secondLine;
  final String iconAsset;
  final double iconScale;
  final VoidCallback onTap;

  const _SecondaryServiceCard({
    required this.firstLine,
    required this.secondLine,
    required this.iconAsset,
    this.iconScale = 1,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.all(Radius.circular(10));

    return LayoutBuilder(
      builder: (context, constraints) {
        final m = _ServiceCardMetrics.fromWidth(constraints.maxWidth);
        final iconSize = m.iconSize * iconScale;
        return DecoratedBox(
          decoration: const BoxDecoration(
            borderRadius: radius,
            boxShadow: [
              BoxShadow(
                color: Color(0x19000000),
                blurRadius: 4,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: const Color(0xFFDFE7E9),
            shape: const RoundedRectangleBorder(
              borderRadius: radius,
              side: BorderSide(
                width: 1,
                color: Color(0xFF0F6876),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              borderRadius: radius,
              child: SizedBox(
                height: m.height,
                width: double.infinity,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: m.padH,
                    vertical: m.padV,
                  ),
                  child: Align(
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: iconSize,
                          height: iconSize,
                          child: SvgPicture.asset(
                            iconAsset,
                            fit: BoxFit.contain,
                          ),
                        ),
                        SizedBox(width: m.gap),
                        Flexible(
                          fit: FlexFit.loose,
                          child: _TwoLineLabel(
                            first: firstLine,
                            second: secondLine,
                            color: const Color(0xFF062F35),
                            fontSize: m.fontSize,
                            lineGap: m.lineGap,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Newest active Care request — delivery ETA or drop-off confirm; opens Active Jobs.
class _ActiveServiceSection extends StatefulWidget {
  const _ActiveServiceSection();

  @override
  State<_ActiveServiceSection> createState() => _ActiveServiceSectionState();
}

class _ActiveServiceSectionState extends State<_ActiveServiceSection> {
  Map<String, dynamic>? _active;
  Set<String> _dropOffConfirmed = {};
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final confirmed = await CareActiveJob.loadDropOffConfirmedIds();
    final tokenResult = await sl<GetValidAccessToken>().call();
    if (!mounted) return;

    await tokenResult.fold(
      (_) async {
        setState(() {
          _dropOffConfirmed = confirmed;
          _loaded = true;
          _active = null;
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
          final active = list
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .where(CareActiveJob.isActiveCareRequest)
              .toList();
          if (!mounted) return;
          setState(() {
            _dropOffConfirmed = confirmed;
            _loaded = true;
            _active = active.isEmpty ? null : active.first;
          });
        } catch (_) {
          if (!mounted) return;
          setState(() {
            _dropOffConfirmed = confirmed;
            _loaded = true;
          });
        }
      },
    );
  }

  Future<void> _openActiveJobs() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const ActiveServicesPage(),
      ),
    );
    if (mounted) _load();
  }

  Future<void> _openProgress() async {
    final active = _active;
    if (active == null) {
      await _openActiveJobs();
      return;
    }
    final id = CareActiveJob.requestId(active);
    if (id.isEmpty) {
      await _openActiveJobs();
      return;
    }
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) =>
            PairProgressPage(requestId: id, initialRequest: active),
      ),
    );
    if (mounted) _load();
  }

  Future<void> _confirmDroppedOff() async {
    final active = _active;
    if (active == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm drop off'),
        content: const Text(
          'Have you dropped off your pair at the service location?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Not yet'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes, dropped off'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    await CareActiveJob.markDropOffConfirmed(CareActiveJob.requestId(active));
    if (!mounted) return;
    await showAppFeedbackAlert(
      context,
      message: 'Drop off confirmed',
      type: AppFeedbackType.success,
    );
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const SizedBox.shrink();

    final width = MediaQuery.sizeOf(context).width;
    final uiScale = (width / 390).clamp(0.84, 1.12).toDouble();
    final titleSize = (16.0 * uiScale).clamp(14.0, 16.0);
    final chevronSize = (28.0 * uiScale).clamp(24.0, 28.0);
    final active = _active;
    final needsDrop = active != null &&
        CareActiveJob.needsDropOffConfirm(
          active,
          dropOffConfirmedIds: _dropOffConfirmed,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 28),
        InkWell(
          onTap: _openActiveJobs,
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
                      fontSize: titleSize,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: const Color(0xFF062F35),
                  size: chevronSize,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (active == null)
          Text(
            'No pairs are currently in treatment',
            style: GoogleFonts.montserrat(
              color: const Color(0xFF9AA4A6),
              fontSize: (14.0 * uiScale).clamp(12.0, 14.0),
              fontWeight: FontWeight.w500,
            ),
          )
        else
          _ActiveServiceCard(
            serviceLabel: CareActiveJob.serviceLabel(
              (active['serviceType'] ?? '').toString(),
            ),
            needsDropOffConfirm: needsDrop,
            estimatedDeliveryLabel: CareActiveJob.formatEstimatePretty(
              CareActiveJob.estimatedDelivery(active),
            ),
            onTap: _openProgress,
            onMarkDroppedOff: _confirmDroppedOff,
          ),
      ],
    );
  }
}

class _ActiveServiceCard extends StatelessWidget {
  static const String _servIcon = 'assets/images/icons/profile/serv.svg';

  final String serviceLabel;
  final bool needsDropOffConfirm;
  final String estimatedDeliveryLabel;
  final VoidCallback onTap;
  final VoidCallback onMarkDroppedOff;

  const _ActiveServiceCard({
    required this.serviceLabel,
    required this.needsDropOffConfirm,
    required this.estimatedDeliveryLabel,
    required this.onTap,
    required this.onMarkDroppedOff,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final uiScale = (width / 390).clamp(0.84, 1.12).toDouble();
    final iconBox = (46.0 * uiScale).clamp(42.0, 52.0);
    final iconPad = (11.0 * uiScale).clamp(9.0, 12.0);
    final iconSize = (iconBox - iconPad * 2).clamp(20.0, 30.0);
    final labelSize = (14.0 * uiScale).clamp(12.0, 14.0);
    final valueSize = (16.0 * uiScale).clamp(14.0, 16.0);
    final gap = (16.0 * uiScale).clamp(12.0, 16.0);
    final btnH = (24.0 * uiScale).clamp(22.0, 28.0);
    final btnFs = (10.0 * uiScale).clamp(9.0, 11.0);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: EdgeInsets.only(
            bottom: (14.0 * uiScale).clamp(10.0, 14.0),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: iconBox,
                height: iconBox,
                padding: EdgeInsets.all(iconPad),
                decoration: BoxDecoration(
                  color: const Color(0x33D9D9D9),
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: const Color(0xFF12899B),
                    width: 1,
                  ),
                ),
                alignment: Alignment.center,
                child: SvgPicture.asset(
                  _servIcon,
                  width: iconSize,
                  height: iconSize,
                ),
              ),
              SizedBox(width: gap),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Service Type',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.montserrat(
                              color: const Color(0xFF12899B),
                              fontSize: labelSize,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: (6.0 * uiScale).clamp(4.0, 8.0)),
                          Text(
                            serviceLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.montserrat(
                              color: const Color(0xFF5A5A5A),
                              fontSize: valueSize,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: (16.0 * uiScale).clamp(12.0, 20.0)),
                    if (needsDropOffConfirm)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Confirm Drop off',
                            maxLines: 1,
                            style: GoogleFonts.montserrat(
                              color: const Color(0xFF12899B),
                              fontSize: labelSize,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: (6.0 * uiScale).clamp(4.0, 8.0)),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: onMarkDroppedOff,
                              borderRadius: BorderRadius.circular(50),
                              child: Ink(
                                height: btnH,
                                padding: EdgeInsets.symmetric(
                                  horizontal: (9.0 * uiScale).clamp(8.0, 12.0),
                                  vertical: (4.0 * uiScale).clamp(3.0, 5.0),
                                ),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    begin: Alignment.centerRight,
                                    end: Alignment.centerLeft,
                                    colors: [
                                      Color(0xFF0CADC5),
                                      Color(0xFF063239),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(50),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x19000000),
                                      blurRadius: 2,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    'Mark as Dropped off',
                                    maxLines: 1,
                                    style: GoogleFonts.boldonse(
                                      color: Colors.white,
                                      fontSize: btnFs,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Estimated Delivery',
                            maxLines: 1,
                            style: GoogleFonts.montserrat(
                              color: const Color(0xFF12899B),
                              fontSize: labelSize,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: (6.0 * uiScale).clamp(4.0, 8.0)),
                          Text(
                            estimatedDeliveryLabel,
                            maxLines: 1,
                            style: GoogleFonts.montserrat(
                              color: const Color(0xFF12899B),
                              fontSize: valueSize,
                              fontWeight: FontWeight.w600,
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
    );
  }
}

class _ServiceHistoryButton extends StatelessWidget {
  final VoidCallback onTap;

  const _ServiceHistoryButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final uiScale = (width / 390).clamp(0.84, 1.12).toDouble();
    final fontSize = (15.0 * uiScale).clamp(13.0, 15.0);
    final iconSize = (26.0 * uiScale).clamp(22.0, 26.0);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: (18.0 * uiScale).clamp(14.0, 18.0),
            vertical: (14.0 * uiScale).clamp(12.0, 16.0),
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFE8EEEE),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF0F6876), width: 1),
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
              Icon(
                Icons.history_rounded,
                color: const Color(0xFF062F35),
                size: iconSize,
              ),
              const SizedBox(width: 10),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'Service History',
                    maxLines: 1,
                    softWrap: false,
                    style: GoogleFonts.boldonse(
                      color: const Color(0xFF062F35),
                      fontSize: fontSize,
                      fontWeight: FontWeight.w400,
                    ),
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
