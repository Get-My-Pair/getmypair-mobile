import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gmp/core/bgtheme.dart';
import 'package:gmp/core/constants/api_endpoints.dart';
import 'package:gmp/core/widgets/app_feedback_alert.dart';
import 'package:gmp/features/articles/domain/entities/article.dart';
import 'package:gmp/features/articles/domain/usecases/get_my_articles.dart';
import 'package:gmp/features/auth/domain/usecases/get_valid_access_token.dart';
import 'package:gmp/features/sell/presentation/pages/sell_my_pair_page.dart';
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

  Widget _buildRentalStylesRow() {
    if (_loadingStyles) {
      return const SizedBox(
        height: 96,
        child: Center(
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
      return Row(
        children: [
          for (final style in _rentalStyles)
            Expanded(child: _RentalStyle(data: style)),
        ],
      );
    }

    return SizedBox(
      height: 100,
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
                      padding: const EdgeInsets.fromLTRB(8, 12, 6, 120),
                      children: [
                        _Header(onBack: () => Navigator.maybePop(context)),
                        const SizedBox(height: 24),
                        const _SearchBar(),
                        const SizedBox(height: 28),
                        Text(
                          'Our Services',
                          style: GoogleFonts.boldonse(
                            color: const Color(0xFF062F35),
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _PrimaryDonateCard(
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const SellMyPairPage(),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
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
                          const SizedBox(height: 32),
                          Text(
                            'In Demand Right Now',
                            style: GoogleFonts.boldonse(
                              color: const Color(0xFF062F35),
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Top Bidded Brands',
                            style: GoogleFonts.montserrat(
                              color: Colors.black,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const SizedBox(
                            height: 105,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              padding: EdgeInsets.symmetric(horizontal: 14),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _DemandBrandImage(
                                    asset: 'assets/images/rehome1 (2).png',
                                    width: 184,
                                    height: 103,
                                  ),
                                  SizedBox(width: 14),
                                  _DemandBrandImage(
                                    asset: 'assets/images/rehome1 (1).png',
                                    width: 129,
                                    height: 105,
                                  ),
                                  SizedBox(width: 14),
                                  _DemandBrandImage(
                                    asset: 'assets/images/rehome1 (3).png',
                                    width: 187,
                                    height: 105,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 22),
                          Text(
                            'Most Requested Rental Styles',
                            style: GoogleFonts.montserrat(
                              color: Colors.black,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildRentalStylesRow(),
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
}

class _Header extends StatelessWidget {
  final VoidCallback onBack;

  const _Header({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
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
            Expanded(
              child: Text(
                'RehomeMyPair',
                style: GoogleFonts.boldonse(
                  color: const Color(0xFF062F35),
                  fontSize: 24,
                  fontWeight: FontWeight.w400,
                  height: 1.1,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.only(left: 32),
          child: Text(
            'Give Your Pair a Second Life!!',
            style: GoogleFonts.boldonse(
              color: const Color(0xFF0E7C8A),
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
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
    const searchHeight = 42.0;
    final width = MediaQuery.sizeOf(context).width;
    final uiScale = (width / 390).clamp(0.84, 1.12).toDouble();

    return Container(
      height: searchHeight,
      padding: const EdgeInsets.all(1.2),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFF0F6876), Color(0xFF09E0FF)],
        ),
        borderRadius: BorderRadius.circular(100),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(
            children: [
              SvgPicture.asset(
                'assets/images/search.svg',
                width: 22,
                height: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  textAlignVertical: TextAlignVertical.center,
                  style: GoogleFonts.montserrat(
                    fontSize: (16.0 * uiScale).clamp(13.0, 17.0),
                    color: Colors.black87,
                    fontWeight: FontWeight.w400,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    isCollapsed: false,
                    filled: false,
                    fillColor: Colors.transparent,
                    contentPadding: const EdgeInsets.symmetric(vertical: 9),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    hintText: 'Search',
                    hintStyle: GoogleFonts.montserrat(
                      color: Colors.black.withValues(alpha: 0.34),
                      fontSize: (16.0 * uiScale).clamp(13.0, 17.0),
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
    return Column(
      children: [
        SizedBox(
          height: 72,
          child: data.imageUrl.isNotEmpty
              ? Image.network(
                  data.imageUrl,
                  height: 72,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => Image.asset(
                    'assets/images/icons/myrack/shoe.png',
                    height: 72,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const Icon(
                      Icons.ice_skating,
                      size: 48,
                      color: Color(0xFF0E7C8A),
                    ),
                  ),
                )
              : Image.asset(
                  'assets/images/icons/myrack/shoe.png',
                  height: 72,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const Icon(
                    Icons.ice_skating,
                    size: 48,
                    color: Color(0xFF0E7C8A),
                  ),
                ),
        ),
        const SizedBox(height: 6),
        Text(
          data.label,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.montserrat(fontSize: 12, color: Colors.black87),
        ),
      ],
    );
  }
}
