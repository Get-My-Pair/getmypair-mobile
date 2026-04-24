import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_feedback_alert.dart';
import '../../../../core/utils/responsive.dart';
import '../../../articles/presentation/pages/article_list_page.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../profile/domain/entities/user_profile.dart';
import '../../../profile/presentation/bloc/profile_bloc.dart';
import '../../../profile/presentation/bloc/profile_state.dart';
import '../../../profile/presentation/pages/profile_page.dart';

/// Profile snapshot from [ProfileState] for map-pin / navigation helpers.
UserProfile? userProfileFromProfileState(ProfileState s) {
  if (s is ProfileLoaded) return s.profile;
  if (s is ProfileUpdating) return s.profile;
  if (s is ProfileImageUploading) return s.profile;
  if (s is ProfileError) return s.profile;
  if (s is AddressActionLoading) return s.profile;
  return null;
}

/// Display name for the user map pin (profile name, else auth name, else “You”).
String mapPinDisplayNameFrom(UserProfile? profile, AuthState auth) {
  final fromProfile = profile?.name.trim() ?? '';
  if (fromProfile.isNotEmpty) return fromProfile;
  if (auth is AuthAuthenticated) return auth.user.name.trim();
  if (auth is AuthProfileCompleted) return auth.user.name.trim();
  return 'You';
}

/// Resolves profile / media paths to a full URL (same idea as home + articles).
/// Idempotent if [path] is already absolute. Handles `uploads/...` without doubling.
String? mapPinAbsoluteProfileImageUrl(String? path) {
  if (path == null || path.isEmpty) return null;
  final t = path.trim();
  if (t.startsWith('http://') || t.startsWith('https://')) return t;
  final base = ApiEndpoints.baseUrl;
  if (t.startsWith('/')) return '$base$t';
  if (t.startsWith('uploads/')) return '$base/$t';
  return '$base/uploads/$t';
}

/// “Shoe Care” — find cobblers near you: light map, distance rings, demo markers,
/// confirm location (returns address to [Navigator.pop]).
///
/// Pass [mapPinDisplayName] / [mapPinProfileImageRef] from the opener (e.g. home).
/// [profileBloc] must be the dashboard’s bloc so nested pushes (e.g. profile tab)
/// keep the same state—pushed routes sit above [BlocProvider<ProfileBloc>].
///
/// [mapPinProfileImageRef] is the raw `UserProfile.profileImage` value (relative or
/// absolute); it is normalized with [mapPinAbsoluteProfileImageUrl] for the pin.
class SelectLocationPage extends StatefulWidget {
  final String initialAddress;
  final String? mapPinDisplayName;
  final String? mapPinProfileImageRef;
  final ProfileBloc profileBloc;

  SelectLocationPage({
    super.key,
    this.initialAddress = '',
    this.mapPinDisplayName,
    this.mapPinProfileImageRef,
    required this.profileBloc,
  });

  @override
  State<SelectLocationPage> createState() => _SelectLocationPageState();
}

class _SelectLocationPageState extends State<SelectLocationPage> {
  static const LatLng _defaultCenter = LatLng(13.0827, 80.2707); // Chennai

  static const Color _titleNavy = Color(0xFF004D4D);
  static const Color _searchBorderBlue = Color(0xFF7EC8E3);
  static const Color _tealButton = Color(0xFF0F6876);
  static const Color _mapGrey = Color(0xFFE8E8E8);

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

  final MapController _mapController = MapController();
  LatLng _markerPosition = _defaultCenter;
  String _address = 'Loading address...';
  bool _isLoadingAddress = false;
  bool _isLoadingCurrent = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initLocation();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Offset [eastMeters] / [northMeters] from [base] (approximate).
  static LatLng _offsetMeters(LatLng base, double eastMeters, double northMeters) {
    const mPerDegLat = 111320.0;
    final lat = base.latitude + northMeters / mPerDegLat;
    final lon = base.longitude +
        eastMeters / (mPerDegLat * math.cos(base.latitude * math.pi / 180));
    return LatLng(lat, lon);
  }

