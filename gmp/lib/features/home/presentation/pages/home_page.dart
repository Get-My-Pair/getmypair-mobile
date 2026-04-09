import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../auth/presentation/pages/mobile_otp_page.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive.dart';
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
import '../../../auth/domain/usecases/get_valid_access_token.dart';
import '../../../../injection_container.dart';

/// Header sweep gradient (matches Figma home hero).
const SweepGradient _kHomeHeaderSweep = SweepGradient(
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

const Color _kOnHeaderText = Color(0xFFDFE7E9);
const Color _kQuickActionMutedBg = Color(0xFFDFE7E9);
const Color _kQuickActionMutedText = Color(0xFF062F35);
const Color _kRackCardBorder = Color(0xFF0F6876);
const Color _kRackCardBg = Color(0xFFF0F0F0);
const Color _kSearchHintColor = Color(0x57000000);

/// Vertical gaps inside the hero (greeting → location → search → stats → carbon).
const double _kHomeHeaderGreetingToLocation = 14;
const double _kHomeHeaderSearchToStats = 18;
const double _kHomeHeaderStatsToCarbon = 12;

/// Section spacing below hero / between blocks (12–16px).
const double _kSectionGap = 28;
const double _kRackThumbGap = 12;

/// Extra breathing room between "My Rack" and quick action tiles.
const double _kAfterRackToActionsGap = 22;

/// Tile height for quick actions.
const double _kQuickActionCellHeight = 86;

/// Stacked tool + bag icons (matches Shoe Care tile spacing in design).
const Widget _kShoeCareLeadingIcons = Column(
  mainAxisSize: MainAxisSize.min,
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    Icon(Icons.handyman_outlined, size: 22, color: Colors.white),
    SizedBox(height: 4),
    Icon(Icons.shopping_bag_outlined, size: 22, color: Colors.white),
  ],
);

