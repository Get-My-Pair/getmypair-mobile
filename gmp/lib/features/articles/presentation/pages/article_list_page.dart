import 'package:flutter/material.dart';
import 'package:gmp/core/constants/api_endpoints.dart';
import 'package:gmp/core/theme/app_colors.dart';
import 'package:gmp/core/utils/responsive.dart';
import 'package:gmp/features/articles/domain/entities/article.dart';
import 'package:gmp/features/articles/domain/usecases/get_my_articles.dart';
import 'package:gmp/features/auth/domain/usecases/get_valid_access_token.dart';
import 'package:gmp/features/home/presentation/pages/chatbot_page.dart';
import 'package:gmp/injection_container.dart';

import 'article_create_page.dart';
import 'article_details_page.dart';

/// Single rack row: teal border card, thumbnail + Boldonse labels (color / brand / model).
class _RackShelfItem extends StatelessWidget {
  final Article article;
  final String imageUrl;
  final VoidCallback onTap;

  const _RackShelfItem({
    required this.article,
    required this.imageUrl,
    required this.onTap,
  });

  static const Color _labelColor = Color(0xFF11899B);
  static const Color _borderTeal = Color(0xFF0F6876);

  @override
  Widget build(BuildContext context) {
    final labelStyle = TextStyle(
      color: _labelColor,
      fontSize: Responsive.fontSize(context, 14),
      fontFamily: 'Boldonse',
      fontWeight: FontWeight.w400,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          constraints: const BoxConstraints(minHeight: 104),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: ShapeDecoration(
            color: const Color(0xFFF0F0F0),
            shape: RoundedRectangleBorder(
              side: const BorderSide(width: 3, color: _borderTeal),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 96,
                height: 60,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _rackThumbPlaceholder(),
                        )
                      : _rackThumbPlaceholder(),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (article.color.isNotEmpty)
                      Text(
                        article.color,
                        style: labelStyle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (article.brand.isNotEmpty)
                      Text(
                        article.brand,
                        style: labelStyle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (article.model.isNotEmpty)
                      Text(
                        article.model,
                        style: labelStyle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (article.color.isEmpty && article.brand.isEmpty && article.model.isEmpty)
                      Text('Tap for details', style: labelStyle),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _rackThumbPlaceholder() {
    return ColoredBox(
      color: AppColors.surfaceVariant,
      child: const Center(
        child: Icon(Icons.checkroom_outlined, color: AppColors.textTertiary, size: 32),
      ),
    );
  }
}

/// Module 3 – Article list. “My Rack” UI (gradient shell, filter chips, shelf rows).
class ArticleListPage extends StatefulWidget {
  const ArticleListPage({super.key});

  @override
  State<ArticleListPage> createState() => _ArticleListPageState();
}

class _ArticleListPageState extends State<ArticleListPage> {
  List<Article>? _articles;
  String? _error;
  bool _loading = true;
  String? _filterCategory;
  String _searchQuery = '';

  static const Color _rackTeal = Color(0xFF0F6876);
  static const Color _rackTealAccent = Color(0xFF11899B);
  static const Color _rackDark = Color(0xFF062F35);
  static const Color _panelBg = Color(0xFFF0F0F0);

  static const SweepGradient _shellSweep = SweepGradient(
    center: Alignment(0.22, -1.07),
    startAngle: -0.55,
    endAngle: 5.73,
    colors: [
      Color(0xFF09E0FF),
      Color(0xFF0F6876),
      Color(0xFF062F35),
      Color(0xFF062F35),
    ],
    stops: [0.05, 0.44, 0.57, 1],
    transform: GradientRotation(-0.55),
  );

  @override
  void initState() {
    super.initState();
    _loadArticles();
  }

  Future<void> _loadArticles() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    final tokenResult = await sl<GetValidAccessToken>().call();
    if (!mounted) return;
    tokenResult.fold(
      (_) {
        setState(() {
          _error = 'Please sign in again';
          _loading = false;
        });
        return;
      },
      (token) async {
        try {
          final result = await sl<GetMyArticles>().call(token);
          if (!mounted) return;
          setState(() {
            _articles = result;
            _loading = false;
            _error = null;
          });
        } catch (e) {
          if (!mounted) return;
          setState(() {
            _error = e.toString().replaceFirst('Exception: ', '');
            _articles = null;
            _loading = false;
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

  List<Article> get _filteredArticles {
    final list = _articles ?? [];
    Iterable<Article> out = list;
    if (_filterCategory != null && _filterCategory!.isNotEmpty) {
      out = out.where((a) => a.category == _filterCategory);
    }
    final q = _searchQuery.trim().toLowerCase();
    if (q.isNotEmpty) {
      out = out.where((a) {
        return a.brand.toLowerCase().contains(q) ||
            a.model.toLowerCase().contains(q) ||
            a.color.toLowerCase().contains(q);
      });
    }
    return out.toList();
  }

  @override
  Widget build(BuildContext context) {
    final bottomSafe = Responsive.bottomInsetOf(context);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      extendBody: true,
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(gradient: _shellSweep),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
                    child: DecoratedBox(
                      decoration: ShapeDecoration(
                        color: _panelBg,
                        shape: RoundedRectangleBorder(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                            bottomLeft: Radius.circular(50),
                            bottomRight: Radius.circular(50),
                          ),
                        ),
                        shadows: const [
                          BoxShadow(
                            color: Color(0x19000000),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                          bottomLeft: Radius.circular(50),
                          bottomRight: Radius.circular(50),
                        ),
                        child: _loading
                            ? _buildLoading(context)
                            : _error != null
                                ? _buildError(context)
                                : _articles!.isEmpty
                                    ? _buildEmpty(context)
                                    : _buildRackBody(context),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 72 + bottomSafe),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: _RackBottomBar(
                  onCenterTap: () => _navigateToCreate(context),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: _rackTealAccent),
          const SizedBox(height: 16),
          Text(
            'Loading your rack…',
            style: TextStyle(
              fontSize: Responsive.fontSize(context, 14),
              fontFamily: 'Montserrat',
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context) {
    final h = Responsive.horizontalPaddingOf(context);
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: h),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: Responsive.fontSize(context, 15),
                fontFamily: 'Montserrat',
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _loadArticles,
              icon: const Icon(Icons.refresh, size: 20),
              label: const Text('Retry'),
              style: FilledButton.styleFrom(
                backgroundColor: _rackTeal,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    final h = Responsive.horizontalPaddingOf(context);
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: h),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.checkroom_outlined, size: 64, color: AppColors.textTertiary),
            const SizedBox(height: 20),
            Text(
              'Your rack is empty',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: Responsive.fontSize(context, 20),
                fontFamily: 'Boldonse',
                fontWeight: FontWeight.w400,
                color: _rackDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first pair',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: Responsive.fontSize(context, 14),
                fontFamily: 'Montserrat',
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: () => _navigateToCreate(context),
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Add shoe'),
              style: FilledButton.styleFrom(
                backgroundColor: _rackTeal,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const List<Map<String, String>> _filterTabs = [
    {'value': '', 'label': 'All'},
    {'value': 'formal', 'label': 'Formals'},
    {'value': 'sports_shoe', 'label': 'Nike'},
    {'value': 'casual', 'label': 'Casuals'},
    {'value': 'boot', 'label': 'Heels'},
    {'value': 'sandal', 'label': 'Converse'},
  ];

  Widget _buildRackBody(BuildContext context) {
    final list = _filteredArticles;
    final hPad = Responsive.horizontalPaddingOf(context).clamp(12.0, 20.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 0),
          child: Row(
            children: [
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: _rackDark),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'My Rack',
                  style: TextStyle(
                    color: _rackDark,
                    fontSize: Responsive.fontSize(context, 24),
                    fontFamily: 'Boldonse',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _navigateToCreate(context),
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    width: 48,
                    height: 48,
                    padding: const EdgeInsets.all(12),
                    decoration: ShapeDecoration(
                      color: const Color(0x33DFE7E9),
                      shape: RoundedRectangleBorder(
                        side: const BorderSide(width: 1, color: _rackTealAccent),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      shadows: const [
                        BoxShadow(
                          color: Color(0x2D000000),
                          blurRadius: 4,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(Icons.add_rounded, color: _rackDark, size: 22),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: hPad),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ChatbotPage()),
                );
              },
              borderRadius: BorderRadius.circular(100),
              child: Ink(
                height: 46,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                decoration: ShapeDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment(1, 0.5),
                    end: Alignment(0, 0.5),
                    colors: [Color(0xFF0CADC5), Color(0xFF063239)],
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.auto_awesome_outlined, color: Colors.white, size: 22),
                    const SizedBox(width: 10),
                    Text(
                      'Style Me',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: Responsive.fontSize(context, 16),
                        fontFamily: 'Boldonse',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: hPad),
          child: Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: ShapeDecoration(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                side: const BorderSide(width: 1, color: _rackDark),
                borderRadius: BorderRadius.circular(100),
              ),
            ),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              style: TextStyle(
                fontSize: Responsive.fontSize(context, 16),
                fontFamily: 'Montserrat',
                color: Colors.black87,
              ),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                hintText: 'Search',
                hintStyle: TextStyle(
                  color: Colors.black.withValues(alpha: 0.34),
                  fontSize: Responsive.fontSize(context, 16),
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.w400,
                ),
                prefixIcon: Icon(Icons.search_rounded, color: Colors.black.withValues(alpha: 0.34), size: 22),
                suffixIcon: Icon(Icons.mic_none_rounded, color: Colors.black.withValues(alpha: 0.34), size: 22),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: hPad),
            itemCount: _filterTabs.length,
            separatorBuilder: (context, index) => const SizedBox(width: 7),
            itemBuilder: (context, i) {
              final tab = _filterTabs[i];
              final value = tab['value']!;
              final label = tab['label']!;
              final isSelected = (value.isEmpty && (_filterCategory == null || _filterCategory!.isEmpty)) ||
                  (_filterCategory == value);
              return _FilterChipPill(
                label: label,
                selected: isSelected,
                onTap: () => setState(() => _filterCategory = value.isEmpty ? null : value),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadArticles,
            color: _rackTealAccent,
            backgroundColor: Colors.white,
            child: list.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(height: MediaQuery.sizeOf(context).height * 0.15),
                      Center(
                        child: Text(
                          'No shoes match',
                          style: TextStyle(
                            fontSize: Responsive.fontSize(context, 15),
                            fontFamily: 'Montserrat',
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: EdgeInsets.fromLTRB(hPad - 2, 0, hPad - 2, 24),
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      final article = list[index];
                      final imageUrl = _imageUrl(article.thumbnailImage);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _RackShelfItem(
                          article: article,
                          imageUrl: imageUrl,
                          onTap: () => _navigateToDetails(context, article),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  void _navigateToDetails(BuildContext context, Article article) {
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (_) => ArticleDetailsPage(articleId: article.id),
      ),
    )
        .then((_) => _loadArticles());
  }

  void _navigateToCreate(BuildContext context) {
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (_) => const ArticleCreatePage(),
      ),
    )
        .then((_) => _loadArticles());
  }
}

class _FilterChipPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChipPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  static const Color _border = Color(0xFFC6C6C6);
  static const Color _teal = Color(0xFF0F6876);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(100),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: ShapeDecoration(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              side: BorderSide(width: selected ? 2 : 1, color: selected ? _teal : _border),
              borderRadius: BorderRadius.circular(100),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.black,
              fontSize: Responsive.fontSize(context, 16),
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}

class _RackBottomBar extends StatelessWidget {
  final VoidCallback onCenterTap;

  const _RackBottomBar({required this.onCenterTap});

  static const SweepGradient _barGradient = SweepGradient(
    center: Alignment(0.22, -1.07),
    startAngle: -0.55,
    endAngle: 5.73,
    colors: [
      Color(0xFF09E0FF),
      Color(0xFF0F6876),
      Color(0xFF062F35),
      Color(0xFF062F35),
    ],
    stops: [0.05, 0.44, 0.57, 1],
    transform: GradientRotation(-0.55),
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: ShapeDecoration(
        gradient: _barGradient,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
        shadows: const [
          BoxShadow(
            color: Color(0xFFABABAB),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Material(
            color: Colors.white,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onCenterTap,
              child: const SizedBox(
                width: 45,
                height: 45,
                child: Icon(Icons.add_rounded, color: Color(0xFF062F35), size: 28),
              ),
            ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.home_outlined, color: Colors.white, size: 24),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.grid_view_rounded, color: Colors.white, size: 24),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.person_outline_rounded, color: Colors.white, size: 24),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
