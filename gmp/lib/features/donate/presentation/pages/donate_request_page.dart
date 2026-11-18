import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:gmp/core/bgtheme.dart';
import 'package:gmp/features/auth/domain/usecases/get_valid_access_token.dart';
import 'package:gmp/features/donate/data/donate_remote_datasource.dart';
import 'package:gmp/injection_container.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

class DonateRequestPage extends StatefulWidget {
  const DonateRequestPage({super.key});

  @override
  State<DonateRequestPage> createState() => _DonateRequestPageState();
}

class _DonateRequestPageState extends State<DonateRequestPage> {
  final _note = TextEditingController();
  final _picker = ImagePicker();
  Uint8List? _photo;
  String? _photoName;
  bool _busy = false;
  bool _loading = true;
  String? _error;
  List<DonateRequestItem> _requests = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final tokenResult = await sl<GetValidAccessToken>().call();
      final token = tokenResult.fold<String?>((_) => null, (value) => value);
      if (token == null) throw Exception('Sign in to donate');
      final requests = await sl<DonateRemoteDataSource>().getMine(token);
      if (!mounted) return;
      setState(() {
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

  Future<void> _pick() async {
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
    if (_photo == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Upload a footwear photo')));
      return;
    }
    setState(() => _busy = true);
    try {
      final tokenResult = await sl<GetValidAccessToken>().call();
      final token = tokenResult.fold<String?>((_) => null, (value) => value);
      if (token == null) throw Exception('Sign in to donate');
      final api = sl<DonateRemoteDataSource>();
      final imageUrl = await api.uploadImage(token, imageBytes: _photo!, fileName: _photoName ?? 'donate.jpg');
      await api.createRequest(token, imageUrl: imageUrl, note: _note.text.trim());
      if (!mounted) return;
      setState(() => _photo = null);
      _note.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Donation request sent for review')),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _label(String status) {
    if (status == 'approved') return 'Approved';
    if (status == 'rejected') return 'Rejected';
    return 'Waiting for review';
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
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.maybePop(context),
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF062F35)),
                        ),
                        Text(
                          'DonateMyPair',
                          style: GoogleFonts.boldonse(color: const Color(0xFF062F35), fontSize: 20),
                        ),
                      ],
                    ),
                    Text(
                      'Upload a photo of the pair you want to give. The request is reviewed in masteradmin.',
                      style: GoogleFonts.montserrat(fontSize: 13, height: 1.35),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _busy ? null : _pick,
                      child: Container(
                        height: 180,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF0F6876)),
                        ),
                        child: _photo == null
                            ? Text('Upload photo', style: GoogleFonts.montserrat(color: const Color(0xFF0F6876)))
                            : Image.memory(_photo!, fit: BoxFit.contain),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _note,
                      maxLines: 3,
                      maxLength: 500,
                      decoration: const InputDecoration(
                        labelText: 'Note (optional)',
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: _busy ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF0F6876),
                        minimumSize: const Size.fromHeight(48),
                      ),
                      child: Text(_busy ? 'Sending…' : 'Create request'),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                    ],
                    const SizedBox(height: 20),
                    Text('Your requests', style: GoogleFonts.boldonse(color: const Color(0xFF062F35), fontSize: 16)),
                    const SizedBox(height: 8),
                    if (_loading)
                      const Center(child: CircularProgressIndicator(color: Color(0xFF0F6876)))
                    else if (_requests.isEmpty)
                      Text('No donation requests yet.', style: GoogleFonts.montserrat())
                    else
                      for (final item in _requests)
                        Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  item.imageUrl,
                                  width: 64,
                                  height: 64,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => const SizedBox(width: 64, height: 64),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(_label(item.status), style: GoogleFonts.montserrat(fontWeight: FontWeight.w600)),
                                    if (item.note.isNotEmpty) Text(item.note, maxLines: 2, overflow: TextOverflow.ellipsis),
                                    if (item.status == 'rejected' && (item.rejectReason ?? '').isNotEmpty)
                                      Text(item.rejectReason!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                                  ],
                                ),
                              ),
                            ],
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
