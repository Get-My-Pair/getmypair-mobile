import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:gmp/core/navigation/customer_dashboard_tab_index.dart';

/// Pops the route, or switches the dashboard to Home and pops to root — same as
/// [ArticleListPage] rack header back affordance.
void popOrGoToDashboardHome(BuildContext context) {
  final nav = Navigator.of(context);
  if (nav.canPop()) {
    nav.pop();
    return;
  }
  customerDashboardTabIndex.value = 0;
  nav.popUntil((route) => route.isFirst);
}

/// Horizontal and top spacing matching [ArticleListPage] `_buildRackBody` header row.
class ArticleStyleHeaderInsets {
  ArticleStyleHeaderInsets._();

  static double _uiScale(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return (width / 390).clamp(0.84, 1.12).toDouble();
  }

  /// Left inset for the back button row (matches rack `titleLeftInset`).
  static double titleLeftInsetOf(BuildContext context) {
    final uiScale = _uiScale(context);
    final headerHInset = (12.0 * uiScale).clamp(10.0, 20.0);
    return (headerHInset - 4).clamp(10.0, 18.0);
  }

  /// Right inset for the header row (matches rack `headerHInset`).
  static double headerRightInsetOf(BuildContext context) {
    final uiScale = _uiScale(context);
    return (12.0 * uiScale).clamp(10.0, 20.0);
  }

  /// Vertical gap below the top padding block (matches rack `topTitleGap`).
  static double topTitleGapOf(BuildContext context) {
    final uiScale = _uiScale(context);
    return (20.0 * uiScale).clamp(18.0, 28.0).toDouble();
  }

  /// Content padding aligned with the article rack header: below status bar,
  /// plus the same inner offsets as the dashboard article list (SafeArea inner
  /// `topInset` 30 + rack `topTitleGap`).
  static EdgeInsets scrollContentPadding(
    BuildContext context, {
    double bottom = 112,
    double belowStatusExtra = 30,
  }) {
    final statusTop = MediaQuery.paddingOf(context).top;
    final topGap = topTitleGapOf(context);
    return EdgeInsets.fromLTRB(
      titleLeftInsetOf(context),
      statusTop + belowStatusExtra + topGap,
      headerRightInsetOf(context),
      bottom,
    );
  }
}

/// Chevron back control — 44×44 min tap target with a 26×26 chevron glyph.
class ChevronScreenBackButton extends StatelessWidget {
  const ChevronScreenBackButton({
    super.key,
    required this.iconColor,
    this.onPressed,
    this.iconAssetPath = 'assets/images/chevron-left.svg',
    this.tooltip = 'Back',
  });

  final Color iconColor;
  final VoidCallback? onPressed;
  final String iconAssetPath;
  final String tooltip;

  static const double iconSize = 26;
  static const double tapTarget = 44;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(
        width: tapTarget,
        height: tapTarget,
      ),
      visualDensity: VisualDensity.standard,
      onPressed: onPressed ?? () => popOrGoToDashboardHome(context),
      icon: SvgPicture.asset(
        iconAssetPath,
        width: iconSize,
        height: iconSize,
        colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
      ),
    );
  }
}
