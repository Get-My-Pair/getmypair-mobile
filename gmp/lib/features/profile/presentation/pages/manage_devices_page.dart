import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/floating_gradient_bottom_nav.dart';

/// Account Settings → Manage Devices: view and remove sessions on other devices.
class ManageDevicesPage extends StatelessWidget {
  const ManageDevicesPage({super.key});

  static String _deviceLabel() {
    if (kIsWeb) return 'Web browser';
    return defaultTargetPlatform == TargetPlatform.android
        ? 'Android device'
        : defaultTargetPlatform == TargetPlatform.iOS
            ? 'iPhone / iPad'
            : 'This device';
  }

  static bool _isPhone() {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  @override
  Widget build(BuildContext context) {
    final thisDeviceLabel = _isPhone() ? 'Android' : _deviceLabel();
    final h = Responsive.horizontalPaddingOf(context);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const ShapeDecoration(
                  gradient: SweepGradient(
                    center: Alignment(0.22, -1.07),
                    startAngle: -0.55,
                    endAngle: 5.73,
                    colors: [
                      Color(0xFF09E0FF),
                      Color(0xFF0F6876),
                      Color(0xFF062F35),
                      Color(0xFF062F35),
                    ],
                    stops: [0.05, 0.44, 0.57, 1.0],
                    transform: GradientRotation(-0.55),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  shadows: [
                    BoxShadow(
                      color: Color(0xFFABABAB),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(h, 44, h, 112),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Manage Devices',
                        style: GoogleFonts.boldonse(
                          color: const Color(0xFFDFE7E9),
                          fontSize: 24,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Devices you\'re currently logged in on. Remove one to sign out from it',
                        style: GoogleFonts.montserrat(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 42),
                      Text(
                        'This Device',
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _DeviceRow(
                        icon: Icons.phone_android,
                        label: thisDeviceLabel,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Other Devices',
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const _DeviceRow(
                        icon: Icons.desktop_windows,
                        label: 'Desktop',
                      ),
                      const _DeviceRow(
                        icon: Icons.watch,
                        label: 'Smart Watch',
                        showTopDivider: false,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const DashboardLinkedBottomNav(selectedTabIndex: 2),
          ],
        ),
      ),
    );
  }
}

class _DeviceRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool showTopDivider;

  const _DeviceRow({
    required this.icon,
    required this.label,
    this.showTopDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: showTopDivider
              ? BorderSide(
                  color: Colors.white.withValues(alpha: 0.50),
                  width: 1,
                )
              : BorderSide.none,
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.50),
            width: 1,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: Color(0xFF71F5FF),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
