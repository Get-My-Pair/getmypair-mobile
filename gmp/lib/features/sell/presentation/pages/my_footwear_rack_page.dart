import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gmp/core/bgtheme.dart';
import 'package:gmp/core/constants/api_endpoints.dart';
import 'package:gmp/core/widgets/floating_gradient_bottom_nav.dart';
import 'package:gmp/features/auth/domain/usecases/get_valid_access_token.dart';
import 'package:gmp/features/sell/data/sell_remote_datasource.dart';
import 'package:gmp/features/sell/presentation/pages/footwear_selection_page.dart';
import 'package:gmp/features/sell/presentation/widgets/sell_shell.dart';
import 'package:gmp/injection_container.dart';
import 'package:google_fonts/google_fonts.dart';

/// Full Luxury / Everyday sell rack — same shell/search/chips/shelves as My Rack.
class MyFootwearRackPage extends StatefulWidget {
  final String footwearType;

  const MyFootwearRackPage({super.key, required this.footwearType});

  @override
  State<MyFootwearRackPage> createState() => _MyFootwearRackPageState();
}

class _MyFootwearRackPageState extends State<MyFootwearRackPage> {
  static const Color _panelBg = Color(0xFFF0F0F0);
  static const Color _rackDark = Color(0xFF062F35);
  static const Color _rackTeal = Color(0xFF11999E);
  static const String _plusIconSvg = '''
<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M12 5V19" stroke="black" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
<path d="M5 12H19" stroke="black" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
</svg>
''';
  static const List<Map<String, String>> _filterTabs = [
    {'value': 'formal', 'label': 'Formals'},
    {'value': 'sports_shoe', 'label': 'Nike'},
    {'value': 'casual', 'label': 'Casuals'},
    {'value': 'boot', 'label': 'Heels'},
    {'value': 'sandal', 'label': 'Converse'},
  ];

  List<SellListing> _listings = [];
  bool _loading = true;
  String? _error;
  String? _filterCategory;
  String _searchQuery = '';
  final ScrollController _rackScrollController = ScrollController();

  bool get _isLuxury => widget.footwearType == 'luxury';