  Future<void> _initLocation() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        if (!mounted) return;
        setState(() => _address = 'Location services disabled');
        return;
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever || perm == LocationPermission.denied) {
        if (!mounted) return;
        setState(() {
          _markerPosition = _defaultCenter;
          _address = 'Allow location to use current position';
        });
        _updateAddressFromLatLng(_defaultCenter);
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final latLng = LatLng(position.latitude, position.longitude);
      if (!mounted) return;
      setState(() => _markerPosition = latLng);
      _mapController.move(latLng, 15.5);
      _updateAddressFromLatLng(latLng);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _markerPosition = _defaultCenter;
        _address = 'Location unavailable';
      });
      _updateAddressFromLatLng(_defaultCenter);
    }
  }

  Future<void> _updateAddressFromLatLng(LatLng latLng) async {
    if (_isLoadingAddress) return;
    setState(() {
      _isLoadingAddress = true;
      _address = 'Loading address...';
    });
    try {
      final placemarks = await placemarkFromCoordinates(
        latLng.latitude,
        latLng.longitude,
      );
      if (!mounted) return;
      if (placemarks.isNotEmpty) {
        final p = placemarks[0];
        final parts = [
          p.subThoroughfare,
          p.thoroughfare,
          p.subLocality,
          p.locality,
          p.administrativeArea,
          p.postalCode,
        ].where((e) => e != null && e.toString().trim().isNotEmpty).toList();
        setState(() => _address = parts.join(', '));
      } else {
        setState(() => _address = 'Selected location');
      }
    } catch (e) {
      if (mounted) setState(() => _address = 'Selected location');
    } finally {
      if (mounted) setState(() => _isLoadingAddress = false);
    }
  }

  Future<void> _useCurrentLocation() async {
    if (_isLoadingCurrent) return;
    setState(() => _isLoadingCurrent = true);
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final latLng = LatLng(position.latitude, position.longitude);
      setState(() => _markerPosition = latLng);
      _mapController.move(latLng, 15.5);
      await _updateAddressFromLatLng(latLng);
    } catch (e) {
      if (mounted) {
        await showAppFeedbackAlert(
          context,
          message: 'Could not get current location',
          type: AppFeedbackType.failure,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingCurrent = false);
    }
  }

  void _confirmLocation() {
    final result = (_address == 'Selected location')
        ? '${_markerPosition.latitude}, ${_markerPosition.longitude}'
        : _address;
    Navigator.of(context).pop(result);
  }

  void _showFilterSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nearby cobblers',
                style: TextStyle(
                  fontSize: Responsive.fontSize(context, 18),
                  fontWeight: FontWeight.w700,
                  color: _titleNavy,
                ),
              ),
              const SizedBox(height: 16),
              _sheetRow('Krishna', '5.0'),
              _sheetRow('Mohan', '5.0'),
              _sheetRow('Shankar', '5.0'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sheetRow(String name, String rating) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(Icons.person_outline_rounded, color: _tealButton, size: 22),
          const SizedBox(width: 12),
          Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w600))),
          Text(rating, style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(width: 4),
          Icon(Icons.star_rounded, size: 18, color: Colors.amber.shade700),
        ],
      ),
    );
  }

  List<Marker> _buildCobblerMarkers() {
    final base = _markerPosition;
    final spots = <({String name, LatLng point})>[
      (name: 'Krishna', point: _offsetMeters(base, 55, 75)),
      (name: 'Mohan', point: _offsetMeters(base, -85, 40)),
      (name: 'Shankar', point: _offsetMeters(base, 70, -65)),
    ];
    return spots
        .map(
          (s) => Marker(
            point: s.point,
            width: 132,
            height: 118,
            alignment: Alignment.bottomCenter,
            child: _CobblerMapPin(name: s.name),
          ),
        )
        .toList();
  }

  Marker _homeMarker(String displayName, String? profileImageUrl) {
    return Marker(
      point: _markerPosition,
      width: 148,
      height: 132,
      alignment: Alignment.bottomCenter,
      child: _UserMapPin(
        displayName: displayName,
        profileImageUrl: profileImageUrl,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hPad = Responsive.horizontalPaddingOf(context).clamp(12.0, 20.0);
    final bottomSafe = Responsive.bottomInsetOf(context);
    final isCompact = MediaQuery.sizeOf(context).width < 360;
    final authState = context.read<AuthBloc>().state;
    final userDisplayName = (widget.mapPinDisplayName != null &&
            widget.mapPinDisplayName!.trim().isNotEmpty)
        ? widget.mapPinDisplayName!.trim()
        : mapPinDisplayNameFrom(null, authState);
    final userImageUrl = mapPinAbsoluteProfileImageUrl(widget.mapPinProfileImageRef);

    return Scaffold(
      backgroundColor: const Color(0xFF062F35),
      extendBody: true,
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          const Positioned.fill(
            child: DecoratedBox(decoration: BoxDecoration(gradient: _shellSweep)),
          ),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(10, 8, 10, 0),
                    child: DecoratedBox(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(22),
                          topRight: Radius.circular(22),
                          bottomLeft: Radius.circular(36),
                          bottomRight: Radius.circular(36),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x19000000),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(22),
                          topRight: Radius.circular(22),
                          bottomLeft: Radius.circular(36),
                          bottomRight: Radius.circular(36),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Padding(
                              padding: EdgeInsets.fromLTRB(hPad, isCompact ? 10 : 14, hPad, 0),
                              child: Row(
                                children: [
                                  if (Navigator.of(context).canPop())
                                    IconButton(
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                                      onPressed: () => Navigator.of(context).maybePop(),
                                      icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: _titleNavy),
                                    )
                                  else
                                    const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Shoe Care',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.boldonse(
                                        color: _titleNavy,
                                        fontSize: Responsive.fontSize(context, isCompact ? 19 : 22),
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ),
                                  Material(
                                    color: Colors.white,
                                    elevation: 2,
                                    shadowColor: Colors.black26,
                                    shape: const CircleBorder(),
                                    child: InkWell(
                                      customBorder: const CircleBorder(),
                                      onTap: _isLoadingCurrent ? null : _useCurrentLocation,
                                      child: SizedBox(
                                        width: 44,
                                        height: 44,
                                        child: _isLoadingCurrent
                                            ? const Padding(
                                                padding: EdgeInsets.all(10),
                                                child: CircularProgressIndicator(strokeWidth: 2, color: _titleNavy),
                                              )
                                            : Icon(Icons.add, color: _titleNavy, size: 26),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: hPad),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      height: 46,
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(100),
                                        border: Border.all(color: _searchBorderBlue, width: 1.5),
                                      ),
                                      child: TextField(
                                        controller: _searchController,
                                        onChanged: (_) => setState(() {}),
                                        style: GoogleFonts.montserrat(
                                          fontSize: Responsive.fontSize(context, 15),
                                          color: Colors.black87,
                                        ),
                                        decoration: InputDecoration(
                                          isDense: true,
                                          border: InputBorder.none,
                                          hintText: 'Search',
                                          hintStyle: GoogleFonts.montserrat(
                                            color: Colors.black.withValues(alpha: 0.35),
                                            fontSize: Responsive.fontSize(context, 15),
                                          ),
                                          prefixIcon: Icon(
                                            Icons.search_rounded,
                                            color: Colors.black.withValues(alpha: 0.35),
                                            size: 22,
                                          ),
                                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Material(
                                    color: _tealButton,
                                    borderRadius: BorderRadius.circular(12),
                                    child: InkWell(
                                      onTap: _showFilterSheet,
                                      borderRadius: BorderRadius.circular(12),
                                      child: SizedBox(
                                        width: isCompact ? 44 : 48,
                                        height: isCompact ? 44 : 48,
                                        child: Icon(
                                          Icons.format_list_bulleted_rounded,
                                          color: Colors.white,
                                          size: isCompact ? 22 : 24,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.fromLTRB(hPad * 0.35, 0, hPad * 0.35, 0),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      ColoredBox(color: _mapGrey),
                                      FlutterMap(
                                        mapController: _mapController,
                                        options: MapOptions(
                                          initialCenter: _markerPosition,
                                          initialZoom: 15.5,
                                          onTap: (_, latLng) {
                                            setState(() => _markerPosition = latLng);
                                            _updateAddressFromLatLng(latLng);
                                          },
                                        ),
                                        children: [
                                          TileLayer(
                                            urlTemplate:
                                                'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                                            subdomains: const ['a', 'b', 'c', 'd'],
                                            userAgentPackageName: 'com.getmypair.app',
                                          ),
                                          CircleLayer(
                                            optimizeRadiusInMeters: true,
                                            circles: [
                                              for (final r in [300.0, 200.0, 100.0])
                                                CircleMarker(
                                                  point: _markerPosition,
                                                  radius: r,
                                                  useRadiusInMeter: true,
                                                  color: Colors.transparent,
                                                  borderStrokeWidth: 1.2,
                                                  borderColor: const Color(0xFF212121).withValues(alpha: 0.55),
                                                ),
                                            ],
                                          ),
                                          MarkerLayer(
                                            markers: [
                                              ..._buildCobblerMarkers(),
                                              _homeMarker(userDisplayName, userImageUrl),
                                            ],
                                          ),
                                        ],
                                      ),
                                      Positioned(
                                        right: 10,
                                        bottom: 10,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: const [
                                            _RingLabel('300m'),
                                            SizedBox(height: 2),
                                            _RingLabel('200m'),
                                            SizedBox(height: 2),
                                            _RingLabel('100m'),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.fromLTRB(hPad, 10, hPad, 14),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _isLoadingAddress ? 'Loading address…' : _address,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.montserrat(
                                        fontSize: Responsive.fontSize(context, 12),
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  FilledButton(
                                    onPressed: _confirmLocation,
                                    style: FilledButton.styleFrom(
                                      backgroundColor: _tealButton,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: Text(
                                      'Confirm',
                                      style: GoogleFonts.montserrat(
                                        fontSize: Responsive.fontSize(context, 14),
                                        fontWeight: FontWeight.w600,
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
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: _ShoeCareBottomNav(
                  profileBloc: widget.profileBloc,
                  onHome: () => Navigator.of(context).maybePop(),
                  onShoeRack: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => const ArticleListPage()),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RingLabel extends StatelessWidget {
  final String text;

  const _RingLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: Responsive.fontSize(context, 11),
        fontWeight: FontWeight.w600,
        color: const Color(0xFF212121).withValues(alpha: 0.65),
        shadows: const [
          Shadow(color: Colors.white, blurRadius: 4),
          Shadow(color: Colors.white, blurRadius: 2),
        ],
      ),
    );
  }
}

/// User location: name tag + profile photo (aligned with home header avatar).
class _UserMapPin extends StatelessWidget {
  final String displayName;
  final String? profileImageUrl;

  const _UserMapPin({
    required this.displayName,
    this.profileImageUrl,
  });

  static const double _avatarD = 40;

  @override
  Widget build(BuildContext context) {
    final trimmed = displayName.trim();
    final initial = trimmed.isEmpty ? 'U' : trimmed[0].toUpperCase();
    final hasUrl = profileImageUrl != null && profileImageUrl!.isNotEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          constraints: const BoxConstraints(maxWidth: 132),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0F6876),
                Color(0xFF062F35),
              ],
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: const [
              BoxShadow(color: Color(0x40000000), blurRadius: 4, offset: Offset(0, 2)),
            ],
          ),
          child: Text(
            displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Container(
          width: _avatarD,
          height: _avatarD,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: const [
              BoxShadow(color: Color(0x40000000), blurRadius: 6, offset: Offset(0, 2)),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: hasUrl
              ? Image.network(
                  profileImageUrl!,
                  width: _avatarD,
                  height: _avatarD,
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                  filterQuality: FilterQuality.medium,
                  errorBuilder: (_, __, ___) => _pinInitials(initial),
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  },
                )
              : _pinInitials(initial),
        ),
      ],
    );
  }

  Widget _pinInitials(String letter) {
    return ColoredBox(
      color: const Color(0xFFE8E8E8),
      child: Center(
        child: Text(
          letter,
          style: GoogleFonts.montserrat(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF424242),
          ),
        ),
      ),
    );
  }
}

/// Gradient name tag + 5★ + person icon (map marker).
class _CobblerMapPin extends StatelessWidget {
  final String name;

  const _CobblerMapPin({required this.name});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0F6876),
                Color(0xFF062F35),
              ],
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: const [
              BoxShadow(color: Color(0x40000000), blurRadius: 4, offset: Offset(0, 2)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                style: GoogleFonts.montserrat(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  5,
                  (_) => const Icon(Icons.star_rounded, size: 11, color: Color(0xFFFFD54F)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        SvgPicture.asset(
          'assets/images/map-pin.svg',
          width: 36,
          height: 36,
          fit: BoxFit.contain,
        ),
      ],
    );
  }
}

/// Teal pill bar: Home (selected), favorites, rack, cart, profile.
class _ShoeCareBottomNav extends StatelessWidget {
  final ProfileBloc profileBloc;
  final VoidCallback onHome;
  final VoidCallback onShoeRack;

  _ShoeCareBottomNav({
    required this.profileBloc,
    required this.onHome,
    required this.onShoeRack,
  });

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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        gradient: _barGradient,
        borderRadius: BorderRadius.circular(100),
        boxShadow: const [
          BoxShadow(
            color: Color(0xFFABABAB),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _navItem(
            selected: true,
            icon: Icons.home_rounded,
            onTap: onHome,
          ),
          _navItem(
            selected: false,
            icon: Icons.favorite_border_rounded,
            onTap: () {
              showAppFeedbackAlert(
                context,
                message: 'Favorites coming soon',
                type: AppFeedbackType.info,
              );
            },
          ),
          _navItem(
            selected: false,
            icon: Icons.checkroom_outlined,
            onTap: onShoeRack,
          ),
          _navItem(
            selected: false,
            icon: Icons.shopping_cart_outlined,
            onTap: () {
              showAppFeedbackAlert(
                context,
                message: 'Cart coming soon',
                type: AppFeedbackType.info,
              );
            },
          ),
          _navItem(
            selected: false,
            icon: Icons.person_outline_rounded,
            onTap: () {
              Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
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
    );
  }

  Widget _navItem({
    required bool selected,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final child = Icon(icon, color: Colors.white, size: 24);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: selected
              ? DecoratedBox(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(icon, color: const Color(0xFF062F35), size: 22),
                  ),
                )
              : child,
        ),
      ),
    );
  }
}
