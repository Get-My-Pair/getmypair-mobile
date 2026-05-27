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
import '../../../../core/widgets/app_feedback_alert.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/floating_gradient_bottom_nav.dart';
import '../../../auth/domain/usecases/get_valid_access_token.dart';
import '../../../profile/presentation/bloc/profile_bloc.dart';
import '../../../profile/presentation/bloc/profile_state.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../../../profile/presentation/utils/saved_location_sync.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'select_location_page.dart';
import '../../../articles/domain/entities/article.dart';
import '../../../articles/domain/usecases/get_my_articles.dart';
import '../../../articles/presentation/pages/article_details_page.dart';
import '../../../articles/presentation/pages/article_list_page.dart';
import '../../../service/presentation/pages/care_my_pair_page.dart';
import '../../../service/presentation/pages/rehome_my_pair_page.dart';
import '../../../../injection_container.dart';

/// Header copy on teal gradient — white for legibility (avoid washed-out light gray).
const Color _kOnHeaderText = Color(0xFFFFFFFF);
const Color _kOnHeaderTextMuted = Color(0xFFE8F4F6);
const Color _kQuickActionMutedBg = Color(0xFFDFE7E9);
const Color _kQuickActionMutedText = Color(0xFF062F35);
const Color _kRackCardBorderStart = Color(0xFF0F6876);
const Color _kRackCardEdgeLight = _kRackCardBorderStart;
const double _kRackCardRadius = 10;
/// My Rack top corners only — fill/clip, no accent line.
const BorderRadius _kRackCardTopRadius = BorderRadius.only(
  topLeft: Radius.circular(_kRackCardRadius),
  topRight: Radius.circular(_kRackCardRadius),
);
/// My Rack bottom corners — teal accent border follows this curve.
const BorderRadius _kRackCardBottomRadius = BorderRadius.only(
  bottomLeft: Radius.circular(_kRackCardRadius),
  bottomRight: Radius.circular(_kRackCardRadius),
);
/// Bottom edge only — avoids a teal hairline when top corners are rounded.
const Border _kRackCardBottomAccentBorder = Border(
  top: BorderSide.none,
  left: BorderSide.none,
  right: BorderSide.none,
  bottom: BorderSide(
    color: _kRackCardEdgeLight,
    width: 3,
  ),
);

BorderRadius _rackCardClipRadius() => BorderRadius.only(
      topLeft: _kRackCardTopRadius.topLeft,
      topRight: _kRackCardTopRadius.topRight,
      bottomLeft: _kRackCardBottomRadius.bottomLeft,
      bottomRight: _kRackCardBottomRadius.bottomRight,
    );
/// My Rack panel fill — design `#F0F0F0`.
const Color _kRackCardBg = Color(0xFFE6E6E6);
/// Secondary copy on light rack panel — darker than [AppColors.textTertiary].
const Color _kRackMutedText = Color(0xFF4E7F8A);
const Color _kSearchHintColor = Color(0xFF5C6E73);
const Color _kHeaderIconTint = Color(0xFFFFFFFF);
const String _kNotificationBellSvgAsset =
    'assets/images/allicons/bell icon.svg';
const String _kHomeMapPinSvgAsset = 'assets/images/allicons/map-pin.svg';
const String _kCareMyPairIconAsset = 'assets/images/icons/home/caremypair.svg';
const String _kRentMyPairIconAsset = 'assets/images/icons/home/rentmypair.svg';
const String _kRehomeMyPairIconAsset =
    'assets/images/icons/home/rehomemypair.svg';
const String _kMyRackMaximizeSvgAsset = 'assets/images/allicons/maximize.svg';
const String _kHomeHeaderBgAsset = 'assets/images/bg/home.png';

/// Vertical gaps inside the hero (location → search → stats → bottom).
const double _kHomeHeaderSearchToStats = 30;
const double _kHomeHeaderStatsToBottom = 14;
/// Bottom corner radius on the hero card.
const double _kHomeHeaderBottomRadius = 20;
/// Visible gap between the hero bottom curve and the My Rack card.
const double _kHomeHeaderToRackGap = 14;

