import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../auth/presentation/pages/mobile_otp_page.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/constants/figma_home_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/floating_gradient_bottom_nav.dart';
import '../../../profile/presentation/bloc/profile_bloc.dart';
import '../../../profile/presentation/bloc/profile_state.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'select_location_page.dart';
import 'chatbot_page.dart';
import '../../../articles/domain/entities/article.dart';
import '../../../articles/domain/usecases/get_my_articles.dart';
import '../../../articles/presentation/pages/article_details_page.dart';
import '../../../articles/presentation/pages/article_list_page.dart';
import '../../../articles/presentation/pages/article_create_page.dart';
import '../../../service/presentation/pages/care_my_pair_page.dart';
import '../../../auth/domain/usecases/get_valid_access_token.dart';
import '../../../../injection_container.dart';

const Color _kOnHeaderText = Color(0xFFDFE7E9);
const Color _kQuickActionMutedBg = Color(0xFFDFE7E9);
const Color _kQuickActionMutedText = Color(0xFF062F35);
const Color _kRackCardBorder = Color(0xFF0F6876);
const Color _kRackCardBg = Color(0xFFF0F0F0);
const Color _kSearchHintColor = Color(0x57000000);
const Color _kHeaderIconTint = Color(0xFFDFE7E9);
const String _kNotificationBellBodySvgAsset = 'assets/images/notification1.svg';
const String _kNotificationBellClapperSvgAsset = 'assets/images/notification2.svg';
const String _kHomeMapPinSvgAsset = 'assets/images/map-pin.svg';
const String _kCareMyPairIconAsset = 'assets/images/icons/home/caremypair.svg';
const String _kRentMyPairIconAsset = 'assets/images/icons/home/rentmypair.svg';
const String _kRehomeMyPairIconAsset = 'assets/images/icons/home/rehomemypair.svg';
const String _kMyRackMaximizeSvgAsset = 'assets/images/maximize.svg';

/// Vertical gaps inside the hero (greeting → location → search → stats).
const double _kHomeHeaderGreetingToLocation = 10;
const double _kHomeHeaderSearchToStats = 24;

/// Section spacing below hero / between blocks (12–16px).
const double _kSectionGap = 28;
const double _kRackThumbGap = 12;

/// Extra breathing room between "My Rack" and quick action tiles.
const double _kAfterRackToActionsGap = 22;

/// Tile height for quick actions (reference @ 390px width).
const double _kQuickActionCellHeight = 86;

/// Scales home chrome from a 390px-wide design frame so the same UI fits smaller devices.
double _homeUiScale(BuildContext context) {
  final w = MediaQuery.sizeOf(context).width;
  return (w / Responsive.designFrameWidth).clamp(0.72, 1.0);
}

/// Space to leave above the dashboard’s floating bottom nav (home tab is non-scrollable).
double _homeViewportBottomReserve(BuildContext context) {
  // Use view-based inset: with [Scaffold.extendBody], [MediaQuery.padding] on the
  // body can be 0 while Samsung still draws a gesture bar — avoid content under the pill.
  final safe = Responsive.physicalBottomInsetOf(context);
  const navOuterVertical = 20.0; // matches [dashboardBottomNavOuterInsets] vertical
  const gapAboveNav = 12.0;
  return safe +
      FloatingGradientBottomNav.barHeight +
      navOuterVertical +
      gapAboveNav;
}

