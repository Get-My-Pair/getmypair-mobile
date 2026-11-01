import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gmp/core/bgtheme.dart';
import 'package:gmp/core/constants/api_endpoints.dart';
import 'package:gmp/core/navigation/customer_dashboard_tab_index.dart';
import 'package:gmp/core/theme/app_colors.dart';
import 'package:gmp/core/utils/responsive.dart';
import 'package:gmp/core/widgets/app_skeleton.dart';
import 'package:gmp/core/widgets/app_gradient_next_style_button.dart';
import 'package:gmp/core/widgets/article_rack_shoe_image.dart';
import 'package:gmp/features/articles/domain/entities/article.dart';
import 'package:gmp/features/articles/domain/usecases/delete_article.dart';
import 'package:gmp/features/articles/domain/usecases/get_article_by_id.dart';
import 'package:gmp/features/auth/domain/usecases/get_valid_access_token.dart';
import 'package:gmp/injection_container.dart';
import 'package:gmp/features/articles/presentation/widgets/footwear_colour_picker.dart';
import 'package:gmp/features/service/presentation/pages/care_my_pair_page.dart';
import 'package:gmp/features/service/presentation/pages/rehome_my_pair_page.dart';
import 'package:gmp/features/service/presentation/pages/save_my_pair_page.dart';

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
    return map[c] ?? c;
  }

  static math.Random _rng(String id, [String salt = '']) =>
      math.Random(Object.hash(id, salt));

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

  static const List<String> _fallbackUsSizes = [
    '06',
    '07',
    '08',
    '09',
    '10',
    '11',
    '12',
  ];

  static const List<(String, Color)> _fallbackColorPalette = [
    ('Denim', Color(0xFF11253F)),
    ('Black', Color(0xFF1A1A1A)),
    ('White', Color(0xFFE2E4E6)),
    ('Green', Color(0xFF2D5A3D)),
    ('Red', Color(0xFF8B2E2E)),
    ('Brown', Color(0xFF5C4033)),
    ('Navy', Color(0xFF1B2A4A)),
    ('Grey', Color(0xFF6B7280)),
  ];

  static const Map<String, Color> _namedColorSwatches = {
    'black': Color(0xFF1A1A1A),
    'white': Color(0xFFF5F5F5),
    'blue': Color(0xFF1E4A7A),
    'navy': Color(0xFF0F2540),
    'red': Color(0xFFB83232),
    'green': Color(0xFF2E6B3C),
    'brown': Color(0xFF5C4033),
    'grey': Color(0xFF6B7280),
    'gray': Color(0xFF6B7280),
    'tan': Color(0xFFC4A77D),
    'orange': Color(0xFFD97736),
    'pink': Color(0xFFC97B9A),
    'yellow': Color(0xFFE6C84A),
    'denim': Color(0xFF11253F),
  };

  static (String name, Color swatch) _randomColorPair(String id) {
    final i = _rng(id, 'pal').nextInt(_fallbackColorPalette.length);
    return _fallbackColorPalette[i];
  }

  /// Backend color string + hex when present; otherwise seeded “random” pair.
  static (String name, Color swatch) _resolveColorRow(Article a) {
    final s = a.color.trim();
    if (s.isEmpty) return _randomColorPair(a.id);

    final label = footwearColourDisplayName(s);
    final swatch = parseFootwearColour(s) ??
        _namedColorSwatches[s.toLowerCase()] ??
        _parseColorHex(s) ??
        _randomColorPair(a.id).$2;
    return (label, swatch);
  }

  static String _shortDetailDate(DateTime d) {
    final mon = _monthShort[d.month - 1];
    final yy = (d.year % 100).toString().padLeft(2, '0');
    return "${d.day} $mon'$yy";
  }

  static String _randomWearDate(Article a) {
    final r = _rng(a.id, 'wear');
    final days = r.nextInt(380) + 14;
    return _shortDetailDate(DateTime.now().subtract(Duration(days: days)));
  }

  /// API `shoeSize` / `size` / `usSize`; otherwise seeded US size.
  static String _sizeLine(Article a) {
    final raw = a.shoeSize?.trim();
    if (raw != null && raw.isNotEmpty) {
      final u = raw.toUpperCase();
      if (u.startsWith('US') || u.startsWith('UK') || u.startsWith('EU')) return raw;
      return 'US: $raw';
    }
    final idx = _rng(a.id, 'size').nextInt(_fallbackUsSizes.length);
    return 'US: ${_fallbackUsSizes[idx]}';
  }

  /// API `lastWornAt`; otherwise seeded date string.
  static String _lastWearLine(Article a) {
    final d = a.lastWornAt;
    if (d != null) return _shortDetailDate(d);
    return _randomWearDate(a);
  }

  /// API `purchaseYear`; otherwise seeded year in a plausible range.
  static String _purchaseYearLine(Article a) {
    final y = a.purchaseYear;
    if (y != null) return y.toString();
    final r = _rng(a.id, 'py');
    return (2019 + r.nextInt(7)).toString();
  }

  /// Category from API code/string; otherwise seeded label.
  static String _categoryDisplay(Article a) {
    final c = a.category.trim();
    if (c.isNotEmpty) return _categoryLabel(c);
    const opts = [
      'Sports shoe',
      'Casuals',
      'Formals',
      'Sandal',
      'Boot',
      'Other',
    ];
    return opts[_rng(a.id, 'cat').nextInt(opts.length)];
  }

  static const List<String> _fallbackBrands = [
    'Nike',
    'Adidas',
    'Converse',
    'Puma',
    'New Balance',
  ];

  static const List<String> _fallbackModels = [
    'Air Max',
    'Sneaker',
    'Classic',
    'Runner',
    'Low Top',
    'Originals',
  ];

  static String _brandLine(Article a) {
    final b = a.brand.trim();
    if (b.isNotEmpty) return b;
    return _fallbackBrands[_rng(a.id, 'brand').nextInt(_fallbackBrands.length)];
  }

  static String _modelLine(Article a) {
    final m = a.model.trim();
    if (m.isNotEmpty) return m;
    return _fallbackModels[_rng(a.id, 'model').nextInt(_fallbackModels.length)];
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
          final messenger = ScaffoldMessenger.of(context);
          Navigator.of(context).pop(true);
          messenger.showSnackBar(
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
    // No floating bottom nav on this page — only safe-area inset.
    final bottomContentInset = math.max(16.0, bottomSafe + 12);
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
                      child: AppSkeletonCards(
                        padding: EdgeInsets.fromLTRB(16, 24, 16, 24),
                      ),
                    ),
                  ),
                ),
              ),
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
                                  AppGradientNextStyleButton(
                                    label: 'Retry',
                                    onPressed: _load,
                                    minWidth: 120,
                                    leading: const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
                                    showTrailingIcon: false,
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
          ],
        ),
      );
    }

    final a = _article!;
    final imagePath = a.rackHeroImagePath;
    final imageUrl = _imageUrl(imagePath);
    final colorRow = _resolveColorRow(a);

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
                      swatchColor: colorRow.$2,
                      colorDisplayName: colorRow.$1,
                      bottomContentInset: bottomContentInset,
                    ),
                  ),
                ),
              ),
            ),
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
    required String colorDisplayName,
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

        var panelH = constraints.maxHeight;
        if (!panelH.isFinite || panelH <= 0) {
          panelH = MediaQuery.sizeOf(context).height * 0.72;
        }
        final innerH = math.max(180.0, panelH - padTop - padBottom);
        final heightScale = (innerH / 620).clamp(0.68, 1.0);
        final layoutScale = scale * heightScale;

        final gap = math.max(4.0, innerH * 0.012);
        final gapHeaderToImage = math.max(12.0, gap * 1.25);
        final gapImageToStats = math.max(9.0, gap * 1.1);
        final gapStatsToCare = math.max(12.0, gap * 1.3);
        final gapButtonsToBottom = math.max(14.0, gap * 1.65);
        final tightVertical = innerH < 460;

        var hGrid = math.min(math.max(innerH * 0.098, 56.0), 102.0);
        const managePairH = 48.0;

        final fixedTail =
            gap + hGrid + gap * 0.65 + hGrid + gap + managePairH;
        const minImageBand = 64.0;
        const headerReserve = 168.0;
        if (headerReserve + gap + fixedTail + minImageBand > innerH) {
          final over =
              headerReserve + gap + fixedTail + minImageBand - innerH + 16;
          hGrid = math.max(52.0, hGrid - over * 0.22);
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
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
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
                                  builder: (_) => ArticleEditPage(
                                    articleId: article.id,
                                    initialArticle: article,
                                  ),
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
                          SizedBox(width: (10 * scale).clamp(8.0, 14.0)),
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
                            onPressed: _deleteArticle,
                            icon: SvgPicture.asset(
                              'assets/images/icons/profile/trash-2.svg',
                              width: (20 * scale).clamp(18.0, 22.0),
                              height: (20 * scale).clamp(18.0, 22.0),
                              colorFilter: const ColorFilter.mode(
                                AppColors.error,
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: (20 * layoutScale).clamp(16.0, 32.0)),
                  Text(
                    _brandLine(article),
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
                    _modelLine(article),
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
              SizedBox(height: gapHeaderToImage),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, imgConstraints) {
                    final maxImgW = math.min(
                      imageWidth,
                      imgConstraints.maxWidth,
                    );
                    return Center(
                      child: ArticleRackShoeImage(
                        imageUrl: imageUrl,
                        width: maxImgW,
                        height: imgConstraints.maxHeight * 0.92,
                        fit: BoxFit.contain,
                        placeholder: _placeholder(),
                        errorPlaceholder: _placeholder(),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: gapImageToStats),
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
                    Expanded(
                      child: _statColorColumn(
                        context,
                        swatchColor: swatchColor,
                        colorName: colorDisplayName,
                        labelStyle: labelMontserrat(),
                        swatchSize: swatchSize,
                      ),
                    ),
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
              SizedBox(height: math.max(10.0, gap * 1.0)),
              SizedBox(
                height: hGrid,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: _statPair(
                        context,
                        value: _categoryDisplay(article),
                        label: 'Category',
                        valueStyle: valueBoldonse(),
                        labelStyle: labelMontserrat(),
                      ),
                    ),
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
              // Shoe care history — temporarily hidden.
              // SizedBox(height: gapStatsToCare),
              // ... shoe care history tile ...
              SizedBox(height: math.max(12.0, gapStatsToCare * 0.35)),
              // Rehome / Rent — temporarily hidden; Manage Pair replaces them.
              // SizedBox(
              //   height: hButtons,
              //   child: Row(
              //     children: [
              //       Expanded(child: _gradientPillButton(label: 'Rehome', ...)),
              //       Expanded(child: _outlinedPillButton(label: 'Rent', ...)),
              //     ],
              //   ),
              // ),
              Center(
                child: SizedBox(
                  width: 241,
                  height: 48,
                  child: _gradientPillButton(
                    label: 'Manage Pair',
                    height: 48,
                    fontSize: 14,
                    onTap: () => _showManagePairSheet(context),
                  ),
                ),
              ),
              SizedBox(height: gapButtonsToBottom),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showManagePairSheet(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.70),
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Container(
            width: double.infinity,
            decoration: const ShapeDecoration(
              color: Color(0xFFF6F6F6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(29, 28, 29, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'What does this pair need today?',
                    style: GoogleFonts.boldonse(
                      color: const Color(0xFF12899B),
                      fontSize: 24,
                      fontWeight: FontWeight.w400,
                      height: 1.63,
                    ),
                  ),
                  const SizedBox(height: 19),
                  _managePairOption(
                    label: 'CareMyPair',
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const CareMyPairPage(),
                        ),
                      );
                    },
                  ),
                  _managePairOption(
                    label: 'RehomeMyPair',
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const RehomeMyPairPage(),
                        ),
                      );
                    },
                  ),
                  _managePairOption(
                    label: 'SaveMyPair',
                    showBottomBorder: false,
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const SaveMyPairPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _managePairOption({
    required String label,
    required VoidCallback onTap,
    bool showBottomBorder = true,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                width: showBottomBorder ? 1 : 0,
                color: const Color(0xFFD9D9D9),
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.montserrat(
                    color: const Color(0xFF0F6876),
                    fontSize: 20,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 24,
                color: Color(0xFF0F6876),
              ),
            ],
          ),
        ),
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
    double fontSize = 16,
  }) {
    const radius = BorderRadius.all(Radius.circular(100));
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Ink(
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          decoration: const ShapeDecoration(
            gradient: LinearGradient(
              begin: Alignment(1.00, 0.50),
              end: Alignment(0.00, 0.50),
              colors: [Color(0xFF0CADC5), Color(0xFF063239)],
            ),
            shape: RoundedRectangleBorder(borderRadius: radius),
            shadows: [
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

  Widget _placeholder() {
    return const Center(
      child: Icon(
        Icons.checkroom_outlined,
        color: AppColors.textTertiary,
        size: 56,
      ),
    );
  }
}
