import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gmp/core/bgtheme.dart';
import 'package:gmp/features/auth/domain/usecases/get_valid_access_token.dart';
import 'package:gmp/features/rent/data/rent_remote_datasource.dart';
import 'package:gmp/injection_container.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

class RentYourFootwearPage extends StatefulWidget {
  const RentYourFootwearPage({super.key});

  @override
  State<RentYourFootwearPage> createState() => _RentYourFootwearPageState();
}

class _RentYourFootwearPageState extends State<RentYourFootwearPage> {
  final _title = TextEditingController();
  final _price = TextEditingController();
  final _picker = ImagePicker();

  Uint8List? _photo;
  String? _photoName;
  String _duration = 'month';
  bool _busy = false;
  bool _loading = true;
  String? _error;
  List<RentListing> _listings = [];
  List<RentRequestItem> _requests = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _title.dispose();
    _price.dispose();
    super.dispose();
  }

  Future<String?> _token() async {
    final result = await sl<GetValidAccessToken>().call();
    return result.fold((_) => null, (token) => token);
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final token = await _token();
      if (token == null) throw Exception('Sign in to list footwear');
      final api = sl<RentRemoteDataSource>();
      final listings = await api.getMyListings(token);
      final requests = await api.getIncomingRequests(token);
      if (!mounted) return;
      setState(() {
        _listings = listings;
        _requests = requests;
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

  Future<void> _pickPhoto() async {
    final file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() {
      _photo = bytes;
      _photoName = file.name;
    });
  }

  Future<void> _submit() async {
    final title = _title.text.trim().isEmpty ? 'Footwear' : _title.text.trim();
    final price = num.tryParse(_price.text.trim());
    if (_photo == null) {
      _toast('Upload a footwear photo');
      return;
    }
    if (price == null || price < 1) {
      _toast('Enter a rent price');
      return;
    }
    setState(() => _busy = true);
    try {
      final token = await _token();
      if (token == null) throw Exception('Sign in to list footwear');
      final api = sl<RentRemoteDataSource>();
      final imageUrl = await api.uploadImage(
        token,
        imageBytes: _photo!,
        fileName: _photoName ?? 'footwear.jpg',
      );
      await api.createListing(
        token,
        title: title,
        imageUrl: imageUrl,
        duration: _duration,
        price: price,
      );
      if (!mounted) return;
      _title.clear();
      _price.clear();
      setState(() => _photo = null);
      _toast('Submitted. Waiting for approval.');
      await _load();
    } catch (e) {
      _toast(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final pending = _listings.where((e) => e.isPending || e.isRejected).toList();
    final approved = _listings.where((e) => e.isApproved).toList();

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
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.maybePop(context),
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF062F35)),
                        ),
                        Expanded(
                          child: Text(
                            'Rent your Footwear',
                            style: GoogleFonts.boldonse(color: const Color(0xFF062F35), fontSize: 18),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _title,
                      decoration: const InputDecoration(
                        labelText: 'Footwear name',
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _busy ? null : _pickPhoto,
                      child: Container(
                        height: 160,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF0F6876)),
                        ),
                        child: _photo == null
                            ? Text(
                                'Upload photo',
                                style: GoogleFonts.montserrat(color: const Color(0xFF0F6876)),
                              )
                            : Image.memory(_photo!, fit: BoxFit.contain),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text('Rent duration', style: GoogleFonts.montserrat(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final item in kRentDurations)
                          ChoiceChip(
                            label: Text(item.label),
                            selected: _duration == item.value,
                            onSelected: (_) => setState(() => _duration = item.value),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _price,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: 'Rent price (₹)',
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _busy ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF0F6876),
                        minimumSize: const Size.fromHeight(48),
                      ),
                      child: Text(_busy ? 'Uploading…' : 'Upload for approval'),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                    ],
                    const SizedBox(height: 24),
                    Text('Waiting for approval', style: GoogleFonts.boldonse(color: const Color(0xFF062F35), fontSize: 16)),
                    const SizedBox(height: 8),
                    if (_loading)
                      const Padding(
                        padding: EdgeInsets.all(12),
                        child: Center(child: CircularProgressIndicator(color: Color(0xFF0F6876))),
                      )
                    else if (pending.isEmpty)
                      Text('No footwear waiting for review.', style: GoogleFonts.montserrat())
                    else
                      for (final item in pending) _ListingTile(item: item, requests: const []),
                    const SizedBox(height: 20),
                    Text('Approved footwear', style: GoogleFonts.boldonse(color: const Color(0xFF062F35), fontSize: 16)),
                    const SizedBox(height: 8),
                    if (!_loading && approved.isEmpty)
                      Text('Approved pairs show here after review.', style: GoogleFonts.montserrat())
                    else
                      for (final item in approved)
                        _ListingTile(
                          item: item,
                          requests: _requests.where((r) => r.listingId == item.id).toList(),
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

class _ListingTile extends StatelessWidget {
  final RentListing item;
  final List<RentRequestItem> requests;

  const _ListingTile({required this.item, required this.requests});

  String get _status {
    if (item.isApproved) return 'Approved';
    if (item.isRejected) return 'Rejected';
    return 'Waiting for approval';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  item.imageUrl,
                  width: 72,
                  height: 72,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const SizedBox(width: 72, height: 72, child: Icon(Icons.image_not_supported)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title, style: GoogleFonts.montserrat(fontWeight: FontWeight.w600)),
                    Text('${item.durationLabel} · ₹${item.price}'),
                    Text(_status, style: GoogleFonts.montserrat(color: const Color(0xFF0F6876), fontSize: 12)),
                    if (item.isRejected && (item.rejectReason ?? '').isNotEmpty)
                      Text(item.rejectReason!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          if (requests.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Rent requests', style: GoogleFonts.montserrat(fontWeight: FontWeight.w600, fontSize: 13)),
            for (final request in requests)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${request.renterName} paid ₹${request.paidAmount} for ${request.durationLabel}',
                  style: GoogleFonts.montserrat(fontSize: 13),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
