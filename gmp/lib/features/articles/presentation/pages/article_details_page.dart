import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gmp/core/bgtheme.dart';
import 'package:gmp/core/constants/api_endpoints.dart';
import 'package:gmp/core/theme/app_colors.dart';
import 'package:gmp/core/utils/responsive.dart';
import 'package:gmp/core/widgets/floating_gradient_bottom_nav.dart';
import 'package:gmp/features/articles/domain/entities/article.dart';
import 'package:gmp/features/articles/domain/usecases/delete_article.dart';
import 'package:gmp/features/articles/domain/usecases/get_article_by_id.dart';
import 'package:gmp/features/auth/domain/usecases/get_valid_access_token.dart';
import 'package:gmp/injection_container.dart';

import 'article_edit_page.dart';

/// Module 3 – Article details. Figma rack-detail layout: gradient shell, panel, stats, actions.
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

  static const Color _rackTeal = Color(0xFF0F6876);
  static const Color _rackTealAccent = Color(0xFF11899B);
  static const Color _rackDark = Color(0xFF062F35);
  static const Color _panelBg = Color(0xFFF0F0F0);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final tokenResult = await sl<GetValidAccessToken>().call();
    if (!mounted) return;
    tokenResult.fold(
      (_) => setState(() {
        _error = 'Please sign in again';
        _loading = false;
      }),
      (token) async {
        try {
          final article = await sl<GetArticleById>().call(token, widget.articleId);
          if (!mounted) return;
          setState(() {
            _article = article;
            _loading = false;
            _error = null;
          });
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
    return map[c] ?? (c.isEmpty ? '—' : c);
  }

  static Color? _parseColorHex(String s) {
    final hex = RegExp(r'#?([0-9A-Fa-f]{6})').firstMatch(s.trim())?.group(1);
    if (hex == null) return null;
    return Color(int.parse(hex, radix: 16) + 0xFF000000);
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
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.textOnPrimary,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true || _article == null || !mounted) return;
    final tokenResult = await sl<GetValidAccessToken>().call();
    if (!mounted) return;
    tokenResult.fold(
      (_) => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in again'), backgroundColor: AppColors.error),
      ),
      (token) async {
        try {
          await sl<DeleteArticle>().call(token, _article!.id);
          if (!mounted) return;
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Shoe removed'), backgroundColor: AppColors.success),
          );
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceFirst('Exception: ', '')),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomSafe = Responsive.bottomInsetOf(context);
    final bottomNavReserve = FloatingGradientBottomNav.barHeight + 12 + bottomSafe;

    if (_loading) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true,
        body: Stack(
          children: [
            ...BgTheme.background(),
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
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.only(
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
                        child: const Center(
                          child: CircularProgressIndicator(color: _rackTealAccent),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: bottomNavReserve),
                ],
              ),
            ),
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

    if (_error != null || _article == null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true,
        body: Stack(
          children: [
            ...BgTheme.background(),
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
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.only(
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
                        child: Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: Responsive.horizontalPaddingOf(context)),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.error_outline, size: 48, color: AppColors.error),
                                const SizedBox(height: 16),
                                Text(
                                  _error ?? 'Shoe not found',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.montserrat(
                                    fontSize: Responsive.fontSize(context, 15),
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Go back'),
                                    ),
                                    const SizedBox(width: 12),
                                    FilledButton(
                                      onPressed: _load,
                                      style: FilledButton.styleFrom(
                                        backgroundColor: _rackTeal,
                                        foregroundColor: Colors.white,
                                      ),
                                      child: const Text('Retry'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: bottomNavReserve),
                ],
              ),
            ),
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

    final a = _article!;
    final imageUrl = _imageUrl(a.thumbnailImage);
    final hPad = Responsive.horizontalPaddingOf(context);
    final swatchColor = _parseColorHex(a.color) ?? const Color(0xFF11253F);

    TextStyle boldonse(double base) => GoogleFonts.boldonse(
          fontWeight: FontWeight.w400,
          fontSize: Responsive.fontSize(context, base),
          color: Colors.black,
        );

    TextStyle montserrat(double base, {Color? color}) => GoogleFonts.montserrat(
          fontWeight: FontWeight.w400,
          fontSize: Responsive.fontSize(context, base),
          color: color ?? Colors.black,
        );

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          ...BgTheme.background(),
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
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
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
                        child: SingleChildScrollView(
                          padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                                    onPressed: () => Navigator.pop(context),
                                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 22, color: _rackDark),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                                        onPressed: () {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Share coming soon')),
                                          );
                                        },
                                        icon: const Icon(Icons.ios_share_rounded, size: 24, color: _rackDark),
                                      ),
                                      PopupMenuButton<String>(
                                        icon: const Icon(Icons.more_horiz_rounded, size: 26, color: _rackDark),
                                        onSelected: (v) async {
                                          if (v == 'edit') {
                                            await Navigator.of(context).push(
                                              MaterialPageRoute(builder: (_) => ArticleEditPage(articleId: a.id)),
                                            );
                                            if (mounted) _load();
                                          } else if (v == 'delete') {
                                            await _deleteArticle();
                                          }
                                        },
                                        itemBuilder: (ctx) => [
                                          const PopupMenuItem(value: 'edit', child: Text('Edit')),
                                          const PopupMenuItem(value: 'delete', child: Text('Delete')),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                a.brand.isNotEmpty ? a.brand : 'Shoe',
                                style: GoogleFonts.boldonse(
                                  color: _rackTealAccent,
                                  fontSize: Responsive.fontSize(context, 24),
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                a.model.isNotEmpty ? a.model : '—',
                                style: GoogleFonts.montserrat(
                                  color: Colors.black,
                                  fontSize: Responsive.fontSize(context, 20),
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Center(
                                child: Transform.rotate(
                                  angle: -0.48,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: SizedBox(
                                      width: Responsive.scaleDesignWidth(context, 165).clamp(210.0, 310.0),
                                      height: Responsive.scaleDesignWidth(context, 135).clamp(100.0, 165.0),
                                      child: imageUrl.isNotEmpty
                                          ? Image.network(
                                              imageUrl,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) => _placeholder(),
                                            )
                                          : _placeholder(),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: Responsive.scaleDesignWidth(context, 30)),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.only(bottom: 14),
                                decoration: ShapeDecoration(
                                  shape: RoundedRectangleBorder(
                                    side: BorderSide(
                                      width: 1,
                                      color: Colors.black.withValues(alpha: 0.2),
                                    ),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: _statPair(
                                        context,
                                        value: '—',
                                        label: 'Size',
                                        valueStyle: boldonse(16),
                                        labelStyle: montserrat(16),
                                      ),
                                    ),
                                    Expanded(
                                      child: _statColorColumn(
                                        context,
                                        swatchColor: swatchColor,
                                        colorName: a.color.isNotEmpty ? a.color : '—',
                                        labelStyle: montserrat(16),
                                      ),
                                    ),
                                    Expanded(
                                      child: _statPair(
                                        context,
                                        value: a.purchaseYear?.toString() ?? '—',
                                        label: 'Purchased',
                                        valueStyle: boldonse(16),
                                        labelStyle: montserrat(16),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: _statPair(
                                      context,
                                      value: _categoryLabel(a.category),
                                      label: 'Category',
                                      valueStyle: boldonse(16),
                                      labelStyle: montserrat(16),
                                    ),
                                  ),
                                  Expanded(
                                    child: _statPair(
                                      context,
                                      value: '—',
                                      label: 'Last wear',
                                      valueStyle: boldonse(16),
                                      labelStyle: montserrat(16),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFF09DFFF)),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x19000000),
                                      blurRadius: 4,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Last sent to shoe care',
                                        style: montserrat(16),
                                      ),
                                    ),
                                    Text(
                                      '—',
                                      textAlign: TextAlign.right,
                                      style: boldonse(16),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                              Row(
                                children: [
                                  Expanded(
                                    child: _gradientPillButton(
                                      label: 'Rehome',
                                      onTap: () {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Rehome coming soon')),
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _outlinedPillButton(
                                      label: 'Rent',
                                      onTap: () {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Rent coming soon')),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Condition: ${_conditionLabel(a.condition)}',
                                style: montserrat(14, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: bottomNavReserve),
              ],
            ),
          ),
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

  Widget _statPair(
    BuildContext context, {
    required String value,
    required String label,
    required TextStyle valueStyle,
    required TextStyle labelStyle,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(value, textAlign: TextAlign.center, style: valueStyle, maxLines: 2, overflow: TextOverflow.ellipsis),
        Text(label, textAlign: TextAlign.center, style: labelStyle),
      ],
    );
  }

  Widget _statColorColumn(
    BuildContext context, {
    required Color swatchColor,
    required String colorName,
    required TextStyle labelStyle,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: ShapeDecoration(
            color: swatchColor,
            shape: const OvalBorder(),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          colorName,
          textAlign: TextAlign.center,
          style: labelStyle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _gradientPillButton({required String label, required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          height: 59,
          decoration: ShapeDecoration(
            gradient: const LinearGradient(
              begin: Alignment(1, 0.5),
              end: Alignment(0, 0.5),
              colors: [Color(0xFF0CADC5), Color(0xFF063239)],
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            shadows: const [
              BoxShadow(
                color: Color(0x19000000),
                blurRadius: 4,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.boldonse(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _outlinedPillButton({required String label, required VoidCallback onTap}) {
    return Material(
      color: const Color(0xFFDFE7E9),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 59,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF0F6876)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x19000000),
                blurRadius: 4,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            label,
            style: GoogleFonts.boldonse(
              color: const Color(0xFF062F35),
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }

  Widget _placeholder() {
    return ColoredBox(
      color: AppColors.surfaceVariant,
      child: const Center(
        child: Icon(Icons.checkroom_outlined, color: AppColors.textTertiary, size: 56),
      ),
    );
  }
}