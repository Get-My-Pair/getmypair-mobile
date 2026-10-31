import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gmp/features/sell/data/sell_remote_datasource.dart';
import 'package:gmp/features/sell/presentation/pages/footwear_selection_page.dart';
import 'package:gmp/features/sell/presentation/pages/my_footwear_rack_page.dart';
import 'package:gmp/features/sell/presentation/widgets/sell_shell.dart';
import 'package:gmp/features/auth/domain/usecases/get_valid_access_token.dart';
import 'package:gmp/injection_container.dart';
import 'package:google_fonts/google_fonts.dart';

/// Sell My Pair hub: Luxury and Everyday, plus the user's reviewed racks.
class SellMyPairPage extends StatefulWidget {
  const SellMyPairPage({super.key});

  @override
  State<SellMyPairPage> createState() => _SellMyPairPageState();
}

class _SellMyPairPageState extends State<SellMyPairPage> {
  List<SellListing> _listings = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final tokenResult = await sl<GetValidAccessToken>().call();
    if (!mounted) return;
    await tokenResult.fold(
      (_) async {
        setState(() => _loading = false);
      },
      (token) async {
        try {
          final listings = await sl<SellRemoteDataSource>().getMyListings(token);
          if (!mounted) return;
          setState(() {
            _listings = listings;
            _loading = false;
          });
        } catch (_) {
          if (!mounted) return;
          setState(() => _loading = false);
        }
      },
    );
  }

  List<SellListing> _of(String type) =>
      _listings.where((item) => item.footwearType == type).take(3).toList();

  void _openSelection(String type) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => FootwearSelectionPage(footwearType: type)))
        .then((_) => _load());
  }

  void _openRack(String type) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => MyFootwearRackPage(footwearType: type)))
        .then((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final uiScale = (width / 390).clamp(0.84, 1.2).toDouble();
    final bodySize = (14.0 * uiScale).clamp(12.5, 16.0);
    final sectionSize = (16.0 * uiScale).clamp(14.0, 18.0);
    final gapSm = (12.0 * uiScale).clamp(8.0, 14.0);
    final gapMd = (16.0 * uiScale).clamp(12.0, 20.0);
    final gapLg = (18.0 * uiScale).clamp(14.0, 22.0);
    final cardGap = (8.0 * uiScale).clamp(6.0, 12.0);

    return SellFlowScaffold(
      children: [
        const SellPageHeader(title: 'SellMyPair'),
        SizedBox(height: gapMd),
        Text(
          'SellMyPair lets you sell any footwear, from daily wear to high-end luxury, directly to the GetMyPair community.',
          style: GoogleFonts.montserrat(
            color: Colors.black87,
            fontSize: bodySize,
            height: 1.35,
          ),
        ),
        SizedBox(height: (14.0 * uiScale).clamp(10.0, 16.0)),
        Text(
          'Select the type of footwear you’d like to sell:',
          style: GoogleFonts.montserrat(
            color: Colors.black87,
            fontSize: bodySize,
            height: 1.35,
          ),
        ),
        SizedBox(height: gapLg),
        Text(
          'Our Services',
          style: GoogleFonts.boldonse(
            color: SellColors.ink,
            fontSize: sectionSize,
            fontWeight: FontWeight.w400,
          ),
        ),
        SizedBox(height: gapSm),
        Row(
          children: [
            Expanded(
              child: _ServiceCard(
                label: 'Luxury',
                iconAsset: 'assets/images/Vector (5).svg',
                filled: true,
                onTap: () => _openSelection('luxury'),
              ),
            ),
            SizedBox(width: cardGap),
            Expanded(
              child: _ServiceCard(
                label: 'Everyday',
                iconAsset: 'assets/images/Group 144.svg',
                filled: false,
                onTap: () => _openSelection('everyday'),
              ),
            ),
          ],
        ),
        SizedBox(height: gapLg),
        Wrap(
          spacing: (14.0 * uiScale).clamp(10.0, 18.0),
          runSpacing: (8.0 * uiScale).clamp(6.0, 12.0),
          children: [
            _HubLegend(asset: SellColors.reviewIcon, label: 'In review'),
            _HubLegend(asset: SellColors.approvedIcon, label: 'Approved'),
            _HubLegend(asset: SellColors.rejectedIcon, label: 'Rejected'),
          ],
        ),
        SizedBox(height: gapLg),
        _RackPreview(
          title: 'My Luxury Rack',
          listings: _of('luxury'),
          loading: _loading,
          onExpand: () => _openRack('luxury'),
        ),
        SizedBox(height: gapLg),
        _RackPreview(
          title: 'My Everyday Rack',
          listings: _of('everyday'),
          loading: _loading,
          onExpand: () => _openRack('everyday'),
        ),
      ],
    );
  }
}

/// Matches Rehome SellMyPair / RentMyPair tile proportions (~2.25× wide as tall).
class _ServiceCardMetrics {
  final double height;
  final double padH;
  final double padV;
  final double iconSize;
  final double iconLeftInset;
  final double gap;
  final double fontSize;

  const _ServiceCardMetrics({
    required this.height,
    required this.padH,
    required this.padV,
    required this.iconSize,
    required this.iconLeftInset,
    required this.gap,
    required this.fontSize,
  });

