import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:gmp/core/bgtheme.dart';
import 'package:gmp/core/constants/api_endpoints.dart';
import 'package:gmp/core/widgets/app_feedback_alert.dart';
import 'package:gmp/features/articles/domain/entities/article.dart';
import 'package:gmp/features/articles/domain/usecases/get_my_articles.dart';
import 'package:gmp/features/auth/domain/usecases/get_valid_access_token.dart';
import 'package:gmp/features/sell/presentation/pages/sell_my_pair_page.dart';
import 'package:gmp/features/service/presentation/widgets/hub_gradient_search_bar.dart';
import 'package:gmp/features/service/presentation/widgets/hub_scoped_search_results.dart';
import 'package:gmp/core/widgets/floating_gradient_bottom_nav.dart';
import 'package:gmp/injection_container.dart';
import 'package:google_fonts/google_fonts.dart';

class RehomeMyPairPage extends StatefulWidget {
  const RehomeMyPairPage({super.key});

  @override
  State<RehomeMyPairPage> createState() => _RehomeMyPairPageState();
}

class _RehomeMyPairPageState extends State<RehomeMyPairPage> {
  static const bool _showStaticMedia = true;

  static const BorderRadius _panelRadius = BorderRadius.only(
    topLeft: Radius.circular(20),
    topRight: Radius.circular(20),
    bottomLeft: Radius.circular(50),
    bottomRight: Radius.circular(50),
  );

  static const List<_RentalStyleData> _fallbackStyles = [
    _RentalStyleData(label: 'Statement Heels'),
    _RentalStyleData(label: 'Designer Boots'),
    _RentalStyleData(label: 'Trail Shoes'),
  ];

  bool _loadingStyles = true;
  List<_RentalStyleData> _rentalStyles = _fallbackStyles;
  String _searchQuery = '';

