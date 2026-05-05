import 'package:flutter/material.dart';
import 'package:gmp/core/bgtheme.dart';
import 'package:gmp/core/constants/api_endpoints.dart';
import 'package:gmp/core/theme/app_colors.dart';
import 'package:gmp/core/widgets/floating_gradient_bottom_nav.dart';
import 'package:gmp/features/articles/domain/entities/article.dart';
import 'package:gmp/features/articles/domain/usecases/get_my_articles.dart';
import 'package:gmp/features/auth/domain/usecases/get_valid_access_token.dart';
import 'package:gmp/injection_container.dart';
import 'package:google_fonts/google_fonts.dart';

import 'service_selection_page.dart';

class RepairMyPairPage extends StatefulWidget {
  final String pageTitle;
  final List<String> allowedServiceTypes;
  final String description;

  const RepairMyPairPage({
    super.key,
    this.pageTitle = 'RepairMyPair',
    this.allowedServiceTypes = const ['repair'],
    this.description =
        'RepairMyPair is a service that restores any part of your footwear.\n\nPlease select the footwear you\'d like to repair.',
  });

  @override
  State<RepairMyPairPage> createState() => _RepairMyPairPageState();
}

class _RepairMyPairPageState extends State<RepairMyPairPage> {
  static const BorderRadius _panelRadius = BorderRadius.only(
    topLeft: Radius.circular(20),
    topRight: Radius.circular(20),
    bottomLeft: Radius.circular(50),
    bottomRight: Radius.circular(50),
  );
  static const Color _teal = Color(0xFF11999E);
  static const Color _dark = Color(0xFF062F35);

  bool _loading = true;
  bool _submitting = false;
  String? _error;
  List<Article> _articles = const [];
  String? _selectedArticleId;

  @override
  void initState() {
    super.initState();
    _loadArticles();
  }

  Future<void> _loadArticles() async {
    setState(() {
      _loading = true;
      _error = null;
    });

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
          final result = await sl<GetMyArticles>().call(token);
          if (!mounted) return;
          setState(() {
            _articles = result;
            _loading = false;
          });
        } catch (e) {
          if (!mounted) return;
          setState(() {
            _loading = false;
            _error = e.toString().replaceFirst('Exception: ', '');
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

  String _displayName(Article article) {
    if (article.brand.trim().isNotEmpty) return article.brand.trim();
    if (article.model.trim().isNotEmpty) return article.model.trim();
    if (article.color.trim().isNotEmpty) return article.color.trim();
    return 'Shoe';
  }

  Future<void> _goNext() async {
    if (_selectedArticleId == null || _submitting) return;
    final selectedArticle = _articles.firstWhere(
      (article) => article.id == _selectedArticleId,
    );
    setState(() => _submitting = true);
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ServiceSelectionPage(
          articleId: _selectedArticleId!,
          allowedServiceTypes: widget.allowedServiceTypes,
          articleName: _displayName(selectedArticle),
          articleImageUrl: _imageUrl(selectedArticle.thumbnailImage),
          flowPageTitle: widget.pageTitle,
        ),
      ),
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (created == true) {
      Navigator.maybePop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomSafe = MediaQuery.viewPaddingOf(context).bottom;
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      extendBody: true,
      body: Stack(
        children: [
          ...BgTheme.background(),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 30, 10, 0),
              child: DecoratedBox(
                decoration: const ShapeDecoration(
                  color: Color(0xFFF0F0F0),
                  shape: RoundedRectangleBorder(borderRadius: _panelRadius),
                ),
                child: ClipRRect(
                  borderRadius: _panelRadius,
                  child: _buildBody(),
                ),
              ),
            ),
          ),
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: DashboardLinkedBottomNav(selectedTabIndex: 1),
          ),
          SizedBox(height: bottomSafe),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: _teal),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.error),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _loadArticles,
                style: FilledButton.styleFrom(backgroundColor: _teal),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (_articles.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            'No footwear found. Please add a pair first.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF5C5C5C)),
          ),
        ),
      );
    }

    final rows = (_articles.length + 2) ~/ 3;
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 128),
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () => Navigator.maybePop(context),
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: _dark,
                size: 24,
              ),
            ),
            Text(
              widget.pageTitle,
              style: GoogleFonts.boldonse(
                color: _dark,
                fontSize: 24,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: 363,
          child: Text(
            widget.description,
            style: GoogleFonts.montserrat(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        const SizedBox(height: 14),
        ...List.generate(rows, (row) {
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
                    label: _displayName(article),
                    imageUrl: _imageUrl(article.thumbnailImage),
                    selected: _selectedArticleId == article.id,
                    onTap: () => setState(() => _selectedArticleId = article.id),
                  ),
                );
              }),
            ),
          );
        }),
        const SizedBox(height: 18),
        SizedBox(
          height: 48,
          child: FilledButton(
            onPressed: _selectedArticleId == null || _submitting ? null : _goNext,
            style: FilledButton.styleFrom(
              backgroundColor: _teal,
              disabledBackgroundColor: _teal.withValues(alpha: 0.35),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _submitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Next',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
          ),
        ),
      ],
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
          bottom: BorderSide(color: _RepairMyPairPageState._teal, width: 2),
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
                  border: Border.all(color: _RepairMyPairPageState._teal, width: 2),
                  color: selected
                      ? _RepairMyPairPageState._teal.withValues(alpha: 0.14)
                      : Colors.transparent,
                ),
                child: selected
                    ? const Center(
                        child: Icon(
                          Icons.check,
                          size: 14,
                          color: _RepairMyPairPageState._teal,
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: imageUrl.isEmpty
                  ? const Icon(Icons.checkroom_outlined, color: Color(0xFF8D8D8D), size: 42)
                  : Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) =>
                          const Icon(Icons.checkroom_outlined, color: Color(0xFF8D8D8D), size: 42),
                    ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.boldonse(
                color: _RepairMyPairPageState._teal,
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
