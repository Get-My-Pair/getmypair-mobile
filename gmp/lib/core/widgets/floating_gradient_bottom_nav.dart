import 'package:flutter/material.dart';

import 'package:gmp/core/navigation/customer_dashboard_tab_index.dart';

/// Pill-shaped floating bar: dark teal → cyan gradient, white outline icons,
/// selected tab on a solid white circle (icon in dark teal).
/// Tabs: Home · Services (rack) · Profile.
class FloatingGradientBottomNav extends StatelessWidget {
  const FloatingGradientBottomNav({
    super.key,
    required this.currentIndex,
    required this.onChanged,
  });

  final int currentIndex;
  final ValueChanged<int> onChanged;

  static const double barHeight = 56;
  static const double hitSize = 44;
  static const Color selectedIconColor = Color(0xFF08343A);

  @override
  Widget build(BuildContext context) {
    final items = <({IconData outlined, IconData filled})>[
      (outlined: Icons.home_outlined, filled: Icons.home_rounded),
      (outlined: Icons.hiking_outlined, filled: Icons.hiking_rounded),
      (outlined: Icons.person_outline_rounded, filled: Icons.person_rounded),
    ];

    return Material(
      color: Colors.transparent,
      elevation: 0,
      child: Container(
        height: barHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(barHeight / 2),
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Color(0xFF08343A),
              Color(0xFF0F6876),
              Color(0xFF00E0FF),
            ],
            stops: [0.0, 0.42, 1.0],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: 18,
              offset: const Offset(0, 8),
              spreadRadius: -4,
            ),
            BoxShadow(
              color: const Color(0xFF0A6C78).withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(items.length, (i) {
              final selected = i == currentIndex;
              final pair = items[i];
              return Expanded(
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
                        child: Icon(
                          selected ? pair.filled : pair.outlined,
                          size: 24,
                          color: selected ? selectedIconColor : Colors.white,
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

/// Same bar as the dashboard, wired to [customerDashboardTabIndex] and root pop.
/// Use on profile stack pages so Home / Rack / Profile match main navigation.
class DashboardLinkedBottomNav extends StatelessWidget {
  const DashboardLinkedBottomNav({
    super.key,
    this.selectedTabIndex = 2,
  });

  /// Highlight while this route is visible (profile flow → 2).
  final int selectedTabIndex;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
        child: FloatingGradientBottomNav(
          currentIndex: selectedTabIndex.clamp(0, 2),
          onChanged: (i) {
            final tab = i.clamp(0, 2);
            customerDashboardTabIndex.value = tab;
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
        ),
      ),
    );
  }
}
