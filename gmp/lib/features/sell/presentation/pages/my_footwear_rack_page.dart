import 'package:flutter/material.dart';
import 'package:gmp/features/sell/data/sell_remote_datasource.dart';
import 'package:gmp/features/auth/domain/usecases/get_valid_access_token.dart';
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

  void _openReason(SellListing listing) {
    final reason = listing.rejectReason;
    if (listing.status != 'rejected' || reason == null || reason.isEmpty) return;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rejected'),
        content: Text(reason),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = _isLuxury ? 'My Luxury Rack' : 'My Everyday Rack';
    return SellFlowScaffold(
      children: [
        SellPageHeader(title: title),
        const SizedBox(height: 8),
        Text(
          'Yellow is in review, green is approved, and red is rejected.',
          style: GoogleFonts.montserrat(fontSize: 13, color: Colors.black54),
        ),
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
      onTap: () => _openReason(listing),
      child: Column(
        children: [
          SellShoeThumb(imageUrl: listing.imageUrl, ringColor: color),
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
