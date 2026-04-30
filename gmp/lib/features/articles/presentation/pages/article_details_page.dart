import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
                        child: _buildFixedResponsiveContent(
                          context,
                          article: a,
                          imageUrl: imageUrl,
                          swatchColor: swatchColor,
                          boldonse: boldonse,
                          montserrat: montserrat,
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

  Widget _buildFixedResponsiveContent(
    BuildContext context, {
    required Article article,
    required String imageUrl,
    required Color swatchColor,
    required TextStyle Function(double) boldonse,
    required TextStyle Function(double, {Color? color}) montserrat,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const designWidth = 390.0;
        const designHeight = 740.0;
        final widthRatio = constraints.maxWidth / designWidth;
        final heightRatio = constraints.maxHeight / designHeight;
        final scale = math.min(widthRatio, heightRatio).clamp(0.58, 1.0);

        final contentWidth = designWidth * scale;
        final padX = 24.0 * scale;
        final padTop = 10.0 * scale;
        final padBottom = 18.0 * scale;
        final headerGap = 8.0 * scale;
        final titleGap = 4.0 * scale;
        final imageGap = 14.0 * scale;
        final sectionGap = 18.0 * scale;
        final buttonGap = 14.0 * scale;

        final imageWidth = (220.0 * scale).clamp(124.0, 240.0);
        final imageHeight = imageWidth * 0.62;
        final swatchSize = (34.0 * scale).clamp(22.0, 34.0);

        return Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: contentWidth,
            height: constraints.maxHeight,
            child: Padding(
              padding: EdgeInsets.fromLTRB(padX, padTop, padX, padBottom),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(
                          minWidth: 34 * scale,
                          minHeight: 34 * scale,
                        ),
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: (22 * scale).clamp(16.0, 22.0),
                          color: _rackDark,
                        ),
                      ),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(
                          minWidth: 34 * scale,
                          minHeight: 34 * scale,
                        ),
                        onPressed: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ArticleEditPage(articleId: article.id),
                            ),
                          );
                          if (mounted) _load();
                        },
                        icon: SvgPicture.asset(
                          'assets/images/icons/profile/edit.svg',
                          width: (20 * scale).clamp(14.0, 20.0),
                          height: (20 * scale).clamp(14.0, 20.0),
                          colorFilter: const ColorFilter.mode(_rackTealAccent, BlendMode.srcIn),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: headerGap),
                  Text(
                    article.brand.isNotEmpty ? article.brand : 'Shoe',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.boldonse(
                      color: _rackTealAccent,
                      fontSize: (24 * scale).clamp(14.0, 24.0),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  SizedBox(height: titleGap),
                  Text(
                    article.model.isNotEmpty ? article.model : '—',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.montserrat(
                      color: Colors.black,
                      fontSize: (20 * scale).clamp(12.0, 20.0),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  SizedBox(height: imageGap),
                  Expanded(
                    child: Center(
                      child: Transform.rotate(
                        angle: -0.48,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            width: imageWidth,
                            height: imageHeight,
                            child: imageUrl.isNotEmpty
                                ? Image.network(
                                    imageUrl,
                                    fit: BoxFit.contain,
                                    alignment: Alignment.center,
                                    errorBuilder: (context, error, stackTrace) => _placeholder(),
                                  )
                                : _placeholder(),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: sectionGap),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.only(bottom: 12 * scale),
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
                            valueStyle: boldonse(16 * scale),
                            labelStyle: montserrat(16 * scale),
                          ),
                        ),
                        Expanded(
                          child: _statColorColumn(
                            context,
                            swatchColor: swatchColor,
                            colorName: article.color.isNotEmpty ? article.color : '—',
                            labelStyle: montserrat(16 * scale),
                            swatchSize: swatchSize,
                          ),
                        ),
                        Expanded(
                          child: _statPair(
                            context,
                            value: article.purchaseYear?.toString() ?? '—',
                            label: 'Purchased',
                            valueStyle: boldonse(16 * scale),
                            labelStyle: montserrat(16 * scale),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: sectionGap),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: _statPair(
                          context,
                          value: _categoryLabel(article.category),
                          label: 'Category',
                          valueStyle: boldonse(16 * scale),
                          labelStyle: montserrat(16 * scale),
                        ),
                      ),
                      Expanded(
                        child: _statPair(
                          context,
                          value: '—',
                          label: 'Last Wear',
                          valueStyle: boldonse(16 * scale),
                          labelStyle: montserrat(16 * scale),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: sectionGap),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(horizontal: 14 * scale, vertical: 10 * scale),
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
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: montserrat(15 * scale),
                          ),
                        ),
                        SizedBox(width: 10 * scale),
                        Text(
                          '—',
                          textAlign: TextAlign.right,
                          style: boldonse(15 * scale),
                        ),
                        SizedBox(width: 6 * scale),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: (22 * scale).clamp(14.0, 22.0),
                          color: _rackTeal,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: sectionGap),
                  Row(
                    children: [
                      Expanded(
                        child: _gradientPillButton(
                          label: 'Rehome',
                          height: 59 * scale,
                          onTap: () {
                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(const SnackBar(content: Text('Rehome coming soon')));
                          },
                        ),
                      ),
                      SizedBox(width: buttonGap),
                      Expanded(
                        child: _outlinedPillButton(
                          label: 'Rent',
                          height: 59 * scale,
                          onTap: () {
                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(const SnackBar(content: Text('Rent coming soon')));
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12 * scale),
                  Text(
                    'Condition: ${_conditionLabel(article.condition)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: montserrat(14 * scale, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
    double swatchSize = 34,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: swatchSize,
          height: swatchSize,
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

  Widget _gradientPillButton({
    required String label,
    required VoidCallback onTap,
    double height = 59,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          height: height,
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

  Widget _outlinedPillButton({
    required String label,
    required VoidCallback onTap,
    double height = 59,
  }) {
    return Material(
      color: const Color(0xFFDFE7E9),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: height,
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