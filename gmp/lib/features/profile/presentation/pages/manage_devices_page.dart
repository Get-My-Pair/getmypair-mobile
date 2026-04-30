import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/bgtheme.dart';
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
    final statusTop = MediaQuery.paddingOf(context).top;

    return Scaffold(
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  image: const DecorationImage(
                    image: AssetImage(BgTheme.backgroundImageAsset),
                    fit: BoxFit.cover,
                  ),
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
                margin: const EdgeInsets.only(bottom: 14),
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(h, statusTop + 72, h, 112),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Manage Devices',
                        style: GoogleFonts.boldonse(
                          color: const Color(0xFFDFE7E9),
                          fontSize: 25,
                          fontWeight: FontWeight.w400,
                          height: 1.18,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Devices you\'re currently logged in on. Remove one to sign out from it',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.montserrat(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          height: 1.2,
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
                        iconAsset: 'assets/images/icons/profile/smartphone.svg',
                        label: thisDeviceLabel,
                        showTopDivider: false,
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
                        iconAsset: 'assets/images/icons/profile/monitor.svg',
                        label: 'Desktop',
                        showTopDivider: false,
                      ),
                      const _DeviceRow(
                        iconAsset: 'assets/images/icons/profile/watch.svg',
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
  final String iconAsset;
  final String label;
  final bool showTopDivider;

  const _DeviceRow({
    required this.iconAsset,
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
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Row(
            children: [
              SvgPicture.asset(
                iconAsset,
                width: 20,
                height: 20,
                colorFilter: const ColorFilter.mode(
                  Colors.white,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: 18),
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
                icon: SvgPicture.asset(
                  'assets/images/icons/profile/trash-2.svg',
                  width: 20,
                  height: 20,
                  colorFilter: const ColorFilter.mode(
                    Color(0xFF71F5FF),
                    BlendMode.srcIn,
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
