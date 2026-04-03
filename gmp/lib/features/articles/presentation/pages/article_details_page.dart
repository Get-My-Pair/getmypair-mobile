import 'package:flutter/material.dart';
import 'package:gmp/core/constants/api_endpoints.dart';
import 'package:gmp/core/theme/app_colors.dart';
import 'package:gmp/core/utils/responsive.dart';
import 'package:gmp/features/articles/domain/entities/article.dart';
import 'package:gmp/features/articles/domain/usecases/delete_article.dart';
import 'package:gmp/features/articles/domain/usecases/get_article_by_id.dart';
import 'package:gmp/features/auth/domain/usecases/get_valid_access_token.dart';
import 'package:gmp/injection_container.dart';

import 'article_create_page.dart';
import 'article_edit_page.dart';
import '../../../service/presentation/pages/service_request_list_page.dart';
import '../../../service/presentation/pages/service_selection_page.dart';

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

  Future<void> _openRequestService() async {
    final a = _article;
    if (a == null) return;
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => ServiceSelectionPage(articleId: a.id)),
    );
    if (!mounted) return;
    if (created == true) {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ServiceRequestListPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomSafe = Responsive.bottomInsetOf(context);

    if (_loading) {
      return Scaffold(
        backgroundColor: const Color(0xFFFAFAFA),
        extendBody: true,
        body: Stack(
          children: [
            const Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: _shellSweep))),
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
                  SizedBox(height: 72 + bottomSafe),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (_error != null || _article == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFFAFAFA),
        extendBody: true,
        body: Stack(
          children: [
            const Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: _shellSweep))),
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
                                  style: TextStyle(
                                    fontSize: Responsive.fontSize(context, 15),
                                    fontFamily: 'Montserrat',
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
                  SizedBox(height: 72 + bottomSafe),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final a = _article!;
    final imageUrl = _imageUrl(a.thumbnailImage);
    final hPad = Responsive.horizontalPaddingOf(context);
    final swatchColor = _parseColorHex(a.color) ?? const Color(0xFF11253F);

    TextStyle boldonse(double base) => TextStyle(
          fontFamily: 'Boldonse',
          fontWeight: FontWeight.w400,
          fontSize: Responsive.fontSize(context, base),
          color: Colors.black,
        );

    TextStyle montserrat(double base, {Color? color}) => TextStyle(
          fontFamily: 'Montserrat',
          fontWeight: FontWeight.w400,
          fontSize: Responsive.fontSize(context, base),
          color: color ?? Colors.black,
        );

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      extendBody: true,
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          const Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: _shellSweep))),
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
                                          } else if (v == 'service') {
                                            await _openRequestService();
                                          } else if (v == 'delete') {
                                            await _deleteArticle();
                                          }
                                        },
                                        itemBuilder: (ctx) => [
                                          const PopupMenuItem(value: 'edit', child: Text('Edit')),
                                          const PopupMenuItem(value: 'service', child: Text('Request service')),
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
                                style: TextStyle(
                                  color: _rackTealAccent,
                                  fontSize: Responsive.fontSize(context, 24),
                                  fontFamily: 'Boldonse',
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                a.model.isNotEmpty ? a.model : '—',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: Responsive.fontSize(context, 20),
                                  fontFamily: 'Montserrat',
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
                              Material(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                clipBehavior: Clip.antiAlias,
                                child: InkWell(
                                  onTap: _openRequestService,
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                    decoration: BoxDecoration(
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
                                        const SizedBox(width: 8),
                                        Transform.rotate(
                                          angle: -3.14159,
                                          child: const Icon(Icons.keyboard_arrow_down_rounded, size: 24),
                                        ),
                                      ],
                                    ),
                                  ),
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
                child: _ArticleDetailBottomBar(
                  onCenterTap: () {
                    Navigator.of(context)
                        .push<void>(
                      MaterialPageRoute<void>(
                        builder: (_) => const ArticleCreatePage(),
                      ),
                    )
                        .then((_) => _load());
                  },
                ),
              ),
            ),
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
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontFamily: 'Boldonse',
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
            style: const TextStyle(
              color: Color(0xFF062F35),
              fontSize: 16,
              fontFamily: 'Boldonse',
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

class _ArticleDetailBottomBar extends StatelessWidget {
  final VoidCallback onCenterTap;

  const _ArticleDetailBottomBar({required this.onCenterTap});

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
