import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/constants/google_maps_config.dart';
import '../../../../core/bgtheme.dart';
import '../../../../core/maps/google_maps_js_loader.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_feedback_alert.dart';
import '../../../../core/widgets/floating_gradient_bottom_nav.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../auth/domain/usecases/get_valid_access_token.dart';
import '../../../profile/domain/entities/user_profile.dart';
import '../../../profile/presentation/bloc/profile_bloc.dart';
import '../../../profile/presentation/bloc/profile_state.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../../../profile/presentation/utils/saved_location_sync.dart';
import '../../../../injection_container.dart';

export '../../../profile/presentation/utils/saved_location_sync.dart'
    show userProfileFromProfileState;

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
  static const double _initialZoom = 15.5;
  static const double _minZoom = 3.0;
  static const double _maxZoom = 19.0;

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

  final Completer<GoogleMapController> _mapController =
      Completer<GoogleMapController>();
  GoogleMapController? _map;
  LatLng _markerPosition = _defaultCenter;
  String _address = 'Loading address...';
  Placemark? _lastPlacemark;
  bool _isLoadingAddress = false;
  bool _isConfirmingLocation = false;
  bool _isSatelliteView = true;
  double _currentZoom = _initialZoom;
  double _selectedRangeKm = 3;
  static const double _minRangeKm = 0;
  static const double _maxRangeKm = 15;
  /// Allowed search ranges (km): 0, 1, 3, 6, 9, 12, 15.
  static const List<double> _rangeOptionsKm = <double>[
    0,
    1,
    3,
    6,
    9,
    12,
    15,
  ];
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  /// Synced from [_searchFocusNode] listener — never read [FocusNode.hasFocus] in [build] on web.
  bool _searchBarHasFocus = false;
  bool _isLoadingCobblers = false;
  String? _cobblerLoadError;
  /// Web: wait for Maps JS (`google.maps`) before building [GoogleMap].
  bool _mapsReady = !kIsWeb;
  String? _mapsLoadError;

  List<_CobblerProfile> _allCobblers = const [];

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(_syncSearchBarFocusFromNode);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureMapsReady();
      _initLocation();
    });
  }

  Future<void> _ensureMapsReady() async {
    if (!kIsWeb || _mapsReady) return;
    try {
      await ensureGoogleMapsJsLoaded(apiKey: GoogleMapsConfig.apiKey);
      if (!mounted) return;
      setState(() {
        _mapsReady = true;
        _mapsLoadError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _mapsReady = false;
        _mapsLoadError = e.toString();
      });
    }
  }

  void _syncSearchBarFocusFromNode() {
    if (!mounted) return;
    final hasFocus = _searchFocusNode.hasFocus;
    if (_searchBarHasFocus == hasFocus) return;
    setState(() => _searchBarHasFocus = hasFocus);
  }

  @override
  void dispose() {
    _searchFocusNode.removeListener(_syncSearchBarFocusFromNode);
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<_CobblerProfile> _safeCobblersSnapshot() {
    try {
      // Web hot-reload can occasionally leave stale state objects; guard against it.
      final cobblers = _allCobblers;
      return List<_CobblerProfile>.from(cobblers);
    } catch (_) {
      return const [];
    }
  }

  List<_NearbyCobbler> get _nearbyCobblers {
    final query = _searchController.text.trim().toLowerCase();
    final maxMeters = _selectedRangeKm * 1000;
    final allCobblers = _safeCobblersSnapshot();

    final cobblers = allCobblers
        .where((c) => c.isActive)
        .map(
          (c) => _NearbyCobbler(
            profile: c,
            distanceMeters: Geolocator.distanceBetween(
              _markerPosition.latitude,
              _markerPosition.longitude,
              c.point.latitude,
              c.point.longitude,
            ),
          ),
        )
        .where((c) => c.distanceMeters <= maxMeters)
        .where((c) => query.isEmpty || c.profile.name.toLowerCase().contains(query))
        .toList()
      ..sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));
    return cobblers;
  }

  String _formatDistance(double meters) {
    if (meters < 1000) return '${meters.round()} m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  String _currentUserRole() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      return authState.user.role.toLowerCase().trim();
    }
    if (authState is AuthProfileCompleted) {
      return authState.user.role.toLowerCase().trim();
    }
    return '';
  }

  String _normalizeRole(String role) {
    final r = role.toLowerCase().trim();
    if (r == 'cobber') return 'cobbler';
    if (r == 'customer') return 'user';
    return r;
  }

  bool _canFetchNearbyCobblersForRole(String role) {
    // Do not block locally; role payloads can vary across deployments.
    // Let backend auth/authorization decide access.
    return true;
  }

  Future<void> _initLocation() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        if (!mounted) return;
        setState(() => _address = 'Location services disabled');
        _fetchNearbyCobblers();
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
        _fetchNearbyCobblers();
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final latLng = LatLng(position.latitude, position.longitude);
      if (!mounted) return;
      setState(() => _markerPosition = latLng);
      await _moveCamera(latLng, _currentZoom);
      _updateAddressFromLatLng(latLng);
      _fetchNearbyCobblers();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _markerPosition = _defaultCenter;
        _address = 'Location unavailable';
      });
      _updateAddressFromLatLng(_defaultCenter);
      _fetchNearbyCobblers();
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
        _lastPlacemark = p;
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
        _lastPlacemark = null;
        setState(() => _address = 'Selected location');
      }
    } catch (e) {
      if (mounted) setState(() => _address = 'Selected location');
    } finally {
      if (mounted) setState(() => _isLoadingAddress = false);
    }
  }

  Future<void> _confirmLocation() async {
    if (_isConfirmingLocation || _isLoadingAddress) return;
    setState(() => _isConfirmingLocation = true);

    final result = (_address == 'Selected location')
        ? '${_markerPosition.latitude}, ${_markerPosition.longitude}'
        : _address;

    final parts = _lastPlacemark != null
        ? AddressParts.fromPlacemark(_lastPlacemark!)
        : AddressParts.fromDisplayLine(
            _address,
            latitude: _markerPosition.latitude,
            longitude: _markerPosition.longitude,
          );

    final tokenResult = await sl<GetValidAccessToken>().call();
    if (mounted) {
      await tokenResult.fold(
        (_) async {},
        (token) => SavedLocationSync.maybePersist(
          context: context,
          profileBloc: widget.profileBloc,
          accessToken: token,
          parts: parts,
          addresses:
              userProfileFromProfileState(widget.profileBloc.state)?.addresses,
        ),
      );
    }

    if (!mounted) return;
    setState(() => _isConfirmingLocation = false);
    Navigator.of(context).pop(result);
  }

  void _showAddressActions() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined, color: _titleNavy),
              title: const Text('Edit'),
              onTap: () {
                Navigator.of(ctx).pop();
                _searchController.text = _address;
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
              title: const Text('Delete'),
              onTap: () {
                Navigator.of(ctx).pop();
                setState(() {
                  _address = 'Selected location';
                  _searchController.clear();
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterSheet() {
    final nearby = _nearbyCobblers;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nearby cobblers (${_selectedRangeKm.toInt()} km)',
                style: TextStyle(
                  fontSize: Responsive.fontSize(context, 18),
                  fontWeight: FontWeight.w700,
                  color: _titleNavy,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Search radius (${_minRangeKm.toInt()}–${_maxRangeKm.toInt()} km)',
                style: GoogleFonts.montserrat(
                  fontSize: Responsive.fontSize(context, 13),
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                height: (MediaQuery.sizeOf(ctx).height * 0.42).clamp(200.0, 360.0),
                child: Theme(
                  data: Theme.of(context).copyWith(
                    radioTheme: RadioThemeData(
                      fillColor: WidgetStateProperty.resolveWith(
                        (states) => states.contains(WidgetState.selected)
                            ? _tealButton
                            : AppColors.textSecondary.withValues(alpha: 0.55),
                      ),
                    ),
                  ),
                  child: RadioGroup<double>(
                    groupValue: _selectedRangeKm,
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _selectedRangeKm = value);
                      _fetchNearbyCobblers();
                      Navigator.of(ctx).pop();
                      _showFilterSheet();
                    },
                    child: ListView.builder(
                      itemCount: _rangeOptionsKm.length,
                      itemBuilder: (context, index) {
                        final km = _rangeOptionsKm[index];
                        return RadioListTile<double>(
                          dense: true,
                          visualDensity: VisualDensity.compact,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                          value: km,
                          title: Text(
                            '${km.toInt()} km',
                            style: GoogleFonts.montserrat(
                              fontSize: Responsive.fontSize(context, 15),
                              fontWeight: FontWeight.w600,
                              color: _titleNavy,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              if (_isLoadingCobblers)
                const Center(child: CircularProgressIndicator())
              else if (_cobblerLoadError != null)
                Text(
                  _cobblerLoadError!,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: Responsive.fontSize(context, 14),
                  ),
                )
              else if (nearby.isEmpty)
                Text(
                  'No active cobblers right now.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: Responsive.fontSize(context, 14),
                  ),
                )
              else
                ...nearby.map(
                  (c) => _sheetRow(
                    c.profile.name,
                    c.profile.rating,
                    _formatDistance(c.distanceMeters),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _moveCamera(LatLng target, double zoom) async {
    final controller = _map ??
        (_mapController.isCompleted ? await _mapController.future : null);
    if (controller == null) return;
    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: target, zoom: zoom),
      ),
    );
  }

  void _zoomIn() {
    final nextZoom = (_currentZoom + 1).clamp(_minZoom, _maxZoom);
    setState(() => _currentZoom = nextZoom);
    _moveCamera(_markerPosition, nextZoom);
  }

  void _zoomOut() {
    final nextZoom = (_currentZoom - 1).clamp(_minZoom, _maxZoom);
    setState(() => _currentZoom = nextZoom);
    _moveCamera(_markerPosition, nextZoom);
  }

  Widget _sheetRow(String name, double rating, String distanceLabel) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(Icons.person_outline_rounded, color: _tealButton, size: 22),
          const SizedBox(width: 12),
          Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w600))),
          Text(distanceLabel, style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(width: 8),
          Text(rating.toStringAsFixed(1), style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(width: 4),
          Icon(Icons.star_rounded, size: 18, color: Colors.amber.shade700),
        ],
      ),
    );
  }

  Set<Marker> _buildMapMarkers(String displayName) {
    final markers = <Marker>{
      Marker(
        markerId: const MarkerId('user'),
        position: _markerPosition,
        infoWindow: InfoWindow(title: displayName),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        zIndexInt: 2,
      ),
    };
    for (final s in _nearbyCobblers) {
      markers.add(
        Marker(
          markerId: MarkerId('cobbler_${s.profile.id}'),
          position: s.profile.point,
          infoWindow: InfoWindow(
            title: s.profile.name,
            snippet: '${s.profile.rating.toStringAsFixed(1)} ★ · ${_formatDistance(s.distanceMeters)}',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
          zIndexInt: 1,
        ),
      );
    }
    return markers;
  }

  Set<Circle> _buildRangeCircles() {
    final rings = <double>[
      _selectedRangeKm * 1000,
      _selectedRangeKm * 600,
      _selectedRangeKm * 300,
    ];
    return {
      for (var i = 0; i < rings.length; i++)
        Circle(
          circleId: CircleId('range_$i'),
          center: _markerPosition,
          radius: rings[i],
          fillColor: Colors.transparent,
          strokeColor: const Color(0xFF212121).withValues(alpha: 0.55),
          strokeWidth: 1,
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final hPad = Responsive.horizontalPaddingOf(context).clamp(12.0, 20.0);
    final bottomSafe = Responsive.bottomInsetOf(context);
    final bottomNavReserve = FloatingGradientBottomNav.barHeight + 12 + bottomSafe;
    final isCompact = MediaQuery.sizeOf(context).width < 360;
    // Map / Sat toggle and zoom controls: one square size, one icon size (matches filter button).
    final mapControlTile = isCompact ? 44.0 : 48.0;
    final mapControlIconSize = isCompact ? 22.0 : 24.0;
    final canPopRoute = Navigator.of(context).canPop();
    final authState = context.read<AuthBloc>().state;
    final userDisplayName = (widget.mapPinDisplayName != null &&
            widget.mapPinDisplayName!.trim().isNotEmpty)
        ? widget.mapPinDisplayName!.trim()
        : mapPinDisplayNameFrom(null, authState);

    return Scaffold(
      backgroundColor: const Color(0xFF062F35),
      extendBody: true,
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: const AssetImage(BgTheme.backgroundImageAsset),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withValues(alpha: 0.14),
                    BlendMode.darken,
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(10, 8, 10, 0),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(22),
                          topRight: Radius.circular(22),
                          bottomLeft: Radius.circular(36),
                          bottomRight: Radius.circular(36),
                        ),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.45),
                          width: 1.1,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x29000000),
                            blurRadius: 18,
                            offset: Offset(0, 8),
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
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.start,
                                textDirection: TextDirection.ltr,
                                children: [
                                  if (canPopRoute)
                                    SizedBox(
                                      width: 32,
                                      height: 44,
                                      child: GestureDetector(
                                        behavior: HitTestBehavior.opaque,
                                        onTap: () => Navigator.of(context).maybePop(),
                                        child: const Align(
                                          alignment: Alignment.centerLeft,
                                          child: Icon(
                                            Icons.arrow_back_ios_new_rounded,
                                            size: 20,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    )
                                  else
                                    const SizedBox(width: 8),
                                  if (canPopRoute) const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      'Cobbler Nearby',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.start,
                                      style: GoogleFonts.boldonse(
                                        color: Colors.white,
                                        fontSize: Responsive.fontSize(context, isCompact ? 19 : 22),
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: hPad),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      // Half of bar height (48): larger values (e.g. 100) can exceed
                                      // RRect limits vs width and trigger "Invalid argument" on some devices.
                                      borderRadius: BorderRadius.circular(24),
                                      child: BackdropFilter(
                                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 220),
                                          curve: Curves.easeOutCubic,
                                          height: 48,
                                          padding: const EdgeInsets.symmetric(horizontal: 12),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(alpha: 0.92),
                                            borderRadius: BorderRadius.circular(24),
                                            border: Border.all(
                                              color: _searchBarHasFocus
                                                  ? const Color(0xFF15808D)
                                                  : Colors.white,
                                              width: _searchBarHasFocus ? 2.2 : 1.6,
                                            ),
                                            boxShadow: [
                                              const BoxShadow(
                                                color: Color(0x22000000),
                                                blurRadius: 10,
                                                offset: Offset(0, 3),
                                              ),
                                              if (_searchBarHasFocus)
                                                BoxShadow(
                                                  color: const Color(0xFF15808D).withValues(alpha: 0.22),
                                                  blurRadius: 14,
                                                  spreadRadius: 0,
                                                ),
                                            ],
                                          ),
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            mainAxisAlignment: MainAxisAlignment.start,
                                            children: [
                                              _AnimatedSearchIcon(
                                                active: !_searchBarHasFocus &&
                                                    _searchController.text.trim().isEmpty,
                                              ),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: TextField(
                                                  controller: _searchController,
                                                  focusNode: _searchFocusNode,
                                                  onChanged: (_) => setState(() {}),
                                                  textAlign: TextAlign.start,
                                                  style: GoogleFonts.montserrat(
                                                    fontSize: Responsive.fontSize(context, 15),
                                                    color: Color(0xFF0A2429),
                                                  ),
                                                  decoration: InputDecoration(
                                                    isDense: true,
                                                    filled: false,
                                                    border: InputBorder.none,
                                                    enabledBorder: InputBorder.none,
                                                    focusedBorder: InputBorder.none,
                                                    disabledBorder: InputBorder.none,
                                                    errorBorder: InputBorder.none,
                                                    focusedErrorBorder: InputBorder.none,
                                                    hintText: 'Search cobbler',
                                                    hintStyle: GoogleFonts.montserrat(
                                                      color: AppColors.textSecondary,
                                                      fontSize: Responsive.fontSize(context, 15),
                                                    ),
                                                    contentPadding:
                                                        const EdgeInsets.symmetric(vertical: 12),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Material(
                                    color: const Color(0xFF0F6876),
                                    borderRadius: BorderRadius.circular(12),
                                    elevation: 2,
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
                                      if (!_mapsReady)
                                        Center(
                                          child: _mapsLoadError == null
                                              ? const CircularProgressIndicator(
                                                  color: _tealButton,
                                                )
                                              : Padding(
                                                  padding: const EdgeInsets.all(16),
                                                  child: Text(
                                                    'Map failed to load.\n'
                                                    'Enable Maps JavaScript API for your key,\n'
                                                    'then fully restart the app (not hot restart).\n\n'
                                                    '$_mapsLoadError',
                                                    textAlign: TextAlign.center,
                                                    style: GoogleFonts.dmSans(
                                                      fontSize: 13,
                                                      color: Colors.black87,
                                                    ),
                                                  ),
                                                ),
                                        )
                                      else
                                        GoogleMap(
                                          initialCameraPosition: CameraPosition(
                                            target: _markerPosition,
                                            zoom: _initialZoom,
                                          ),
                                          mapType: (_isSatelliteView == true)
                                              ? MapType.hybrid
                                              : MapType.normal,
                                          minMaxZoomPreference:
                                              const MinMaxZoomPreference(
                                            _minZoom,
                                            _maxZoom,
                                          ),
                                          // Geolocation + Maps WebGL together is flaky on Chrome.
                                          myLocationEnabled: !kIsWeb,
                                          myLocationButtonEnabled: false,
                                          zoomControlsEnabled: false,
                                          compassEnabled: false,
                                          mapToolbarEnabled: false,
                                          markers:
                                              _buildMapMarkers(userDisplayName),
                                          circles: _buildRangeCircles(),
                                          onMapCreated: (controller) {
                                            _map = controller;
                                            if (!_mapController.isCompleted) {
                                              _mapController.complete(controller);
                                            }
                                          },
                                          onCameraMove: (position) {
                                            _currentZoom = position.zoom;
                                          },
                                          onTap: (latLng) {
                                            setState(
                                              () => _markerPosition = latLng,
                                            );
                                            _updateAddressFromLatLng(latLng);
                                            _fetchNearbyCobblers();
                                          },
                                        ),
                                      Positioned(
                                        right: 10,
                                        bottom: 10,
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            _RingLabel('${_selectedRangeKm.toInt()}km'),
                                            const SizedBox(height: 2),
                                            _RingLabel('${(_selectedRangeKm * 0.6).toStringAsFixed(1)}km'),
                                            const SizedBox(height: 2),
                                            _RingLabel('${(_selectedRangeKm * 0.3).toStringAsFixed(1)}km'),
                                            const SizedBox(height: 10),
                                            Material(
                                              color: (_isSatelliteView == true)
                                                  ? const Color(0xFF0F6876)
                                                  : Colors.white.withValues(alpha: 0.92),
                                              borderRadius: BorderRadius.circular(12),
                                              shadowColor: Colors.black45,
                                              elevation: 2,
                                              child: InkWell(
                                                onTap: () => setState(
                                                  () => _isSatelliteView = !(_isSatelliteView == true),
                                                ),
                                                borderRadius: BorderRadius.circular(12),
                                                child: SizedBox(
                                                  width: mapControlTile,
                                                  height: mapControlTile,
                                                  child: Center(
                                                    child: FittedBox(
                                                      fit: BoxFit.scaleDown,
                                                      child: Text(
                                                        (_isSatelliteView == true) ? 'Map' : 'Sat',
                                                        maxLines: 1,
                                                        style: GoogleFonts.montserrat(
                                                          color: (_isSatelliteView == true)
                                                              ? Colors.white
                                                              : const Color(0xFF0A2429),
                                                          fontSize: Responsive.fontSize(
                                                            context,
                                                            isCompact ? 12 : 13,
                                                          ),
                                                          fontWeight: FontWeight.w700,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            _ZoomButton(
                                              size: mapControlTile,
                                              iconSize: mapControlIconSize,
                                              icon: Icons.add_rounded,
                                              onTap: _zoomIn,
                                            ),
                                            const SizedBox(height: 8),
                                            _ZoomButton(
                                              size: mapControlTile,
                                              iconSize: mapControlIconSize,
                                              icon: Icons.remove_rounded,
                                              onTap: _zoomOut,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.fromLTRB(hPad, 10, hPad, 0),
                              child: _buildNearbyCobblerStrip(),
                            ),
                            Padding(
                              padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 16),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.35),
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: Text(
                                          _isLoadingAddress ? 'Loading address…' : _address,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.left,
                                          style: GoogleFonts.montserrat(
                                            fontSize: Responsive.fontSize(context, 12),
                                            color: Colors.white.withValues(alpha: 0.95),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ),
                                    PopupMenuButton<String>(
                                      tooltip: 'More',
                                      icon: const Icon(
                                        Icons.more_vert_rounded,
                                        color: Colors.white,
                                      ),
                                      onSelected: (value) {
                                        if (value == 'edit') {
                                          _showAddressActions();
                                        } else if (value == 'delete') {
                                          setState(() => _address = 'Selected location');
                                        }
                                      },
                                      itemBuilder: (_) => const [
                                        PopupMenuItem(
                                          value: 'edit',
                                          child: Text('Edit'),
                                        ),
                                        PopupMenuItem(
                                          value: 'delete',
                                          child: Text('Delete'),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 6),
                                    FilledButton(
                                      onPressed: (_isLoadingAddress || _isConfirmingLocation)
                                          ? null
                                          : _confirmLocation,
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
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: bottomNavReserve),
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
                child: DashboardLinkedBottomNav(
                  selectedTabIndex: 0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNearbyCobblerStrip() {
    final nearby = _nearbyCobblers;
    if (_isLoadingCobblers) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
        ),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (_cobblerLoadError != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
        ),
        child: Text(
          _cobblerLoadError!,
          style: GoogleFonts.montserrat(
            fontSize: Responsive.fontSize(context, 12),
            color: Colors.white.withValues(alpha: 0.95),
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    if (nearby.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
        ),
        child: Text(
          'No active cobblers right now.',
          style: GoogleFonts.montserrat(
            fontSize: Responsive.fontSize(context, 12),
            color: Colors.white.withValues(alpha: 0.95),
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    return SizedBox(
      height: 78,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: nearby.length.clamp(0, 8),
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final c = nearby[i];
          return Container(
            width: 176,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.white,
                  child: Text(
                    c.profile.name[0].toUpperCase(),
                    style: const TextStyle(
                      color: _titleNavy,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.profile.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.montserrat(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatDistance(c.distanceMeters),
                        style: GoogleFonts.montserrat(
                          color: Colors.white.withValues(alpha: 0.92),
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Text(
                      c.profile.rating.toStringAsFixed(1),
                      style: GoogleFonts.montserrat(
                        color: Colors.white.withValues(alpha: 0.95),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(Icons.star_rounded, size: 14, color: Color(0xFFFFD54F)),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _fetchNearbyCobblers() async {
    if (_isLoadingCobblers) return;
    setState(() {
      _isLoadingCobblers = true;
      _cobblerLoadError = null;
    });

    try {
      final role = _normalizeRole(_currentUserRole());
      if (!_canFetchNearbyCobblersForRole(role)) {
        if (!mounted) return;
        setState(() {
          _allCobblers = const [];
          _cobblerLoadError = 'Nearby cobblers are unavailable for this account.';
        });
        return;
      }

      final tokenResult = await sl<GetValidAccessToken>().call();
      final token = tokenResult.fold((_) => null, (t) => t);
      if (token == null) {
        if (!mounted) return;
        setState(() {
          _allCobblers = const [];
          _cobblerLoadError = 'Please sign in again to fetch cobblers.';
        });
        return;
      }

      final endpoint = ApiEndpoints.cobblerNearby(
        lat: _markerPosition.latitude,
        lng: _markerPosition.longitude,
        radiusKm: _selectedRangeKm,
      );
      debugPrint(
        '[SelectLocationPage] Fetch nearby cobblers: '
        'lat=${_markerPosition.latitude}, lng=${_markerPosition.longitude}, '
        'radiusKm=$_selectedRangeKm, endpoint=$endpoint',
      );

      final json = await sl<DioClient>().get(endpoint, accessToken: token);
      final data = (json['data'] is Map<String, dynamic>)
          ? json['data'] as Map<String, dynamic>
          : <String, dynamic>{};
      final list = (data['cobblers'] ??
              data['profiles'] ??
              data['items'] ??
              json['cobblers'] ??
              json['profiles'] ??
              json['items']) as List<dynamic>? ??
          const [];

      final parsed = list
          .whereType<Map<String, dynamic>>()
          .map(_parseCobblerProfile)
          .whereType<_CobblerProfile>()
          .toList();
      debugPrint(
        '[SelectLocationPage] Nearby cobbler response parsed: '
        'rawCount=${list.length}, parsedCount=${parsed.length}',
      );

      if (!mounted) return;
      setState(() => _allCobblers = parsed);
    } on ServerException catch (e) {
      debugPrint(
        '[SelectLocationPage] Nearby cobbler API error: '
        'status=${e.statusCode}, message=${e.message}',
      );
      if (!mounted) return;
      var userMsg = e.message;
      if (e.statusCode == 403) {
        final role = _normalizeRole(_currentUserRole());
        if (role == 'user' || role == 'cobbler' || role == 'admin') {
          userMsg = 'Access denied while loading nearby cobblers. Please sign in again.';
        }
      }
      setState(() {
        _allCobblers = const [];
        _cobblerLoadError =
            userMsg.trim().isEmpty ? 'Unable to load cobblers right now.' : userMsg;
      });
    } catch (e) {
      debugPrint('[SelectLocationPage] Nearby cobbler fetch failed: $e');
      if (!mounted) return;
      setState(() {
        _allCobblers = const [];
        _cobblerLoadError = 'Unable to load cobblers right now.';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoadingCobblers = false);
      }
    }
  }

  _CobblerProfile? _parseCobblerProfile(Map<String, dynamic> raw) {
    final id = (raw['_id'] ?? raw['id'] ?? '').toString();
    final name = (raw['name'] ?? raw['fullName'] ?? raw['shopName'] ?? '').toString().trim();

    final location = (raw['location'] is Map<String, dynamic>)
        ? raw['location'] as Map<String, dynamic>
        : <String, dynamic>{};
    // Backend nearby API returns GeoJSON on `lastKnownLocation`, not `location`.
    final lastKnownLocation = (raw['lastKnownLocation'] is Map<String, dynamic>)
        ? raw['lastKnownLocation'] as Map<String, dynamic>
        : <String, dynamic>{};
    final coords =
        _geoJsonCoordinates(location) ?? _geoJsonCoordinates(lastKnownLocation);
    final lat = _toDouble(
      raw['lat'] ??
          raw['latitude'] ??
          location['lat'] ??
          location['latitude'] ??
          location['y'] ??
          lastKnownLocation['lat'] ??
          lastKnownLocation['latitude'] ??
          (coords?.$2),
    );
    final lng = _toDouble(
      raw['lng'] ??
          raw['lon'] ??
          raw['longitude'] ??
          location['lng'] ??
          location['lon'] ??
          location['longitude'] ??
          location['x'] ??
          lastKnownLocation['lng'] ??
          lastKnownLocation['lon'] ??
          lastKnownLocation['longitude'] ??
          (coords?.$1),
    );
    if (name.isEmpty || lat == null || lng == null) return null;

    final rating = _toDouble(raw['rating'] ?? raw['avgRating'] ?? raw['averageRating']) ?? 0;
    final status = (raw['status'] ??
            raw['availabilityStatus'] ??
            raw['onlineStatus'] ??
            '')
        .toString()
        .toLowerCase()
        .trim();
    final isOnline = _toBool(
          raw['isOnline'] ?? raw['online'] ?? raw['onlineMode'] ?? raw['isAvailable'],
        ) ??
        _toBool(location['isOnline'] ?? location['online']);
    final isActiveFlag = _toBool(raw['isActive'] ?? raw['active']);
    final hasAnyAvailabilitySignal =
        isOnline != null || isActiveFlag != null || status.isNotEmpty;
    final isActive = (isOnline == true) ||
        (isActiveFlag == true) ||
        status == 'active' ||
        status == 'online' ||
        status == 'available' ||
        !hasAnyAvailabilitySignal;

    return _CobblerProfile(
      id: id.isEmpty ? name : id,
      name: name,
      point: LatLng(lat, lng),
      rating: rating,
      isActive: isActive,
    );
  }

  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  bool? _toBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    final s = value.toString().toLowerCase().trim();
    if (s == 'true' || s == '1' || s == 'yes' || s == 'online' || s == 'active') {
      return true;
    }
    if (s == 'false' || s == '0' || s == 'no' || s == 'offline' || s == 'inactive') {
      return false;
    }
    return null;
  }

  (double, double)? _geoJsonCoordinates(Map<String, dynamic> location) {
    final coordinates = location['coordinates'];
    if (coordinates is! List || coordinates.length < 2) return null;
    final lon = _toDouble(coordinates[0]);
    final lat = _toDouble(coordinates[1]);
    if (lon == null || lat == null) return null;
    return (lon, lat);
  }
}

class _CobblerProfile {
  final String id;
  final String name;
  final LatLng point;
  final double rating;
  final bool isActive;

  const _CobblerProfile({
    required this.id,
    required this.name,
    required this.point,
    required this.rating,
    required this.isActive,
  });
}

class _NearbyCobbler {
  final _CobblerProfile profile;
  final double distanceMeters;

  const _NearbyCobbler({
    required this.profile,
    required this.distanceMeters,
  });
}

/// Gentle pulse on the magnifier when the bar is idle (empty + unfocused).
class _AnimatedSearchIcon extends StatefulWidget {
  final bool active;

  const _AnimatedSearchIcon({required this.active});

  @override
  State<_AnimatedSearchIcon> createState() => _AnimatedSearchIconState();
}

class _AnimatedSearchIconState extends State<_AnimatedSearchIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _scale = Tween<double>(begin: 1, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    if (widget.active) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(_AnimatedSearchIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      _controller.repeat(reverse: true);
    } else if (!widget.active && oldWidget.active) {
      _controller.stop();
      _controller.animateTo(
        0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scale.value,
          child: child,
        );
      },
      child: const Icon(
        Icons.search_rounded,
        color: Color(0xFF15808D),
        size: 22,
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

class _ZoomButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final double iconSize;

  const _ZoomButton({
    required this.icon,
    required this.onTap,
    required this.size,
    required this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.9),
      borderRadius: BorderRadius.circular(12),
      shadowColor: Colors.black45,
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: size,
          height: size,
          child: Center(
            child: Icon(
              icon,
              color: const Color(0xFF062F35),
              size: iconSize,
            ),
          ),
        ),
      ),
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
                    child: ProfilePage(),
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
