import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:gmp/core/widgets/app_feedback_alert.dart';
import 'package:gmp/core/widgets/app_skeleton.dart';
import 'package:gmp/core/widgets/article_rack_shoe_image.dart';
import 'package:gmp/core/widgets/floating_gradient_bottom_nav.dart';
import 'package:gmp/features/articles/domain/entities/article.dart';
import 'package:gmp/features/articles/domain/usecases/get_my_articles.dart';
import 'package:gmp/features/articles/domain/usecases/update_article.dart';
import 'package:gmp/features/articles/presentation/pages/article_details_page.dart';
import 'package:gmp/features/articles/presentation/widgets/footwear_colour_picker.dart';
import 'package:gmp/features/auth/domain/usecases/get_valid_access_token.dart';
import 'package:gmp/features/service/presentation/widgets/service_request_bg_layer.dart';
import 'package:gmp/injection_container.dart';

/// Favorites (2nd bottom-nav tab): footwear marked with the heart while editing.
class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  static const String routeName = '/favorites';

  static const BorderRadius _panelRadius = BorderRadius.only(
    topLeft: Radius.circular(20),
    topRight: Radius.circular(20),
    bottomLeft: Radius.circular(50),
    bottomRight: Radius.circular(50),
  );

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  static const Color _ink = Color(0xFF062F35);
  static const Color _teal = Color(0xFF12899B);
  static const Color _heart = Color(0xFFE5365B);

  bool _loading = true;
  String? _error;
  List<Article> _items = const [];

  /// Ids whose un-favourite request is in flight.
  final Set<String> _busy = <String>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    final tokenResult = await sl<GetValidAccessToken>().call();
    if (!mounted) return;

    await tokenResult.fold(
      (_) async {
        setState(() {
          _loading = false;
          if (!silent || _items.isEmpty) _error = 'Please sign in again';
        });
      },
      (token) async {
        try {
          final all = await sl<GetMyArticles>().call(token);
          if (!mounted) return;
          setState(() {
            _items = all.where((a) => a.isFavorite).toList();
            _loading = false;
            _error = null;
          });
        } catch (e) {
          if (!mounted) return;
          setState(() {
            _loading = false;
            // Keep what is already on screen when a quiet refresh fails.
            if (!silent || _items.isEmpty) {
              _error = e.toString().replaceFirst('Exception: ', '');
            }
          });
        }
      },
    );
  }

  Future<void> _removeFavorite(Article article) async {
    if (_busy.contains(article.id)) return;
    final index = _items.indexWhere((a) => a.id == article.id);
    if (index < 0) return;

    setState(() {
      _busy.add(article.id);
      _items = [..._items]..removeAt(index); // optimistic
    });

    void restore() {
      if (!mounted) return;
      setState(() {
        _busy.remove(article.id);
        final at = index.clamp(0, _items.length);
        _items = [..._items]..insert(at, article);
      });
    }

    final tokenResult = await sl<GetValidAccessToken>().call();
    if (!mounted) return;
    await tokenResult.fold(
      (_) async {
        restore();
        showAppFeedbackAlert(
          context,
          message: 'Please sign in again',
          type: AppFeedbackType.failure,
        );
      },
      (token) async {
        try {
          await sl<UpdateArticle>().call(
            token,
            article.id,
            isFavorite: false,
          );
          if (!mounted) return;
          setState(() => _busy.remove(article.id));
        } catch (e) {
          restore();
          if (!mounted) return;
          showAppFeedbackAlert(
            context,
            message: e.toString().replaceFirst('Exception: ', ''),
            type: AppFeedbackType.failure,
          );
        }
      },
    );
  }

  Future<void> _open(Article article) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ArticleDetailsPage(
          articleId: article.id,
          initialArticle: article,
        ),
      ),
    );
    // The heart may have been changed while editing.
    if (mounted) _load(silent: true);
  }

  @override
  Widget build(BuildContext context) {
    final bottomSafe = MediaQuery.viewPaddingOf(context).bottom;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: Stack(
        children: [
          ...ServiceRequestBgLayer.stackBehind(),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 30, 10, 0),
              child: DecoratedBox(
                decoration: ShapeDecoration(
                  color: ServiceRequestBgLayer.panelFill,
                  shape: const RoundedRectangleBorder(
                    borderRadius: FavoritesPage._panelRadius,
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
                  borderRadius: FavoritesPage._panelRadius,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 12, 8, 8),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: () => Navigator.maybePop(context),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints.tightFor(
                                width: 26,
                                height: 26,
                              ),
                              icon: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: _ink,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Favorites',
                                style: GoogleFonts.boldonse(
                                  color: _ink,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: _loading ? null : _load,
                              icon: const Icon(
                                Icons.refresh_rounded,
                                color: _ink,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(child: _body(bottomSafe)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: const DashboardLinkedBottomNav(
              selectedTabIndex: -1,
              highlightFavorites: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _body(double bottomSafe) {
    if (_loading) return const AppSkeletonList(itemCount: 3);

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(color: const Color(0xFFB00020)),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _load,
                style: FilledButton.styleFrom(backgroundColor: _teal),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_items.isEmpty) {
      return RefreshIndicator(
        color: _teal,
        onRefresh: () => _load(silent: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(32, 64, 32, 120 + bottomSafe),
          children: [
            const Icon(Icons.favorite_border_rounded, size: 64, color: _teal),
            const SizedBox(height: 16),
            Text(
              'No favorites yet',
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                color: _ink,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Open a footwear in My Rack, tap Edit and press the heart '
              'to save it here.',
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                color: const Color(0xFF6B7C80),
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: _teal,
      onRefresh: () => _load(silent: true),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16, 8, 16, 120 + bottomSafe),
        itemCount: _items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 14),
        itemBuilder: (_, i) {
          final article = _items[i];
          return _FavoriteCard(
            key: ValueKey(article.id),
            article: article,
            onTap: () => _open(article),
            onUnfavorite: () => _removeFavorite(article),
          );
        },
      ),
    );
  }
}

class _FavoriteCard extends StatelessWidget {
  const _FavoriteCard({
    super.key,
    required this.article,
    required this.onTap,
    required this.onUnfavorite,
  });

  final Article article;
  final VoidCallback onTap;
  final VoidCallback onUnfavorite;

  @override
  Widget build(BuildContext context) {
    final colourRaw = article.color.trim();
    final swatch = parseFootwearColour(colourRaw);
    final colourLabel =
        colourRaw.isEmpty ? null : footwearColourDisplayName(colourRaw);
    final size = article.shoeSize?.trim();
    final image = article.rackHeroImagePath ?? '';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _FavoritesPageState._teal, width: 1),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 96,
                  height: 76,
                  child: image.isEmpty
                      ? Container(
                          color: const Color(0xFFE8EEEE),
                          child: const Icon(
                            Icons.directions_walk_rounded,
                            size: 28,
                            color: _FavoritesPageState._teal,
                          ),
                        )
                      : ArticleRackShoeImage(
                          imageUrl: image,
                          fit: BoxFit.contain,
                        ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      article.brand,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.montserrat(
                        color: _FavoritesPageState._teal,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      article.model,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.montserrat(
                        color: _FavoritesPageState._ink,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (swatch != null) ...[
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: swatch,
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(
                                color: Colors.black.withValues(alpha: 0.18),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Flexible(
                          child: Text(
                            [
                              if (colourLabel != null) colourLabel,
                              if (size != null && size.isNotEmpty) size,
                            ].join('  ·  '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.montserrat(
                              color: const Color(0xFF6B7C80),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Remove from favorites',
                onPressed: onUnfavorite,
                icon: const Icon(
                  Icons.favorite_rounded,
                  color: _FavoritesPageState._heart,
                  size: 28,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
