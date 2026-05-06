import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gmp/core/bgtheme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gmp/core/widgets/floating_gradient_bottom_nav.dart';
import 'package:gmp/features/service/presentation/pages/maintain_my_pair_page.dart';
import 'package:gmp/features/service/presentation/pages/repair_my_pair_page.dart';
import 'package:gmp/features/service/presentation/pages/wash_my_pair_page.dart';

class CareMyPairPage extends StatelessWidget {
  const CareMyPairPage({super.key});

  static const BorderRadius _panelRadius = BorderRadius.only(
    topLeft: Radius.circular(20),
    topRight: Radius.circular(20),
    bottomLeft: Radius.circular(50),
    bottomRight: Radius.circular(50),
  );

  static const List<_VideoCardData> _videos = [
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

  @override
  Widget build(BuildContext context) {
    final bottomSafe = MediaQuery.viewPaddingOf(context).bottom;
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      extendBody: true,
      body: Stack(
        children: [
          ...BgTheme.background(),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 30, 10, 0),
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
                    padding: const EdgeInsets.fromLTRB(10, 12, 6, 120),
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
                          _PrimaryServiceCard(
                            label: 'RepairMyPair',
                            onTap: () => _openRepairPage(context),
                          ),
                          const SizedBox(height: 19),
                          Row(
                            children: [
                              Expanded(
                                child: _SecondaryServiceCard(
                                  label: 'Maintain\nMyPair',
                                  iconAsset: 'assets/images/icons/caremypair/mmp.svg',
                                  iconSize: 56,
                                  labelFontSize: 13.2,
                                  onTap: () => _openMaintainPage(context),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: _SecondaryServiceCard(
                                  label: 'Wash\nMyPair',
                                  iconAsset: 'assets/images/icons/caremypair/wmp.svg',
                                  onTap: () => _openWashPage(context),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          Text(
                            'DIY Solutions',
                            style: GoogleFonts.boldonse(
                              color: const Color(0xFF062F35),
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Videos',
                            style: GoogleFonts.montserrat(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            height: 113,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _videos.length,
                              separatorBuilder: (_, _) => const SizedBox(width: 14),
                              itemBuilder: (_, i) => _VideoCard(data: _videos[i]),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Articles',
                            style: GoogleFonts.montserrat(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            height: 172,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _articles.length,
                              separatorBuilder: (_, _) => const SizedBox(width: 13),
                              itemBuilder: (_, i) => _ArticleCard(data: _articles[i]),
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
          SizedBox(height: bottomSafe),
        ],
      ),
    );
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
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF062F35), size: 24),
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

/// Same shell as [ArticleListPage] rack search (gradient stroke, white fill); no filter icon.
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
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: _cardHeight,
          padding: const EdgeInsets.symmetric(horizontal: 20),
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
  static const double _cardHeight = 86;
  final String label;
  final String iconAsset;
  final double iconSize;
  final double labelFontSize;
  final VoidCallback onTap;

  const _SecondaryServiceCard({
    required this.label,
    required this.iconAsset,
    this.iconSize = 38,
    this.labelFontSize = 16,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: _cardHeight,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFDFE7E9),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF0F6876)),
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
              SvgPicture.asset(
                iconAsset,
                width: iconSize,
                height: iconSize,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  textAlign: TextAlign.left,
                  style: GoogleFonts.boldonse(
                    color: const Color(0xFF062F35),
                    fontSize: labelFontSize,
                    height: 1.7,
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

class _VideoCardData {
  final String title;
  final String image;

  const _VideoCardData({required this.title, required this.image});
}

class _VideoCard extends StatelessWidget {
  final _VideoCardData data;

  const _VideoCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 174,
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

  const _ArticleCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
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
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
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
    );
  }
}
