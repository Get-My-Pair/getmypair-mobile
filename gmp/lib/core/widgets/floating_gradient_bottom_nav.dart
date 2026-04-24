import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:gmp/core/navigation/customer_dashboard_tab_index.dart';
import 'package:gmp/core/theme/app_colors.dart';

/// Pill-shaped floating bar: angular (conic) teal sweep from Figma `825:756`,
/// white icons, selected tab on a solid white circle (icon in dark teal).
/// Tabs: Home · Services (rack) · Profile.
///
/// The exported SVG uses `foreignObject` + HTML conic-gradient; Flutter cannot
/// render that as an asset, so the same stops are applied via [SweepGradient].
class FloatingGradientBottomNav extends StatelessWidget {
  const FloatingGradientBottomNav({
    super.key,
    required this.currentIndex,
    required this.onChanged,
  });

  final int currentIndex;
  final ValueChanged<int> onChanged;

  /// Inner pill from Figma: `rect … height="58" rx="29"`.
  static const double barHeight = 58;
  static const double _pillRadius = barHeight / 2;
  static const double hitSize = 44;
  static const Color selectedIconColor = Color(0xFF08343A);
  static const String _homeIcon = 'assets/images/icons/home.svg';
  static const String _middleShoeIcon = 'assets/images/icons/shoe.svg';
  static const String _profileIcon = 'assets/images/icons/profile.svg';

  @override
  Widget build(BuildContext context) {
    final svgIcons = <String>[_homeIcon, _middleShoeIcon, _profileIcon];

    return Material(
      color: Colors.transparent,
      elevation: 0,
      child: Container(
        height: barHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_pillRadius),
          gradient: AppColors.figma825AngularSweep,
          // Matches SVG filter: `feOffset dy="4"` + `feGaussianBlur stdDeviation="6"`.
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFABABAB).withValues(alpha: 0.55),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 10,
            vertical: (barHeight - hitSize) / 2,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(svgIcons.length, (i) {
              final selected = i == currentIndex;
              // Use fixed-width cells so `spaceBetween` can increase the gap between items.
              return SizedBox(
                width: hitSize,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => onChanged(i),
                    customBorder: const CircleBorder(),
                    splashColor: Colors.white24,
                    highlightColor: Colors.white10,
                    child: Center(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutCubic,
                        width: hitSize,
                        height: hitSize,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: selected ? Colors.white : Colors.transparent,
                          boxShadow: selected
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.12),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: SvgPicture.asset(
                          svgIcons[i],
                          width: i == 2 ? 23 : 22,
                          height: i == 2 ? 23 : 22,
                          colorFilter: ColorFilter.mode(
                            selected ? selectedIconColor : Colors.white,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

/// Outer padding around [FloatingGradientBottomNav] on [CustomerDashboardPage]
/// and on pushed stack pages that use [DashboardLinkedBottomNav].
///
/// Horizontal insets scale down on narrow devices so the pill does not overflow;
/// at ~390px width they stay close to the original 80px side margins.
EdgeInsets dashboardBottomNavOuterInsets(BuildContext context) {
  final w = MediaQuery.sizeOf(context).width;
  final safeBottom = MediaQuery.viewPaddingOf(context).bottom;
  const minBarBody = 172.0;
  final side = ((w - minBarBody) * 0.5).clamp(16.0, 88.0);
  // Use a moderated bottom inset so bars stay comfortable above gesture/home
  // areas without floating too high on devices with large safe insets.
  final bottom = safeBottom <= 0
      ? 6.0
      : (safeBottom * 0.55 + 2.0).clamp(8.0, 22.0).toDouble();
  return EdgeInsets.fromLTRB(side, 16, side, bottom);
}

/// Same bar as the dashboard, wired to [customerDashboardTabIndex] and root pop.
/// Use on profile stack pages so Home / Rack / Profile match main navigation.
class DashboardLinkedBottomNav extends StatelessWidget {
  const DashboardLinkedBottomNav({super.key, this.selectedTabIndex = 2});

  /// Highlight while this route is visible (profile flow → 2).
  final int selectedTabIndex;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: dashboardBottomNavOuterInsets(context),
      child: FloatingGradientBottomNav(
        currentIndex: selectedTabIndex.clamp(0, 2),
        onChanged: (i) {
          final tab = i.clamp(0, 2);
          customerDashboardTabIndex.value = tab;
          Navigator.of(context).popUntil((route) => route.isFirst);
        },
      ),
    );
  }
}
