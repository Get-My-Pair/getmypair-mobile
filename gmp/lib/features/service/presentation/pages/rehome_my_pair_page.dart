import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gmp/core/bgtheme.dart';
import 'package:gmp/core/widgets/app_feedback_alert.dart';
import 'package:gmp/features/sell/presentation/pages/sell_my_pair_page.dart';
import 'package:gmp/core/widgets/floating_gradient_bottom_nav.dart';
import 'package:google_fonts/google_fonts.dart';

/// Rehome hub. Sell My Pair opens the luxury and everyday selling flow. Rent stays coming soon.
class RehomeMyPairPage extends StatelessWidget {
  const RehomeMyPairPage({super.key});

  static const BorderRadius _panelRadius = BorderRadius.only(
    topLeft: Radius.circular(20),
    topRight: Radius.circular(20),
    bottomLeft: Radius.circular(50),
    bottomRight: Radius.circular(50),
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
                      padding: const EdgeInsets.fromLTRB(8, 12, 6, 120),
                      children: [
                      _Header(onBack: () => Navigator.maybePop(context)),
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.only(left: 36),
                        child: Text(
                          'Give Your Pair a Second Life!!',
                          style: GoogleFonts.boldonse(
                            color: const Color(0xFF0E7C8A),
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
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
                        crossAxisAlignment: CrossAxisAlignment.start,
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
                          const SizedBox(width: 14),
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
                        height: 92,
                        child: Row(
                          children: [
                            Expanded(child: _BrandTile(label: 'GUCCI', tone: _BrandTone.gucci)),
                            SizedBox(width: 10),
                            Expanded(child: _BrandTile(label: 'PRADA', tone: _BrandTone.prada)),
                            SizedBox(width: 10),
                            Expanded(child: _BrandTile(label: 'BA', tone: _BrandTone.balenciaga)),
                          ],
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
                      const Row(
                        children: [
                          Expanded(child: _RentalStyle(label: 'Statement Heels')),
                          Expanded(child: _RentalStyle(label: 'Designer Boots')),
                          Expanded(child: _RentalStyle(label: 'Trail Shoes')),
                        ],
                      ),
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
          'RehomeMyPair',
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

class _PrimaryDonateCard extends StatelessWidget {
  static const double _cardHeight = 108;
  final VoidCallback onTap;

  const _PrimaryDonateCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: _cardHeight,
          padding: const EdgeInsets.symmetric(horizontal: 10),
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
          child: const Row(
            children: [
              SizedBox(
                width: 56,
                height: 34,
                child: Image(
                  image: AssetImage(
                    'assets/images/icons/rehomemypair/sellmypair.png',
                  ),
                  fit: BoxFit.contain,
                  color: Colors.white,
                  colorBlendMode: BlendMode.srcIn,
                ),
              ),
              SizedBox(width: 10),
              Flexible(
                child: _TwoLineLabel(
                  first: 'Sell',
                  second: 'MyPair',
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TwoLineLabel extends StatelessWidget {
  final String first;
  final String second;
  final Color color;

  const _TwoLineLabel({
    required this.first,
    required this.second,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final style = GoogleFonts.boldonse(
      color: color,
      fontSize: 15,
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
        const SizedBox(height: 16),
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
  const _RentTaggedShoe();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      height: 34,
      child: Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
        children: [
          const Positioned(
            top: 6,
            left: 2,
            right: 2,
            child: SizedBox(
              height: 26,
              child: Image(
                image: AssetImage(
                  'assets/images/icons/rehomemypair/rentmypair_shoe.png',
                ),
                fit: BoxFit.contain,
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 3,
            child: Transform.rotate(
              angle: -0.27,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFF062F35),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  child: Text(
                    'RENT',
                    style: GoogleFonts.boldonse(
                      color: Colors.white,
                      fontSize: 7,
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
  static const double _cardHeight = 108;
  final VoidCallback onTap;

  const _SecondaryServiceCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.all(Radius.circular(10));

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
          child: const SizedBox(
            height: _cardHeight,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: [
                  _RentTaggedShoe(),
                  SizedBox(width: 10),
                  Flexible(
                    child: _TwoLineLabel(
                      first: 'Rent',
                      second: 'MyPair',
                      color: Color(0xFF062F35),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum _BrandTone { gucci, prada, balenciaga }

class _BrandTile extends StatelessWidget {
  final String label;
  final _BrandTone tone;

  const _BrandTile({required this.label, required this.tone});

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    switch (tone) {
      case _BrandTone.gucci:
        bg = const Color(0xFFC4A36A);
        fg = const Color(0xFF5C3B16);
      case _BrandTone.prada:
        bg = Colors.black;
        fg = Colors.white;
      case _BrandTone.balenciaga:
        bg = Colors.white;
        fg = Colors.black;
    }
    return Container(
      height: 88,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
        border: tone == _BrandTone.balenciaga ? Border.all(color: const Color(0xFFD7D7D7)) : null,
      ),
      child: Text(
        label,
        style: GoogleFonts.cinzel(
          color: fg,
          fontSize: tone == _BrandTone.balenciaga ? 22 : 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _RentalStyle extends StatelessWidget {
  final String label;

  const _RentalStyle({required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Image.asset(
          'assets/images/icons/myrack/shoe.png',
          height: 72,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => const Icon(Icons.ice_skating, size: 48, color: Color(0xFF0E7C8A)),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.montserrat(fontSize: 12, color: Colors.black87),
        ),
      ],
    );
  }
}