/// Tile height for quick actions (reference @ 390px width).
const double _kQuickActionCellHeight = 78;

/// Scales home chrome from a 390px-wide design frame so the same UI fits smaller devices.
double _homeUiScale(BuildContext context) {
  final w = MediaQuery.sizeOf(context).width;
  return (w / Responsive.designFrameWidth).clamp(0.72, 1.0);
}

/// Vertical gap between the location row and the search field: design scale plus a
/// fraction of screen height so tall/narrow devices keep similar visual balance.
double _homeLocationToSearchGap(BuildContext context, double s) {
  final h = MediaQuery.sizeOf(context).height;
  // Base + small % of height; kept tight; scales down on narrow phones via [s].
  return ((16 * s) + (h * 0.01)).clamp(16.0, 28.0);
}

/// Search bar height: scales with [s] and grows slightly on taller viewports.
double _homeSearchBarHeight(BuildContext context, double s) {
  final h = MediaQuery.sizeOf(context).height;
  return ((48 * s) + (h * 0.006)).clamp(36.0, 58.0);
}

/// Responsive horizontal crop for header image to avoid side seams/gaps.
/// Tuned for common mobile widths (10+ buckets).
double _homeHeaderScaleXForWidth(double width) {
  if (width <= 320) return 1.16;
  if (width <= 340) return 1.14;
  if (width <= 360) return 1.13;
  if (width <= 375) return 1.12;
  if (width <= 390) return 1.11;
  if (width <= 400) return 1.10;
  if (width <= 412) return 1.095;
  if (width <= 430) return 1.09;
  if (width <= 480) return 1.08;
  if (width <= 520) return 1.07;
  return 1.06;
}

