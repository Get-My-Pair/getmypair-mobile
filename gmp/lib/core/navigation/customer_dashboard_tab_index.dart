import 'package:flutter/foundation.dart';

/// Syncs [CustomerDashboardPage]'s tab when profile sub-routes set the tab before
/// popping back to the dashboard root.
final ValueNotifier<int> customerDashboardTabIndex = ValueNotifier<int>(0);
