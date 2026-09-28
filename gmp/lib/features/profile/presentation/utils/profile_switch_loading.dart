import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../bloc/profile_state.dart';

/// Single loading popup while the active family/self profile is switching.
///
/// Stays open through [ProfileSwitching] and the first [ProfileLoaded] after
/// the switch. Close only via [onDetailsReady] once the new details are on
/// screen, or on [ProfileError].
class ProfileSwitchLoading {
  ProfileSwitchLoading._();

  static bool _visible = false;
  static bool _waitingForDetails = false;
  static String? _targetProfileId;
  static int _seq = 0;

  static void sync(BuildContext context, ProfileState current) {
    if (current is ProfileSwitching) {
      _targetProfileId = current.targetProfileId;
      _waitingForDetails = true;
      _show(context, current.targetName);
      return;
    }

    if (current is ProfileError) {
      _waitingForDetails = false;
      _close(context);
    }
    // ProfileLoaded: keep the popup until [onDetailsReady].
  }

  /// Call after the switched profile’s details have been painted.
  static void onDetailsReady(BuildContext context, {String? profileId}) {
    if (!_visible && !_waitingForDetails) return;
    if (profileId != null &&
        _targetProfileId != null &&
        profileId != _targetProfileId) {
      return;
    }
    _waitingForDetails = false;
    _close(context);
  }

  static void _show(BuildContext context, String targetName) {
    if (_visible || !context.mounted) return;
    _visible = true;
    final seq = ++_seq;
    final name = targetName.trim();
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (ctx) => PopScope(
        canPop: false,
        child: AlertDialog(
          backgroundColor: const Color(0xFF0B3A4A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Switching profile',
                textAlign: TextAlign.center,
                style: GoogleFonts.boldonse(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
              if (name.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Loading $name…',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    ).whenComplete(() {
      if (seq == _seq) {
        _visible = false;
        _waitingForDetails = false;
      }
    });

    Future<void>.delayed(const Duration(seconds: 12), () {
      if (seq != _seq || !_visible) return;
      _waitingForDetails = false;
      _close(context);
    });
  }

  static void _close(BuildContext context) {
    if (!_visible) return;
    _visible = false;
    _waitingForDetails = false;
    _targetProfileId = null;
    if (!context.mounted) return;
    final nav = Navigator.of(context, rootNavigator: true);
    if (nav.canPop()) nav.pop();
  }
}
