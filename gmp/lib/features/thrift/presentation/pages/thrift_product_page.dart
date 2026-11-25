import 'package:flutter/material.dart';
import 'package:gmp/core/bgtheme.dart';
import 'package:gmp/features/thrift/presentation/pages/thrift_checkout_page.dart';
import 'package:gmp/features/thrift/thrift_catalog.dart';
import 'package:google_fonts/google_fonts.dart';

class ThriftProductPage extends StatefulWidget {
  final ThriftProduct product;

  const ThriftProductPage({super.key, required this.product});

  @override
  State<ThriftProductPage> createState() => _ThriftProductPageState();
}

class _ThriftProductPageState extends State<ThriftProductPage> {
  /// On [BgTheme] image — use light ink; keep dark ink only on white cards/chips.
  static const _onBg = Color(0xFFFFFFFF);
  static const _onBgMuted = Color(0xFFE8F4F6);
  static const _ink = Color(0xFF062F35);
  static const _accent = Color(0xFF0F6876);
  static const _discount = Color(0xFF09E0FF);

  final _page = PageController();
  int _index = 0;

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.product;
    final photos = item.images.isEmpty ? const [''] : item.images;
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
                  padding: const EdgeInsets.fromLTRB(4, 4, 16, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.maybePop(context),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _onBg),
                      ),
                      Expanded(
                        child: Text(
                          item.brand,
                          style: GoogleFonts.boldonse(fontSize: 18, color: _onBg),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: ColoredBox(
                          color: Colors.white,
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: PageView.builder(
                              controller: _page,
                              itemCount: photos.length,
                              onPageChanged: (value) => setState(() => _index = value),
                              itemBuilder: (_, i) => ThriftImage(url: photos[i], fit: BoxFit.contain),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(photos.length, (i) {
                          final on = i == _index;
                          return Container(
                            width: on ? 16 : 6,
                            height: 6,
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            decoration: BoxDecoration(
                              color: on ? _onBg : _onBg.withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        item.brand,
                        style: GoogleFonts.montserrat(color: _onBgMuted, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        item.title,
                        style: GoogleFonts.montserrat(fontSize: 20, fontWeight: FontWeight.w700, color: _onBg),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            thriftMoney(item.price),
                            style: GoogleFonts.montserrat(fontSize: 24, fontWeight: FontWeight.w800, color: _onBg),
                          ),
                          if (item.discountPercent > 0) ...[
                            const SizedBox(width: 8),
                            Text(
                              thriftMoney(item.mrp),
                              style: GoogleFonts.montserrat(
                                decoration: TextDecoration.lineThrough,
                                color: _onBgMuted.withValues(alpha: 0.75),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${item.discountPercent}% off',
                              style: GoogleFonts.montserrat(color: _discount, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (item.size.isNotEmpty) _chip('Size ${item.size}'),
                          _chip(item.conditionLabel),
                          if (item.color.isNotEmpty) _chip(item.color),
                          if (item.gender.isNotEmpty) _chip(item.gender),
                          _chip(item.stock > 0 ? 'In stock' : 'Out of stock'),
                        ],
                      ),
                      if (item.model.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Model ${item.model}',
                          style: GoogleFonts.montserrat(color: _onBgMuted),
                        ),
                      ],
                      if (item.description.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          item.description,
                          style: GoogleFonts.montserrat(height: 1.4, color: _onBgMuted),
                        ),
                      ],
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: FilledButton(
                    onPressed: item.stock < 1
                        ? null
                        : () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => ThriftCheckoutPage(product: item),
                              ),
                            );
                          },
                    style: FilledButton.styleFrom(
                      backgroundColor: _accent,
                      foregroundColor: _onBg,
                      disabledBackgroundColor: _onBg.withValues(alpha: 0.35),
                      disabledForegroundColor: _onBg,
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(
                      item.stock < 1 ? 'Out of stock' : 'Pay now',
                      style: GoogleFonts.montserrat(fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w600, color: _ink),
      ),
    );
  }
}