  String get _title => _isLuxury ? 'My Luxury Rack' : 'My Everyday Rack';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _rackScrollController.dispose();
    super.dispose();
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
          final listings = await sl<SellRemoteDataSource>().getMyListings(
            token,
            footwearType: widget.footwearType,
          );
          if (!mounted) return;
          setState(() {
            _listings = listings;
            _loading = false;
            _error = null;
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

  static String _imageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    final base = ApiEndpoints.baseUrl;
    if (path.startsWith('/')) return '$base$path';
    return '$base/uploads/$path';
  }

  String _label(SellListing listing) {
    if (listing.color.trim().isNotEmpty) return listing.color.trim();
    if (listing.model.trim().isNotEmpty) return listing.model.trim();
    if (listing.brand.trim().isNotEmpty) return listing.brand.trim();
    return 'Shoe';
  }

  List<SellListing> get _filteredListings {
    Iterable<SellListing> out = _listings;

    if (_filterCategory != null && _filterCategory!.isNotEmpty) {
      out = out.where((a) => a.category == _filterCategory);
    }

    final q = _searchQuery.trim().toLowerCase();
    if (q.isNotEmpty) {
      out = out.where((a) {
        return a.brand.toLowerCase().contains(q) ||
            a.model.toLowerCase().contains(q) ||
            a.color.toLowerCase().contains(q) ||
            a.category.toLowerCase().contains(q);
      });
    }

    return out.toList();
  }

  void _openAddFlow() {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => FootwearSelectionPage(
              footwearType: widget.footwearType,
            ),
          ),
        )
        .then((_) => _load());
  }

  void _onListingTap(SellListing listing) {
    if (listing.status == 'rejected') {
      _openRejectedSheet(listing);
      return;
    }
    if (listing.status == 'approved') {
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Approved'),
          content: const Text('This footwear was approved by admin review.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        ),
      );
      return;
    }
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('In review'),
        content: const Text(
          'Admin is reviewing this footwear. You will see Approved or Rejected here after their decision.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _openRejectedSheet(SellListing listing) {
    final reason = listing.rejectReason?.trim();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    SvgPicture.asset(
                      SellColors.rejectedIcon,
                      width: 28,
                      height: 28,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Rejected',
                      style: GoogleFonts.boldonse(
                        color: SellColors.rejected,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  (reason == null || reason.isEmpty)
                      ? 'Admin rejected this sell request. You can submit again.'
                      : reason,
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    height: 1.4,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 18),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _openAddFlow();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SellColors.teal,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(46),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Resubmit',
                    style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    'Close',
                    style: GoogleFonts.montserrat(color: SellColors.ink),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final uiScale = (width / 390).clamp(0.84, 1.12).toDouble();
    final horizontalInset = (10.0 * uiScale).clamp(8.0, 16.0);
    const panelRadius = BorderRadius.only(
      topLeft: Radius.circular(20),
      topRight: Radius.circular(20),
      bottomLeft: Radius.circular(50),
      bottomRight: Radius.circular(50),
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: Stack(
        children: [
          ...BgTheme.background(),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(horizontalInset, 30, horizontalInset, 0),
              child: DecoratedBox(
                decoration: const ShapeDecoration(
                  color: _panelBg,
                  shape: RoundedRectangleBorder(borderRadius: panelRadius),
                  shadows: [
                    BoxShadow(
                      color: Color(0x19000000),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: panelRadius,
                  child: _loading
                      ? const Center(
                          child: CircularProgressIndicator(color: _rackTeal),
                        )
                      : _error != null
                          ? _buildError()
                          : _buildRackBody(uiScale),
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

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(color: Colors.red, fontSize: 15),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _load,
              child: Text(
                'Retry',
                style: GoogleFonts.montserrat(
                  color: _rackTeal,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRackBody(double uiScale) {
    final list = _filteredListings;
    final rowCount = (list.length + 2) ~/ 3;
    final headerHInset = (12.0 * uiScale).clamp(10.0, 20.0);
    final titleLeftInset = (headerHInset - 4).clamp(10.0, 18.0);
    final topTitleGap = (20.0 * uiScale).clamp(18.0, 28.0);
    final titleSize = (20.0 * uiScale).clamp(18.0, 24.0);
    const plusSize = 42.0;
    const searchHeight = 42.0;
    final filtersHeight = (28.0 * uiScale).clamp(26.0, 32.0);
    final sectionGap = (10.0 * uiScale).clamp(8.0, 14.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(titleLeftInset, topTitleGap, headerHInset, 0),
          child: Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints.tightFor(
                        width: 26,
                        height: 26,
                      ),
                      visualDensity: const VisualDensity(
                        horizontal: -4,
                        vertical: -4,
                      ),
                      onPressed: () => Navigator.maybePop(context),
                      icon: SvgPicture.asset(
                        'assets/images/chevron-left.svg',
                        width: 26,
                        height: 26,
                        colorFilter: const ColorFilter.mode(
                          _rackDark,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                    const SizedBox(width: 7),
                    Flexible(
                      child: Text(
                        _title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.boldonse(
                          color: _rackDark,
                          fontSize: titleSize,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _openAddFlow,
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    width: plusSize,
                    height: plusSize,
                    padding: const EdgeInsets.all(1.4),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF09E0FF), Color(0xFF0F6876)],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x3A000000),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF6F7),
                        borderRadius: BorderRadius.circular(22.6),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: SvgPicture.string(
                          _plusIconSvg,
                          width: 14,
                          height: 14,
                          fit: BoxFit.contain,
                          colorFilter: const ColorFilter.mode(
                            _rackDark,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: (14.0 * uiScale).clamp(12.0, 18.0)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: headerHInset),
          child: Container(
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
                        onChanged: (value) =>
                            setState(() => _searchQuery = value),
                        textAlignVertical: TextAlignVertical.center,
                        style: GoogleFonts.montserrat(
                          fontSize: (16.0 * uiScale).clamp(13.0, 17.0),
                          color: Colors.black87,
                          fontWeight: FontWeight.w400,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          filled: false,
                          fillColor: Colors.transparent,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 9),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
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
          ),
        ),
        SizedBox(height: sectionGap),
        SizedBox(
          height: filtersHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: headerHInset),
            itemCount: _filterTabs.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final tab = _filterTabs[i];
              final value = tab['value']!;
              final selected = _filterCategory == value;
              return _FilterChipPill(
                label: tab['label']!,
                selected: selected,
                onTap: () => setState(() {
                  _filterCategory = selected ? null : value;
                }),
              );
            },
          ),
        ),
        SizedBox(height: (8.0 * uiScale).clamp(6.0, 10.0)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: headerHInset),
          child: Wrap(
            spacing: 14,
            runSpacing: 8,
            children: const [
              _LegendItem(asset: SellColors.reviewIcon, label: 'In review'),
              _LegendItem(asset: SellColors.approvedIcon, label: 'Approved'),
              _LegendItem(asset: SellColors.rejectedIcon, label: 'Rejected'),
            ],
          ),
        ),
        SizedBox(height: (8.0 * uiScale).clamp(6.0, 10.0)),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            color: _rackTeal,
            backgroundColor: Colors.white,
            child: _listings.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(height: MediaQuery.sizeOf(context).height * 0.16),
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 28),
                          child: Text(
                            'Uploaded footwear will appear here after you submit a sell request.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.montserrat(
                              fontSize: 14,
                              height: 1.4,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : list.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                            height: MediaQuery.sizeOf(context).height * 0.16,
                          ),
                          Center(
                            child: Text(
                              'No shoes match',
                              style: GoogleFonts.montserrat(
                                fontSize: 15,
                                color: Colors.black45,
                              ),
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        controller: _rackScrollController,
                        padding: EdgeInsets.fromLTRB(
                          headerHInset,
                          2,
                          headerHInset,
                          (100.0 * uiScale).clamp(90.0, 120.0),
                        ),
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        itemCount: rowCount,
                        itemBuilder: (context, rowIndex) {
                          final start = rowIndex * 3;
                          final slice = list.skip(start).take(3).toList();
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: rowIndex == rowCount - 1
                                  ? 0
                                  : (10.0 * uiScale).clamp(8.0, 14.0),
                            ),
                            child: SellRackShelf(
                              children: [
                                for (final listing in slice)
                                  SellRackShoeCell(
                                    imageUrl: _imageUrl(listing.imageUrl),
                                    label: _label(listing),
                                    status: listing.status,
                                    onTap: () => _onListingTap(listing),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ),
      ],
    );
  }
}

class _FilterChipPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChipPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(100),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 1.5),
          decoration: ShapeDecoration(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              side: BorderSide(
                width: selected ? 1.4 : 1,
                color: selected ? const Color(0xFF11999E) : const Color(0xFFC6C6C6),
              ),
              borderRadius: BorderRadius.circular(100),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.montserrat(
              color: const Color(0xFF1A1A1A),
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 1.0,
            ),
          ),
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final String asset;
  final String label;

  const _LegendItem({required this.asset, required this.label});

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