/// Home Page — lives in the outer features layer.
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
              backgroundColor: const Color(0xFFFAFAFA),
              body: Stack(
                children: [
                  SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 112),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _HomeTopCard(
                          userName: userName,
                          currentAddress: _currentAddress,
                          pairsInRackDisplay: _pairsInRackDisplay,
                          onLocationTap: () async {
                            final profile = userProfileFromProfileState(
                              context.read<ProfileBloc>().state,
                            );
                            final authState = context.read<AuthBloc>().state;
                            final selected = await Navigator.of(context)
                                .push<String>(
                                  MaterialPageRoute(
                                    builder: (_) => SelectLocationPage(
                                      profileBloc: context.read<ProfileBloc>(),
                                      initialAddress: _currentAddress,
                                      mapPinDisplayName:
                                          mapPinDisplayNameFrom(profile, authState),
                                      mapPinProfileImageRef: profile?.profileImage,
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
                                setState(() => _currentAddress = addressText);
                              }
                            }
                          },
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: Responsive.horizontalPaddingOf(context),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              SizedBox(height: _kSectionGap),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.fromLTRB(
                                  12,
                                  14,
                                  12,
                                  16,
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
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                              top: 2,
                                              left: 16,
                                              right: 4,
                                            ),
                                            child: Text(
                                              'My Rack',
                                              style: GoogleFonts.boldonse(
                                                fontSize: 16,
                                                color: _kQuickActionMutedText,
                                                height: 1.1,
                                              ),
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: _openArticleList,
                                          tooltip: 'Digital Shoes Rack',
                                          padding: const EdgeInsets.only(right: 12),
                                          alignment: Alignment.topRight,
                                          constraints: const BoxConstraints(
                                            minWidth: 44,
                                            minHeight: 44,
                                          ),
                                          icon: Icon(
                                            Icons.open_in_full,
                                            size: 22,
                                            color: _kQuickActionMutedText,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    SizedBox(
                                      height: 80,
                                      width: double.infinity,
                                      child:
                                          _rackLoading && _rackArticles == null
                                          ? const Center(
                                              child: SizedBox(
                                                width: 24,
                                                height: 24,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: AppColors.primary,
                                                    ),
                                              ),
                                            )
                                          : _rackError != null
                                          ? Center(
                                              child: Text(
                                                _rackError!,
                                                textAlign: TextAlign.center,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: AppColors.textTertiary,
                                                ),
                                              ),
                                            )
                                          : (_rackArticles == null ||
                                                _rackArticles!.isEmpty)
                                          ? Center(
                                              child: Text(
                                                'No pairs yet — tap ↗ to open your rack',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: AppColors.textTertiary,
                                                ),
                                              ),
                                            )
                                          : _RackThumbStrip(
                                              articles: _rackArticles!.toList(),
                                              gap: _kRackThumbGap,
                                              onOpen: _openArticleDetails,
                                              articleImageUrl: _articleImageUrl,
                                              articleThumb: _articleThumb,
                                            ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: _kAfterRackToActionsGap),
                              _QuickActionCard(
                                label: 'Shoe Care',
                                icon: Icons.design_services_outlined,
                                highlight: true,
                                leading: _kShoeCareLeadingIcons,
                                fullWidth: true,
                                onTap: () => _openServiceFlow(
                                  title:
                                      'Select article for Shoe Care (Repair, Maintenance, Wash)',
                                  allowedServiceTypes: const [
                                    'repair',
                                    'maintenance',
                                    'wash',
                                  ],
                                ),
                              ),
                              const SizedBox(height: 22),
                              Row(
                                children: [
                                  const Expanded(
                                    child: _QuickActionCard(
                                      label: 'Rent',
                                      icon: Icons.repeat_rounded,
                                    ),
                                  ),
                                  const SizedBox(width: 28),
                                  Expanded(
                                    child: _QuickActionCard(
                                      label: 'Rehome',
                                      icon: Icons.home_work_outlined,
                                      onTap: () => _openServiceFlow(
                                        title:
                                            'Select article for Rehome (Donate, Dispose)',
                                        allowedServiceTypes: const [
                                          'donate',
                                          'dispose',
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    right: 14,
                    bottom: 104,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(40),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ChatbotPage(),
                            ),
                          );
                        },
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment(1, 0.2),
                              end: Alignment(-0.4, 1),
                              colors: [Color(0xFF12899B), Color(0xFF09E0FF)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0x1A000000),
                                blurRadius: 4,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.waves_rounded,
                              color: Color(0xFFB8FEFF),
                              size: 32,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Large profile photo with two smaller circles on the right (design mock).
class _ProfileAvatarCluster extends StatelessWidget {
  final String? imageUrl;
  final VoidCallback onTap;

  const _ProfileAvatarCluster({required this.imageUrl, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 96,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0x55D7EEF2),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.notifications_none_rounded,
                color: const Color(0xFFDFE7E9),
                size: 23,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: 96,
              height: 52,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.centerRight,
                children: [
                  Positioned(
                    left: 0,
                    top: 2,
                    child: _avatarRing(radius: 24, imageUrl: imageUrl),
                  ),
                  Positioned(
                    right: 4,
                    top: 0,
                    child: _avatarRing(radius: 11, imageUrl: null, isSmall: true),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: _avatarRing(radius: 11, imageUrl: null, isSmall: true),
                  ),
                ],
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
        border: Border.all(color: Colors.white, width: 2),
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
                size: isSmall ? 12 : 24,
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

  const _HomeTopCard({
    required this.userName,
    required this.currentAddress,
    required this.pairsInRackDisplay,
    required this.onLocationTap,
  });

  static String _addressLineForHome(String raw) {
    final s = raw.replaceFirst(RegExp(r'^📍\s*'), '').trim();
    if (s.isEmpty) return 'HSR Layout, Bangalore';
    return s;
  }

  @override
  Widget build(BuildContext context) {
    final topSafe = MediaQuery.paddingOf(context).top;
    final greetingName = userName.isEmpty ? 'Aashi' : userName;
    final horizontal = Responsive.horizontalPaddingOf(context);
    final addressLine = _addressLineForHome(currentAddress);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        horizontal,
        topSafe + 34,
        horizontal,
        26,
      ),
      decoration: BoxDecoration(
        gradient: _kHomeHeaderSweep,
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hello, $greetingName!',
                      textAlign: TextAlign.left,
                      style: GoogleFonts.boldonse(
                        fontSize: 24,
                        fontWeight: FontWeight.w400,
                        color: _kOnHeaderText,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: _kHomeHeaderGreetingToLocation),
                    GestureDetector(
                      onTap: onLocationTap,
                      behavior: HitTestBehavior.opaque,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Icon(
                              Icons.location_on_outlined,
                              color: _kOnHeaderText.withValues(alpha: 0.95),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Home',
                                      style: GoogleFonts.montserrat(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: _kOnHeaderText,
                                        height: 1.15,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.chevron_right_rounded,
                                      size: 16,
                                      color: _kOnHeaderText,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  addressLine,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.montserrat(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
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
                  ],
                ),
              ),
              const SizedBox(width: 12),
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
                  return _ProfileAvatarCluster(
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
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 18),
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
                  Icon(
                    Icons.search,
                    size: 24,
                    color: _kSearchHintColor,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Search',
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: _kSearchHintColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: _kHomeHeaderSearchToStats),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _StatItem(
                  value: pairsInRackDisplay,
                  label: 'Pairs in your rack',
                ),
              ),
              const Expanded(
                child: _StatItem(value: '05', label: 'Pairs Donated'),
              ),
              const Expanded(
                child: _StatItem(value: '00', label: 'Pairs Sold'),
              ),
              const Expanded(
                child: _StatItem(value: '02', label: 'Pairs in Care'),
              ),
            ],
          ),
          const SizedBox(height: _kHomeHeaderStatsToCarbon),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;

  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          value,
          textAlign: TextAlign.center,
          style: GoogleFonts.boldonse(
            fontSize: 24,
            fontWeight: FontWeight.w400,
            color: _kOnHeaderText,
            height: 1,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 2,
          style: GoogleFonts.montserrat(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _kOnHeaderText,
            height: 1.2,
          ),
        ),
      ],
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
            ((constraints.maxWidth - gap * (fitCount - 1)) / fitCount)
                ;

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
  final IconData icon;
  final bool highlight;
  final Widget? leading;
  final VoidCallback? onTap;
  final bool fullWidth;

  const _QuickActionCard({
    required this.label,
    required this.icon,
    this.highlight = false,
    this.leading,
    this.onTap,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = highlight ? Colors.white : _kQuickActionMutedText;
    final padding = highlight
        ? const EdgeInsets.fromLTRB(18, 8, 18, 8)
        : const EdgeInsets.symmetric(horizontal: 14, vertical: 8);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: _kQuickActionCellHeight,
          padding: padding,
          decoration: BoxDecoration(
            color: highlight ? null : _kQuickActionMutedBg,
            gradient: highlight
                ? const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [Color(0xFF063239), Color(0xFF0CADC5)],
                  )
                : null,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              leading ?? Icon(icon, size: 24, color: textColor),
              SizedBox(width: fullWidth ? 20 : 14),
              Flexible(
                child: Text(
                  label,
                  maxLines: 2,
                  textAlign: TextAlign.left,
                  style: GoogleFonts.boldonse(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: textColor,
                    height: 1.05,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
