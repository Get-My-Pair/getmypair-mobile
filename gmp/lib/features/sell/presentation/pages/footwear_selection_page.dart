import 'package:flutter/material.dart';
import 'package:gmp/features/articles/domain/entities/article.dart';
import 'package:gmp/features/articles/domain/usecases/get_my_articles.dart';
import 'package:gmp/features/auth/domain/usecases/get_valid_access_token.dart';
import 'package:gmp/features/sell/presentation/pages/footwear_selling_page.dart';
import 'package:gmp/features/sell/presentation/widgets/sell_shell.dart';
import 'package:gmp/injection_container.dart';
import 'package:google_fonts/google_fonts.dart';

/// Grid of the user's luxury or everyday articles. Tap one to start selling.
class FootwearSelectionPage extends StatefulWidget {
  final String footwearType;

  const FootwearSelectionPage({super.key, required this.footwearType});

  bool get isLuxury => footwearType == 'luxury';

  @override
  State<FootwearSelectionPage> createState() => _FootwearSelectionPageState();
}

class _FootwearSelectionPageState extends State<FootwearSelectionPage> {
  List<Article> _articles = [];
  bool _loading = true;
  String? _error;
  String? _selectedId;

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
          final all = await sl<GetMyArticles>().call(token);
          if (!mounted) return;
          setState(() {
            _articles = all
                .where((article) =>
                    (article.footwearType == 'luxury' ? 'luxury' : 'everyday') ==
                    widget.footwearType)
                .toList();
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

  String _label(Article article) {
    final name = article.model.trim().isNotEmpty ? article.model : article.brand;
    if (name.length <= 10) return name;
    return '${name.substring(0, 9)}...';
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isLuxury ? 'Luxury' : 'Everyday';
    final prompt = widget.isLuxury
        ? 'Please select the luxury footwear you’d like to sell'
        : 'Please select the everyday footwear you’d like to sell';

    return SellFlowScaffold(
      children: [
        SellPageHeader(title: title),
        const SizedBox(height: 16),
        Text(
          prompt,
          style: GoogleFonts.montserrat(fontSize: 15, height: 1.35, color: Colors.black87),
        ),
        const SizedBox(height: 18),
        if (_loading)
          const Padding(
            padding: EdgeInsets.only(top: 40),
            child: Center(child: CircularProgressIndicator(color: SellColors.teal)),
          )
        else if (_error != null)
          Text(_error!, style: GoogleFonts.montserrat(color: Colors.red))
        else if (_articles.isEmpty)
          Text(
            'No $title footwear yet. Add footwear and choose $title as the type.',
            style: GoogleFonts.montserrat(fontSize: 14, height: 1.4),
          )
        else
          _grid(),
      ],
    );
  }

  Widget _grid() {
    final rows = <Widget>[];
    for (var i = 0; i < _articles.length; i += 3) {
      final slice = _articles.skip(i).take(3).toList();
      rows.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var c = 0; c < 3; c++)
              Expanded(
                child: c < slice.length
                    ? _tile(slice[c])
                    : const SizedBox.shrink(),
              ),
          ],
        ),
      );
      rows.add(const Divider(color: SellColors.line, thickness: 1.4, height: 28));
    }
    return Column(children: rows);
  }

  Widget _tile(Article article) {
    final selected = _selectedId == article.id;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedId = article.id);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => FootwearSellingPage(
              article: article,
              footwearType: widget.footwearType,
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: SellColors.teal,
              size: 22,
            ),
            const SizedBox(height: 8),
            SellShoeThumb(imageUrl: article.rackHeroImagePath),
            const SizedBox(height: 6),
            Text(
              _label(article),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.montserrat(
                color: SellColors.teal,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
