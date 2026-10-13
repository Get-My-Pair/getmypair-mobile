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
    return SellFlowScaffold(
      children: [
        const SellPageHeader(title: 'SellMyPair'),
        const SizedBox(height: 16),
        Text(
          'SellMyPair lets you sell any footwear, from daily wear to high-end luxury, directly to the GetMyPair community.',
          style: GoogleFonts.montserrat(
            color: Colors.black87,
            fontSize: 14,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Select the type of footwear you’d like to sell:',
          style: GoogleFonts.montserrat(
            color: Colors.black87,
            fontSize: 14,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Our Services',
          style: GoogleFonts.boldonse(
            color: SellColors.ink,
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ServiceCard(
                label: 'Luxury',
                icon: Icons.diamond_outlined,
                filled: true,
                onTap: () => _openSelection('luxury'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ServiceCard(
                label: 'Everyday',
                icon: Icons.sentiment_satisfied_alt_outlined,
                filled: false,
                onTap: () => _openSelection('everyday'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 14,
          runSpacing: 8,
          children: [
            _HubLegend(asset: SellColors.reviewIcon, label: 'In review'),
            _HubLegend(asset: SellColors.approvedIcon, label: 'Approved'),
            _HubLegend(asset: SellColors.rejectedIcon, label: 'Rejected'),
          ],
        ),
        const SizedBox(height: 18),
        _RackPreview(
          title: 'My Luxury Rack',
          listings: _of('luxury'),
          loading: _loading,
          onExpand: () => _openRack('luxury'),
        ),
        const SizedBox(height: 18),
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

class _ServiceCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool filled;
  final VoidCallback onTap;

  const _ServiceCard({
    required this.label,
    required this.icon,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = filled ? Colors.white : SellColors.ink;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          height: 92,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: filled
                ? const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [Color(0xFF06343A), Color(0xFF14D7EA)],
                  )
                : null,
            color: filled ? null : const Color(0xFFE7EEF0),
            border: filled ? null : Border.all(color: SellColors.teal, width: 1.2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.boldonse(
                  color: color,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.boldonse(
                  color: SellColors.ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            IconButton(
              onPressed: onExpand,
              tooltip: 'Open rack',
              icon: const Icon(Icons.open_in_new_rounded, color: SellColors.ink, size: 18),
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (loading)
          const SizedBox(
            height: 104,
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2, color: SellColors.teal),
              ),
            ),
          )
        else if (listings.isEmpty)
          GestureDetector(
            onTap: onExpand,
            child: Container(
              height: 104,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: SellRackShelf.shelfBg,
                border: Border(
                  bottom: BorderSide(color: SellRackShelf.shelfBorder, width: 3),
                ),
                borderRadius: SellRackShelf.shelfRadius,
              ),
              child: Text(
                'No requests yet — tap ↗ to open your rack',
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(color: Colors.black45, fontSize: 13),
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(asset, width: 18, height: 18),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.montserrat(fontSize: 12, color: Colors.black54),
        ),
      ],
    );
  }
}