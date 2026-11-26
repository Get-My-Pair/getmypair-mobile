import 'package:flutter/material.dart';
import 'package:gmp/core/bgtheme.dart';
import 'package:gmp/features/auth/domain/entities/user.dart';
import 'package:gmp/features/auth/domain/usecases/get_current_user.dart';
import 'package:gmp/features/auth/domain/usecases/get_valid_access_token.dart';
import 'package:gmp/features/rent/data/rent_remote_datasource.dart';
import 'package:gmp/features/rent/presentation/pages/rent_footwear_detail_page.dart';
import 'package:gmp/features/thrift/thrift_catalog.dart';
import 'package:gmp/injection_container.dart';
import 'package:google_fonts/google_fonts.dart';

class AvailableRentFootwearPage extends StatefulWidget {
  const AvailableRentFootwearPage({super.key});

  @override
  State<AvailableRentFootwearPage> createState() => _AvailableRentFootwearPageState();
}

class _AvailableRentFootwearPageState extends State<AvailableRentFootwearPage> {
  static const _onBg = Color(0xFFFFFFFF);
  static const _onBgMuted = Color(0xFFE8F4F6);

  bool _loading = true;
  String? _error;
  String? _myId;
  List<RentListing> _listings = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final tokenResult = await sl<GetValidAccessToken>().call();
      final token = tokenResult.fold<String?>((_) => null, (value) => value);
      if (token == null) throw Exception('Sign in to browse rentals');
      final userResult = await sl<GetCurrentUser>().call();
      final user = userResult.fold<User?>((_) => null, (value) => value);
      final listings = await sl<RentRemoteDataSource>().getAvailable(token);
      if (!mounted) return;
      setState(() {
        _myId = user?.id;
        _listings = listings;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          ...BgTheme.background(),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.maybePop(context),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _onBg),
                      ),
                      Expanded(
                        child: Text(
                          'Available Rent Footwear',
                          style: GoogleFonts.boldonse(fontSize: 18, color: _onBg),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(child: _body()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _onBg));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_error!, textAlign: TextAlign.center, style: GoogleFonts.montserrat(color: _onBgMuted)),
        ),
      );
    }
    if (_listings.isEmpty) {
      return Center(
        child: Text(
          'No approved footwear is available yet.',
          textAlign: TextAlign.center,
          style: GoogleFonts.montserrat(color: _onBgMuted),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.62,
        ),
        itemCount: _listings.length,
        itemBuilder: (context, index) {
          final item = _listings[index];
          final mine = _myId != null && item.ownerId == _myId;
          return Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () async {
                final paid = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => RentFootwearDetailPage(listing: item, mine: mine),
                  ),
                );
                if (paid == true) _load();
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: ThriftImage(url: item.imageUrl)),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.ownerName.isEmpty ? 'Community pair' : item.ownerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.montserrat(
                            fontSize: 11,
                            color: const Color(0xFF5A5A5A),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          item.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.montserrat(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF062F35),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          thriftMoney(item.price),
                          style: GoogleFonts.montserrat(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF062F35),
                          ),
                        ),
                        Text(
                          mine ? 'Your listing' : item.durationLabel,
                          style: GoogleFonts.montserrat(
                            fontSize: 11,
                            color: const Color(0xFF12899B),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