  static _ServiceCardMetrics fromWidth(double cardWidth) {
    final height = (cardWidth / 2.25).clamp(64.0, 96.0);
    final padH = (cardWidth * 0.06).clamp(8.0, 14.0);
    final padV = (height * 0.12).clamp(8.0, 14.0);
    final innerH = (height - padV * 2).clamp(18.0, height);
    final iconSize = (innerH * 0.78).clamp(28.0, 46.0);
    final iconLeftInset = (cardWidth * 0.04).clamp(6.0, 14.0);
    final gap = (cardWidth * 0.05).clamp(8.0, 14.0);
    final fontSize = (innerH * 0.28).clamp(12.0, 16.0);
    return _ServiceCardMetrics(
      height: height,
      padH: padH,
      padV: padV,
      iconSize: iconSize,
      iconLeftInset: iconLeftInset,
      gap: gap,
      fontSize: fontSize,
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final String label;
  final String iconAsset;
  final bool filled;
  final VoidCallback onTap;

  const _ServiceCard({
    required this.label,
    required this.iconAsset,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = filled ? Colors.white : SellColors.ink;
    return LayoutBuilder(
      builder: (context, constraints) {
        final m = _ServiceCardMetrics.fromWidth(constraints.maxWidth);
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(10),
            child: Ink(
              height: m.height,
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(
                m.padH + m.iconLeftInset,
                m.padV,
                m.padH,
                m.padV,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: filled
                    ? const LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [Color(0xFF06343A), Color(0xFF14D7EA)],
                      )
                    : null,
                color: filled ? null : const Color(0xFFE7EEF0),
                border: filled
                    ? null
                    : Border.all(color: SellColors.teal, width: 1.2),
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
                    width: m.iconSize,
                    height: m.iconSize,
                    colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                  ),
                  SizedBox(width: m.gap),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.boldonse(
                        color: color,
                        fontSize: m.fontSize,
                        fontWeight: FontWeight.w400,
                      ),
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

class _RackPreview extends StatelessWidget {
  final String title;
  final List<SellListing> listings;
  final bool loading;
  final VoidCallback onExpand;

  const _RackPreview({
    required this.title,
    required this.listings,
    required this.loading,
    required this.onExpand,
  });

  String _label(SellListing listing) {
    if (listing.model.trim().isNotEmpty) return listing.model.trim();
    if (listing.brand.trim().isNotEmpty) return listing.brand.trim();
    return 'Shoe';
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final uiScale = (width / 390).clamp(0.84, 1.2).toDouble();
    final titleSize = (16.0 * uiScale).clamp(14.0, 18.0);
    final emptySize = (13.0 * uiScale).clamp(11.5, 14.5);
    // Match [SellRackShelf] height math (base 104 × uiScale).
    final shelfH = (104.0 * uiScale).clamp(88.0, 128.0);
    final iconBtn = (18.0 * uiScale).clamp(16.0, 22.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.boldonse(
                  color: SellColors.ink,
                  fontSize: titleSize,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            IconButton(
              onPressed: onExpand,
              tooltip: 'Open rack',
              visualDensity: VisualDensity.compact,
              constraints: BoxConstraints.tightFor(
                width: (40.0 * uiScale).clamp(36.0, 44.0),
                height: (40.0 * uiScale).clamp(36.0, 44.0),
              ),
              icon: SvgPicture.asset(
                'assets/images/maximize.svg',
                width: iconBtn,
                height: iconBtn,
                colorFilter: const ColorFilter.mode(
                  SellColors.ink,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: (6.0 * uiScale).clamp(4.0, 8.0)),
        if (loading)
          SizedBox(
            height: shelfH,
            width: double.infinity,
            child: const Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: SellColors.teal,
                ),
              ),
            ),
          )
        else if (listings.isEmpty)
          GestureDetector(
            onTap: onExpand,
            child: Container(
              height: shelfH,
              width: double.infinity,
              alignment: Alignment.center,
              padding: EdgeInsets.symmetric(
                horizontal: (12.0 * uiScale).clamp(8.0, 16.0),
              ),
              decoration: const BoxDecoration(
                color: SellRackShelf.shelfBg,
                border: Border(
                  bottom: BorderSide(color: SellRackShelf.shelfBorder, width: 3),
                ),
                borderRadius: SellRackShelf.shelfRadius,
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'No requests yet — tap ',
                      style: GoogleFonts.montserrat(
                        color: Colors.black45,
                        fontSize: emptySize,
                      ),
                    ),
                    SvgPicture.asset(
                      'assets/images/maximize.svg',
                      width: (14.0 * uiScale).clamp(12.0, 16.0),
                      height: (14.0 * uiScale).clamp(12.0, 16.0),
                      colorFilter: const ColorFilter.mode(
                        Colors.black45,
                        BlendMode.srcIn,
                      ),
                    ),
                    Text(
                      ' to open your rack',
                      style: GoogleFonts.montserrat(
                        color: Colors.black45,
                        fontSize: emptySize,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          SellRackShelf(
            children: [
              for (final item in listings)
                SellRackShoeCell(
                  imageUrl: item.imageUrl,
                  label: _label(item),
                  status: item.status,
                  onTap: onExpand,
                ),
            ],
          ),
      ],
    );
  }
}

class _HubLegend extends StatelessWidget {
  final String asset;
  final String label;

  const _HubLegend({required this.asset, required this.label});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final uiScale = (width / 390).clamp(0.84, 1.2).toDouble();
    final icon = (18.0 * uiScale).clamp(16.0, 22.0);
    final fontSize = (12.0 * uiScale).clamp(11.0, 14.0);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(asset, width: icon, height: icon),
        SizedBox(width: (6.0 * uiScale).clamp(4.0, 8.0)),
        Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: fontSize,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }
}