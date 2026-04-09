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
import '../../../service/presentation/pages/service_selection_page.dart';

/// Rack cell: product image (contain) + single centered teal label (mockup: no card frame).
class _RackGridItem extends StatelessWidget {
  final Article article;
  final String imageUrl;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool selectionMode;
  final bool selected;

  const _RackGridItem({
    required this.article,
    required this.imageUrl,
    required this.onTap,
    this.onLongPress,
    this.selectionMode = false,
    this.selected = false,
  });

  static const Color _labelColor = Color(0xFF11999E);
  static const Color _ringTeal = Color(0xFF11999E);

  static String _displayLabel(Article a) {
    if (a.color.trim().isNotEmpty) return a.color.trim();
    if (a.brand.trim().isNotEmpty) return a.brand.trim();
    if (a.model.trim().isNotEmpty) return a.model.trim();
    return 'Shoe';
  }

  @override
  Widget build(BuildContext context) {
    final labelStyle = TextStyle(
      color: _labelColor,
      fontSize: Responsive.fontSize(context, 11),
      fontFamily: 'Boldonse',
      fontWeight: FontWeight.w400,
      height: 1.15,
    );
    final label = _displayLabel(article);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(top: selectionMode ? 8 : 0),
                      child: imageUrl.isNotEmpty
                          ? Image.network(
                              imageUrl,
                              fit: BoxFit.contain,
                              errorBuilder: (_, _, _) => _rackThumbPlaceholder(),
                            )
                          : _rackThumbPlaceholder(),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: labelStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              if (selectionMode)
                Positioned(
                  left: 0,
                  top: 0,
                  child: GestureDetector(
                    onTap: onTap,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: selected ? _ringTeal : Colors.white,
                        border: Border.all(color: _ringTeal, width: 2),
                      ),
                      child: selected
                          ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                          : null,
                    ),
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
      color: Colors.transparent,
      child: Center(
        child: Icon(Icons.checkroom_outlined, color: AppColors.textTertiary.withValues(alpha: 0.5), size: 32),
      ),
    );
  }
}

/// Module 3 – Article list. “My Rack” UI (gradient shell, filter chips, shelf rows).
class ArticleListPage extends StatefulWidget {
  final List<String>? serviceFlowAllowedTypes;
  final String? serviceFlowTitle;

  const ArticleListPage({
    super.key,
    this.serviceFlowAllowedTypes,
    this.serviceFlowTitle,
  });

  @override
  State<ArticleListPage> createState() => _ArticleListPageState();
}

class _ArticleListPageState extends State<ArticleListPage> {
  bool get _isServiceFlowMode =>
      widget.serviceFlowAllowedTypes != null &&
      widget.serviceFlowAllowedTypes!.isNotEmpty;

  List<Article>? _articles;
  String? _error;
  bool _loading = true;
  String? _filterCategory;
  String _searchQuery = '';
  bool _selectionMode = false;
  final Set<String> _selectedIds = {};

  static const Color _rackTeal = Color(0xFF0F6876);
  /// Primary UI teal from mockup (#11999E).
  static const Color _rackTealPrimary = Color(0xFF11999E);
  static const Color _rackDark = Color(0xFF062F35);
  static const Color _panelBg = Color(0xFFF5F5F5);

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
                child: const _RackBottomBar(),
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
          const CircularProgressIndicator(color: _rackTealPrimary),
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

