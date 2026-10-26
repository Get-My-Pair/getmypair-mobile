import 'package:flutter/material.dart';
import 'package:gmp/core/bgtheme.dart';
import 'package:gmp/core/constants/api_endpoints.dart';
import 'package:gmp/core/theme/app_colors.dart';
import 'package:gmp/core/widgets/app_feedback_alert.dart';
import 'package:gmp/core/widgets/app_skeleton.dart';
import 'package:gmp/core/widgets/article_rack_shoe_image.dart';
import 'package:gmp/core/widgets/floating_gradient_bottom_nav.dart';
import 'package:gmp/features/sell/presentation/widgets/sell_shell.dart';
import 'package:gmp/features/articles/domain/entities/article.dart';
import 'package:gmp/features/articles/domain/usecases/get_my_articles.dart';
import 'package:gmp/features/auth/domain/usecases/get_valid_access_token.dart';
import 'package:gmp/injection_container.dart';
import 'package:google_fonts/google_fonts.dart';

import '../utils/service_flow_article.dart';
import '../utils/service_flow_layout.dart';
import 'donate_my_pair_flow.dart';
import 'service_selection_page.dart';

class RepairMyPairPage extends StatefulWidget {
  final String pageTitle;
  final List<String> allowedServiceTypes;
  final String description;
  /// Teal tagline under the title (Rehome-style header).
  final String tagline;

  const RepairMyPairPage({
    super.key,
    this.pageTitle = 'RepairMyPair',
    this.allowedServiceTypes = const ['repair'],
    this.tagline = '',
    this.description =
        'RepairMyPair is a service that restores any part of your footwear. Please select the footwear you\'d like to repair.',
  });

  @override
  State<RepairMyPairPage> createState() => _RepairMyPairPageState();
}

class _RepairMyPairPageState extends State<RepairMyPairPage> {
  static const BorderRadius _panelRadius = BorderRadius.only(
    topLeft: Radius.circular(20),
    topRight: Radius.circular(20),
    bottomLeft: Radius.circular(50),
    bottomRight: Radius.circular(50),
  );

  /// Content card sits above the full-bleed white Next dock (square bottom).
  static const BorderRadius _panelRadiusAboveDock = BorderRadius.only(
    topLeft: Radius.circular(20),
    topRight: Radius.circular(20),
  );
  static const Color _teal = Color(0xFF11999E);
  static const Color _dark = Color(0xFF062F35);

  bool _loading = true;
  bool _submitting = false;
  String? _error;
  List<Article> _articles = const [];
  final Set<String> _selectedArticleIds = {};

  @override
  void initState() {
    super.initState();
    _loadArticles();
  }

  Future<void> _loadArticles() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final tokenResult = await sl<GetValidAccessToken>().call();
    if (!mounted) return;

