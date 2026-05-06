import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:gmp/core/navigation/customer_dashboard_tab_index.dart';
import 'package:gmp/core/theme/app_colors.dart';
import 'package:gmp/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:gmp/features/profile/presentation/pages/profile_page.dart';
import 'package:gmp/injection_container.dart';

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
            horizontal: 12,
            vertical: (barHeight - hitSize) / 2,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final tabCount = svgIcons.length;
              final slotWidth = constraints.maxWidth / tabCount;
              final dynamicHitSize = slotWidth.clamp(28.0, hitSize).toDouble();
              final iconBase = (dynamicHitSize * 0.50).clamp(14.0, 22.0).toDouble();
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(tabCount, (i) {
                  final selected = i == currentIndex;
                  return SizedBox(
                    width: dynamicHitSize,
                    height: hitSize,
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
                            width: dynamicHitSize,
                            height: dynamicHitSize,
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
                              width: i == 2 ? iconBase + 1 : iconBase,
                              height: i == 2 ? iconBase + 1 : iconBase,
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
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Outer padding around [FloatingGradientBottomNav] on [CustomerDashboardPage]
/// and on pushed stack pages that use [DashboardLinkedBottomNav].
///
/// Horizontal insets scale down on narrow devices so the pill does not overflow,
/// while keeping the bar visibly wider on most phones.
EdgeInsets dashboardBottomNavOuterInsets(BuildContext context) {
  final w = MediaQuery.sizeOf(context).width;
  final safeBottom = MediaQuery.viewPaddingOf(context).bottom;
  const minBarBody = 240.0;
  final side = ((w - minBarBody) * 0.5).clamp(20.0, 72.0);
  // Scale bottom inset with width + safe-area so spacing feels consistent
  // across compact phones and larger screens.
  final widthFactor = ((w - 320.0) / 160.0).clamp(0.0, 1.0);
  final baseBottom = 14.5 + (widthFactor * 6.3);
  final bottom = safeBottom <= 0
      ? baseBottom
      : (baseBottom + (safeBottom * 0.72)).clamp(16.0, 36.0).toDouble();
  return EdgeInsets.fromLTRB(side, 7, side, bottom);
}

/// Same bar as the dashboard, wired to [customerDashboardTabIndex] and root pop.
/// Use on profile stack pages so Home / Rack / Profile match main navigation.
class DashboardLinkedBottomNav extends StatelessWidget {
  const DashboardLinkedBottomNav({
    super.key,
    this.selectedTabIndex = 2,
    this.onProfileTabWhenCannotPop,
  });

  /// Highlight while this route is visible (profile flow → 2).
  final int selectedTabIndex;

  /// When the user taps Profile (tab 2) and this navigator cannot pop, run this
  /// instead of only syncing tab — e.g. open Edit Profile from the root profile screen.
  final VoidCallback? onProfileTabWhenCannotPop;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: dashboardBottomNavOuterInsets(context),
      child: FloatingGradientBottomNav(
        currentIndex: selectedTabIndex.clamp(0, 2),
        onChanged: (i) {
          final tab = i.clamp(0, 2);
          if (tab == selectedTabIndex) return;
          customerDashboardTabIndex.value = tab;
          final nav = Navigator.of(context);
          if (tab == 2) {
            if (onProfileTabWhenCannotPop != null && !nav.canPop()) {
              onProfileTabWhenCannotPop!();
              return;
            }
            ProfileBloc profileBloc;
            try {
              profileBloc = context.read<ProfileBloc>();
            } catch (_) {
              profileBloc = sl<ProfileBloc>();
            }
            nav.push(
              MaterialPageRoute(
                builder: (_) => BlocProvider.value(
                  value: profileBloc,
                  child: const ProfilePage(),
                ),
              ),
            );
            return;
          }
          nav.popUntil((route) => route.isFirst);
        },
      ),
    );
  }
}
