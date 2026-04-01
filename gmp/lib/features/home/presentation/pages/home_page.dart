import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../auth/presentation/pages/mobile_otp_page.dart';
import '../../../../core/theme/app_colors.dart';
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

          return Scaffold(
            backgroundColor: const Color(0xFFF4F5F7),
            body: Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 130),
                  child: Column(
                    children: [
                      _HomeTopCard(
                        userName: userName,
                        currentAddress: _currentAddress,
                        onLocationTap: () async {
                          final selected = await Navigator.of(context).push<String>(
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
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: Responsive.horizontalPaddingOf(context),
                        ),
                        child: Column(
                          children: [
                            const SizedBox(height: 14),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF2F3),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: const [
                                      Text(
                                        'My Rack',
                                        style: TextStyle(
                                          fontSize: 32,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      Icon(Icons.open_in_full,
                                          color: AppColors.textPrimary),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    children: const [
                                      Icon(Icons.directions_run,
                                          size: 62, color: Color(0xFFEE8E3D)),
                                      Icon(Icons.sports_tennis,
                                          size: 62, color: Color(0xFF1C3E73)),
                                      Icon(Icons.checkroom,
                                          size: 62, color: Color(0xFFCDD2D8)),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Container(
                                    height: 4,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryLight,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _QuickActionCard(
                                    label: 'Shoe\nCare',
                                    icon: Icons.design_services_outlined,
                                    highlight: true,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: _QuickActionCard(
                                    label: 'Rehome',
                                    icon: Icons.home_work_outlined,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Row(
                              children: [
                                Expanded(
                                  child: _QuickActionCard(
                                    label: 'Rent',
                                    icon: Icons.repeat_rounded,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: _QuickActionCard(
                                    label: 'Style Me',
                                    icon: Icons.auto_awesome_outlined,
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

class _HomeTopCard extends StatelessWidget {
  final String userName;
  final String currentAddress;
  final Future<void> Function() onLocationTap;

  const _HomeTopCard({
    required this.userName,
    required this.currentAddress,
    required this.onLocationTap,
  });

  @override
  Widget build(BuildContext context) {
    final greetingName = userName.isEmpty ? 'Aashi' : userName;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        Responsive.horizontalPaddingOf(context),
        56,
        Responsive.horizontalPaddingOf(context),
        18,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF08343A),
            Color(0xFF0A6C78),
            Color(0xFF0FC8DD),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                      style: const TextStyle(
                        fontSize: 46,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: onLocationTap,
                      child: Row(
                        children: [
                          const Icon(Icons.location_on_outlined,
                              color: Colors.white, size: 20),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              currentAddress.replaceFirst('📍 ', ''),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
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
                      radius: 30,
                      backgroundColor: Colors.white30,
                      backgroundImage: imageUrl != null && imageUrl.isNotEmpty
                          ? NetworkImage(imageUrl)
                          : null,
                      child: imageUrl == null || imageUrl.isEmpty
                          ? const Icon(Icons.person, color: Colors.white, size: 28)
                          : null,
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
            ),
            child: const Row(
              children: [
                Icon(Icons.search, color: AppColors.textTertiary),
                SizedBox(width: 10),
                Text(
                  'Search',
                  style: TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 20,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StatItem(value: '25', label: 'Pairs in\nyour rack'),
              _StatItem(value: '05', label: 'Pairs\nDonated'),
              _StatItem(value: '00', label: 'Pairs\nSold'),
              _StatItem(value: '02', label: 'Pairs in\nCare'),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  colors: [Color(0xFF7BE8E6), Color(0xFFC9FFE2)],
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.eco_outlined, size: 20, color: AppColors.primaryDark),
                  SizedBox(width: 8),
                  Text(
                    '50',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Carbon Credits',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDark,
                    ),
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
  final String label;

  const _StatItem({
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 52,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool highlight;

  const _QuickActionCard({
    required this.label,
    required this.icon,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final baseColor = highlight ? AppColors.primary : const Color(0xFFE3E8EA);
    final textColor = highlight ? Colors.white : AppColors.textPrimary;
    return Container(
      height: 108,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: baseColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 36, color: textColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w700,
                color: textColor,
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