    await tokenResult.fold(
      (_) async {
        setState(() {
          _loading = false;
          _error = 'Please sign in again';
        });
      },
      (token) async {
        try {
          final result = await sl<GetMyArticles>().call(token);
          if (!mounted) return;
          setState(() {
            _articles = result;
            _loading = false;
          });
        } catch (e) {
          if (!mounted) return;
          setState(() {
            _loading = false;
            _error = e.toString().replaceFirst('Exception: ', '');
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

  String _displayName(Article article) {
    if (article.brand.trim().isNotEmpty) return article.brand.trim();
    if (article.model.trim().isNotEmpty) return article.model.trim();
    if (article.color.trim().isNotEmpty) return article.color.trim();
    return 'Shoe';
  }

  bool get _isDonateOnlyPicker =>
      widget.allowedServiceTypes.length == 1 &&
      widget.allowedServiceTypes.first.trim().toLowerCase() == 'donate';

  void _toggleArticleSelection(String articleId) {
    setState(() {
      if (_selectedArticleIds.contains(articleId)) {
        _selectedArticleIds.remove(articleId);
      } else {
        _selectedArticleIds.add(articleId);
      }
    });
  }

  List<ServiceFlowArticle> get _selectedFlowArticles {
    return _articles
        .where((a) => _selectedArticleIds.contains(a.id))
        .map(
          (a) {
            final brand = a.brand.trim();
            final model = a.model.trim();
            return ServiceFlowArticle(
              id: a.id,
              name: brand.isNotEmpty
                  ? brand
                  : model.isNotEmpty
                      ? model
                      : _displayName(a),
              subtitle: brand.isNotEmpty && model.isNotEmpty ? model : null,
              imageUrl: _imageUrl(a.rackHeroImagePath),
            );
          },
        )
        .toList();
  }

  Future<void> _goNext() async {
    if (_submitting) return;
    if (_selectedArticleIds.isEmpty) {
      await showAppFeedbackAlert(
        context,
        message: 'Please select at least one pair of footwear',
        type: AppFeedbackType.warning,
      );
      return;
    }
    final selectedArticles = _selectedFlowArticles;
    if (selectedArticles.isEmpty) return;
    setState(() => _submitting = true);
    final allowed = widget.allowedServiceTypes;
    final isDonateOnly = allowed.length == 1 &&
        allowed.first.trim().toLowerCase() == 'donate';
    final primary = selectedArticles.first;

    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => isDonateOnly
            ? DonateMyPairDetailsPage(
                articleId: primary.id,
                articleName: primary.name,
                articleImageUrl: primary.imageUrl,
                selectedArticles: selectedArticles,
              )
            : ServiceSelectionPage.multi(
                selectedArticles: selectedArticles,
                allowedServiceTypes: widget.allowedServiceTypes,
                flowPageTitle: widget.pageTitle,
              ),
      ),
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (created == true) {
      Navigator.maybePop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final uiScale = (width / 390).clamp(0.84, 1.12).toDouble();
    final horizontalInset = (10.0 * uiScale).clamp(8.0, 16.0);
    const topInset = 52.0;

    final hideBottomNav = !_isDonateOnlyPicker;
    final bottomSafe = MediaQuery.viewPaddingOf(context).bottom;
    final uiScaleBody = (width / 390).clamp(0.84, 1.12).toDouble();
    final layoutScale = serviceFlowLayoutScale(context, uiScale: uiScaleBody);
    final pillH = (48 * layoutScale).clamp(40.0, 52.0);
    final fs = (16 * layoutScale).clamp(12.0, 16.0);
    final canNext = _selectedArticleIds.isNotEmpty && !_submitting;
    // White dock height (padding + button + safe area) for content clearance.
    final dockH = hideBottomNav ? (14 + pillH + 14 + bottomSafe) : 0.0;
    final panelRadius =
        hideBottomNav ? _panelRadiusAboveDock : _panelRadius;

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
                  hideBottomNav ? dockH - 12 : 0,
                ),
                child: DecoratedBox(
                  decoration: ShapeDecoration(
                    color: const Color(0xFFF0F0F0),
                    shape: RoundedRectangleBorder(borderRadius: panelRadius),
                    shadows: const [
                      BoxShadow(
                        color: Color(0x19000000),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: panelRadius,
                    child: _isDonateOnlyPicker
                        ? _buildBody(context)
                        : LayoutBuilder(
                            builder: (context, constraints) =>
                                _buildBody(context, constraints),
                          ),
                  ),
                ),
              ),
            ),
          ),
          if (hideBottomNav)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildFullBleedNextDock(
                canNext: canNext,
                pillH: pillH,
                fontSize: fs,
                bottomSafe: bottomSafe,
              ),
            ),
          if (!hideBottomNav)
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

  Widget _buildFullBleedNextDock({
    required bool canNext,
    required double pillH,
    required double fontSize,
    required double bottomSafe,
  }) {
    const pillW = 168.0;
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      padding: EdgeInsets.fromLTRB(20, 14, 20, 14 + bottomSafe),
      child: Center(
        child: SizedBox(
          width: pillW,
          height: pillH,
          child: canNext
              ? DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Color(0xFF063239),
                        Color(0xFF0CADC5),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(100),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x19000000),
                        blurRadius: 4,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextButton(
                    onPressed: _goNext,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                    child: _submitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'Next',
                            style: GoogleFonts.boldonse(
                              color: Colors.white,
                              fontSize: fontSize,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                  ),
                )
              : DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFFBDBDBD),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Center(
                    child: Text(
                      'Next',
                      style: GoogleFonts.boldonse(
                        color: const Color(0xFF4A4A4A),
                        fontSize: fontSize,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, [BoxConstraints? constraints]) {
    if (_loading) {
      return const AppSkeletonCards();
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.error),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _loadArticles,
                style: FilledButton.styleFrom(backgroundColor: _teal),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (_articles.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            'No footwear found. Please add a pair first.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF5C5C5C)),
          ),
        ),
      );
    }

    if (_isDonateOnlyPicker) {
      return _buildDonateFootwearPickerLegacy(context);
    }

    final width = MediaQuery.sizeOf(context).width;
    final uiScale = (width / 390).clamp(0.84, 1.12).toDouble();
    final layoutScale = serviceFlowLayoutScale(context, uiScale: uiScale);
    final fs = (16 * layoutScale).clamp(12.0, 16.0);
    final rowGap = (10 * layoutScale).clamp(6.0, 14.0);
    final rowH = (112 * layoutScale).clamp(96.0, 128.0);

    final rows = (_articles.length + 2) ~/ 3;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      children: [
        _PageHeader(
          title: widget.pageTitle,
          tagline: widget.tagline,
          titleFontSize: 20,
          taglineFontSize: 12,
          iconSize: 20,
          gap: 6,
          onBack: () => Navigator.maybePop(context),
        ),
        if (widget.description.trim().isNotEmpty) ...[
          SizedBox(height: 10 * layoutScale),
          Text(
            widget.description,
            style: GoogleFonts.montserrat(
              color: Colors.black,
              fontSize: fs,
              fontWeight: FontWeight.w400,
              height: 1.35,
            ),
          ),
        ],
        SizedBox(height: 24 * layoutScale),
        // Same My Rack shelf chrome as home / sell rack selection.
        ...List.generate(rows, (row) {
          return Padding(
            padding: EdgeInsets.only(bottom: row == rows - 1 ? 0 : rowGap),
            child: SellRackShelf(
              height: rowH,
              children: List.generate(3, (col) {
                final index = row * 3 + col;
                if (index >= _articles.length) {
                  return const SizedBox.shrink();
                }
                final article = _articles[index];
                return _ShoeOption(
                  layoutScale: layoutScale,
                  label: _displayName(article),
                  imageUrl: _imageUrl(article.rackHeroImagePath),
                  selected: _selectedArticleIds.contains(article.id),
                  onTap: () => _toggleArticleSelection(article.id),
                );
              }),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildDonateFootwearPickerLegacy(BuildContext context) {
    final rows = (_articles.length + 2) ~/ 3;
    return ListView(
      padding: const EdgeInsets.fromLTRB(10, 12, 12, 128),
      children: [
        _PageHeader(
          title: widget.pageTitle,
          tagline: widget.tagline,
          onBack: () => Navigator.maybePop(context),
        ),
        if (widget.description.trim().isNotEmpty) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: 363,
            child: Text(
              widget.description,
              style: GoogleFonts.montserrat(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
        const SizedBox(height: 14),
        ...List.generate(rows, (row) {
          return Padding(
            padding: EdgeInsets.only(bottom: row == rows - 1 ? 0 : 10),
            child: SellRackShelf(
              children: List.generate(3, (col) {
                final index = row * 3 + col;
                if (index >= _articles.length) {
                  return const SizedBox.shrink();
                }
                final article = _articles[index];
                return _ShoeOption(
                  label: _displayName(article),
                  imageUrl: _imageUrl(article.rackHeroImagePath),
                  selected: _selectedArticleIds.contains(article.id),
                  onTap: () => _toggleArticleSelection(article.id),
                );
              }),
            ),
          );
        }),
        const SizedBox(height: 18),
        Center(
          child: SizedBox(
            width: 164,
            height: 48,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                  colors: [
                    Color(0xFF0CADC5),
                    Color(0xFF063239),
                  ],
                ),
                borderRadius: BorderRadius.circular(100),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x19000000),
                    blurRadius: 4,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: TextButton(
                onPressed: _submitting ? null : _goNext,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Next',
                            style: GoogleFonts.boldonse(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(width: 20),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Matches Rehome header:
/// ← Title
///    Teal tagline
class _PageHeader extends StatelessWidget {
  final String title;
  final String tagline;
  final VoidCallback onBack;
  final double titleFontSize;
  final double taglineFontSize;
  final double iconSize;
  final double gap;

  const _PageHeader({
    required this.title,
    required this.tagline,
    required this.onBack,
    this.titleFontSize = 24,
    this.taglineFontSize = 14,
    this.iconSize = 24,
    this.gap = 6,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            IconButton(
              onPressed: onBack,
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints.tightFor(width: 26, height: 26),
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: _RepairMyPairPageState._dark,
                size: iconSize,
              ),
            ),
            SizedBox(width: gap),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.boldonse(
                  color: _RepairMyPairPageState._dark,
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.w400,
                  height: 1.1,
                ),
              ),
            ),
          ],
        ),
        if (tagline.trim().isNotEmpty) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 40),
            child: Text(
              tagline,
              style: GoogleFonts.boldonse(
                color: const Color(0xFF0E7C8A),
                fontSize: taglineFontSize,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ShoeOption extends StatelessWidget {
  final String label;
  final String imageUrl;
  final bool selected;
  final VoidCallback onTap;
  final double layoutScale;

  const _ShoeOption({
    required this.label,
    required this.imageUrl,
    required this.selected,
    required this.onTap,
    this.layoutScale = 1,
  });

  @override
  Widget build(BuildContext context) {
    final radio = (20 * layoutScale).clamp(16.0, 22.0);
    final checkSz = (12 * layoutScale).clamp(10.0, 14.0);
    final shoeIcon = (36 * layoutScale).clamp(28.0, 42.0);
    final labelFs = (12.5 * layoutScale).clamp(11.0, 14.0);
    final borderW = (1.8 * layoutScale).clamp(1.4, 2.0);
    final short = label.length <= 10 ? label : '${label.substring(0, 9)}...';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: radio,
                height: radio,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _RepairMyPairPageState._teal,
                    width: borderW,
                  ),
                  color: selected
                      ? _RepairMyPairPageState._teal.withValues(alpha: 0.14)
                      : Colors.transparent,
                ),
                child: selected
                    ? Center(
                        child: Icon(
                          Icons.check,
                          size: checkSz,
                          color: _RepairMyPairPageState._teal,
                        ),
                      )
                    : null,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(2, 2, 2, 0),
                child: imageUrl.isEmpty
                    ? Icon(
                        Icons.checkroom_outlined,
                        color: const Color(0xFF8D8D8D),
                        size: shoeIcon,
                      )
                    : ArticleRackShoeImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.contain,
                        placeholder: Icon(
                          Icons.checkroom_outlined,
                          color: const Color(0xFF8D8D8D),
                          size: shoeIcon,
                        ),
                        errorPlaceholder: Icon(
                          Icons.checkroom_outlined,
                          color: const Color(0xFF8D8D8D),
                          size: shoeIcon,
                        ),
                      ),
              ),
            ),
            SizedBox(height: 2 * layoutScale),
            Text(
              short,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.boldonse(
                color: _RepairMyPairPageState._teal,
                fontWeight: FontWeight.w400,
                fontSize: labelFs,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