/// Space to leave above the dashboard’s floating bottom nav (home tab is non-scrollable).
double _homeViewportBottomReserve(BuildContext context) {
  final size = MediaQuery.sizeOf(context);
  final navInsets = dashboardBottomNavOuterInsets(context);
  final gapAboveNav = (size.height * 0.0002).clamp(0.0, 0.25);
  // Ultra-tight reserve so lower cards sit almost flush above nav.
  return (FloatingGradientBottomNav.barHeight * 0.26) +
      (navInsets.bottom * 0.12) +
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
  AddressParts? _detectedLocationParts;
  bool _locationSavePromptHandled = false;

  static String _formatPlacemarkForHomeHeader(Placemark p) {
    final subLocality = p.subLocality?.trim();
    final locality = p.locality?.trim();
    final administrativeArea = p.administrativeArea?.trim();

    // If we have a neighborhood (e.g. Mylapore), show only that.
    if (subLocality != null && subLocality.isNotEmpty) {
      final sLower = subLocality.toLowerCase();
      if (sLower == 'mylapore' || sLower == 'mylapur') {
        return '📍 Mylapur';
      }
      return '📍 $subLocality';
    }

    // Otherwise show only the main area name (e.g. Chennai).
    if (locality != null && locality.isNotEmpty) {
      return '📍 $locality';
    }

    if (administrativeArea != null && administrativeArea.isNotEmpty) {
      return '📍 $administrativeArea';
    }

    return _fallbackAddress;
  }

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
      return _formatPlacemarkForHomeHeader(p);
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
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        _detectedLocationParts = AddressParts.fromPlacemark(place);
        setState(() {
          _currentAddress = _formatPlacemarkForHomeHeader(place);
        });
        _maybePromptSaveDetectedLocation();
      } else {
        setState(() => _currentAddress = '📍 Location unavailable');
      }
    } catch (e) {
      setState(() => _currentAddress = '📍 Location unavailable');
    }
  }

  Future<void> _maybePromptSaveDetectedLocation() async {
    if (_locationSavePromptHandled || _detectedLocationParts == null) return;

    final profile =
        userProfileFromProfileState(context.read<ProfileBloc>().state);
    if (profile == null) return;

    _locationSavePromptHandled = true;

    final tokenResult = await sl<GetValidAccessToken>().call();
    if (!mounted) return;
    await tokenResult.fold(
      (_) async {},
      (token) => SavedLocationSync.maybePersist(
        context: context,
        profileBloc: context.read<ProfileBloc>(),
        accessToken: token,
        parts: _detectedLocationParts!,
        addresses: profile.addresses,
      ),
    );
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
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Container(
          color: _kRackCardBg,
          alignment: Alignment.center,
          child: const Icon(
            Icons.checkroom_outlined,
            color: _kRackMutedText,
            size: 28,
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Image.network(
        url,
        errorBuilder: (_, _, _) => const Center(
          child: Icon(
            Icons.checkroom_outlined,
            color: _kRackMutedText,
            size: 28,
          ),
        ),
        fit: BoxFit.contain,
        alignment: Alignment.center,
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
            builder: (_) => ArticleDetailsPage(
              articleId: article.id,
              initialArticle: article,
            ),
          ),
        )
        .then((_) {
          if (mounted) _loadRackPreview();
        });
  }

  @override
  Widget build(BuildContext context) {
    final uiScale = _homeUiScale(context);
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const MobileOTPPage()),
            (route) => false,
          );
        }
      },
      child: BlocListener<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state is ProfileLoaded || state is AddressActionLoading) {
            _maybePromptSaveDetectedLocation();
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
                      final maxH =
                          (constraints.maxHeight -
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
                                    final authState = context
                                        .read<AuthBloc>()
                                        .state;
                                    final selected = await Navigator.of(context)
                                        .push<String>(
                                          MaterialPageRoute(
                                            builder: (_) => SelectLocationPage(
                                              profileBloc: context
                                                  .read<ProfileBloc>(),
                                              initialAddress: _currentAddress,
                                              mapPinDisplayName:
                                                  mapPinDisplayNameFrom(
                                                    profile,
                                                    authState,
                                                  ),
                                              mapPinProfileImageRef:
                                                  profile?.profileImage,
                                            ),
                                          ),
                                        );
                                    if (selected != null && mounted) {
                                      final addressText =
                                          _looksLikeLatLong(selected)
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
                                        (Responsive.horizontalPaddingOf(
                                                  context,
                                                ) -
                                                4)
                                            .clamp(10.0, 20.0),
                                  ),
                                  child: LayoutBuilder(
                                    builder: (context, bodyConstraints) {
                                      final bodyH = bodyConstraints.maxHeight;
                                      final headerToRackGap =
                                          (_kHomeHeaderToRackGap * layoutScale)
                                              .clamp(10.0, 18.0);
                                      final rackCardTopPaddingLoose =
                                          (64 * layoutScale).clamp(16.0, 26.0);
                                      final rackCardBottomPadding =
                                          (7 * layoutScale).clamp(5.0, 7.0);
                                      final showRackThumbs = !_rackLoading &&
                                          _rackError == null &&
                                          _rackArticles != null &&
                                          _rackArticles!.isNotEmpty;
                                      final rackCardTopPadding = showRackThumbs
                                          ? ((20 * layoutScale).clamp(14.0, 23.0))
                                          : rackCardTopPaddingLoose;
                                      // Keep loading/empty/error card height aligned with
                                      // the loaded rack card so the section does not jump.
                                      // Thumb row allowance + clamps tuned so the rack card
                                      // reads taller; same value when empty/loading so height
                                      // does not jump when articles appear.
                                      final rackLoadingHeight =
                                          (rackCardTopPaddingLoose +
                                                  24 +
                                                  1 +
                                                  76 +
                                                  rackCardBottomPadding)
                                              .clamp(118.0, 146.0);
                                      final rackHeight = rackLoadingHeight;
                                      final uniformCardGap = (bodyH * 0.026)
                                          .clamp(10.0, 16.0);
                                      final careCardH = (bodyH * 0.2).clamp(
                                        56.0,
                                        96.0,
                                      );
                                      final midSpacer = uniformCardGap;
                                      final actionH = (bodyH * 0.2).clamp(
                                        56.0,
                                        96.0,
                                      );
                                      final rackClipRadius = _rackCardClipRadius();
                                      return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          SizedBox(height: headerToRackGap),
                                          SizedBox(
                                            height: rackHeight,
                                            child: ClipRRect(
                                              borderRadius: rackClipRadius,
                                              clipBehavior: Clip.hardEdge,
                                              child: Container(
                                                width: double.infinity,
                                                decoration: const BoxDecoration(
                                                  color: _kRackCardBg,
                                                  border:
                                                      _kRackCardBottomAccentBorder,
                                                  // Bottom radius only — top stays clean.
                                                  borderRadius:
                                                      _kRackCardBottomRadius,
                                                ),
                                                child: Stack(
                                                  children: [
                                                    Padding(
                                                      padding:
                                                          EdgeInsets.fromLTRB(
                                                        14,
                                                        rackCardTopPadding,
                                                        14,
                                                        rackCardBottomPadding,
                                                      ),
                                                      child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .stretch,
                                                      children: [
                                                        Row(
                                                          children: [
                                                            Text(
                                                              'My Rack',
                                                              style: GoogleFonts.boldonse(
                                                                fontSize: 16,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w400,
                                                                color: const Color(
                                                                  0xFF062F35,
                                                                ),
                                                              ),
                                                            ),
                                                            const Spacer(),
                                                            SizedBox(
                                                              width: 24,
                                                              height: 24,
                                                              child: IconButton(
                                                                onPressed:
                                                                    _openArticleList,
                                                                tooltip:
                                                                    'Digital Shoes Rack',
                                                                padding:
                                                                    EdgeInsets
                                                                        .zero,
                                                                constraints:
                                                                    const BoxConstraints(
                                                                      minWidth:
                                                                          24,
                                                                      minHeight:
                                                                          24,
                                                                    ),
                                                                icon:
                                                                    SvgPicture.asset(
                                                                  _kMyRackMaximizeSvgAsset,
                                                                  fit: BoxFit
                                                                      .contain,
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        SizedBox(
                                                          height: showRackThumbs
                                                              ? (12 * layoutScale)
                                                                  .clamp(
                                                                    10.0,
                                                                    18.0,
                                                                  )
                                                              : (8 * layoutScale)
                                                                  .clamp(
                                                                    6.0,
                                                                    10.0,
                                                                  ),
                                                        ),
                                                        if (_rackLoading &&
                                                            _rackArticles == null)
                                                          Expanded(
                                                            child: Center(
                                                              child: SizedBox(
                                                                width: 24,
                                                                height: 24,
                                                                child:
                                                                    CircularProgressIndicator(
                                                                  strokeWidth:
                                                                      2,
                                                                  color: AppColors
                                                                      .primary,
                                                                ),
                                                              ),
                                                            ),
                                                          )
                                                        else if (_rackError !=
                                                            null)
                                                          Expanded(
                                                            child: Center(
                                                              child: Text(
                                                                _rackError!,
                                                                textAlign:
                                                                    TextAlign
                                                                        .center,
                                                                maxLines: 2,
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                                style:
                                                                    const TextStyle(
                                                                  fontSize: 12,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500,
                                                                  color:
                                                                      _kRackMutedText,
                                                                ),
                                                              ),
                                                            ),
                                                          )
                                                        else if (_rackArticles ==
                                                                null ||
                                                            _rackArticles!
                                                                .isEmpty)
                                                          Expanded(
                                                            child: const Center(
                                                              child: Text(
                                                                'No pairs yet — tap ↗ to open your rack',
                                                                textAlign:
                                                                    TextAlign
                                                                        .center,
                                                                style: TextStyle(
                                                                  fontSize: 12,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500,
                                                                  color:
                                                                      _kRackMutedText,
                                                                ),
                                                              ),
                                                            ),
                                                          )
                                                        else
                                                          Expanded(
                                                            child: Align(
                                                              alignment: Alignment
                                                                  .bottomCenter,
                                                              child:
                                                                  _RackThumbStrip(
                                                                articles:
                                                                    _rackArticles!
                                                                        .take(3)
                                                                        .toList(),
                                                                gap: 10,
                                                                onOpen:
                                                                    _openArticleDetails,
                                                                articleImageUrl:
                                                                    _articleImageUrl,
                                                                articleThumb:
                                                                    _articleThumb,
                                                              ),
                                                            ),
                                                          ),
                                                      ],
                                                    ),
                                                  ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: uniformCardGap),
                                          _QuickActionCard(
                                            label: 'CareMyPair',
                                            highlight: true,
                                            fullWidth: true,
                                            iconAssetUrl: _kCareMyPairIconAsset,
                                            iconWidth: (48 * layoutScale).clamp(
                                              32.0,
                                              48.0,
                                            ),
                                            iconHeight: (48 * layoutScale)
                                                .clamp(32.0, 48.0),
                                            cellHeight: careCardH,
                                            onTap: () =>
                                                Navigator.of(context).push(
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        const CareMyPairPage(),
                                                  ),
                                                ),
                                          ),
                                          SizedBox(height: midSpacer),
                                          SizedBox(
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
                                                      CrossAxisAlignment
                                                          .stretch,
                                                  children: [
                                                    Expanded(
                                                      child: _QuickActionCard(
                                                        label: 'Rent\nMyPair',
                                                        grayed: true,
                                                        iconAssetUrl:
                                                            _kRentMyPairIconAsset,
                                                        iconWidth: rentIconW,
                                                        iconHeight: rentIconH,
                                                        cellHeight: actionH,
                                                        onTap: () =>
                                                            showComingSoon(
                                                          context,
                                                          feature: 'Rent MyPair',
                                                        ),
                                                      ),
                                                    ),
                                                    SizedBox(
                                                      width: (12 * layoutScale)
                                                          .clamp(6.0, 16.0),
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
                                                            Navigator.of(context).push(
                                                          MaterialPageRoute<void>(
                                                            builder: (_) =>
                                                                const RehomeMyPairPage(),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
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
                  //               'assets/images/allicons/chat.png',
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
    final bellSize = (32.0 * s).clamp(28.0, 38.0);
    final bellPadH = (4.0 * s).clamp(3.0, 5.5);
    final bellPadV = (4.0 * s).clamp(3.0, 5.5);
    final bellIconW = (18.0 * s).clamp(16.0, 22.0);
    final bellIconH = bellIconW * (16 / 14);

    // Glass chrome — scaled from header scale [s] so blur, rim, and lift stay proportional.
    final blurSigma = (14.0 * s).clamp(11.0, 18.0);
    final rimW = (1.0 * s).clamp(0.85, 1.25);
    final liftBlur = (9.0 * s).clamp(7.0, 12.0);
    final liftY = (3.0 * s).clamp(2.5, 4.5);
    final haloBlur = (6.0 * s).clamp(4.5, 9.0);
    final rimHighlightBlur = (2.0 * s).clamp(1.0, 3.0);

    return GestureDetector(
      onTap: onTap,
      child: RepaintBoundary(
        child: Container(
          width: bellSize,
          height: bellSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              // Primary float — cool-tinted shadow reads on gradients and light UI.
              BoxShadow(
                color: const Color(0xFF0A2540).withValues(alpha: 0.20),
                blurRadius: liftBlur,
                offset: Offset(0, liftY),
              ),
              // Soft ambient pool — separates control from background.
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: haloBlur,
                offset: Offset(0, liftY * 0.45),
              ),
              // Tight top catch-light — glass edge lift (inset feel from spread).
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.32),
                blurRadius: rimHighlightBlur,
                spreadRadius: -(1.1 * s).clamp(0.75, 1.45),
                offset: Offset(0, -(0.9 * s).clamp(0.45, 1.15)),
              ),
            ],
          ),
          child: ClipOval(
            clipBehavior: Clip.antiAlias,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // 1) Base body tint — radial bias keeps icon legible on dark + light headers.
                  DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        center: const Alignment(-0.22, -0.32),
                        radius: 1.05,
                        colors: [
                          Colors.white.withValues(alpha: 0.26),
                          Colors.white.withValues(alpha: 0.11),
                          Colors.white.withValues(alpha: 0.07),
                        ],
                        stops: const [0.0, 0.52, 1.0],
                      ),
                    ),
                  ),
                  // 2) Diagonal frosted film — main glass read; restrained alphas.
                  DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.34),
                          Colors.white.withValues(alpha: 0.07),
                          Colors.white.withValues(alpha: 0.16),
                        ],
                        stops: const [0.0, 0.48, 1.0],
                      ),
                    ),
                  ),
                  // 3) Top specular band — iOS-style polished highlight.
                  Align(
                    alignment: Alignment.topCenter,
                    child: FractionallySizedBox(
                      heightFactor: 0.40,
                      widthFactor: 1,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white.withValues(alpha: 0.20),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // 4) Bottom depth wash — anchors hierarchy without muddying blur.
                  DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          const Color(0xFF0A1628).withValues(alpha: 0.07),
                        ],
                      ),
                    ),
                  ),
                  // 5) Inner rim glow — subtle inner edge light.
                  DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        radius: 1.0,
                        colors: [
                          Colors.transparent,
                          Colors.white.withValues(alpha: 0.0),
                          Colors.white.withValues(alpha: 0.09),
                        ],
                        stops: const [0.0, 0.78, 1.0],
                      ),
                    ),
                  ),
                  // 6) Glass rim stroke — full-bleed ring; does not consume bell padding.
                  IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          width: rimW,
                          color: Colors.white.withValues(alpha: 0.40),
                        ),
                      ),
                      child: const SizedBox.expand(),
                    ),
                  ),
                  // 7) Bell icon.
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: bellPadH,
                      vertical: bellPadV,
                    ),
                    child: Center(
                      child: SvgPicture.asset(
                        _kNotificationBellSvgAsset,
                        width: bellIconW,
                        height: bellIconH,
                        fit: BoxFit.contain,
                        colorFilter: const ColorFilter.mode(
                          _kHeaderIconTint,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Profile avatar beside location — single ring; family members live in profile module.
class _HomeProfileAvatarStack extends StatelessWidget {
  final String? imageUrl;
  final VoidCallback onTap;

  const _HomeProfileAvatarStack({required this.imageUrl, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = _homeHeaderChromeScale(context);
    final narrow = MediaQuery.sizeOf(context).width < 360;
    final rLarge = ((narrow ? 28.0 : 30.0) * s).clamp(26.0, 32.0);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: _avatarRing(radius: rLarge, imageUrl: imageUrl),
    );
  }

  Widget _avatarRing({required double radius, required String? imageUrl}) {
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
                size: (radius * 1.25).clamp(32.0, 42.0),
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
    final cleanedSegments = s
        .split(',')
        .map((e) => e.trim())
        .where(
          (e) =>
              e.isNotEmpty && e.toLowerCase() != 'null' && e.toLowerCase() != 'undefined',
        )
        .toList();
    if (cleanedSegments.isEmpty) return 'HSR Layout, Bangalore';
    return cleanedSegments.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final shortestSide = MediaQuery.sizeOf(context).shortestSide;
    final compact = width < 360;
    final headerScaleX = _homeHeaderScaleXForWidth(width);
    final s = _homeUiScale(context) * layoutScale;
    final deviceIconScale = (shortestSide / 390).clamp(0.82, 1.35).toDouble();
    final locationIconSize = (20 * s * deviceIconScale).clamp(15.0, 28.0);
    final greetingName = userName.isEmpty ? 'Aashi' : userName;
    final horizontal = Responsive.horizontalPaddingOf(context);
    final headerHorizontal = (horizontal - 2).clamp(14.0, horizontal);
    final addressLine = _addressLineForHome(currentAddress);
    final imageBleed = (4.0 * s).clamp(2.0, 6.0);
    final topPad = (66 * layoutScale).clamp(40.0, 76.0);
    final bottomPad = (26 * layoutScale).clamp(16.0, 32.0);
    final searchBarH = _homeSearchBarHeight(context, s);
    const headerRadius = BorderRadius.only(
      bottomLeft: Radius.circular(_kHomeHeaderBottomRadius),
      bottomRight: Radius.circular(_kHomeHeaderBottomRadius),
    );
    return ClipRRect(
      borderRadius: headerRadius,
      clipBehavior: Clip.antiAlias,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: headerRadius,
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.footwearHeroMid,
                    AppColors.footwearHeroStart,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: -imageBleed,
            left: 0,
            right: 0,
            bottom: -imageBleed,
            child: Transform.scale(
              // Crop transparent side pixels from the header asset.
              scaleX: headerScaleX,
              scaleY: 1.02,
              alignment: Alignment.topCenter,
              child: Image.asset(
                _kHomeHeaderBgAsset,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                errorBuilder: (_, _, _) => Image.asset(
                  'assets/images/bg.png',
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                ),
              ),
            ),
          ),
            Padding(
              padding: EdgeInsets.fromLTRB(0, topPad, 0, bottomPad),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: headerHorizontal),
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
                              fontSize: ((compact ? 46.0 : 48.0) * s).clamp(
                                13.0,
                                23.0,
                              ),
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
                    SizedBox(height: (8 * s).clamp(4.0, 14.0)),
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
                                  width: locationIconSize,
                                  height: locationIconSize,
                                  child: SvgPicture.asset(
                                    _kHomeMapPinSvgAsset,
                                    fit: BoxFit.contain,
                                    colorFilter: const ColorFilter.mode(
                                      _kHeaderIconTint,
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                ),
                                SizedBox(width: (12 * s).clamp(8.0, 14.0)),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'Home',
                                            style: GoogleFonts.montserrat(
                                              fontSize: (14 * s).clamp(
                                                10.0,
                                                14.0,
                                              ),
                                              fontWeight: FontWeight.w600,
                                              color: _kOnHeaderText,
                                              height: 1.15,
                                            ),
                                          ),
                                          SizedBox(
                                            width: (4 * s).clamp(2.0, 4.0),
                                          ),
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
                                                size: (16 * s).clamp(
                                                  11.0,
                                                  16.0,
                                                ),
                                                color: _kOnHeaderText,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: (4 * s).clamp(2.0, 6.0)),
                                      Text(
                                        addressLine,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.montserrat(
                                          fontSize:
                                              ((compact ? 14.0 : 16.0) * s)
                                                  .clamp(10.0, 16.0),
                                          fontWeight: FontWeight.w400,
                                          color: _kOnHeaderTextMuted,
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
                        SizedBox(width: (4 * s).clamp(3.0, 8.0)),
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
                    SizedBox(height: _homeLocationToSearchGap(context, s)),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: (1 * s).clamp(0.0, 3.0),
                      ),
                      child: Container(
                        height: searchBarH,
                        padding: EdgeInsets.symmetric(
                          horizontal: (16 * s).clamp(12.0, 20.0),
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(searchBarH / 2),
                          // boxShadow: [
                          //   BoxShadow(
                          //     color: Colors.black.withValues(alpha: 0.06),
                          //     blurRadius: 8,
                          //     offset: const Offset(0, 2),
                          //   ),
                          // ],
                        ),
                        alignment: Alignment.centerLeft,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SvgPicture.asset(
                              'assets/images/search.svg',
                              width: 22,
                              height: 22,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Search an area or address',
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
                    SizedBox(
                      height: (_kHomeHeaderSearchToStats * s).clamp(22.0, 40.0),
                    ),
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
              ),
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
    final valueSize = ((narrow ? 22.0 : 26.0) * s).clamp(18.0, 28.0);
    final labelSize = (11.5 * s).clamp(9.0, 12.0);
    final labelStyle = GoogleFonts.montserrat(
      fontSize: labelSize,
      fontWeight: FontWeight.w500,
      color: _kOnHeaderTextMuted,
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
                SizedBox(height: (7 * s).clamp(4.0, 10.0)),
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

/// Horizontal rack preview: small logical thumb size + [BoxFit.contain] so
/// varied aspect ratios and future uploads are not cropped at the sides.
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

  /// Reference frame for [FittedBox]; keeps three-up rows readable on phones.
  static const double _kThumbW = 124;
  static const double _kThumbH = 66;

  @override
  Widget build(BuildContext context) {
    if (articles.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final len = articles.length;
        final fitCount = len <= 3 ? len : 3;
        final visible = articles.take(fitCount).toList();
        final safeGap = gap.clamp(6.0, 12.0);
        final radius = BorderRadius.circular(12);

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            for (int i = 0; i < visible.length; i++) ...[
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => onOpen(visible[i]),
                    borderRadius: radius,
                    child: ClipRRect(
                      borderRadius: radius,
                      child: FittedBox(
                        fit: BoxFit.contain,
                        alignment: Alignment.center,
                        child: SizedBox(
                          width: _kThumbW,
                          height: _kThumbH,
                          child: articleThumb(
                            articleImageUrl(visible[i].thumbnailImage),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (i != visible.length - 1) SizedBox(width: safeGap),
            ],
          ],
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
  final bool grayed;
  final VoidCallback? onTap;
  final bool fullWidth;

  const _QuickActionCard({
    required this.label,
    this.iconAssetUrl,
    this.iconWidth = 24,
    this.iconHeight = 24,
    this.cellHeight,
    this.highlight = false,
    this.grayed = false,
    this.onTap,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final s = (MediaQuery.sizeOf(context).width / 430)
        .clamp(0.85, 1.15)
        .toDouble();
    final isTwoLine = label.contains('\n');
    final textColor = highlight
        ? Colors.white
        : grayed
            ? AppColors.greyedButtonLabel
            : _kQuickActionMutedText;
    final iconColor = grayed ? AppColors.greyedButtonLabel : textColor;
    final resolvedHeight =
        cellHeight ??
        (isTwoLine
            ? (_kQuickActionCellHeight + 28) * s
            : _kQuickActionCellHeight * s);
    final padding = highlight
        ? EdgeInsets.fromLTRB(18 * s, 8 * s, 18 * s, 8 * s)
        : EdgeInsets.symmetric(
            horizontal: 12 * s,
            vertical: (isTwoLine ? 18 : 8) * s,
          );
    const cardRadius = 12.0;
    const borderWidth = AppColors.greyedButtonBorderWidth;
    final innerRadius = cardRadius - borderWidth;

    final cardBody = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: iconWidth,
          height: iconHeight,
          child: _buildActionIcon(iconColor),
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
                fontSize:
                    ((MediaQuery.sizeOf(context).width < 360 ? 14.0 : 16.0) *
                            s)
                        .clamp(11.0, 16.0),
                fontWeight: FontWeight.w400,
                color: textColor,
                height: isTwoLine ? 1.6 : 1.08,
              ),
            ),
          ),
        ),
      ],
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(cardRadius),
        child: grayed && !highlight
            ? Container(
                height: resolvedHeight,
                decoration: AppColors.greyedButtonOuterDecoration(cardRadius),
                padding: const EdgeInsets.all(borderWidth),
                child: Container(
                  padding: padding,
                  decoration:
                      AppColors.greyedButtonInnerDecoration(innerRadius),
                  alignment: Alignment.center,
                  child: cardBody,
                ),
              )
            : Container(
                height: resolvedHeight,
                padding: padding,
                decoration: BoxDecoration(
                  color: _kQuickActionMutedBg,
                  gradient: highlight
                      ? const LinearGradient(
                          begin: Alignment(1, 0.5),
                          end: Alignment(0, 0.5),
                          colors: [
                            AppColors.primaryLight,
                            AppColors.footwearHeroStart,
                          ],
                        )
                      : null,
                  borderRadius: BorderRadius.circular(cardRadius),
                ),
                alignment: Alignment.center,
                child: cardBody,
              ),
      ),
    );
  }

  Widget _buildActionIcon(Color textColor) {
    final source = iconAssetUrl;
    if (source == null || source.isEmpty) {
      return Icon(Icons.widgets_outlined, size: 24, color: textColor);
    }

    if (source.startsWith('http://') || source.startsWith('https://')) {
      return Image.network(
        source,
        fit: BoxFit.contain,
        color: textColor,
        colorBlendMode: BlendMode.srcIn,
        errorBuilder: (_, _, _) =>
            Icon(Icons.widgets_outlined, size: 24, color: textColor),
      );
    }

    return SvgPicture.asset(
      source,
      fit: BoxFit.contain,
      colorFilter: ColorFilter.mode(textColor, BlendMode.srcIn),
    );
  }
}
