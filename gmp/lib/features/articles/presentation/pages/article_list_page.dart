import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gmp/core/bgtheme.dart';
import 'package:gmp/core/constants/api_endpoints.dart';
import 'package:gmp/core/theme/app_colors.dart';
import 'package:gmp/core/widgets/floating_gradient_bottom_nav.dart';
import 'package:gmp/features/articles/domain/entities/article.dart';
import 'package:gmp/features/articles/domain/usecases/get_my_articles.dart';
import 'package:gmp/features/auth/domain/usecases/get_valid_access_token.dart';
import 'package:gmp/injection_container.dart';

import '../../../service/presentation/pages/service_selection_page.dart';
import 'article_create_page.dart';
import 'article_details_page.dart';

class ArticleListPage extends StatefulWidget {
  final List<String>? serviceFlowAllowedTypes;
  final String? serviceFlowTitle;
  final bool showBottomBar;

  const ArticleListPage({
    super.key,
    this.serviceFlowAllowedTypes,
    this.serviceFlowTitle,
    this.showBottomBar = true,
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
  final ScrollController _rackScrollController = ScrollController();

  static const Color _rackTeal = Color(0xFF0F6876);
  static const Color _rackTealPrimary = Color(0xFF11999E);
  static const Color _rackDark = Color(0xFF062F35);
  static const Color _panelBg = Color(0xFFF0F0F0);
  static const String _plusIconSvg = '''
<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M12 5V19" stroke="black" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
<path d="M5 12H19" stroke="black" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
</svg>
''';

  static const List<Map<String, String>> _filterTabs = [
    {'value': 'formal', 'label': 'Formals'},
    {'value': 'sports_shoe', 'label': 'Nike'},
    {'value': 'casual', 'label': 'Casuals'},
    {'value': 'boot', 'label': 'Heels'},
    {'value': 'sandal', 'label': 'Converse'},
  ];

  @override
  void initState() {
    super.initState();
    _loadArticles();
  }

  @override
  void dispose() {
    _rackScrollController.dispose();
    super.dispose();
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
    final bottomSafe = MediaQuery.viewPaddingOf(context).bottom;
    final width = MediaQuery.sizeOf(context).width;
    final uiScale = (width / 390).clamp(0.84, 1.12).toDouble();
    final horizontalInset = (10.0 * uiScale).clamp(8.0, 16.0);
    final topInset = (58.0 * uiScale).clamp(34.0, 70.0);
    const panelRadius = BorderRadius.only(
      topLeft: Radius.circular(20),
      topRight: Radius.circular(20),
      bottomLeft: Radius.circular(50),
      bottomRight: Radius.circular(50),
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: Stack(
        children: [
          ...BgTheme.background(),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalInset,
                topInset,
                horizontalInset,
                0,
              ),
              child: DecoratedBox(
                decoration: const ShapeDecoration(
                  color: _panelBg,
                  shape: RoundedRectangleBorder(borderRadius: panelRadius),
                  shadows: [
                    BoxShadow(
                      color: Color(0x19000000),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: panelRadius,
                  child: _loading
                      ? _buildLoading()
                      : _error != null
                      ? _buildError()
                      : (_articles?.isEmpty ?? true)
                      ? _buildEmpty()
                      : _buildRackBody(),
                ),
              ),
            ),
          ),
          if (widget.showBottomBar)
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: DashboardLinkedBottomNav(selectedTabIndex: 1),
            ),
          if (!widget.showBottomBar) SizedBox(height: bottomSafe),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: _rackTealPrimary),
          const SizedBox(height: 16),
          Text(
            'Loading your rack...',
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 15,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _loadArticles,
              icon: const Icon(Icons.refresh, size: 20),
              label: const Text('Retry'),
              style: FilledButton.styleFrom(
                backgroundColor: _rackTealPrimary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.checkroom_outlined,
              size: 64,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 20),
            Text(
              'Your rack is empty',
              textAlign: TextAlign.center,
              style: GoogleFonts.boldonse(
                fontSize: 20,
                fontWeight: FontWeight.w400,
                color: _rackDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first pair',
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 14,
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: () => _navigateToCreate(context),
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Add shoe'),
              style: FilledButton.styleFrom(
                backgroundColor: _rackTealPrimary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRackBody() {
    final list = _filteredArticles;
    final rowCount = (list.length + 2) ~/ 3;
    final width = MediaQuery.sizeOf(context).width;
    final uiScale = (width / 390).clamp(0.84, 1.12).toDouble();
    final headerHInset = (12.0 * uiScale).clamp(10.0, 20.0);
    final titleLeftInset = (headerHInset - 4).clamp(6.0, 16.0);
    final topTitleGap = (10.0 * uiScale).clamp(8.0, 14.0);
    final titleSize = (20.0 * uiScale).clamp(18.0, 24.0);
    const plusSize = 48.0;
    const searchHeight = 42.0;
    final filtersHeight = (30.0 * uiScale).clamp(28.0, 36.0);
    final sectionGap = (10.0 * uiScale).clamp(8.0, 14.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            titleLeftInset,
            topTitleGap,
            headerHInset,
            0,
          ),
          child: Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 40,
                        minHeight: 40,
                      ),
                      onPressed: () => Navigator.maybePop(context),
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 20,
                        color: _rackDark,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      'My Rack',
                      style: GoogleFonts.boldonse(
                        color: _rackDark,
                        fontSize: titleSize,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _navigateToCreate(context),
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    width: plusSize,
                    height: plusSize,
                    decoration: ShapeDecoration(
                      color: const Color(0x33DFE7E9),
                      shape: RoundedRectangleBorder(
                        side: const BorderSide(
                          width: 1,
                          color: _rackTealPrimary,
                        ),
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
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: SvgPicture.string(
                        _plusIconSvg,
                        fit: BoxFit.contain,
                        colorFilter: const ColorFilter.mode(
                          _rackDark,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_isServiceFlowMode)
          Padding(
            padding: EdgeInsets.fromLTRB(
              headerHInset + 4,
              4,
              headerHInset + 4,
              2,
            ),
            child: Text(
              widget.serviceFlowTitle ?? 'Select an article to continue',
              style: GoogleFonts.montserrat(
                fontSize: (13.0 * uiScale).clamp(12.0, 15.0),
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        SizedBox(height: (12.0 * uiScale).clamp(8.0, 14.0)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: headerHInset),
          child: Container(
            height: searchHeight,
            padding: const EdgeInsets.only(top: 9, left: 33, right: 34, bottom: 9),
            decoration: ShapeDecoration(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                side: const BorderSide(width: 1, color: _rackDark),
                borderRadius: BorderRadius.circular(100),
              ),
            ),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              style: GoogleFonts.montserrat(
                fontSize: (16.0 * uiScale).clamp(13.0, 17.0),
                color: Colors.black87,
              ),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                hintText: 'Search',
                hintStyle: GoogleFonts.montserrat(
                  color: Colors.black.withValues(alpha: 0.34),
                  fontSize: (16.0 * uiScale).clamp(13.0, 17.0),
                  fontWeight: FontWeight.w400,
                ),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 24,
                  minHeight: 24,
                ),
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Center(
                    child: SvgPicture.asset(
                      'assets/images/search.svg',
                      width: 24,
                      height: 24,
                      colorFilter: ColorFilter.mode(
                        Colors.black.withValues(alpha: 0.34),
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
                suffixIconConstraints: const BoxConstraints(
                  minWidth: 24,
                  minHeight: 24,
                ),
                suffixIcon: Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 1,
                        height: 24,
                        color: Colors.black.withValues(alpha: 0.18),
                      ),
                      const SizedBox(width: 10),
                      SvgPicture.asset(
                        'assets/images/filter.svg',
                        width: 24,
                        height: 24,
                        colorFilter: ColorFilter.mode(
                          Colors.black.withValues(alpha: 0.34),
                          BlendMode.srcIn,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: sectionGap),
        SizedBox(
          height: filtersHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: headerHInset),
            itemCount: _filterTabs.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final tab = _filterTabs[i];
              final value = tab['value']!;
              final label = tab['label']!;
              return _FilterChipPill(
                label: label,
                selected: _filterCategory == value,
                onTap: () => setState(() => _filterCategory = value),
              );
            },
          ),
        ),
        SizedBox(height: (8.0 * uiScale).clamp(6.0, 10.0)),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadArticles,
            color: _rackTealPrimary,
            backgroundColor: Colors.white,
            child: list.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                        height: MediaQuery.sizeOf(context).height * 0.18,
                      ),
                      Center(
                        child: Text(
                          'No shoes match',
                          style: GoogleFonts.montserrat(
                            fontSize: 15,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ),
                    ],
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final spacing = (10.0 * uiScale).clamp(8.0, 14.0);
                      final barMargin = (8.0 * uiScale).clamp(6.0, 14.0);
                      return RawScrollbar(
                        controller: _rackScrollController,
                        thumbVisibility: true,
                        thickness: 7,
                        radius: const Radius.circular(3.5),
                        mainAxisMargin: barMargin,
                        crossAxisMargin: 2,
                        thumbColor: Colors.black.withValues(alpha: 0.50),
                        child: ListView.builder(
                          controller: _rackScrollController,
                          padding: EdgeInsets.fromLTRB(
                            headerHInset,
                            2,
                            headerHInset,
                            (24.0 * uiScale).clamp(20.0, 30.0),
                          ),
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics(),
                          ),
                          itemCount: rowCount,
                          itemBuilder: (context, rowIndex) {
                            return Padding(
                              padding: EdgeInsets.only(
                                bottom: rowIndex == rowCount - 1 ? 0 : spacing,
                              ),
                              child: _RackRow(
                                uiScale: uiScale,
                                children: List.generate(3, (colIndex) {
                                  final itemIndex = rowIndex * 3 + colIndex;
                                  if (itemIndex >= list.length) {
                                    return const SizedBox.shrink();
                                  }
                                  final article = list[itemIndex];
                                  return _RackGridItem(
                                    article: article,
                                    imageUrl: _imageUrl(article.thumbnailImage),
                                    onTap: () {
                                      if (_isServiceFlowMode) {
                                        _navigateToServiceSelection(
                                          context,
                                          article,
                                        );
                                      } else {
                                        _navigateToDetails(context, article);
                                      }
                                    },
                                  );
                                }),
                              ),
                            );
                          },
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
        .push(MaterialPageRoute(builder: (_) => const ArticleCreatePage()))
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
            Navigator.maybePop(context, true);
          }
        });
  }
}

class _RackGridItem extends StatelessWidget {
  final Article article;
  final String imageUrl;
  final VoidCallback onTap;

  const _RackGridItem({
    required this.article,
    required this.imageUrl,
    required this.onTap,
  });

  static String _displayLabel(Article article) {
    if (article.color.trim().isNotEmpty) return article.color.trim();
    if (article.brand.trim().isNotEmpty) return article.brand.trim();
    if (article.model.trim().isNotEmpty) return article.model.trim();
    return 'Shoe';
  }

  @override
  Widget build(BuildContext context) {
    final label = _displayLabel(article);
    final uiScale = (MediaQuery.sizeOf(context).width / 390)
        .clamp(0.84, 1.12)
        .toDouble();
    final nameSize = (12.5 * uiScale).clamp(11.0, 14.0);
    final labelGap = (6.0 * uiScale).clamp(4.0, 8.0);
    final panelPad = (6.0 * uiScale).clamp(4.0, 8.0);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            panelPad,
            panelPad,
            panelPad,
            panelPad - 1,
          ),
          child: Column(
            children: [
              Expanded(
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => _rackThumbPlaceholder(),
                      )
                    : _rackThumbPlaceholder(),
              ),
              SizedBox(height: labelGap),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: GoogleFonts.boldonse(
                  color: const Color(0xFF11899B),
                  fontSize: nameSize,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _rackThumbPlaceholder() {
    return Center(
      child: Icon(
        Icons.checkroom_outlined,
        color: AppColors.textTertiary.withValues(alpha: 0.5),
        size: 32,
      ),
    );
  }
}

class _RackRow extends StatelessWidget {
  final List<Widget> children;
  final double uiScale;

  const _RackRow({required this.children, required this.uiScale});

  @override
  Widget build(BuildContext context) {
    final borderRadius = (10.0 * uiScale).clamp(8.0, 12.0);
    final rowPad = (8.0 * uiScale).clamp(6.0, 10.0);
    final childGap = (4.0 * uiScale).clamp(2.0, 6.0);

    return AspectRatio(
      aspectRatio: 3.08,
      child: Container(
        padding: EdgeInsets.fromLTRB(rowPad, rowPad, rowPad, rowPad - 1),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F0F0),
          borderRadius: BorderRadius.circular(borderRadius),
          border: const Border(
            bottom: BorderSide(
              color: _ArticleListPageState._rackTealPrimary,
              width: 2.5,
            ),
          ),
        ),
        child: Row(
          children: List.generate(3, (index) {
            return Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: childGap),
                child: children[index],
              ),
            );
          }),
        ),
      ),
    );
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
  static const Color _chipBorder = Color(0xFFC6C6C6);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(100),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
          decoration: ShapeDecoration(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              side: BorderSide(
                width: selected ? 1.4 : 1,
                color: selected ? _teal : _chipBorder,
              ),
              borderRadius: BorderRadius.circular(100),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.montserrat(
              color: const Color(0xFF1A1A1A),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

/*
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gmp/core/constants/api_endpoints.dart';
import 'package:gmp/core/theme/app_colors.dart';
import 'package:gmp/core/utils/responsive.dart';
import 'package:gmp/core/widgets/floating_gradient_bottom_nav.dart';
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
    final labelStyle = GoogleFonts.boldonse(
      color: _labelColor,
      fontSize: Responsive.fontSize(context, 14),
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
  final bool showBottomBar;

  const ArticleListPage({
    super.key,
    this.serviceFlowAllowedTypes,
    this.serviceFlowTitle,
    this.showBottomBar = true,
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
                    padding: const EdgeInsets.fromLTRB(10, 75, 10, 0),
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
                SizedBox(
                  height: widget.showBottomBar
                      ? (FloatingGradientBottomNav.barHeight + 12 + bottomSafe)
                      : bottomSafe,
                ),
              ],
            ),
          ),
          if (widget.showBottomBar)
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: DashboardLinkedBottomNav(selectedTabIndex: 1),
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
            style: GoogleFonts.montserrat(
              fontSize: Responsive.fontSize(context, 14),
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
              style: GoogleFonts.montserrat(
                fontSize: Responsive.fontSize(context, 15),
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
              style: GoogleFonts.boldonse(
                fontSize: Responsive.fontSize(context, 20),
                fontWeight: FontWeight.w400,
                color: _rackDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first pair',
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: Responsive.fontSize(context, 14),
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
    {'value': 'formal', 'label': 'Formals'},
    {'value': 'sports_shoe', 'label': 'Nike'},
    {'value': 'casual', 'label': 'Casuals'},
    {'value': 'boot', 'label': 'Heels'},
    {'value': 'sandal', 'label': 'Converse'},
  ];

  Widget _buildRackBody(BuildContext context) {
    final list = _filteredArticles;
    final hPad = Responsive.horizontalPaddingOf(context).clamp(12.0, 20.0);
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
                        style: GoogleFonts.boldonse(
                          color: _rackDark,
                          fontSize: Responsive.fontSize(context, 22),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    Text(
                      '$selectedCount Selected',
                      style: GoogleFonts.montserrat(
                        color: const Color(0xFF5C5C5C),
                        fontSize: Responsive.fontSize(context, 14),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: Text(
                        'My Rack',
                        style: GoogleFonts.boldonse(
                          color: _rackDark,
                          fontSize: Responsive.fontSize(context, 24),
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
                          decoration: ShapeDecoration(
                            color: const Color(0x33DFE7E9),
                            shape: RoundedRectangleBorder(
                              side: const BorderSide(width: 1, color: _rackTealPrimary),
                              borderRadius: BorderRadius.circular(22),
                            ),
                            shadows: const [
                              BoxShadow(
                                color: Color(0x2E000000),
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
        if (!_selectionMode) ...[
          if (_isServiceFlowMode) ...[
            Padding(
              padding: EdgeInsets.fromLTRB(hPad, 6, hPad, 2),
              child: Text(
                widget.serviceFlowTitle ?? 'Select an article to continue',
                style: GoogleFonts.montserrat(
                  fontSize: Responsive.fontSize(context, 13),
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
                    gradient: const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [Color(0xFF063239), Color(0xFF0CADC5)],
                    ),
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
                        style: GoogleFonts.boldonse(
                          color: Colors.white,
                          fontSize: Responsive.fontSize(context, 16),
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
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: ShapeDecoration(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  side: const BorderSide(width: 1, color: _rackDark),
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                style: GoogleFonts.montserrat(
                  fontSize: Responsive.fontSize(context, 16),
                  color: Colors.black87,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  hintText: 'Search',
                  hintStyle: GoogleFonts.montserrat(
                    color: Colors.black.withValues(alpha: 0.35),
                    fontSize: Responsive.fontSize(context, 16),
                    fontWeight: FontWeight.w400,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: Colors.black.withValues(alpha: 0.35),
                    size: 22,
                  ),
                  suffixIcon: Icon(
                    Icons.tune_rounded,
                    color: Colors.black.withValues(alpha: 0.35),
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
                          style: GoogleFonts.montserrat(
                            fontSize: Responsive.fontSize(context, 15),
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
                        Container(
                          height: 104,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                          decoration: const ShapeDecoration(
                            color: _panelBg,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.all(Radius.circular(10)),
                            ),
                          ),
                          child: DecoratedBox(
                            decoration: const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: _rackTealPrimary, width: 3),
                              ),
                            ),
                            // Fixed height avoids AspectRatio + tight Row width fighting maxHeight (~84px),
                            // which triggers a layout assertion on web and mobile.
                            child: SizedBox(
                              height: 74,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: List.generate(3, (c) {
                                  final idx = r * 3 + c;
                                  if (idx >= list.length) {
                                    return const Expanded(child: SizedBox.shrink());
                                  }
                                  final article = list[idx];
                                  final imageUrl = _imageUrl(article.thumbnailImage);
                                  return Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 2),
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
                            ),
                          ),
                        ),
                        if (r < rowCount - 1) const SizedBox(height: 12),
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
        Navigator.maybePop(context, true);
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
  static const Color _chipBorder = Color(0xFFC6C6C6);

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
              side: BorderSide(width: selected ? 1.4 : 1, color: selected ? _teal : _chipBorder),
              borderRadius: BorderRadius.circular(100),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.montserrat(
              color: const Color(0xFF1A1A1A),
              fontSize: Responsive.fontSize(context, 16),
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}
*/
