import 'package:flutter/material.dart';
import 'package:gmp/core/constants/api_endpoints.dart';
import 'package:gmp/core/theme/app_colors.dart';
import 'package:gmp/core/utils/responsive.dart';
import 'package:gmp/features/articles/domain/entities/article.dart';
import 'package:gmp/features/articles/domain/usecases/delete_article.dart';
import 'package:gmp/features/articles/domain/usecases/get_article_by_id.dart';
import 'package:gmp/features/auth/domain/usecases/get_valid_access_token.dart';
import 'package:gmp/injection_container.dart';

import 'article_edit_page.dart';

/// Module 3 – Article details. Displays shoe info, materials, repair history placeholder,
/// service requests placeholder. Buttons: Edit, Delete, Request Service.
class ArticleDetailsPage extends StatefulWidget {
  final String articleId;

  const ArticleDetailsPage({super.key, required this.articleId});

  @override
  State<ArticleDetailsPage> createState() => _ArticleDetailsPageState();
}

class _ArticleDetailsPageState extends State<ArticleDetailsPage> {
  Article? _article;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final tokenResult = await sl<GetValidAccessToken>().call();
    if (!mounted) return;
    tokenResult.fold(
      (_) => setState(() { _error = 'Please sign in again'; _loading = false; }),
      (token) async {
        try {
          final article = await sl<GetArticleById>().call(token, widget.articleId);
          if (!mounted) return;
          setState(() { _article = article; _loading = false; _error = null; });
        } catch (e) {
          if (!mounted) return;
          setState(() {
            _error = e.toString().replaceFirst('Exception: ', '');
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

  static String _conditionLabel(String c) {
    if (c.isEmpty) return '—';
    return c[0].toUpperCase() + c.substring(1).toLowerCase();
  }

  static String _categoryLabel(String c) {
    const map = {
      'sports_shoe': 'Sports shoe',
      'casual': 'Casual',
      'formal': 'Formal',
      'sandal': 'Sandal',
      'boot': 'Boot',
      'slipper': 'Slipper',
      'other': 'Other',
    };
    return map[c] ?? c;
  }

  Future<void> _deleteArticle() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete shoe'),
        content: const Text(
          'Are you sure you want to remove this shoe from your passport? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true || _article == null || !mounted) return;
    final tokenResult = await sl<GetValidAccessToken>().call();
    if (!mounted) return;
    tokenResult.fold(
      (_) => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please sign in again'), backgroundColor: AppColors.error)),
      (token) async {
        try {
          await sl<DeleteArticle>().call(token, _article!.id);
          if (!mounted) return;
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Shoe removed'), backgroundColor: AppColors.success));
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: AppColors.error),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Shoe Details',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
          centerTitle: true,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: AppColors.primary),
              const SizedBox(height: 16),
              Text(
                'Loading...',
                style: TextStyle(fontSize: 14, color: AppColors.textTertiary),
              ),
            ],
          ),
        ),
      );
    }
    if (_error != null || _article == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Shoe Details',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
          centerTitle: true,
        ),
        body: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: Responsive.horizontalPaddingOf(context)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.error_outline, size: 48, color: AppColors.error),
                ),
                const SizedBox(height: 20),
                Text(
                  _error ?? 'Shoe not found',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _load,
                  icon: const Icon(Icons.refresh, size: 20),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final a = _article!;
    final horizontal = Responsive.horizontalPaddingOf(context);
    final imageUrl = _imageUrl(a.thumbnailImage);

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
          'Shoe Details',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(horizontal, 8, horizontal, 24),
        children: [
          // Hero image card
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      height: 260,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder(260),
                    )
                  : _placeholder(260),
            ),
          ),
          const SizedBox(height: 20),
          // Title: Brand & Model
          Text(
            '${a.brand} ${a.model}',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 16),
          // Details card
          _sectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _detailRow('Category', _categoryLabel(a.category)),
                _divider(),
                _detailRow('Color', a.color.isNotEmpty ? a.color : '—'),
                if (a.purchaseYear != null) ...[
                  _divider(),
                  _detailRow('Purchase year', a.purchaseYear.toString()),
                ],
                _divider(),
                _detailRow('Condition', _conditionLabel(a.condition)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Materials card
          _sectionCard(
            title: 'Materials',
            child: a.materials.isEmpty
                ? Text(
                    'No materials added',
                    style: TextStyle(fontSize: 14, color: AppColors.textTertiary),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: a.materials
                        .map(
                          (m) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    '${m.type} ${m.percentage}%',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
          ),
          const SizedBox(height: 16),
          // Repair history card
          _sectionCard(
            title: 'Repair history',
            child: Row(
              children: [
                Icon(Icons.history, size: 20, color: AppColors.textTertiary),
                const SizedBox(width: 10),
                Text(
                  'No repairs yet',
                  style: TextStyle(fontSize: 14, color: AppColors.textTertiary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Service requests card
          _sectionCard(
            title: 'Service requests',
            child: Row(
              children: [
                Icon(Icons.build_outlined, size: 20, color: AppColors.textTertiary),
                const SizedBox(width: 10),
                Text(
                  'No service requests yet',
                  style: TextStyle(fontSize: 14, color: AppColors.textTertiary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ArticleEditPage(articleId: a.id),
                    ),
                  ).then((_) => _load()),
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  label: const Text('Edit'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _deleteArticle,
                  icon: const Icon(Icons.delete_outline, size: 20),
                  label: const Text('Delete'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Request Service coming in Module 4'),
                    backgroundColor: AppColors.info,
                  ),
                );
              },
              icon: const Icon(Icons.build_outlined, size: 20),
              label: const Text('Request Service'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _sectionCard({String? title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
          ],
          child,
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, color: AppColors.textTertiary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Divider(height: 1, color: AppColors.divider);
  }

  Widget _placeholder(double height) {
    return Container(
      height: height,
      width: double.infinity,
      color: AppColors.surfaceVariant,
      child: const Icon(Icons.checkroom_outlined, color: AppColors.textTertiary, size: 56),
    );
  }
}
