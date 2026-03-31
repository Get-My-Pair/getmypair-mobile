import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive.dart';

/// Metro-style select delivery location page: map with draggable pin,
/// "Use my current location", and Confirm Location.
class SelectLocationPage extends StatefulWidget {
  final String initialAddress;

  const SelectLocationPage({super.key, this.initialAddress = ''});

  @override
  State<SelectLocationPage> createState() => _SelectLocationPageState();
}

class _SelectLocationPageState extends State<SelectLocationPage> {
  static const LatLng _defaultCenter = LatLng(13.0827, 80.2707); // Chennai
  final MapController _mapController = MapController();
  LatLng _markerPosition = _defaultCenter;
  String _address = 'Loading address...';
  bool _isLoadingAddress = false;
  bool _isLoadingCurrent = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initLocation();
    });
  }

  Future<void> _initLocation() async {
    try {
      bool enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        setState(() => _address = 'Location services disabled');
        return;
      }
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever ||
          perm == LocationPermission.denied) {
        setState(() {
          _markerPosition = _defaultCenter;
          _address = 'Allow location to use current position';
        });
        _updateAddressFromLatLng(_defaultCenter);
        return;
      }
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final latLng = LatLng(position.latitude, position.longitude);
      setState(() => _markerPosition = latLng);
      _mapController.move(latLng, 16);
      _updateAddressFromLatLng(latLng);
    } catch (e) {
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
      List<Placemark> placemarks = await placemarkFromCoordinates(
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
      if (mounted) {
        setState(() => _address = 'Selected location');
      }
    } finally {
      if (mounted) setState(() => _isLoadingAddress = false);
    }
  }

  Future<void> _useCurrentLocation() async {
    if (_isLoadingCurrent) return;
    setState(() => _isLoadingCurrent = true);
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final latLng = LatLng(position.latitude, position.longitude);
      setState(() => _markerPosition = latLng);
      _mapController.move(latLng, 16);
      await _updateAddressFromLatLng(latLng);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not get current location')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingCurrent = false);
    }
  }

  void _confirmLocation() {
    // If reverse geocoding failed, pass lat,lng so home can convert to address
    final result = (_address == 'Selected location')
        ? '${_markerPosition.latitude}, ${_markerPosition.longitude}'
        : _address;
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: TextField(
            readOnly: true,
            decoration: InputDecoration(
              hintText: 'Search for building, street or area',
              hintStyle: TextStyle(
                fontSize: 14,
                color: AppColors.textTertiary,
              ),
              prefixIcon: Icon(Icons.search, color: AppColors.textSecondary, size: 22),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _markerPosition,
              initialZoom: 15,
              onTap: (_, latLng) {
                setState(() => _markerPosition = latLng);
                _updateAddressFromLatLng(latLng);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.getmypair.app',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _markerPosition,
                    width: 48,
                    height: 48,
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.red,
                      size: 48,
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Overlay text
          Positioned(
            top: 16,
            left: Responsive.horizontalPaddingOf(context),
            right: Responsive.horizontalPaddingOf(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primaryDark.withOpacity(0.92),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Order will be delivered here. Move the pin to change location.',
                style: TextStyle(color: AppColors.textOnPrimary, fontSize: 13),
              ),
            ),
          ),
          // Use current location button
          Positioned(
            bottom: 180 + MediaQuery.of(context).padding.bottom,
            left: Responsive.horizontalPaddingOf(context),
            child: Material(
              color: AppColors.textOnPrimary,
              borderRadius: BorderRadius.circular(12),
              elevation: 4,
              child: InkWell(
                onTap: _isLoadingCurrent ? null : _useCurrentLocation,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.my_location,
                        color: _isLoadingCurrent ? AppColors.textTertiary : AppColors.error,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isLoadingCurrent ? 'Getting location...' : 'Use my current location',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _isLoadingCurrent ? Colors.grey : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Bottom card: Deliver To + Confirm
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 16,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    Responsive.horizontalPaddingOf(context),
                    20,
                    Responsive.horizontalPaddingOf(context),
                    16 + MediaQuery.of(context).padding.bottom,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Deliver To',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.location_on, color: AppColors.primary, size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _address,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _confirmLocation,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: AppColors.textOnPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Confirm Location', style: TextStyle(fontWeight: FontWeight.w600)),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward, size: 20),
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
        ],
      ),
    );
  }
}
