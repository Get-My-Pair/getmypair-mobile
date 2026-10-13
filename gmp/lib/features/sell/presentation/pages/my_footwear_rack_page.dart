import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gmp/features/sell/data/sell_remote_datasource.dart';
import 'package:gmp/features/auth/domain/usecases/get_valid_access_token.dart';
import 'package:gmp/features/sell/presentation/pages/footwear_selection_page.dart';
import 'package:gmp/features/sell/presentation/widgets/sell_shell.dart';
import 'package:gmp/injection_container.dart';
import 'package:google_fonts/google_fonts.dart';

/// Full list of submitted luxury or everyday sell requests, coloured by review.
class MyFootwearRackPage extends StatefulWidget {
  final String footwearType;

  const MyFootwearRackPage({super.key, required this.footwearType});

  @override
  State<MyFootwearRackPage> createState() => _MyFootwearRackPageState();
}

class _MyFootwearRackPageState extends State<MyFootwearRackPage> {
  List<SellListing> _listings = [];
  bool _loading = true;
  String? _error;

  bool get _isLuxury => widget.footwearType == 'luxury';

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
            _error = e.toString();
          });
        }
      },
    );
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
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
          ],
        ),
      );
      return;
    }
    // In review — status only (no edit while pending).
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('In review'),
        content: const Text(
          'Admin is reviewing this footwear. You will see Approved or Rejected here after their decision.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
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
                    SvgPicture.asset(SellColors.rejectedIcon, width: 28, height: 28),
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
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => FootwearSelectionPage(
                          footwearType: widget.footwearType,
                        ),
                      ),
                    ).then((_) => _load());
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
    final title = _isLuxury ? 'My Luxury Rack' : 'My Everyday Rack';
    return SellFlowScaffold(
      children: [
        SellPageHeader(title: title),
        const SizedBox(height: 10),
        _StatusLegend(),
        const SizedBox(height: 16),
        if (_loading)
          const Padding(
            padding: EdgeInsets.only(top: 40),
            child: Center(child: CircularProgressIndicator(color: SellColors.teal)),
          )
        else if (_error != null)
          Text(_error!, style: GoogleFonts.montserrat(color: Colors.red))
        else if (_listings.isEmpty)
          Text(
            'Uploaded footwear will appear here after you submit a sell request.',
            style: GoogleFonts.montserrat(fontSize: 14, height: 1.4),
          )
        else
          _grid(),
      ],
    );
  }

  Widget _grid() {
    final rows = <Widget>[];
    for (var i = 0; i < _listings.length; i += 3) {
      final slice = _listings.skip(i).take(3).toList();
      rows.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var c = 0; c < 3; c++)
              Expanded(
                child: c < slice.length ? _tile(slice[c]) : const SizedBox.shrink(),
              ),
          ],
        ),
      );
      rows.add(const Divider(color: SellColors.line, thickness: 1.4, height: 28));
    }
    return Column(children: rows);
  }

  Widget _tile(SellListing listing) {
    final name = listing.model.trim().isNotEmpty ? listing.model : listing.brand;
    final short = name.length <= 10 ? name : '${name.substring(0, 9)}...';
    final color = sellStatusColor(listing.status);
    return GestureDetector(
      onTap: () => _onListingTap(listing),
      child: Column(
        children: [
          SellShoeThumb(
            imageUrl: listing.imageUrl,
            status: listing.status,
          ),
          const SizedBox(height: 6),
          Text(
            short,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.montserrat(
              color: SellColors.teal,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            sellStatusLabel(listing.status),
            style: GoogleFonts.montserrat(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 14,
      runSpacing: 8,
      children: const [
        _LegendItem(asset: SellColors.reviewIcon, label: 'In review'),
        _LegendItem(asset: SellColors.approvedIcon, label: 'Approved'),
        _LegendItem(asset: SellColors.rejectedIcon, label: 'Rejected'),
      ],
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
