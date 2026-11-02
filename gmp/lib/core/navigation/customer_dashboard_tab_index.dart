import 'package:flutter/foundation.dart';

/// Syncs [CustomerDashboardPage]'s tab when profile sub-routes set the tab before
/// popping back to the dashboard root.
///
/// `0` = Home, `1` = My Rack. Profile is opened as a pushed route, not a tab page.
final ValueNotifier<int> customerDashboardTabIndex = ValueNotifier<int>(0);

/// When `true`, the Home ↔ My Rack vertical [PageView] may accept a downward
/// swipe from My Rack (list is at top / empty / loading).
final ValueNotifier<bool> myRackAllowsHomeSwipe = ValueNotifier<bool>(true);
