import 'package:flutter/material.dart';
import 'package:gmp/core/bgtheme.dart';
import 'package:gmp/features/auth/domain/usecases/get_valid_access_token.dart';
import 'package:gmp/features/rent/data/rent_remote_datasource.dart';
import 'package:gmp/injection_container.dart';
import 'package:google_fonts/google_fonts.dart';

/// Confirms payment, then creates the rent request for the listing owner.
class RentPayPage extends StatefulWidget {
  final RentListing listing;

  const RentPayPage({super.key, required this.listing});

  @override
  State<RentPayPage> createState() => _RentPayPageState();
}

class _RentPayPageState extends State<RentPayPage> {
  bool _busy = false;

  Future<void> _pay() async {
    setState(() => _busy = true);
    try {
      final tokenResult = await sl<GetValidAccessToken>().call();
      final token = tokenResult.fold<String?>((_) => null, (value) => value);
      if (token == null) throw Exception('Sign in to pay');
      await sl<RentRemoteDataSource>().createPaidRequest(token, listingId: widget.listing.id);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Request sent'),
          content: Text(
            '₹${widget.listing.price} is recorded for ${widget.listing.durationLabel}. '
            'The owner of this pair can see your request.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
          ],
        ),
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.listing;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          ...BgTheme.background(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F0F0),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.maybePop(context),
                            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF062F35)),
                          ),
                          Text(
                            'Pay to rent',
                            style: GoogleFonts.boldonse(color: const Color(0xFF062F35), fontSize: 20),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          item.imageUrl,
                          height: 200,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => const SizedBox(height: 200, child: Icon(Icons.image_not_supported)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(item.title, style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w600)),
                      Text(item.ownerName.isEmpty ? 'Community pair' : 'Listed by ${item.ownerName}'),
                      const SizedBox(height: 8),
                      Text('Duration: ${item.durationLabel}'),
                      Text(
                        'Amount: ₹${item.price}',
                        style: GoogleFonts.montserrat(fontSize: 20, fontWeight: FontWeight.w700, color: const Color(0xFF062F35)),
                      ),
                      const Spacer(),
                      Text(
                        'Payment creates a rent request on this pair. The person who listed it will see your name and the amount paid.',
                        style: GoogleFonts.montserrat(fontSize: 13, height: 1.4),
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: _busy ? null : _pay,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF0F6876),
                          minimumSize: const Size.fromHeight(50),
                        ),
                        child: Text(_busy ? 'Paying…' : 'Pay ₹${item.price}'),
                      ),
                    ],
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