  List<HubSearchHit> _rehomeSearchHits(BuildContext context) {
    final hits = <HubSearchHit>[
      HubSearchHit(
        title: 'SellMyPair',
        subtitle: 'List footwear for sale',
        keywords: [
          'sell',
          'listing',
          'marketplace',
          'rehome',
          'rehomemypair',
          'service',
        ],
        icon: Icons.sell_outlined,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const SellMyPairPage()),
          );
        },
      ),
      HubSearchHit(
        title: 'RentMyPair',
        subtitle: 'Rent pairs from the community',
        keywords: [
          'rent',
          'rental',
          'rehome',
          'rehomemypair',
          'service',
        ],
        icon: Icons.event_available_outlined,
        onTap: () => showComingSoon(context, feature: 'RentMyPair'),
      ),
    ];

    for (final style in _rentalStyles) {
      hits.add(
        HubSearchHit(
          title: style.label,
          subtitle: 'Requested rental style',
          keywords: [
            'style',
            'rental',
            'rent',
            'rehome',
            ...style.label.toLowerCase().split(' '),
          ],
          icon: Icons.ice_skating_outlined,
          onTap: () => showComingSoon(context, feature: 'RentMyPair'),
        ),
      );
    }

    return hits;
  }

  @override
  void initState() {
    super.initState();
    _loadRentalStyles();
  }

  static String _imageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    final base = ApiEndpoints.baseUrl;
    if (path.startsWith('/')) return '$base$path';
    return '$base/uploads/$path';
  }

  static String _styleLabel(Article article) {
    final category = article.category.trim();
    if (category.isNotEmpty) return category;
    final brand = article.brand.trim();
    if (brand.isNotEmpty) return brand;
    final model = article.model.trim();
    if (model.isNotEmpty) return model;
    return 'Style';
  }

  Future<void> _loadRentalStyles() async {
    final tokenResult = await sl<GetValidAccessToken>().call();
    if (!mounted) return;

    await tokenResult.fold(
      (_) async {
        setState(() {
          _loadingStyles = false;
          _rentalStyles = _fallbackStyles;
        });
      },
      (token) async {
        try {
          final articles = await sl<GetMyArticles>().call(token);
          if (!mounted) return;

          final byCategory = <String, Article>{};
          for (final article in articles) {
            final key = article.category.trim().toLowerCase();
            if (key.isEmpty) continue;
            byCategory.putIfAbsent(key, () => article);
            if (byCategory.length >= 6) break;
          }

          final source = byCategory.isNotEmpty
              ? byCategory.values.toList()
              : articles.take(6).toList();

          final styles = source
              .map(
                (a) => _RentalStyleData(
                  label: _styleLabel(a),
                  imageUrl: _imageUrl(a.rackHeroImagePath),
                ),
              )
              .toList();

          setState(() {
            _loadingStyles = false;
            _rentalStyles = styles.isNotEmpty ? styles : _fallbackStyles;
          });
        } catch (_) {
          if (!mounted) return;
          setState(() {
            _loadingStyles = false;
            _rentalStyles = _fallbackStyles;
          });
        }
      },
    );
  }

  Widget _buildRentalStylesRow({required double height}) {
    if (_loadingStyles) {
      return SizedBox(
        height: height,
        child: const Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFF0E7C8A),
            ),
          ),
        ),
      );
    }

    if (_rentalStyles.length <= 3) {
      return SizedBox(
        height: height,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final style in _rentalStyles)
              Expanded(child: _RentalStyle(data: style)),
          ],
        ),
      );
    }

    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _rentalStyles.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (_, i) => SizedBox(
          width: 110,
          child: _RentalStyle(data: _rentalStyles[i]),
        ),
      ),
    );
  }

  TextStyle _sectionTitle(double fontSize) {
    return GoogleFonts.boldonse(
      color: const Color(0xFF062F35),
      fontSize: fontSize,
      fontWeight: FontWeight.w400,
    );
  }

  TextStyle _subsectionLabel(double fontSize) {
    return GoogleFonts.montserrat(
      color: Colors.black,
      fontSize: fontSize,
      fontWeight: FontWeight.w500,
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    // Same width / edge packing as SellMyPair (SellFlowScaffold).
    final uiScale = (width / 390).clamp(0.84, 1.2).toDouble();
    final horizontalInset = (10.0 * uiScale).clamp(8.0, 20.0);
    final topInset = (40.0 * uiScale).clamp(28.0, 52.0);
    final contentPadH = (14.0 * uiScale).clamp(10.0, 20.0);
    final contentPadTop = (12.0 * uiScale).clamp(10.0, 16.0);
    final bottomNavH = dashboardLinkedBottomNavStackHeight(context);
    final contentPadBottom = bottomNavH + (12.0 * uiScale).clamp(8.0, 16.0);
    final searching = _searchQuery.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.hardEdge,
        children: [
          ...BgTheme.background(),
          Positioned.fill(
            child: SafeArea(
              bottom: false,
              child: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalInset,
                    topInset,
                    horizontalInset,
                    0,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: DecoratedBox(
                      decoration: const ShapeDecoration(
                        color: Color(0xFFF0F0F0),
                        shape: RoundedRectangleBorder(
                          borderRadius: _panelRadius,
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
                        borderRadius: _panelRadius,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final available = (constraints.maxHeight -
                                    contentPadTop -
                                    contentPadBottom)
                                .clamp(0.0, double.infinity);
                            // Pack like SellMyPair: scale gaps/blocks, no vertical scroll.
                            const designH = 560.0;
                            final hScale =
                                (available / 640).clamp(0.68, 1.0);
                            final s = uiScale * hScale;
                            final isTall = available > designH + 24;
                            final distribute = isTall && !searching;

                            final sectionSize =
                                (16.0 * s).clamp(13.0, 18.0);
                            final subSize =
                                (15.0 * s).clamp(12.0, 15.0);
                            final gapSm =
                                (10.0 * s).clamp(6.0, 12.0);
                            final gapMd =
                                (14.0 * s).clamp(8.0, 16.0);
                            final gapLg =
                                (18.0 * s).clamp(10.0, 24.0);
                            final cardGap =
                                (8.0 * uiScale).clamp(6.0, 12.0);
                            final brandH =
                                (105.0 * hScale).clamp(72.0, 105.0);
                            final stylesH =
                                (96.0 * hScale).clamp(68.0, 96.0);
                            final brandScale = brandH / 105.0;

                            return Padding(
                              padding: EdgeInsets.fromLTRB(
                                contentPadH,
                                contentPadTop,
                                contentPadH,
                                contentPadBottom,
                              ),
                              child: SizedBox(
                                height: available,
                                width: double.infinity,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    _Header(
                                      onBack: () =>
                                          Navigator.maybePop(context),
                                      uiScale: uiScale,
                                    ),
                                    SizedBox(height: gapLg),
                                    HubGradientSearchBar(
                                      hintText: 'Search RehomeMyPair',
                                      showClear: true,
                                      onChanged: (value) => setState(
                                        () => _searchQuery = value,
                                      ),
                                    ),
                                    SizedBox(height: gapLg),
                                    if (searching)
                                      Expanded(
                                        child: SingleChildScrollView(
                                          keyboardDismissBehavior:
                                              ScrollViewKeyboardDismissBehavior
                                                  .onDrag,
                                          physics:
                                              const ClampingScrollPhysics(),
                                          child: HubScopedSearchResults(
                                            query: _searchQuery,
                                            hubName: 'RehomeMyPair',
                                            hits: _rehomeSearchHits(
                                              context,
                                            ),
                                          ),
                                        ),
                                      )
                                    else ...[
                                      Text(
                                        'Our Services',
                                        style: _sectionTitle(sectionSize),
                                      ),
                                      SizedBox(height: gapMd),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _PrimaryDonateCard(
                                              onTap: () {
                                                Navigator.of(context).push(
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        const SellMyPairPage(),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                          SizedBox(width: cardGap),
                                          Expanded(
                                            child: _SecondaryServiceCard(
                                              onTap: () => showComingSoon(
                                                context,
                                                feature: 'RentMyPair',
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (_showStaticMedia) ...[
                                        if (distribute)
                                          const Spacer(flex: 2)
                                        else
                                          SizedBox(height: gapLg),
                                        Text(
                                          'In Demand Right Now',
                                          style:
                                              _sectionTitle(sectionSize),
                                        ),
                                        SizedBox(height: gapSm),
                                        Text(
                                          'Top Bidded Brands',
                                          style:
                                              _subsectionLabel(subSize),
                                        ),
                                        SizedBox(height: gapSm),
                                        SizedBox(
                                          height: brandH,
                                          child: SingleChildScrollView(
                                            scrollDirection:
                                                Axis.horizontal,
                                            padding:
                                                const EdgeInsets.symmetric(
                                              horizontal: 4,
                                            ),
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                _DemandBrandImage(
                                                  asset:
                                                      'assets/images/rehome1 (2).png',
                                                  width: 184 * brandScale,
                                                  height: brandH * 0.98,
                                                ),
                                                SizedBox(
                                                  width: 14 * brandScale,
                                                ),
                                                _DemandBrandImage(
                                                  asset:
                                                      'assets/images/rehome1 (1).png',
                                                  width: 129 * brandScale,
                                                  height: brandH,
                                                ),
                                                SizedBox(
                                                  width: 14 * brandScale,
                                                ),
                                                _DemandBrandImage(
                                                  asset:
                                                      'assets/images/rehome1 (3).png',
                                                  width: 187 * brandScale,
                                                  height: brandH,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        if (distribute)
                                          const Spacer(flex: 2)
                                        else
                                          SizedBox(height: gapMd),
                                        Text(
                                          'Most Requested Rental Styles',
                                          style:
                                              _subsectionLabel(subSize),
                                        ),
                                        SizedBox(height: gapSm),
                                        _buildRentalStylesRow(
                                          height: stylesH,
                                        ),
                                        if (distribute)
                                          const Spacer(flex: 1),
                                      ],
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
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
}

class _Header extends StatelessWidget {
  final VoidCallback onBack;
  final double uiScale;

  const _Header({required this.onBack, this.uiScale = 1});

  @override
  Widget build(BuildContext context) {
    final titleSize = (24.0 * uiScale).clamp(20.0, 28.0);
    final subtitleSize = (14.0 * uiScale).clamp(12.0, 16.0);
    final iconSize = (22.0 * uiScale).clamp(18.0, 24.0);
    final backBox = (26.0 * uiScale).clamp(24.0, 30.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: onBack,
              padding: EdgeInsets.zero,
              constraints: BoxConstraints.tightFor(
                width: backBox,
                height: backBox,
              ),
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: const Color(0xFF062F35),
                size: iconSize,
              ),
            ),
            SizedBox(width: (4.0 * uiScale).clamp(2.0, 6.0)),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  'RehomeMyPair',
                  maxLines: 1,
                  style: GoogleFonts.boldonse(
                    color: const Color(0xFF062F35),
                    fontSize: titleSize,
                    fontWeight: FontWeight.w400,
                    height: 1.1,
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: (4.0 * uiScale).clamp(2.0, 6.0)),
        Padding(
          padding: EdgeInsets.only(left: (backBox + 8).clamp(28.0, 40.0)),
          child: Text(
            'Give Your Pair a Second Life!!',
            style: GoogleFonts.boldonse(
              color: const Color(0xFF0E7C8A),
              fontSize: subtitleSize,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}

class _ServiceCardMetrics {
  final double height;
  final double padH;
  final double padV;
  final double iconW;
  final double iconH;
  final double iconLeftInset;
  final double gap;
  final double fontSize;
  final double lineGap;

  const _ServiceCardMetrics({
    required this.height,
    required this.padH,
    required this.padV,
    required this.iconW,
    required this.iconH,
    required this.iconLeftInset,
    required this.gap,
    required this.fontSize,
    required this.lineGap,
  });

  static _ServiceCardMetrics fromWidth(double cardWidth) {
    final height = (cardWidth / 2.25).clamp(68.0, 86.0);
    final padH = (cardWidth * 0.06).clamp(8.0, 12.0);
    final padV = (height * 0.12).clamp(8.0, 12.0);
    final innerH = (height - padV * 2).clamp(18.0, height);
    final iconH = (innerH * 0.78).clamp(30.0, 42.0);
    final iconW = (iconH * 1.15).clamp(34.0, 48.0);
    final iconLeftInset = (cardWidth * 0.04).clamp(6.0, 12.0);
    final gap = (cardWidth * 0.05).clamp(8.0, 12.0);
    final fontSize = (innerH * 0.28).clamp(12.0, 15.0);
    final lineGap = (innerH * 0.14).clamp(4.0, 8.0);
    return _ServiceCardMetrics(
      height: height,
      padH: padH,
      padV: padV,
      iconW: iconW,
      iconH: iconH,
      iconLeftInset: iconLeftInset,
      gap: gap,
      fontSize: fontSize,
      lineGap: lineGap,
    );
  }
}

class _PrimaryDonateCard extends StatelessWidget {
  final VoidCallback onTap;

  const _PrimaryDonateCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final m = _ServiceCardMetrics.fromWidth(constraints.maxWidth);
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              height: m.height,
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(
                m.padH + m.iconLeftInset,
                m.padV,
                m.padH,
                m.padV,
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
              child: Row(
                children: [
                  SizedBox(
                    width: m.iconW * 1.18,
                    height: m.iconH * 1.18,
                    child: const Image(
                      image: AssetImage(
                        'assets/images/icons/rehomemypair/sellmypair.png',
                      ),
                      fit: BoxFit.contain,
                      color: Colors.white,
                      colorBlendMode: BlendMode.srcIn,
                    ),
                  ),
                  SizedBox(width: m.gap),
                  Flexible(
                    child: _TwoLineLabel(
                      first: 'Sell',
                      second: 'MyPair',
                      color: Colors.white,
                      fontSize: m.fontSize,
                      lineGap: m.lineGap,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
      height: 1,
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

class _RentTaggedShoe extends StatelessWidget {
  final double width;
  final double height;

  const _RentTaggedShoe({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    final tagFont = (height * 0.22).clamp(6.0, 8.0);
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: height * 0.12,
            left: 0,
            right: 0,
            child: SizedBox(
              height: height * 0.78,
              child: const Image(
                image: AssetImage(
                  'assets/images/icons/rehomemypair/rentmypair_shoe.png',
                ),
                fit: BoxFit.contain,
              ),
            ),
          ),
          Positioned(
            right: -2,
            bottom: height * 0.12,
            child: Transform.rotate(
              angle: -0.27,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFF062F35),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: tagFont * 0.45,
                    vertical: tagFont * 0.15,
                  ),
                  child: Text(
                    'RENT',
                    style: GoogleFonts.boldonse(
                      color: Colors.white,
                      fontSize: tagFont,
                      height: 1,
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

class _SecondaryServiceCard extends StatelessWidget {
  final VoidCallback onTap;

  const _SecondaryServiceCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.all(Radius.circular(10));

    return LayoutBuilder(
      builder: (context, constraints) {
        final m = _ServiceCardMetrics.fromWidth(constraints.maxWidth);
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
                  padding: EdgeInsets.fromLTRB(
                    m.padH + m.iconLeftInset,
                    m.padV,
                    m.padH,
                    m.padV,
                  ),
                  child: Row(
                    children: [
                      _RentTaggedShoe(width: m.iconW, height: m.iconH),
                      SizedBox(width: m.gap),
                      Flexible(
                        child: _TwoLineLabel(
                          first: 'Rent',
                          second: 'MyPair',
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
        );
      },
    );
  }
}

class _DemandBrandImage extends StatelessWidget {
  final String asset;
  final double width;
  final double height;

  const _DemandBrandImage({
    required this.asset,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Image.asset(
        asset,
        fit: BoxFit.cover,
        alignment: Alignment.center,
      ),
    );
  }
}

class _RentalStyleData {
  final String label;
  final String imageUrl;

  const _RentalStyleData({
    required this.label,
    this.imageUrl = '',
  });
}

class _RentalStyle extends StatelessWidget {
  final _RentalStyleData data;

  const _RentalStyle({required this.data});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxH = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : 96.0;
        final labelH = math.min(28.0, maxH * 0.28);
        final gap = math.min(6.0, maxH * 0.06);
        final imageH = math.max(36.0, maxH - labelH - gap);

        Widget shoeImage({required double height}) {
          if (data.imageUrl.isNotEmpty) {
            return Image.network(
              data.imageUrl,
              height: height,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => Image.asset(
                'assets/images/icons/myrack/shoe.png',
                height: height,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => Icon(
                  Icons.ice_skating,
                  size: height * 0.66,
                  color: const Color(0xFF0E7C8A),
                ),
              ),
            );
          }
          return Image.asset(
            'assets/images/icons/myrack/shoe.png',
            height: height,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => Icon(
              Icons.ice_skating,
              size: height * 0.66,
              color: const Color(0xFF0E7C8A),
            ),
          );
        }

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: imageH, child: shoeImage(height: imageH)),
            SizedBox(height: gap),
            SizedBox(
              height: labelH,
              child: Text(
                data.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.montserrat(
                  fontSize: (12.0 * (imageH / 72)).clamp(9.0, 12.0),
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
