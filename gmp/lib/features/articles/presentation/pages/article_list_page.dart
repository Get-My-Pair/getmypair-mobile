import 'package:flutter/material.dart';
import 'package:gmp/core/constants/api_endpoints.dart';
import 'package:gmp/core/theme/app_colors.dart';
import 'package:gmp/core/utils/responsive.dart';
import 'package:gmp/features/articles/domain/entities/article.dart';
import 'package:gmp/features/articles/domain/usecases/get_my_articles.dart';
import 'package:gmp/features/auth/domain/usecases/get_valid_access_token.dart';
import 'package:gmp/injection_container.dart';

import 'article_create_page.dart';
import 'article_details_page.dart';

/// Module 3 – Article list. Digital Shoes Rack UI with shelf layout and filter tabs.
/// Tap a shoe → Shoe details (edit/delete).
class ArticleListPage extends StatefulWidget {
  const ArticleListPage({super.key});

  @override
  State<ArticleListPage> createState() => _ArticleListPageState();
}

class _ArticleListPageState extends State<ArticleListPage> {
  List<Article>? _articles;
  String? _error;
  bool _loading = true;
  /// null = All, else category value (sports_shoe, casual, formal)
  String? _filterCategory;

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

  /// Build full URL for image. Handles both full URLs and relative paths.
  static String _imageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    final base = ApiEndpoints.baseUrl;
    if (path.startsWith('/')) return '$base$path';
    return '$base/uploads/$path';
  }

  List<Article> get _filteredArticles {
    final list = _articles ?? [];
    if (_filterCategory == null || _filterCategory!.isEmpty) return list;
    return list.where((a) => a.category == _filterCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Digital Shoes Rack',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: AppColors.textPrimary),
            onPressed: () {
              // Search / edit placeholder
            },
          ),
        ],
      ),
      body: _loading
          ? _buildLoading()
          : _error != null
              ? _buildError(context)
              : _articles!.isEmpty
                  ? _buildEmpty(context)
                  : _buildRackList(context),
      floatingActionButton: _loading
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _navigateToCreate(context),
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textOnPrimary,
              icon: const Icon(Icons.add, size: 22),
              label: const Text('Add Shoe', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppColors.primary),
          const SizedBox(height: 16),
          Text(
            'Loading your Digital Shoes Rack...',
            style: TextStyle(fontSize: 14, color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: Responsive.horizontalPaddingOf(context)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline, size: 48, color: AppColors.error),
            ),
            const SizedBox(height: 20),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadArticles,
              icon: const Icon(Icons.refresh, size: 20),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textOnPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: Responsive.horizontalPaddingOf(context)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.checkroom_outlined,
                size: 64,
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Your Digital Shoes Rack is empty',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first pair to your Digital Shoes Rack',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textTertiary),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: () => _navigateToCreate(context),
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Add Shoe'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textOnPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const List<Map<String, String>> _filterTabs = [
    {'value': '', 'label': 'All'},
    {'value': 'sports_shoe', 'label': 'Sports'},
    {'value': 'casual', 'label': 'Casual'},
    {'value': 'formal', 'label': 'Formal'},
  ];

  Widget _buildRackList(BuildContext context) {
    final list = _filteredArticles;
    return RefreshIndicator(
      onRefresh: _loadArticles,
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _RackHeader(
              pairCount: _articles!.length,
              filterCategory: _filterCategory,
              filterTabs: _filterTabs,
              onFilterChanged: (v) => setState(() => _filterCategory = v.isEmpty ? null : v),
            ),
          ),
          if (list.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: Text(
                  'No shoes in this category',
                  style: TextStyle(color: AppColors.textTertiary, fontSize: 15),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final article = list[index];
                  final imageUrl = _imageUrl(article.thumbnailImage);
                  return _RackShelfItem(
                    article: article,
                    imageUrl: imageUrl,
                    onTap: () => _navigateToDetails(context, article),
                  );
                },
                childCount: list.length,
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  void _navigateToDetails(BuildContext context, Article article) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ArticleDetailsPage(articleId: article.id),
      ),
    ).then((_) => _loadArticles());
  }

  void _navigateToCreate(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const ArticleCreatePage(),
      ),
    ).then((_) => _loadArticles());
  }
}

/// Rack header: title, pair count, filter tabs (All, Sports, Casual, Formal).
class _RackHeader extends StatelessWidget {
  final int pairCount;
  final String? filterCategory;
  final List<Map<String, String>> filterTabs;
  final ValueChanged<String> onFilterChanged;

  const _RackHeader({
    required this.pairCount,
    required this.filterCategory,
    required this.filterTabs,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'MY SHOES',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 10),
              Icon(Icons.checkroom_outlined, size: 20, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                '$pairCount ${pairCount == 1 ? 'Pair' : 'Pairs'}',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: filterTabs.map((tab) {
                final value = tab['value']!;
                final label = tab['label']!;
                final isSelected = (filterCategory == null && value.isEmpty) ||
                    (filterCategory != null && filterCategory == value);
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => onFilterChanged(value),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? AppColors.onPrimary
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Single shelf row: shoe image (illuminated) + dark info panel (brand/model, condition, QR placeholder).
class _RackShelfItem extends StatelessWidget {
  final Article article;
  final String imageUrl;
  final VoidCallback onTap;

  const _RackShelfItem({
    required this.article,
    required this.imageUrl,
    required this.onTap,
  });

  static String _categoryLabel(String category) {
    const map = {
      'sports_shoe': 'Sports',
      'casual': 'Casual',
      'formal': 'Formal',
      'sandal': 'Sandal',
      'boot': 'Boot',
      'other': 'Other',
    };
    return map[category] ?? category;
  }

  static String _conditionLabel(String condition) {
    if (condition.isEmpty) return '—';
    final c = condition.toLowerCase();
    if (c == 'excellent') return 'Excellent';
    if (c == 'good') return 'Good';
    if (c == 'fair') return 'Fair';
    if (c == 'poor') return 'Poor';
    return condition[0].toUpperCase() + condition.substring(1).toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Illuminated shelf area – shoe image
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(11)),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.12),
                        blurRadius: 12,
                        spreadRadius: -2,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(11)),
                    child: imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _placeholder(),
                          )
                        : _placeholder(),
                  ),
                ),
                // Info panel (brand/model, details, QR)
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: const BorderRadius.horizontal(right: Radius.circular(11)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${article.brand} ${article.model}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_categoryLabel(article.category)} · ${_conditionLabel(article.condition)}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (article.color.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  article.color,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: AppColors.textTertiary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                        // QR placeholder
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Icon(
                            Icons.qr_code_2_rounded,
                            size: 28,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: AppColors.surfaceVariant,
      child: const Center(
        child: Icon(
          Icons.checkroom_outlined,
          color: AppColors.textTertiary,
          size: 40,
        ),
      ),
    );
  }
}
