import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../auth/presentation/pages/welcome_page.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/utils/responsive.dart';
import '../../../profile/presentation/bloc/profile_bloc.dart';
import '../../../profile/presentation/bloc/profile_state.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import 'package:gmp/routes.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'select_location_page.dart';
import 'chatbot_page.dart';

/// Home Page — lives in the outer features layer.
/// This is the landing tab shown to authenticated users on the main dashboard.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _currentAddress = '📍 Fetching location...';

  @override
  void initState() {
    super.initState();
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
    return lat != null && lng != null &&
        lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180;
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
      final locality = p.subLocality ?? p.locality ?? p.administrativeArea ?? '';
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
          _currentAddress = '📍 ${place.subLocality ?? place.locality}, ${place.administrativeArea}';
        });
      } else {
        setState(() => _currentAddress = '📍 Location unavailable');
      }
    } catch (e) {
      setState(() => _currentAddress = '📍 Location unavailable');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const WelcomePage()),
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

          return Scaffold(
            backgroundColor: AppColors.background,
            body: Stack(
              children: [
                CustomScrollView(
                  slivers: [
                    // ── App Bar ──────────────────────────────────
                    SliverAppBar(
                      pinned: true,
                      floating: false,
                      backgroundColor: AppColors.background,
                      elevation: 0,
                      title: GestureDetector(
                        onTap: () async {
                          final selected =
                              await Navigator.of(context).push<String>(
                            MaterialPageRoute(
                              builder: (_) => SelectLocationPage(
                                initialAddress: _currentAddress,
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
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.location_on,
                                size: 18, color: AppColors.primary),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                _currentAddress,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 2),
                            Icon(Icons.keyboard_arrow_down,
                                size: 18, color: AppColors.textSecondary),
                          ],
                        ),
                      ),
                      actions: [
                        // Carbon chip only (Coin removed)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.primary),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.eco_outlined,
                                  color: AppColors.primary, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                '0 Carbon',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
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
                          child: BlocBuilder<ProfileBloc, ProfileState>(
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
                              return CircleAvatar(
                                radius: 18,
                                backgroundColor: AppColors.primaryLight,
                                backgroundImage: imageUrl != null &&
                                        imageUrl.isNotEmpty
                                    ? NetworkImage(imageUrl)
                                    : null,
                                child: imageUrl == null || imageUrl.isEmpty
                                    ? const Icon(Icons.person,
                                        color: AppColors.primary, size: 20)
                                    : null,
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                      ],
                    ),
                    // ── Footwear hero banner ─────────────────────────
                    SliverToBoxAdapter(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final horizontal = Responsive.horizontalPaddingOf(context);
                          return Container(
                            margin: EdgeInsets.fromLTRB(horizontal, 12, horizontal, 0),
                            padding: EdgeInsets.symmetric(horizontal: horizontal, vertical: 20),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  AppColors.footwearHeroStart,
                                  AppColors.footwearHeroEnd,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.25),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (userName.isNotEmpty)
                                  Text(
                                    'Hello, $userName 👋',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Your feet deserve the best.',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white70,
                                    height: 1.35,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.directions_walk,
                                      color: Colors.white.withOpacity(0.9),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Shop • Repair • Recycle',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white.withOpacity(0.95),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),

                    // ── Digital Shoes Rack button ─────────────────────────────
                    SliverToBoxAdapter(
                      child: Builder(
                        builder: (context) {
                          final horizontal = Responsive.horizontalPaddingOf(context);
                          return Padding(
                            padding: EdgeInsets.fromLTRB(horizontal, 16, horizontal, 0),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => Navigator.of(context).pushNamed(AppRoutes.articleList),
                                borderRadius: BorderRadius.circular(14),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryLight,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: AppColors.primary),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: AppColors.shadow,
                                        blurRadius: 8,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Icon(
                                          Icons.checkroom_outlined,
                                          color: AppColors.primary,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      const Expanded(
                                        child: Text(
                                          'Digital Shoes Rack',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                      ),
                                      const Icon(
                                        Icons.chevron_right,
                                        color: AppColors.primary,
                                        size: 24,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // ── Discover bar (footwear theme) ─────────────────
                    SliverToBoxAdapter(
                      child: Builder(
                        builder: (context) {
                          final horizontal = Responsive.horizontalPaddingOf(context);
                          return Container(
                            margin: EdgeInsets.fromLTRB(horizontal, 20, horizontal, 0),
                            padding: EdgeInsets.symmetric(horizontal: horizontal * 0.8, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.border),
                              boxShadow: const [
                                BoxShadow(
                                  color: AppColors.shadow,
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.search_rounded, color: AppColors.textTertiary, size: 22),
                                const SizedBox(width: 12),
                                Text(
                                  'Discover shoes & services',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: AppColors.textTertiary,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),

                    // ── Services section (footwear theme) ─────────────
                    SliverToBoxAdapter(
                      child: LayoutBuilder(
                        builder: (context, _) {
                          final horizontal = Responsive.horizontalPaddingOf(context);
                          return Padding(
                            padding: EdgeInsets.fromLTRB(horizontal, 28, horizontal, 0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      height: 4,
                                      width: 36,
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'What we offer',
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Find, fix, and give shoes a second life.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 20),

                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    final w = MediaQuery.sizeOf(context).width;
                                    final aspectRatio =
                                        w <= Responsive.breakpointSmall ? 1.0 : 1.12;
                                    return GridView.count(
                                      crossAxisCount: 2,
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      mainAxisSpacing: 14,
                                      crossAxisSpacing: 14,
                                      childAspectRatio: aspectRatio,
                                      children: [
                                        _ServiceCard(
                                          icon: Icons.shopping_bag_outlined,
                                          label: 'Digital Shoes Rack',
                                          color: const Color(0xFF6750A4),
                                          onTap: () => Navigator.of(context).pushNamed(AppRoutes.articleList),
                                        ),
                                        const _ServiceCard(
                                          icon: Icons.build_outlined,
                                          label: 'Maintain & Repair',
                                          color: Color(0xFF2196F3),
                                        ),
                                        const _ServiceCard(
                                          icon: Icons.recycling_outlined,
                                          label: 'Recycle',
                                          color: Color(0xFF4CAF50),
                                        ),
                                        const _ServiceCard(
                                          icon: Icons.card_giftcard_outlined,
                                          label: 'Donate',
                                          color: Color(0xFFFF9800),
                                        ),
                                        const _ServiceCard(
                                          icon: Icons.local_offer_outlined,
                                          label: 'Resale',
                                          color: Color(0xFFE91E63),
                                        ),
                                        const _ServiceCard(
                                          icon: Icons.storefront_outlined,
                                          label: 'Rent',
                                          color: Color(0xFF9C27B0),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                                const SizedBox(height: 36),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                Positioned(
                  right: 16,
                  bottom: 86,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ChatbotPage(),
                          ),
                        );
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Image.asset(
                          'assets/images/Live chatbot.gif',
                          width: 72,
                          height: 72,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _ServiceCard({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border, width: 1),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 12,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 30),
              ),
              const SizedBox(height: 14),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  height: 1.28,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