/// Home Page — Figma `335:1687`; icons from [FigmaHomeAssets].
/// This is the landing tab shown to authenticated users on the main dashboard.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _currentAddress = '📍 Fetching location...';
  List<Article>? _rackArticles;
  bool _rackLoading = true;
  String? _rackError;

  @override
  void initState() {
    super.initState();
    _loadRackPreview();
    _getCurrentLocation();
    // If we ever show coords (e.g. from map), convert to address on load
    if (_looksLikeLatLong(_currentAddress)) {
      _latLongToAddress(_currentAddress).then((address) {
        if (mounted && address != _currentAddress) {
          setState(() => _currentAddress = address);
        }
      });
    }
  }

  /// Returns true if [text] looks like "lat, long" (e.g. "13.13210, 80.24567").
  bool _looksLikeLatLong(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return false;
    final parts = trimmed.split(',').map((s) => s.trim()).toList();
    if (parts.length != 2) return false;
    final lat = double.tryParse(parts[0]);
    final lng = double.tryParse(parts[1]);
    return lat != null &&
        lng != null &&
        lat >= -90 &&
        lat <= 90 &&
        lng >= -180 &&
        lng <= 180;
  }

  /// Converts "lat, long" to a human-readable address. Never returns raw coordinates.
  static const String _fallbackAddress = '📍 Your location';

  Future<String> _latLongToAddress(String text) async {
    if (!_looksLikeLatLong(text)) return text;
    final parts = text.split(',').map((s) => s.trim()).toList();
    final lat = double.tryParse(parts[0])!;
    final lng = double.tryParse(parts[1])!;
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isEmpty) return _fallbackAddress;
      Placemark p = placemarks[0];
      final locality =
          p.subLocality ?? p.locality ?? p.administrativeArea ?? '';
      final area = p.administrativeArea ?? p.country ?? '';
      if (locality.isEmpty && area.isEmpty) return _fallbackAddress;
      return '📍 ${[locality, area].where((e) => e.isNotEmpty).join(', ')}';
    } catch (_) {
      return _fallbackAddress;
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _currentAddress = '📍 Location services disabled');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _currentAddress = '📍 Location permission denied');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() => _currentAddress = '📍 Location permanently denied');
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          _currentAddress =
              '📍 ${place.subLocality ?? place.locality}, ${place.administrativeArea}';
        });
      } else {
        setState(() => _currentAddress = '📍 Location unavailable');
      }
    } catch (e) {
      setState(() => _currentAddress = '📍 Location unavailable');
    }
  }

  static String _articleImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    final base = ApiEndpoints.baseUrl;
    if (path.startsWith('/')) return '$base$path';
    return '$base/uploads/$path';
  }

  Future<void> _loadRackPreview() async {
    if (!mounted) return;
    setState(() {
      _rackLoading = true;
      _rackError = null;
    });

    final tokenResult = await sl<GetValidAccessToken>().call();
    if (!mounted) return;
    tokenResult.fold(
      (_) {
        if (!mounted) return;
        setState(() {
          _rackError = 'Sign in to see your rack';
          _rackArticles = null;
          _rackLoading = false;
        });
      },
      (token) async {
        try {
          final result = await sl<GetMyArticles>().call(token);
          if (!mounted) return;
          setState(() {
            _rackArticles = result;
            _rackLoading = false;
            _rackError = null;
          });
        } catch (e) {
          if (!mounted) return;
          setState(() {
            _rackError = e.toString().replaceFirst('Exception: ', '');
            _rackArticles = null;
            _rackLoading = false;
          });
        }
      },
    );
  }

  Widget _articleThumb(String url) {
    if (url.isEmpty) {
      return Container(
        color: const Color(0xFFE0E4E6),
        alignment: Alignment.center,
        child: const Icon(
          Icons.checkroom_outlined,
          color: AppColors.textTertiary,
          size: 28,
        ),
      );
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => Container(
        color: const Color(0xFFE0E4E6),
        alignment: Alignment.center,
        child: const Icon(
          Icons.checkroom_outlined,
          color: AppColors.textTertiary,
          size: 28,
        ),
      ),
    );
  }

  String get _pairsInRackDisplay {
    if (_rackLoading && _rackArticles == null) return '—';
    final n = _rackArticles?.length ?? 0;
    return n.toString().padLeft(2, '0');
  }

  void _openArticleList() {
    Navigator.of(context)
        .push<void>(
          MaterialPageRoute<void>(builder: (_) => const ArticleListPage()),
        )
        .then((_) {
          if (mounted) _loadRackPreview();
        });
  }

  void _openArticleDetails(Article article) {
    Navigator.of(context)
        .push<void>(
          MaterialPageRoute<void>(
            builder: (_) => ArticleDetailsPage(articleId: article.id),
          ),
        )
        .then((_) {
          if (mounted) _loadRackPreview();
        });
  }

  Future<void> _openServiceFlow({
    required String title,
    required List<String> allowedServiceTypes,
  }) async {
    final hasArticles = (_rackArticles?.isNotEmpty ?? false);
    if (!hasArticles) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add article first to continue')),
      );
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(builder: (_) => const ArticleCreatePage()),
      );
      if (mounted) {
        await _loadRackPreview();
      }
      return;
    }

    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => ArticleListPage(
          serviceFlowAllowedTypes: allowedServiceTypes,
          serviceFlowTitle: title,
        ),
      ),
    );
    if (mounted) {
      _loadRackPreview();
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isCompact = width < 360;
    final uiScale = _homeUiScale(context);
    final fabSize = (72 * uiScale).clamp(56.0, 72.0);
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const MobileOTPPage()),
            (route) => false,
          );
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final userName = state is AuthAuthenticated
              ? state.user.name
              : state is AuthProfileCompleted
              ? state.user.name
              : '';
          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle.light.copyWith(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.light,
            ),
            child: Scaffold(
              backgroundColor: AppColors.background,
              body: Stack(
                fit: StackFit.expand,
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final w = constraints.maxWidth;
                      final maxH = (constraints.maxHeight -
                              _homeViewportBottomReserve(context))
                          .clamp(120.0, double.infinity);
                      final heightScale = (maxH / 760).clamp(0.5, 1.0);
                      final layoutScale = math.min(uiScale, heightScale);

                      return Align(
                        alignment: Alignment.topCenter,
                        child: SizedBox(
                          width: w,
                          height: maxH,
                          child: Column(
                            mainAxisSize: MainAxisSize.max,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _HomeTopCard(
                                userName: userName,
                                currentAddress: _currentAddress,
                                pairsInRackDisplay: _pairsInRackDisplay,
                                layoutScale: layoutScale,
                                onLocationTap: () async {
                                  final profile = userProfileFromProfileState(
                                    context.read<ProfileBloc>().state,
                                  );
                                  final authState = context.read<AuthBloc>().state;
                                  final selected = await Navigator.of(context)
                                      .push<String>(
                                        MaterialPageRoute(
                                          builder: (_) => SelectLocationPage(
                                            profileBloc:
                                                context.read<ProfileBloc>(),
                                            initialAddress: _currentAddress,
                                            mapPinDisplayName: mapPinDisplayNameFrom(
                                              profile,
                                              authState,
                                            ),
                                            mapPinProfileImageRef:
                                                profile?.profileImage,
                                          ),
                                        ),
                                      );
                                  if (selected != null && mounted) {
                                    final addressText = _looksLikeLatLong(selected)
                                        ? await _latLongToAddress(selected)
                                        : selected.startsWith('📍')
                                        ? selected
                                        : '📍 $selected';
                                    if (mounted) {
                                      setState(
                                        () => _currentAddress = addressText,
                                      );
                                    }
                                  }
                                },
                              ),
                              Expanded(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal:
                                        Responsive.horizontalPaddingOf(context),
                                  ),
                                  child: Builder(
                                    builder: (context) {
                                      final actionH =
                                          (_kQuickActionCellHeight *
                                                  layoutScale)
                                              .clamp(44.0, 86.0);
                                      final midSpacer =
                                          (22 * layoutScale)
                                              .clamp(3.0, 22.0);
                                      return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      SizedBox(
                                        height: (_kSectionGap * layoutScale)
                                            .clamp(4.0, _kSectionGap),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Container(
                                        width: double.infinity,
                                        padding: EdgeInsets.fromLTRB(
                                          12 * layoutScale,
                                          14 * layoutScale,
                                          12 * layoutScale,
                                          16 * layoutScale,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _kRackCardBg,
                                          borderRadius: BorderRadius.circular(10),
                                          border: const Border(
                                            bottom: BorderSide(
                                              color: _kRackCardBorder,
                                              width: 3,
                                            ),
                                          ),
                                        ),
                                        child: LayoutBuilder(
                                          builder: (context, rackInner) {
                                            final innerH = rackInner.maxHeight;
                                            final gapLoose =
                                                (12 * uiScale * layoutScale)
                                                    .clamp(2.0, 12.0);
                                            final rackHeaderReserve =
                                                innerH < 88 ? 40.0 : 46.0;
                                            const minStrip = 1.0;
                                            final gapTight = (innerH -
                                                    rackHeaderReserve -
                                                    minStrip)
                                                .clamp(0.0, gapLoose);
                                            final headerGap =
                                                innerH < 88 ? gapTight : gapLoose;
                                            final compactRackHeader =
                                                innerH < 88;
                                            return Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Expanded(
                                                  child: Padding(
                                                    padding: EdgeInsets.only(
                                                      top: compactRackHeader
                                                          ? 4
                                                          : 10,
                                                      left: 16,
                                                      right: 4,
                                                    ),
                                                    child: Text(
                                                      'My Rack',
                                                      style:
                                                          GoogleFonts.boldonse(
                                                            fontSize:
                                                                compactRackHeader
                                                                    ? 14
                                                                    : 16,
                                                            fontWeight:
                                                                FontWeight.w400,
                                                            color:
                                                                _kQuickActionMutedText,
                                                            height: 1.05,
                                                          ),
                                                    ),
                                                  ),
                                                ),
                                                IconButton(
                                                  onPressed: _openArticleList,
                                                  tooltip: 'Digital Shoes Rack',
                                                  visualDensity:
                                                      VisualDensity.compact,
                                                  style: IconButton.styleFrom(
                                                    tapTargetSize:
                                                        MaterialTapTargetSize
                                                            .shrinkWrap,
                                                    minimumSize: Size(
                                                      compactRackHeader
                                                          ? 36
                                                          : 44,
                                                      compactRackHeader
                                                          ? 36
                                                          : 44,
                                                    ),
                                                    padding:
                                                        const EdgeInsets.only(
                                                      right: 8,
                                                    ),
                                                  ),
                                                  alignment: Alignment.topRight,
                                                  icon: SizedBox(
                                                    width: compactRackHeader
                                                        ? 20
                                                        : 24,
                                                    height: compactRackHeader
                                                        ? 20
                                                        : 24,
                                                    child: SvgPicture.asset(
                                                      _kMyRackMaximizeSvgAsset,
                                                      fit: BoxFit.contain,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            SizedBox(height: headerGap),
                                            Expanded(
                                              child: LayoutBuilder(
                                                builder: (context, stripBox) {
                                                  final idealStrip =
                                                      (80 * layoutScale).clamp(
                                                        42.0,
                                                        80.0,
                                                      );
                                                  final stripH = math.max(
                                                    1.0,
                                                    math.min(
                                                      idealStrip,
                                                      stripBox.maxHeight,
                                                    ),
                                                  );
                                                  return SizedBox(
                                                    height: stripH,
                                                    width: double.infinity,
                                                    child:
                                                        _rackLoading &&
                                                            _rackArticles ==
                                                                null
                                                        ? const Center(
                                                            child: SizedBox(
                                                              width: 24,
                                                              height: 24,
                                                              child:
                                                                  CircularProgressIndicator(
                                                                strokeWidth: 2,
                                                                color: AppColors
                                                                    .primary,
                                                              ),
                                                            ),
                                                          )
                                                        : _rackError != null
                                                        ? Center(
                                                            child: Text(
                                                              _rackError!,
                                                              textAlign:
                                                                  TextAlign
                                                                      .center,
                                                              maxLines: 2,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                              style: TextStyle(
                                                                fontSize: 12,
                                                                color: AppColors
                                                                    .textTertiary,
                                                              ),
                                                            ),
                                                          )
                                                        : (_rackArticles ==
                                                                      null ||
                                                                  _rackArticles!
                                                                      .isEmpty)
                                                        ? Center(
                                                            child: Text(
                                                              'No pairs yet — tap ↗ to open your rack',
                                                              textAlign:
                                                                  TextAlign
                                                                      .center,
                                                              style: TextStyle(
                                                                fontSize: 12,
                                                                color: AppColors
                                                                    .textTertiary,
                                                              ),
                                                            ),
                                                          )
                                                        : _RackThumbStrip(
                                                            articles:
                                                                _rackArticles!
                                                                    .take(3)
                                                                    .toList(),
                                                            gap:
                                                                _kRackThumbGap *
                                                                layoutScale,
                                                            onOpen:
                                                                _openArticleDetails,
                                                            articleImageUrl:
                                                                _articleImageUrl,
                                                            articleThumb:
                                                                _articleThumb,
                                                          ),
                                                  );
                                                },
                                              ),
                                            ),
                                          ],
                                        );
                                          },
                                        ),
                                      ),
                                      ),
                                      SizedBox(
                                        height:
                                            (_kAfterRackToActionsGap *
                                                    layoutScale)
                                                .clamp(
                                                  4.0,
                                                  _kAfterRackToActionsGap,
                                                ),
                                      ),
                                      _QuickActionCard(
                                        label: 'CareMyPair',
                                        highlight: true,
                                        fullWidth: true,
                                        iconAssetUrl: _kCareMyPairIconAsset,
                                        iconWidth:
                                            (48 * layoutScale).clamp(32.0, 48.0),
                                        iconHeight:
                                            (48 * layoutScale).clamp(32.0, 48.0),
                                        cellHeight:
                                            (_kQuickActionCellHeight *
                                                    layoutScale)
                                                .clamp(52.0, 86.0),
                                        onTap: () => Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const CareMyPairPage(),
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: midSpacer),
                                      Expanded(
                                        flex: 1,
                                        child: Align(
                                          alignment: Alignment.bottomCenter,
                                          child: SizedBox(
                                        height: actionH,
                                        child: Builder(
                                          builder: (_) {
                                            final rentIconW =
                                                (51 * layoutScale).clamp(
                                                  34.0,
                                                  51.0,
                                                );
                                            final rentIconH =
                                                (48 * layoutScale).clamp(
                                                  32.0,
                                                  48.0,
                                                );
                                            final rehomeIconW =
                                                (48 * layoutScale).clamp(
                                                  32.0,
                                                  48.0,
                                                );
                                            final rehomeIconH =
                                                (41 * layoutScale).clamp(
                                                  26.0,
                                                  41.0,
                                                );

                                            return Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.stretch,
                                              children: [
                                                Expanded(
                                                  child: _QuickActionCard(
                                                    label: 'Rent\nMyPair',
                                                    iconAssetUrl:
                                                        _kRentMyPairIconAsset,
                                                    iconWidth: rentIconW,
                                                    iconHeight: rentIconH,
                                                    cellHeight: actionH,
                                                  ),
                                                ),
                                                SizedBox(
                                                  width: (28 * layoutScale)
                                                      .clamp(6.0, 28.0),
                                                ),
                                                Expanded(
                                                  child: _QuickActionCard(
                                                    label: 'Rehome\nMyPair',
                                                    iconAssetUrl:
                                                        _kRehomeMyPairIconAsset,
                                                    iconWidth: rehomeIconW,
                                                    iconHeight: rehomeIconH,
                                                    cellHeight: actionH,
                                                    onTap: () =>
                                                        _openServiceFlow(
                                                          title:
                                                              'Select article for Rehome MyPair (Donate, Dispose)',
                                                          allowedServiceTypes:
                                                              const [
                                                                'donate',
                                                                'dispose',
                                                              ],
                                                        ),
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                        ),
                                          ),
                                        ),
                                      ),
                                    ],
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  // // Floating chatbot entry — pushes [ChatbotPage] for in-app support chat.
                  // Positioned(
                  //   right: isCompact ? 10 : 14,
                  //   bottom: isCompact ? 90 : 60,
                  //   child: Material(
                  //     color: Colors.transparent,
                  //     child: InkWell(
                  //       borderRadius: BorderRadius.circular(40),
                  //       onTap: () {
                  //         Navigator.of(context).push(
                  //           MaterialPageRoute(
                  //             builder: (_) => const ChatbotPage(),
                  //           ),
                  //         );
                  //       },
                  //       child: Container(
                  //         width: fabSize,
                  //         height: fabSize,
                  //         decoration: BoxDecoration(
                  //           shape: BoxShape.circle,
                  //           gradient: LinearGradient(
                  //             begin: const Alignment(1, 0.2),
                  //             end: const Alignment(-0.4, 1),
                  //             colors: [
                  //               AppColors.primary,
                  //               AppColors.footwearHeroEnd,
                  //             ],
                  //           ),
                  //           boxShadow: [
                  //             BoxShadow(
                  //               color: Color(0x1A000000),
                  //               blurRadius: 4,
                  //               offset: Offset(0, 4),
                  //             ),
                  //           ],
                  //         ),
                  //         child: Center(
                  //           child: Padding(
                  //             padding: const EdgeInsets.all(12),
                  //             child: Image.asset(
                  //               'assets/images/chat.png',
                  //               fit: BoxFit.contain,
                  //             ),
                  //           ),
                  //         ),
                  //       ),
                  //     ),
                  //   ),
                  // ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

double _homeHeaderChromeScale(BuildContext context) {
  return (MediaQuery.sizeOf(context).width / 430).clamp(0.85, 1.15).toDouble();
}

/// Notification bell — top row with greeting (Figma row 1).
class _HomeHeaderBell extends StatelessWidget {
  final VoidCallback onTap;

  const _HomeHeaderBell({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = _homeHeaderChromeScale(context);
    final bellSize = (54.0 * s).clamp(48.0, 58.0);
    final bellPad = (12.0 * s).clamp(9.0, 14.0);
    final bellBodyW = (21.0 * s).clamp(17.0, 24.0);
    final bellBodyH = (17.5 * s).clamp(14.0, 20.0);
    final bellClapperW = (11.5 * s).clamp(9.0, 14.0);
    final bellClapperH = (6.0 * s).clamp(5.0, 8.0);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: bellSize,
        height: bellSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.14),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: EdgeInsets.all(bellPad),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.38),
                    Colors.white.withValues(alpha: 0.14),
                  ],
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.55),
                  width: 1,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      _kNotificationBellBodySvgAsset,
                      width: bellBodyW,
                      height: bellBodyH,
                      fit: BoxFit.contain,
                    ),
                    Transform.translate(
                      offset: Offset(0, 2 * s),
                      child: SvgPicture.asset(
                        _kNotificationBellClapperSvgAsset,
                        width: bellClapperW,
                        height: bellClapperH,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Overlapping profile avatars — same row as location (Figma row 2).
class _HomeProfileAvatarStack extends StatelessWidget {
  final String? imageUrl;
  final VoidCallback onTap;

  const _HomeProfileAvatarStack({
    required this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final s = _homeHeaderChromeScale(context);
    final rLarge = 32.0 * s;
    final rSmall = 20.0 * s;
    final stackH = 84.0 * s;
    final smallInset = (2 * s).clamp(0.0, 4.0);
    // Large + small column almost tangent: tiny [kiss] only so borders read as touching, not stacked deep.
    final kiss = (2 * s).clamp(0.0, 3.5);
    final stackW = math.max(
      2 * rLarge + 2 * rSmall + smallInset - kiss,
      2 * rLarge + 6,
    );
    final smallStagger = (5 * s).clamp(3.0, 8.0);

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: stackW,
        height: stackH,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 0,
              top: (stackH - (rLarge * 2)) / 2,
              child: _avatarRing(radius: rLarge, imageUrl: imageUrl),
            ),
            Positioned(
              right: smallInset,
              top: 0,
              child: _avatarRing(
                radius: rSmall,
                imageUrl: imageUrl,
                isSmall: true,
              ),
            ),
            Positioned(
              right: smallInset + smallStagger,
              bottom: 0,
              child: _avatarRing(
                radius: rSmall,
                imageUrl: null,
                isSmall: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _avatarRing({
    required double radius,
    required String? imageUrl,
    bool isSmall = false,
  }) {
    final url = imageUrl;
    final hasImage = url != null && url.isNotEmpty;
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: radius,
        backgroundColor: Colors.white24,
        backgroundImage: hasImage ? NetworkImage(url) : null,
        child: hasImage
            ? null
            : Icon(
                Icons.person_rounded,
                size: isSmall ? 18 : 34,
                color: Colors.white,
              ),
      ),
    );
  }
}

class _HomeTopCard extends StatelessWidget {
  final String userName;
  final String currentAddress;
  final String pairsInRackDisplay;
  final Future<void> Function() onLocationTap;
  final double layoutScale;

  const _HomeTopCard({
    required this.userName,
    required this.currentAddress,
    required this.pairsInRackDisplay,
    required this.onLocationTap,
    this.layoutScale = 1.0,
  });

  static String _addressLineForHome(String raw) {
    final s = raw.replaceFirst(RegExp(r'^📍\s*'), '').trim();
    if (s.isEmpty) return 'HSR Layout, Bangalore';
    return s;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 360;
    final s = _homeUiScale(context) * layoutScale;
    final greetingName = userName.isEmpty ? 'Aashi' : userName;
    final horizontal = Responsive.horizontalPaddingOf(context);
    final headerHorizontal = (horizontal - 4).clamp(12.0, horizontal);
    final addressLine = _addressLineForHome(currentAddress);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        headerHorizontal,
        (76 * layoutScale).clamp(44.0, 88.0),
        headerHorizontal,
        (22 * layoutScale).clamp(10.0, 26.0),
      ),
      decoration: BoxDecoration(
        gradient: AppColors.figma825AngularSweep,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0xFFABABAB),
            blurRadius: 12,
            offset: Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  'Hello, $greetingName!',
                  textAlign: TextAlign.left,
                  style: GoogleFonts.boldonse(
                    fontSize:
                        ((compact ? 20.0 : 24.0) * s).clamp(13.0, 24.0),
                    fontWeight: FontWeight.w400,
                    color: _kOnHeaderText,
                    height: 1.1,
                  ),
                ),
              ),
              _HomeHeaderBell(
                onTap: () {
                  final profileBloc = context.read<ProfileBloc>();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => BlocProvider.value(
                        value: profileBloc,
                        child: const ProfilePage(),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          SizedBox(
            height: (_kHomeHeaderGreetingToLocation * s).clamp(4.0, 16.0),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: onLocationTap,
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: (24 * s).clamp(14.0, 24.0),
                        height: (24 * s).clamp(14.0, 24.0),
                        child: SvgPicture.asset(
                          _kHomeMapPinSvgAsset,
                          fit: BoxFit.contain,
                          colorFilter: const ColorFilter.mode(
                            _kHeaderIconTint,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                      SizedBox(width: (10 * s).clamp(4.0, 10.0)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Home',
                                  style: GoogleFonts.montserrat(
                                    fontSize: (14 * s).clamp(10.0, 14.0),
                                    fontWeight: FontWeight.w600,
                                    color: _kOnHeaderText,
                                    height: 1.15,
                                  ),
                                ),
                                SizedBox(width: (4 * s).clamp(2.0, 4.0)),
                                SizedBox(
                                  width: (14 * s).clamp(10.0, 14.0),
                                  height: (14 * s).clamp(10.0, 14.0),
                                  child: Image.network(
                                    FigmaHomeAssets.chevronRight,
                                    fit: BoxFit.contain,
                                    color: _kHeaderIconTint,
                                    colorBlendMode: BlendMode.srcIn,
                                    errorBuilder: (_, _, _) => Icon(
                                      Icons.chevron_right_rounded,
                                      size: (16 * s).clamp(11.0, 16.0),
                                      color: _kOnHeaderText,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: (2 * s).clamp(1.0, 2.0)),
                            Text(
                              addressLine,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.montserrat(
                                fontSize:
                                    ((compact ? 14.0 : 16.0) * s).clamp(
                                      10.0,
                                      16.0,
                                    ),
                                fontWeight: FontWeight.w300,
                                color: _kOnHeaderText,
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: (8 * s).clamp(6.0, 12.0)),
              BlocBuilder<ProfileBloc, ProfileState>(
                buildWhen: (prev, curr) =>
                    curr is ProfileLoaded ||
                    curr is ProfileUpdating ||
                    curr is ProfileImageUploading,
                builder: (context, profileState) {
                  final profile = profileState is ProfileLoaded
                      ? profileState.profile
                      : profileState is ProfileUpdating
                      ? profileState.profile
                      : profileState is ProfileImageUploading
                      ? profileState.profile
                      : null;
                  final imageUrl = profile?.profileImage;
                  return _HomeProfileAvatarStack(
                    imageUrl: imageUrl,
                    onTap: () {
                      final profileBloc = context.read<ProfileBloc>();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => BlocProvider.value(
                            value: profileBloc,
                            child: const ProfilePage(),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
          SizedBox(height: (14 * s).clamp(6.0, 18.0)),
          Padding(
            padding: EdgeInsets.symmetric(vertical: (2 * s).clamp(0.0, 6.0)),
            child: Container(
              height: (46 * s).clamp(32.0, 48.0),
              padding: EdgeInsets.symmetric(horizontal: (16 * s).clamp(12.0, 20.0)),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              alignment: Alignment.centerLeft,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: (24 * s).clamp(14.0, 24.0),
                    height: (24 * s).clamp(14.0, 24.0),
                    child: Image.network(
                      FigmaHomeAssets.search,
                      fit: BoxFit.contain,
                      color: _kSearchHintColor,
                      colorBlendMode: BlendMode.srcIn,
                      errorBuilder: (_, _, _) => Icon(
                        Icons.search,
                        size: (24 * s).clamp(14.0, 24.0),
                        color: _kSearchHintColor,
                      ),
                    ),
                  ),
                  SizedBox(width: 10 * s),
                  Expanded(
                    child: Text(
                      'Search',
                      style: GoogleFonts.montserrat(
                        fontSize: (16 * s).clamp(10.0, 16.0),
                        fontWeight: FontWeight.w400,
                        color: _kSearchHintColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: (_kHomeHeaderSearchToStats * s).clamp(14.0, 30.0)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: (5 * s).clamp(3.0, 8.0),
                  ),
                  child: _StatItem(
                    value: pairsInRackDisplay,
                    labelLine1: 'Pairs in',
                    labelLine2: 'your rack',
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: (5 * s).clamp(3.0, 8.0),
                  ),
                  child: const _StatItem(
                    value: '05',
                    labelLine1: 'Pairs',
                    labelLine2: 'Donated',
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: (5 * s).clamp(3.0, 8.0),
                  ),
                  child: const _StatItem(
                    value: '00',
                    labelLine1: 'Pairs',
                    labelLine2: 'Sold',
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: (5 * s).clamp(3.0, 8.0),
                  ),
                  child: const _StatItem(
                    value: '02',
                    labelLine1: 'Pairs in',
                    labelLine2: 'Care',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String labelLine1;
  final String labelLine2;

  const _StatItem({
    required this.value,
    required this.labelLine1,
    required this.labelLine2,
  });

  @override
  Widget build(BuildContext context) {
    final s = _homeUiScale(context);
    final narrow = MediaQuery.sizeOf(context).width < 360;
    final valueSize = ((narrow ? 28.0 : 32.0) * s).clamp(22.0, 32.0);
    final labelSize = (14 * s).clamp(10.0, 14.0);
    final labelStyle = GoogleFonts.montserrat(
      fontSize: labelSize,
      fontWeight: FontWeight.w400,
      color: _kOnHeaderText,
      height: 1.15,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        return FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: constraints.maxWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.boldonse(
                    fontSize: valueSize,
                    fontWeight: FontWeight.w400,
                    color: _kOnHeaderText,
                    height: 1,
                  ),
                ),
                SizedBox(height: (11 * s).clamp(6.0, 14.0)),
                Text(
                  labelLine1,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: labelStyle,
                ),
                Text(
                  labelLine2,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: labelStyle,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Horizontal rack preview with even gaps; scrolls when many items.
class _RackThumbStrip extends StatelessWidget {
  const _RackThumbStrip({
    required this.articles,
    required this.gap,
    required this.onOpen,
    required this.articleImageUrl,
    required this.articleThumb,
  });

  final List<Article> articles;
  final double gap;
  final void Function(Article article) onOpen;
  final String Function(String?) articleImageUrl;
  final Widget Function(String url) articleThumb;

  @override
  Widget build(BuildContext context) {
    if (articles.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // If there are only a few pairs, distribute them so spacing feels
        // natural; if there are many pairs, keep a consistent width and scroll.
        final len = articles.length;
        final fitCount = len <= 4 ? len : 4;
        final rackHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : 80.0;
        final tileWidth =
            ((constraints.maxWidth - gap * (fitCount - 1)) / fitCount);

        return ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.zero,
          itemCount: len,
          separatorBuilder: (context, _) => SizedBox(width: gap),
          itemBuilder: (context, index) {
            final article = articles[index];
            final url = articleImageUrl(article.thumbnailImage);
            return SizedBox(
              width: tileWidth,
              height: rackHeight,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => onOpen(article),
                  borderRadius: BorderRadius.circular(12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: tileWidth,
                      height: rackHeight,
                      child: articleThumb(url),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final String label;
  final String? iconAssetUrl;
  final double iconWidth;
  final double iconHeight;
  final double? cellHeight;
  final bool highlight;
  final VoidCallback? onTap;
  final bool fullWidth;

  const _QuickActionCard({
    required this.label,
    this.iconAssetUrl,
    this.iconWidth = 24,
    this.iconHeight = 24,
    this.cellHeight,
    this.highlight = false,
    this.onTap,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final s = (MediaQuery.sizeOf(context).width / 430).clamp(0.85, 1.15).toDouble();
    final isTwoLine = label.contains('\n');
    final textColor = highlight ? Colors.white : _kQuickActionMutedText;
    final resolvedHeight =
        cellHeight ??
        (isTwoLine
            ? (_kQuickActionCellHeight + 28) * s
            : _kQuickActionCellHeight * s);
    final padding = highlight
        ? EdgeInsets.fromLTRB(18 * s, 8 * s, 18 * s, 8 * s)
        : EdgeInsets.symmetric(
            horizontal: 12 * s,
            vertical: (isTwoLine ? 10 : 8) * s,
          );
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: resolvedHeight,
          padding: padding,
          decoration: BoxDecoration(
            color: highlight ? null : _kQuickActionMutedBg,
            gradient: highlight
                ? LinearGradient(
                    begin: const Alignment(1, 0.5),
                    end: const Alignment(0, 0.5),
                    colors: [
                      AppColors.primaryLight,
                      AppColors.footwearHeroStart,
                    ],
                  )
                : null,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: iconWidth,
                height: iconHeight,
                child: _buildActionIcon(textColor),
              ),
              SizedBox(width: (fullWidth ? 20 : 14) * s),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    label,
                    maxLines: 2,
                    textAlign: TextAlign.left,
                    style: GoogleFonts.boldonse(
                      fontSize: ((MediaQuery.sizeOf(context).width < 360
                              ? 14.0
                              : 16.0) *
                          s)
                          .clamp(11.0, 16.0),
                      fontWeight: FontWeight.w400,
                      color: textColor,
                      height: isTwoLine ? 1.45 : 1.10,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionIcon(Color textColor) {
    final source = iconAssetUrl;
    if (source == null || source.isEmpty) {
      return Icon(
        Icons.widgets_outlined,
        size: 24,
        color: textColor,
      );
    }

    if (source.startsWith('http://') || source.startsWith('https://')) {
      return Image.network(
        source,
        fit: BoxFit.contain,
        color: textColor,
        colorBlendMode: BlendMode.srcIn,
        errorBuilder: (_, _, _) => Icon(
          Icons.widgets_outlined,
          size: 24,
          color: textColor,
        ),
      );
    }

    return SvgPicture.asset(
      source,
      fit: BoxFit.contain,
      colorFilter: ColorFilter.mode(textColor, BlendMode.srcIn),
    );
  }
}
