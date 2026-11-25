import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gmp/core/bgtheme.dart';
import 'package:gmp/core/constants/api_endpoints.dart';
import 'package:gmp/core/network/dio_client.dart';
import 'package:gmp/features/auth/domain/usecases/get_valid_access_token.dart';
import 'package:gmp/features/thrift/thrift_catalog.dart';
import 'package:gmp/features/thrift/presentation/pages/thrift_product_page.dart';
import 'package:gmp/injection_container.dart';
import 'package:google_fonts/google_fonts.dart';

class ThriftStorePage extends StatefulWidget {
  const ThriftStorePage({super.key});

  @override
  State<ThriftStorePage> createState() => _ThriftStorePageState();
}

class _ThriftStorePageState extends State<ThriftStorePage> {
  /// Text/icons on [BgTheme] image — dark teal is invisible on the cyan/teal bg.
  static const _onBg = Color(0xFFFFFFFF);
  static const _onBgMuted = Color(0xFFE8F4F6);
  static const _ink = Color(0xFF062F35);
  static const _accent = Color(0xFF0F6876);

  static const _categories = [
    'all',
    'sneakers',
    'formal',
    'sports',
    'sandals',
    'boots',
    'slippers',
  ];

  final _search = TextEditingController();
  Timer? _debounce;
  String _category = 'all';
  bool _loading = true;
  String _error = '';
  List<ThriftProduct> _items = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<String?> _token() async {
    final result = await sl<GetValidAccessToken>().call();
    return result.fold<String?>((_) => null, (value) => value);
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final token = await _token();
      if (token == null) throw Exception('Sign in to open Thrift Store');
      final res = await sl<DioClient>().get(
        ApiEndpoints.thriftProducts(q: _search.text, category: _category),
        accessToken: token,
      );
      final data = (res['data'] as Map?) ?? const {};
      final raw = data['items'] as List? ?? const [];
      if (!mounted) return;
      setState(() {
        _items = raw
            .map((e) => ThriftProduct.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
        _items = const [];
      });
    }
  }

  void _onSearch(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _load);
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
                  padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.maybePop(context),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _onBg),
                      ),
                      Text(
                        'Thrift Store',
                        style: GoogleFonts.boldonse(fontSize: 22, color: _onBg),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: TextField(
                    controller: _search,
                    onChanged: _onSearch,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Search brand, shoe, size',
                      prefixIcon: const Icon(Icons.search, color: _accent),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _categories.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final key = _categories[index];
                      final selected = key == _category;
                      final label = key == 'all' ? 'All' : '${key[0].toUpperCase()}${key.substring(1)}';
                      return ChoiceChip(
                        label: Text(label),
                        selected: selected,
                        selectedColor: _accent,
                        backgroundColor: Colors.white,
                        side: BorderSide(color: selected ? _accent : const Color(0xFFB7C9CC)),
                        labelStyle: GoogleFonts.montserrat(
                          color: selected ? _onBg : _ink,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                        onSelected: (_) {
                          setState(() => _category = key);
                          _load();
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
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
    if (_error.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _error,
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(color: _onBgMuted, height: 1.4),
          ),
        ),
      );
    }
    if (_items.isEmpty) {
      return Center(
        child: Text(
          'No footwear yet.\nAdd pairs from Masteradmin → Thrift Store.',
          textAlign: TextAlign.center,
          style: GoogleFonts.montserrat(color: _onBgMuted, height: 1.4),
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.62,
      ),
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final item = _items[index];
        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => ThriftProductPage(product: item)),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: ThriftImage(url: item.cover)),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.brand,
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
                      if (item.discountPercent > 0)
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: thriftMoney(item.mrp),
                                style: GoogleFonts.montserrat(
                                  fontSize: 11,
                                  color: const Color(0xFF8A8A8A),
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                              TextSpan(
                                text: '  ${item.discountPercent}% off',
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
              ],
            ),
          ),
        );
      },
    );
  }
}
