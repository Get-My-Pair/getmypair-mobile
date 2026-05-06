import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gmp/core/bgtheme.dart';
import 'package:gmp/core/constants/api_endpoints.dart';
import 'package:gmp/core/navigation/customer_dashboard_tab_index.dart';
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

  /// Optional list/cache payload while GET loads (same id as [articleId]).
  final Article? initialArticle;

  const ArticleDetailsPage({
    super.key,
    required this.articleId,
    this.initialArticle,
  });

  @override
  State<ArticleDetailsPage> createState() => _ArticleDetailsPageState();
}

class _ArticleDetailsPageState extends State<ArticleDetailsPage> {
  Article? _article;
  bool _loading = true;
  String? _error;

  static const Color _rackTeal = Color(0xFF0F6876);
  static const Color _rackTealAccent = Color(0xFF11899B);
  static const Color _panelBg = Color(0xFFF0F0F0);

  @override
  void initState() {
    super.initState();
    final seed = widget.initialArticle;
    if (seed != null && seed.id == widget.articleId) {
      _article = seed;
      _loading = false;
    }
    _load();
  }

  Future<void> _load() async {
    final keepExisting = _article != null;
    if (!keepExisting && mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    final tokenResult = await sl<GetValidAccessToken>().call();
    if (!mounted) return;
    tokenResult.fold(
      (_) => setState(() {
        _error = 'Please sign in again';
        _loading = false;
      }),
      (token) async {
        try {
          final article = await sl<GetArticleById>().call(
            token,
            widget.articleId,
          );
          if (!mounted) return;
          setState(() {
            _article = article;
            _loading = false;
            _error = null;
          });
        } catch (e) {
          if (!mounted) return;
          setState(() {
            if (_article == null) {
              _error = e.toString().replaceFirst('Exception: ', '');
            }
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

  static String _categoryLabel(String c) {
    const map = {
      'sports_shoe': 'Sports shoe',
      'casual': 'Casuals',
      'formal': 'Formals',
      'sandal': 'Sandal',
      'boot': 'Boot',
      'slipper': 'Slipper',
      'other': 'Other',
    };
    return map[c] ?? (c.isEmpty ? '—' : c);
  }

  static const String _staticSize = 'US: —';
  static const String _staticDash = '—';

  static const List<String> _monthShort = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  /// API `shoeSize` / `size` / `usSize`; otherwise static placeholder.
  static String _sizeLine(Article a) {
    final raw = a.shoeSize?.trim();
    if (raw != null && raw.isNotEmpty) {
      final u = raw.toUpperCase();
      if (u.startsWith('US')) return raw;
      return 'US: $raw';
    }
    return _staticSize;
  }

  /// API `lastWornAt` / `lastWear`; otherwise em dash.
  static String _lastWearLine(Article a) {
    final d = a.lastWornAt;
    if (d != null) return _shortDetailDate(d);
    return _staticDash;
  }

  /// API `lastShoeCareAt` / `shoeCareAt`; otherwise em dash.
  static String _shoeCareDateLine(Article a) {
    final d = a.lastShoeCareAt;
    if (d != null) return _shortDetailDate(d);
    return _staticDash;
  }

  static String _shortDetailDate(DateTime d) {
    final mon = _monthShort[d.month - 1];
    final yy = (d.year % 100).toString().padLeft(2, '0');
    return "${d.day} $mon'$yy";
  }

  static String _purchaseYearLine(Article a) {
    final y = a.purchaseYear;
    if (y != null) return y.toString();
    return _staticDash;
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
        const SnackBar(
          content: Text('Please sign in again'),
          backgroundColor: AppColors.error,
        ),
      ),
      (token) async {
        try {
          await sl<DeleteArticle>().call(token, _article!.id);
          if (!mounted) return;
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Shoe removed'),
              backgroundColor: AppColors.success,
            ),
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

  static const BorderRadius _panelRadius = BorderRadius.only(
    topLeft: Radius.circular(20),
    topRight: Radius.circular(20),
    bottomLeft: Radius.circular(50),
    bottomRight: Radius.circular(50),
  );

  @override
  Widget build(BuildContext context) {
    final bottomSafe = Responsive.bottomInsetOf(context);
    final bottomNavReserve =
        FloatingGradientBottomNav.barHeight + 12 + bottomSafe;
    final width = MediaQuery.sizeOf(context).width;
    final uiScale = (width / 390).clamp(0.84, 1.12).toDouble();
    final horizontalInset = (10.0 * uiScale).clamp(8.0, 16.0);
    const topInset = 52.0;

    if (_loading) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true,
        body: Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.none,
          children: [
            ...BgTheme.background(),
            Positioned.fill(
              child: SafeArea(
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
                      shape: RoundedRectangleBorder(borderRadius: _panelRadius),
                      shadows: [
                        BoxShadow(
                          color: Color(0x19000000),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const ClipRRect(
                      borderRadius: _panelRadius,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: _rackTealAccent,
                        ),
                      ),
                    ),
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
          ],
        ),
      );
    }

    if (_error != null || _article == null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true,
        body: Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.none,
          children: [
            ...BgTheme.background(),
            Positioned.fill(
              child: SafeArea(
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
                      shape: RoundedRectangleBorder(borderRadius: _panelRadius),
                      shadows: [
                        BoxShadow(
                          color: Color(0x19000000),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: _panelRadius,
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: Responsive.horizontalPaddingOf(context),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 48,
                                color: AppColors.error,
                              ),
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

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.none,
        children: [
          ...BgTheme.background(),
          Positioned.fill(
            child: SafeArea(
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
                    shape: RoundedRectangleBorder(borderRadius: _panelRadius),
                    shadows: [
                      BoxShadow(
                        color: Color(0x19000000),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: _panelRadius,
                    child: _buildFixedResponsiveContent(
                      context,
                      article: a,
                      imageUrl: imageUrl,
                      swatchColor: swatchColor,
                      bottomContentInset: bottomNavReserve,
                    ),
                  ),
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
        ],
      ),
    );
  }

  Widget _buildFixedResponsiveContent(
    BuildContext context, {
    required Article article,
    required String imageUrl,
    required Color swatchColor,
    required double bottomContentInset,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final uiScale = (width / 390).clamp(0.84, 1.12).toDouble();
        final scale = uiScale;

        final padX = (15.0 * scale).clamp(12.0, 20.0);
        final padTop = (22.0 * scale).clamp(18.0, 34.0);
        final padBottom = bottomContentInset + (12.0 * scale);
        final titleGap = (10.0 * scale).clamp(8.0, 16.0);
        final buttonGap = (14.0 * scale).clamp(10.0, 18.0);

        var panelH = constraints.maxHeight;
        if (!panelH.isFinite || panelH <= 0) {
          panelH = MediaQuery.sizeOf(context).height * 0.72;
        }
        final innerH = math.max(180.0, panelH - padTop - padBottom);
        final heightScale = (innerH / 620).clamp(0.68, 1.0);
        final layoutScale = scale * heightScale;

        final gap = math.max(4.0, innerH * 0.012);
        final tightVertical = innerH < 460;

        var hGrid = math.min(math.max(innerH * 0.098, 56.0), 102.0);
        var hCare = math.min(math.max(innerH * 0.084, 54.0), 90.0);
        var hButtons = math.min(math.max(innerH * 0.088, 46.0), 54.0);

        final fixedTail =
            gap + hGrid + gap * 0.65 + hGrid + gap + hCare + gap + hButtons;
        const minImageBand = 64.0;
        const headerReserve = 168.0;
        if (headerReserve + gap + fixedTail + minImageBand > innerH) {
          final over =
              headerReserve + gap + fixedTail + minImageBand - innerH + 16;
          hGrid = math.max(52.0, hGrid - over * 0.18);
          hCare = math.max(48.0, hCare - over * 0.12);
          hButtons = math.max(42.0, hButtons - over * 0.12);
        }

        final imageWidth = (width - padX * 2).clamp(160.0, 320.0);
        final swatchSize = (34.0 * layoutScale).clamp(22.0, 36.0);
        final valueSize = (16.0 * layoutScale).clamp(13.0, 17.0);
        final labelSize = (12.0 * layoutScale).clamp(10.0, 13.0);
        final dividerColor = Colors.black.withValues(alpha: 0.2);

        TextStyle valueBoldonse() => GoogleFonts.boldonse(
          fontWeight: FontWeight.w400,
          fontSize: valueSize,
          color: Colors.black,
        );

        TextStyle labelMontserrat() => GoogleFonts.montserrat(
          fontWeight: FontWeight.w400,
          fontSize: labelSize,
          color: AppColors.textSecondary,
        );

        Widget vDivider(double rowHeight) =>
            Container(width: 1, height: rowHeight * 0.72, color: dividerColor);

        return Padding(
          padding: EdgeInsets.fromLTRB(padX, padTop, padX, padBottom),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        style: IconButton.styleFrom(
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          minimumSize: Size.zero,
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        ),
                        constraints: const BoxConstraints.tightFor(
                          width: 30,
                          height: 30,
                        ),
                        onPressed: () {
                          final nav = Navigator.of(context);
                          if (nav.canPop()) {
                            nav.pop();
                            return;
                          }
                          customerDashboardTabIndex.value = 0;
                          nav.popUntil((route) => route.isFirst);
                        },
                        icon: SvgPicture.asset(
                          'assets/images/chevron-left.svg',
                          width: 24,
                          height: 24,
                          colorFilter: const ColorFilter.mode(
                            _rackTealAccent,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                      IconButton(
                        style: IconButton.styleFrom(
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          minimumSize: Size.zero,
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        ),
                        constraints: BoxConstraints.tightFor(
                          width: math.max(30.0, 26 * scale),
                          height: math.max(30.0, 26 * scale),
                        ),
                        onPressed: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  ArticleEditPage(articleId: article.id),
                            ),
                          );
                          if (mounted) _load();
                        },
                        icon: SvgPicture.asset(
                          'assets/images/icons/profile/edit.svg',
                          width: (20 * scale).clamp(18.0, 22.0),
                          height: (20 * scale).clamp(18.0, 22.0),
                          colorFilter: const ColorFilter.mode(
                            _rackTealAccent,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: (20 * layoutScale).clamp(16.0, 32.0)),
                  Text(
                    article.brand.isNotEmpty ? article.brand : 'Shoe',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.boldonse(
                      color: _rackTealAccent,
                      fontSize: (24 * layoutScale).clamp(18.0, 26.0),
                      fontWeight: FontWeight.w400,
                      height: 1.15,
                    ),
                  ),
                  SizedBox(height: titleGap),
                  Text(
                    article.model.isNotEmpty ? article.model : '—',
                    maxLines: tightVertical ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.montserrat(
                      color: Colors.black,
                      fontSize: (20 * layoutScale).clamp(14.0, 22.0),
                      fontWeight: FontWeight.w400,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
              SizedBox(height: math.max(6.0, gap * 0.65)),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, imgConstraints) {
                    final maxImgW = math.min(
                      imageWidth,
                      imgConstraints.maxWidth,
                    );
                    return Center(
                      child: Transform.rotate(
                        angle: -0.38,
                        child: Transform.flip(
                          flipX: true,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox(
                              width: maxImgW,
                              height: imgConstraints.maxHeight * 0.92,
                              child: imageUrl.isNotEmpty
                                  ? Image.network(
                                      imageUrl,
                                      fit: BoxFit.contain,
                                      alignment: Alignment.center,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              _placeholder(),
                                    )
                                  : _placeholder(),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: gap),
              Container(
                height: hGrid,
                padding: EdgeInsets.only(bottom: (5 * scale).clamp(4.0, 9.0)),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(width: 1, color: dividerColor),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: _statPair(
                        context,
                        value: _sizeLine(article),
                        label: 'Size',
                        valueStyle: valueBoldonse(),
                        labelStyle: labelMontserrat(),
                      ),
                    ),
                    vDivider(hGrid),
                    Expanded(
                      child: _statColorColumn(
                        context,
                        swatchColor: swatchColor,
                        colorName: article.color.isNotEmpty
                            ? article.color
                            : '—',
                        labelStyle: labelMontserrat(),
                        swatchSize: swatchSize,
                      ),
                    ),
                    vDivider(hGrid),
                    Expanded(
                      child: _statPair(
                        context,
                        value: _purchaseYearLine(article),
                        label: 'Purchased',
                        valueStyle: valueBoldonse(),
                        labelStyle: labelMontserrat(),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: gap * 0.65),
              SizedBox(
                height: hGrid,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: _statPair(
                        context,
                        value: _categoryLabel(article.category),
                        label: 'Category',
                        valueStyle: valueBoldonse(),
                        labelStyle: labelMontserrat(),
                      ),
                    ),
                    vDivider(hGrid),
                    Expanded(
                      child: _statPair(
                        context,
                        value: _lastWearLine(article),
                        label: 'Last Wear',
                        valueStyle: valueBoldonse(),
                        labelStyle: labelMontserrat(),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: gap),
              SizedBox(
                height: hCare,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Shoe care history coming soon'),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Ink(
                      height: hCare,
                      padding: EdgeInsets.symmetric(
                        horizontal: (16 * scale).clamp(12.0, 20.0),
                        vertical: (8 * scale).clamp(6.0, 12.0),
                      ),
                      decoration: ShapeDecoration(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          side: const BorderSide(
                            width: 1,
                            color: Color(0xFF09DFFF),
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        shadows: const [
                          BoxShadow(
                            color: Color(0x19000000),
                            blurRadius: 4,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              'Last sent to shoe care',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.montserrat(
                                fontWeight: FontWeight.w400,
                                fontSize: (14 * scale).clamp(12.0, 15.0),
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          Text(
                            _shoeCareDateLine(article),
                            textAlign: TextAlign.right,
                            style: GoogleFonts.boldonse(
                              fontWeight: FontWeight.w400,
                              fontSize: (16 * scale).clamp(14.0, 17.0),
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(width: 8 * scale),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: (24 * scale).clamp(20.0, 26.0),
                            color: _rackTealAccent,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: gap),
              SizedBox(
                height: hButtons,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _gradientPillButton(
                        label: 'Rehome',
                        height: hButtons,
                        fontSize: (14 * scale).clamp(12.0, 15.0),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Rehome coming soon')),
                          );
                        },
                      ),
                    ),
                    SizedBox(width: buttonGap),
                    Expanded(
                      child: _outlinedPillButton(
                        label: 'Rent',
                        height: hButtons,
                        fontSize: (14 * scale).clamp(12.0, 15.0),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Rent coming soon')),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            value,
            textAlign: TextAlign.center,
            style: valueStyle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          Text(label, textAlign: TextAlign.center, style: labelStyle),
        ],
      ),
    );
  }

  Widget _statColorColumn(
    BuildContext context, {
    required Color swatchColor,
    required String colorName,
    required TextStyle labelStyle,
    double swatchSize = 34,
  }) {
    final gap = math.min(4.0, swatchSize * 0.14);
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.center,
      child: Column(
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
          SizedBox(height: gap),
          Text(
            colorName,
            textAlign: TextAlign.center,
            style: labelStyle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _gradientPillButton({
    required String label,
    required VoidCallback onTap,
    required double height,
    required double fontSize,
  }) {
    final radius = height / 2;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: Ink(
          height: height,
          decoration: ShapeDecoration(
            gradient: const LinearGradient(
              begin: Alignment(1, 0.5),
              end: Alignment(0, 0.5),
              colors: [Color(0xFF0CADC5), Color(0xFF063239)],
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radius),
            ),
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
                fontSize: fontSize,
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
    required double height,
    required double fontSize,
  }) {
    final radius = height / 2;
    return Material(
      color: const Color(0xFFDFE7E9),
      borderRadius: BorderRadius.circular(radius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: Container(
          height: height,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
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
              fontSize: fontSize,
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
        child: Icon(
          Icons.checkroom_outlined,
          color: AppColors.textTertiary,
          size: 56,
        ),
      ),
    );
  }
}
