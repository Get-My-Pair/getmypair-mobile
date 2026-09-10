import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../../domain/entities/address.dart';
import '../../domain/entities/user_profile.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../bloc/profile_state.dart';

/// Parsed address fields for syncing GPS / map picks into the profile address list.
class AddressParts {
  final String addressLine1;
  final String city;
  final String state;
  final String pincode;

  const AddressParts({
    required this.addressLine1,
    required this.city,
    required this.state,
    required this.pincode,
  });

  factory AddressParts.fromPlacemark(Placemark placemark) {
    final street = [
      placemark.subThoroughfare,
      placemark.thoroughfare,
    ]
        .where((e) => e != null && e.toString().trim().isNotEmpty)
        .map((e) => e!.trim())
        .join(' ');

    var line1 = street.trim();
    if (line1.isEmpty) {
      line1 = (placemark.subLocality ?? placemark.locality ?? '').trim();
    }
    if (line1.isEmpty) {
      line1 = (placemark.name ?? placemark.street ?? '').trim();
    }

    final city = (placemark.locality ??
            placemark.subAdministrativeArea ??
            placemark.administrativeArea ??
            '')
        .trim();
    final state = (placemark.administrativeArea ?? placemark.country ?? '').trim();
    final pincode = (placemark.postalCode ?? '').trim();

    return AddressParts(
      addressLine1: line1.isEmpty ? city : line1,
      city: city.isEmpty ? state : city,
      state: state,
      pincode: pincode,
    );
  }

  factory AddressParts.fromDisplayLine(
    String display, {
    LatLng? coordinates,
  }) {
    var cleaned = display.replaceFirst(RegExp(r'^📍\s*'), '').trim();
    if (cleaned.isEmpty ||
        cleaned == 'Selected location' ||
        cleaned == 'Loading address...' ||
        cleaned.startsWith('Location ')) {
      if (coordinates != null) {
        return AddressParts(
          addressLine1:
              '${coordinates.latitude.toStringAsFixed(5)}, ${coordinates.longitude.toStringAsFixed(5)}',
          city: 'Current location',
          state: '',
          pincode: '',
        );
      }
      return const AddressParts(
        addressLine1: 'Current location',
        city: '',
        state: '',
        pincode: '',
      );
    }

    final segments =
        cleaned.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    if (segments.length >= 3) {
      return AddressParts(
        addressLine1: segments.sublist(0, segments.length - 2).join(', '),
        city: segments[segments.length - 2],
        state: segments.last,
        pincode: '',
      );
    }
    if (segments.length == 2) {
      return AddressParts(
        addressLine1: segments[0],
        city: segments[1],
        state: '',
        pincode: '',
      );
    }
    return AddressParts(
      addressLine1: cleaned,
      city: '',
      state: '',
      pincode: '',
    );
  }

  String get preview {
    return [
      addressLine1,
      city,
      state,
      pincode,
    ].where((p) => p.trim().isNotEmpty).join(', ');
  }
}

UserProfile? userProfileFromProfileState(ProfileState state) {
  if (state is ProfileLoaded) return state.profile;
  if (state is ProfileUpdating) return state.profile;
  if (state is ProfileImageUploading) return state.profile;
  if (state is ProfileError) return state.profile;
  if (state is AddressActionLoading) return state.profile;
  return null;
}

/// Offers to add or update a saved address — skips exact duplicates; confirms before write.
abstract final class SavedLocationSync {
  SavedLocationSync._();

  static String _norm(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();

  static String _keyFromAddress(Address address) => [
        _norm(address.addressLine1),
        _norm(address.city),
        _norm(address.state),
        _norm(address.pincode),
      ].join('|');

  static String _keyFromParts(AddressParts parts) => [
        _norm(parts.addressLine1),
        _norm(parts.city),
        _norm(parts.state),
        _norm(parts.pincode),
      ].join('|');

  static bool isSameLocation(Address existing, AddressParts parts) {
    if (_keyFromAddress(existing) == _keyFromParts(parts)) return true;

    final existingCity = _norm(existing.city);
    final partsCity = _norm(parts.city);
    if (existingCity.isEmpty || partsCity.isEmpty || existingCity != partsCity) {
      return false;
    }

    final existingLine = _norm(existing.addressLine1);
    final partsLine = _norm(parts.addressLine1);
    if (existingLine.isEmpty || partsLine.isEmpty) return false;
    return existingLine == partsLine ||
        existingLine.contains(partsLine) ||
        partsLine.contains(existingLine);
  }

  static Address? findMatchingAddress(
    List<Address> addresses,
    AddressParts parts,
  ) {
    for (final address in addresses) {
      if (isSameLocation(address, parts)) return address;
    }
    return null;
  }

  /// Returns `true` if the user chose to save or update (or data was already up to date).
  ///
  /// When [promptOnlyWhenEmpty] is true (home open), only asks if there are no
  /// saved addresses — never prompts again once location data exists.
  static Future<bool> maybePersist({
    required BuildContext context,
    required ProfileBloc profileBloc,
    required String accessToken,
    required AddressParts parts,
    List<Address>? addresses,
    bool promptOnlyWhenEmpty = false,
  }) async {
    if (accessToken.isEmpty) return false;
    if (parts.addressLine1.trim().isEmpty && parts.city.trim().isEmpty) {
      return false;
    }

    final resolvedAddresses =
        addresses ?? userProfileFromProfileState(profileBloc.state)?.addresses ?? [];

    // Home open / auto-detect: skip entirely if user already has location data.
    if (promptOnlyWhenEmpty && resolvedAddresses.isNotEmpty) {
      return false;
    }

    final existing = findMatchingAddress(resolvedAddresses, parts);

    if (existing != null && _keyFromAddress(existing) == _keyFromParts(parts)) {
      return false;
    }

    if (!context.mounted) return false;

    final preview = parts.preview;
    final bool? confirmed;
    if (existing != null) {
      // Auto-open flow should not nag to replace existing addresses.
      if (promptOnlyWhenEmpty) return false;

      confirmed = await _showDialog(
        context: context,
        title: 'Update saved location?',
        message:
            'You already have a similar address saved. Replace it with this location?\n\n$preview',
        confirmLabel: 'Replace',
        cancelLabel: 'Keep existing',
      );
      if (confirmed != true || !context.mounted) return false;

      profileBloc.add(
        AddressUpdateRequested(
          accessToken: accessToken,
          addressId: existing.id,
          addressLine1: parts.addressLine1,
          city: parts.city,
          state: parts.state,
          pincode: parts.pincode,
        ),
      );
      return true;
    }

    confirmed = await _showDialog(
      context: context,
      title: 'Save your location?',
      message:
          'Save this location to your address list so you can use it next time you sign in.\n\n$preview',
      confirmLabel: 'Save',
      cancelLabel: 'Not now',
    );
    if (confirmed != true || !context.mounted) return false;

    profileBloc.add(
      AddressAddRequested(
        accessToken: accessToken,
        addressLine1: parts.addressLine1,
        city: parts.city,
        state: parts.state,
        pincode: parts.pincode,
      ),
    );
    return true;
  }

  static Future<bool?> _showDialog({
    required BuildContext context,
    required String title,
    required String message,
    required String confirmLabel,
    required String cancelLabel,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          title,
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        content: Text(
          message,
          style: GoogleFonts.montserrat(fontSize: 14, height: 1.35),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(cancelLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }
}
