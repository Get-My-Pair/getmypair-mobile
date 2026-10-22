import 'package:flutter/material.dart';
import 'package:gmp/core/constants/api_endpoints.dart';
import 'package:gmp/core/widgets/app_feedback_alert.dart';
import 'package:gmp/features/articles/domain/entities/article.dart';
import 'package:gmp/features/articles/domain/usecases/get_my_articles.dart';
import 'package:gmp/features/auth/domain/usecases/get_valid_access_token.dart';
import 'package:gmp/features/sell/presentation/pages/footwear_selling_page.dart';
import 'package:gmp/features/sell/presentation/widgets/sell_shell.dart';
import 'package:gmp/injection_container.dart';
import 'package:google_fonts/google_fonts.dart';

/// Luxury / Everyday sell picker — same select + Next layout as DonateMyPair.
class FootwearSelectionPage extends StatefulWidget {
  final String footwearType;

  const FootwearSelectionPage({super.key, required this.footwearType});

  bool get isLuxury => footwearType == 'luxury';

  @override
  State<FootwearSelectionPage> createState() => _FootwearSelectionPageState();
}

class _FootwearSelectionPageState extends State<FootwearSelectionPage> {
  static const Color _teal = Color(0xFF11999E);

  List<Article> _articles = [];
  bool _loading = true;
  String? _error;
  String? _selectedId;

  String get _title => widget.isLuxury ? 'Luxury' : 'Everyday';

  String get _tagline => widget.isLuxury
      ? 'Luxury Finds, Ready to Sell!!'
      : 'Everyday Pairs, Ready to Sell!!';

  String get _description => widget.isLuxury
      ? "Please select the luxury footwear you'd like to sell."
      : "Please select the everyday footwear you'd like to sell.";

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
          final filtered = all
              .where(
                (article) =>
                    (article.footwearType == 'luxury' ? 'luxury' : 'everyday') ==
                    widget.footwearType,
              )
              .toList();
          setState(() {
            _articles = filtered;
            // Default-select first pair (DonateMyPair-style ready-to-go).
            _selectedId = filtered.isNotEmpty ? filtered.first.id : null;
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

  static String _imageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    final base = ApiEndpoints.baseUrl;
    if (path.startsWith('/')) return '$base$path';
    return '$base/uploads/$path';
  }

  String _label(Article article) {
    final brand = article.brand.trim();
    if (brand.isNotEmpty) return brand;
    final model = article.model.trim();
    if (model.isNotEmpty) {
      return model.length <= 10 ? model : '${model.substring(0, 9)}...';
    }
    return 'Shoe';
  }

  void _select(String articleId) {
    setState(() => _selectedId = articleId);
  }

  Future<void> _goNext() async {
    if (_selectedId == null) {
      await showAppFeedbackAlert(
        context,
        message: 'Please select a pair of footwear',
        type: AppFeedbackType.warning,
      );
      return;
    }
    Article? selected;
    for (final article in _articles) {
      if (article.id == _selectedId) {
        selected = article;
        break;
      }
    }
    if (selected == null) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FootwearSellingPage(
          article: selected!,
          footwearType: widget.footwearType,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SellFlowScaffold(
      children: [
        SellPageHeader(title: _title, subtitle: _tagline),
        const SizedBox(height: 10),
        Text(
          _description,
          style: GoogleFonts.montserrat(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 14),
        if (_loading)
          const Padding(
            padding: EdgeInsets.only(top: 40),
            child: Center(
              child: CircularProgressIndicator(color: SellColors.teal),
            ),
          )
        else if (_error != null)
          Text(_error!, style: GoogleFonts.montserrat(color: Colors.red))
        else if (_articles.isEmpty)
          Text(
            'No $_title footwear yet. Add footwear and choose $_title as the type.',
            style: GoogleFonts.montserrat(fontSize: 14, height: 1.4),
          )
        else ...[
          _grid(),
          const SizedBox(height: 18),
          _nextButton(),
        ],
      ],
    );
  }

  /// Same 3-up row chrome as DonateMyPair picker.
  Widget _grid() {
    final rows = (_articles.length + 2) ~/ 3;
    return Column(
      children: List.generate(rows, (row) {
        return Padding(
          padding: EdgeInsets.only(bottom: row == rows - 1 ? 0 : 10),
          child: _ShoeRow(
            children: List.generate(3, (col) {
              final index = row * 3 + col;
              if (index >= _articles.length) {
                return const Expanded(child: SizedBox.shrink());
              }
              final article = _articles[index];
              return Expanded(
                child: _ShoeOption(
                  label: _label(article),
                  imageUrl: _imageUrl(article.rackHeroImagePath),
                  selected: _selectedId == article.id,
                  onTap: () => _select(article.id),
                ),
              );
            }),
          ),
        );
      }),
    );
  }

  Widget _nextButton() {
    final enabled = _selectedId != null;
    return Center(
      child: SizedBox(
        width: 164,
        height: 48,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerRight,
              end: Alignment.centerLeft,
              colors: enabled
                  ? const [Color(0xFF0CADC5), Color(0xFF063239)]
                  : const [Color(0xFF9BB8BC), Color(0xFF6A7F83)],
            ),
            borderRadius: BorderRadius.circular(100),
            boxShadow: const [
              BoxShadow(
                color: Color(0x19000000),
                blurRadius: 4,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: TextButton(
            onPressed: enabled ? _goNext : null,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(100),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Next',
                  style: GoogleFonts.boldonse(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(width: 20),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ShoeRow extends StatelessWidget {
  final List<Widget> children;

  const _ShoeRow({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 112,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(10),
        border: const Border(
          bottom: BorderSide(
            color: _FootwearSelectionPageState._teal,
            width: 2,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

class _ShoeOption extends StatelessWidget {
  final String label;
  final String imageUrl;
  final bool selected;
  final VoidCallback onTap;

  const _ShoeOption({
    required this.label,
    required this.imageUrl,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Column(
          children: [
            const SizedBox(height: 2),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _FootwearSelectionPageState._teal,
                    width: 2,
                  ),
                  color: selected
                      ? _FootwearSelectionPageState._teal
                          .withValues(alpha: 0.14)
                      : Colors.transparent,
                ),
                child: selected
                    ? const Center(
                        child: Icon(
                          Icons.check,
                          size: 14,
                          color: _FootwearSelectionPageState._teal,
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: imageUrl.isEmpty
                  ? const Icon(
                      Icons.checkroom_outlined,
                      color: Color(0xFF8D8D8D),
                      size: 42,
                    )
                  : Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.checkroom_outlined,
                        color: Color(0xFF8D8D8D),
                        size: 42,
                      ),
                    ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.boldonse(
                color: _FootwearSelectionPageState._teal,
                fontWeight: FontWeight.w400,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
