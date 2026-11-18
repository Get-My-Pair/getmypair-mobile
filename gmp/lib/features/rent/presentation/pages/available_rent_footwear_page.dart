import 'package:flutter/material.dart';
import 'package:gmp/core/bgtheme.dart';
import 'package:gmp/features/auth/domain/entities/user.dart';
import 'package:gmp/features/auth/domain/usecases/get_current_user.dart';
import 'package:gmp/features/auth/domain/usecases/get_valid_access_token.dart';
import 'package:gmp/features/rent/data/rent_remote_datasource.dart';
import 'package:gmp/features/rent/presentation/pages/rent_pay_page.dart';
import 'package:gmp/injection_container.dart';
import 'package:google_fonts/google_fonts.dart';

class AvailableRentFootwearPage extends StatefulWidget {
  const AvailableRentFootwearPage({super.key});

  @override
  State<AvailableRentFootwearPage> createState() => _AvailableRentFootwearPageState();
}

class _AvailableRentFootwearPageState extends State<AvailableRentFootwearPage> {
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
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F0F0),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.maybePop(context),
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF062F35)),
                        ),
                        Expanded(
                          child: Text(
                            'Available Rent Footwear',
                            style: GoogleFonts.boldonse(color: const Color(0xFF062F35), fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                    Expanded(
                      child: _loading
                          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0F6876)))
                          : _error != null
                              ? Center(child: Text(_error!))
                              : _listings.isEmpty
                                  ? const Center(child: Text('No approved footwear is available yet.'))
                                  : RefreshIndicator(
                                      onRefresh: _load,
                                      child: ListView.separated(
                                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                                        itemCount: _listings.length,
                                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                                        itemBuilder: (context, index) {
                                          final item = _listings[index];
                                          final mine = _myId != null && item.ownerId == _myId;
                                          return Material(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(12),
                                            child: InkWell(
                                              borderRadius: BorderRadius.circular(12),
                                              onTap: mine
                                                  ? null
                                                  : () async {
                                                      final paid = await Navigator.of(context).push<bool>(
                                                        MaterialPageRoute(
                                                          builder: (_) => RentPayPage(listing: item),
                                                        ),
                                                      );
                                                      if (paid == true) _load();
                                                    },
                                              child: Padding(
                                                padding: const EdgeInsets.all(10),
                                                child: Row(
                                                  children: [
                                                    ClipRRect(
                                                      borderRadius: BorderRadius.circular(8),
                                                      child: Image.network(
                                                        item.imageUrl,
                                                        width: 84,
                                                        height: 84,
                                                        fit: BoxFit.cover,
                                                        errorBuilder: (_, _, _) => const SizedBox(
                                                          width: 84,
                                                          height: 84,
                                                          child: Icon(Icons.image_not_supported),
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text(item.title, style: GoogleFonts.montserrat(fontWeight: FontWeight.w600)),
                                                          Text(item.ownerName.isEmpty ? 'Community pair' : item.ownerName),
                                                          Text('${item.durationLabel} · ₹${item.price}'),
                                                          const SizedBox(height: 4),
                                                          Text(
                                                            mine ? 'Your listing' : 'Pay to request',
                                                            style: GoogleFonts.montserrat(
                                                              color: const Color(0xFF0F6876),
                                                              fontWeight: FontWeight.w600,
                                                              fontSize: 13,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
