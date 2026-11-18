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
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF062F35)),
                      ),
                      Expanded(
                        child: Text(
                          item.brand,
                          style: GoogleFonts.boldonse(fontSize: 18, color: const Color(0xFF062F35)),
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
                              color: on ? const Color(0xFF0F6876) : const Color(0xFFB7C9CC),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 14),
                      Text(item.brand, style: GoogleFonts.montserrat(color: const Color(0xFF5A5A5A), fontWeight: FontWeight.w600)),
                      Text(
                        item.title,
                        style: GoogleFonts.montserrat(fontSize: 20, fontWeight: FontWeight.w700, color: const Color(0xFF062F35)),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            thriftMoney(item.price),
                            style: GoogleFonts.montserrat(fontSize: 24, fontWeight: FontWeight.w800, color: const Color(0xFF062F35)),
                          ),
                          if (item.discountPercent > 0) ...[
                            const SizedBox(width: 8),
                            Text(
                              thriftMoney(item.mrp),
                              style: GoogleFonts.montserrat(
                                decoration: TextDecoration.lineThrough,
                                color: const Color(0xFF8A8A8A),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${item.discountPercent}% off',
                              style: GoogleFonts.montserrat(color: const Color(0xFF12899B), fontWeight: FontWeight.w700),
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
                        Text('Model ${item.model}', style: GoogleFonts.montserrat()),
                      ],
                      if (item.description.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(item.description, style: GoogleFonts.montserrat(height: 1.4)),
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
                      backgroundColor: const Color(0xFF0F6876),
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(
                      item.stock < 1 ? 'Out of stock' : 'Buy now',
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
      child: Text(label, style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}