  Widget _buildTealRowDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Container(
          height: 2,
          margin: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: _rackTealPrimary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  Widget _buildRackBody(BuildContext context) {
    final list = _filteredArticles;
    final hPad = Responsive.horizontalPaddingOf(context).clamp(12.0, 20.0);
    final canPop = Navigator.canPop(context);
    final rowCount = list.isEmpty ? 0 : (list.length + 2) ~/ 3;
    final selectedCount = _selectedIds.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 0),
          child: _selectionMode
              ? Row(
                  children: [
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                      onPressed: () => setState(() {
                        _selectionMode = false;
                        _selectedIds.clear();
                      }),
                      icon: Icon(Icons.close_rounded, size: 24, color: _rackDark),
                    ),
                    Expanded(
                      child: Text(
                        'My Rack',
                        style: TextStyle(
                          color: _rackDark,
                          fontSize: Responsive.fontSize(context, 22),
                          fontFamily: 'Boldonse',
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    Text(
                      '$selectedCount Selected',
                      style: TextStyle(
                        color: const Color(0xFF5C5C5C),
                        fontSize: Responsive.fontSize(context, 14),
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    if (canPop)
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: _rackDark),
                      ),
                    if (canPop) const SizedBox(width: 4),
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
                          width: 44,
                          height: 44,
                          decoration: ShapeDecoration(
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                              side: const BorderSide(width: 1.5, color: _rackTealPrimary),
                              borderRadius: BorderRadius.circular(22),
                            ),
                          ),
                          child: Icon(Icons.add_rounded, color: _rackDark, size: 22),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
        if (!_selectionMode) ...[
          if (_isServiceFlowMode) ...[
            Padding(
              padding: EdgeInsets.fromLTRB(hPad, 6, hPad, 2),
              child: Text(
                widget.serviceFlowTitle ?? 'Select an article to continue',
                style: TextStyle(
                  fontSize: Responsive.fontSize(context, 13),
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 6),
          ],
          const SizedBox(height: 14),
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
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: ShapeDecoration(
                    color: _rackTealPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.star_outline_rounded, color: Colors.white, size: 24),
                      const SizedBox(width: 10),
                      Text(
                        'Style Me',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: Responsive.fontSize(context, 17),
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
          const SizedBox(height: 14),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: hPad),
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: ShapeDecoration(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  side: const BorderSide(width: 1.5, color: _rackTealPrimary),
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
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  hintText: 'Search',
                  hintStyle: TextStyle(
                    color: Colors.black.withValues(alpha: 0.35),
                    fontSize: Responsive.fontSize(context, 16),
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.w400,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: Colors.black.withValues(alpha: 0.35),
                    size: 22,
                  ),
                  suffixIcon: Icon(
                    Icons.tune_rounded,
                    color: _rackTealPrimary.withValues(alpha: 0.85),
                    size: 22,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: hPad),
              itemCount: _filterTabs.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
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
        ],
        const SizedBox(height: 8),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadArticles,
            color: _rackTealPrimary,
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
                : ListView(
                    padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 24),
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    children: [
                      for (int r = 0; r < rowCount; r++) ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: List.generate(3, (c) {
                            final idx = r * 3 + c;
                            if (idx >= list.length) {
                              return const Expanded(child: SizedBox.shrink());
                            }
                            final article = list[idx];
                            final imageUrl = _imageUrl(article.thumbnailImage);
                            return Expanded(
                              child: AspectRatio(
                                aspectRatio: 0.72,
                                child: _RackGridItem(
                                  article: article,
                                  imageUrl: imageUrl,
                                  selectionMode: _selectionMode,
                                  selected: _selectedIds.contains(article.id),
                                  onLongPress: () => setState(() {
                                    _selectionMode = true;
                                    _selectedIds.add(article.id);
                                  }),
                                  onTap: () {
                                    if (_selectionMode) {
                                      setState(() {
                                        if (_selectedIds.contains(article.id)) {
                                          _selectedIds.remove(article.id);
                                          if (_selectedIds.isEmpty) {
                                            _selectionMode = false;
                                          }
                                        } else {
                                          _selectedIds.add(article.id);
                                        }
                                      });
                                    } else {
                                      if (_isServiceFlowMode) {
                                        _navigateToServiceSelection(
                                          context,
                                          article,
                                        );
                                      } else {
                                        _navigateToDetails(context, article);
                                      }
                                    }
                                  },
                                ),
                              ),
                            );
                          }),
                        ),
                        if (r < rowCount - 1) _buildTealRowDivider(),
                      ],
                    ],
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

  void _navigateToServiceSelection(BuildContext context, Article article) {
    Navigator.of(context)
        .push<bool>(
      MaterialPageRoute(
        builder: (_) => ServiceSelectionPage(
          articleId: article.id,
          allowedServiceTypes: widget.serviceFlowAllowedTypes,
        ),
      ),
    )
        .then((created) {
      if (created == true && mounted) {
        Navigator.of(context).pop(true);
      }
    });
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

  static const Color _teal = Color(0xFF11999E);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(100),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: ShapeDecoration(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              side: BorderSide(width: selected ? 2 : 1.2, color: _teal),
              borderRadius: BorderRadius.circular(100),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: const Color(0xFF1A1A1A),
              fontSize: Responsive.fontSize(context, 14),
              fontFamily: 'Montserrat',
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

/// Mockup: Home · Favorites · Rack (shoe) · Cart · Profile — white circle on active tab.
class _RackBottomBar extends StatelessWidget {
  const _RackBottomBar();

  static const double _barHeight = 56;
  static const double _hitSize = 44;
  static const Color _selectedIconColor = Color(0xFF08343A);

  /// Rack tab is index 2 while on this page.
  static const int _rackTabIndex = 2;

  @override
  Widget build(BuildContext context) {
    final items = <({IconData outlined, IconData filled, VoidCallback onTap})>[
      (
        outlined: Icons.home_outlined,
        filled: Icons.home_rounded,
        onTap: () {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        },
      ),
      (
        outlined: Icons.favorite_border_rounded,
        filled: Icons.favorite_rounded,
        onTap: () {},
      ),
      (
        outlined: Icons.checkroom_outlined,
        filled: Icons.checkroom,
        onTap: () {},
      ),
      (
        outlined: Icons.shopping_cart_outlined,
        filled: Icons.shopping_cart_rounded,
        onTap: () {},
      ),
      (
        outlined: Icons.person_outline_rounded,
        filled: Icons.person_rounded,
        onTap: () {},
      ),
    ];

    return Material(
      color: Colors.transparent,
      elevation: 0,
      child: Container(
        height: _barHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_barHeight / 2),
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Color(0xFF08343A),
              Color(0xFF0F6876),
              Color(0xFF11999E),
              Color(0xFF00D4E0),
            ],
            stops: [0.0, 0.35, 0.65, 1.0],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: 18,
              offset: const Offset(0, 8),
              spreadRadius: -4,
            ),
            BoxShadow(
              color: const Color(0xFF0A6C78).withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(items.length, (i) {
              final selected = i == _rackTabIndex;
              final item = items[i];
              return Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: item.onTap,
                    customBorder: const CircleBorder(),
                    splashColor: Colors.white24,
                    highlightColor: Colors.white10,
                    child: Center(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutCubic,
                        width: _hitSize,
                        height: _hitSize,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: selected ? Colors.white : Colors.transparent,
                          boxShadow: selected
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.12),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Icon(
                          selected ? item.filled : item.outlined,
                          size: 24,
                          color: selected ? _selectedIconColor : Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
