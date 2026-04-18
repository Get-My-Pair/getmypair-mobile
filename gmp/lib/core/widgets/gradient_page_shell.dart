import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_gradients.dart';

/// Full-screen teal → cyan gradient behind a transparent [Scaffold].
class GradientPageShell extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? floatingActionButton;

  const GradientPageShell({
    super.key,
    this.appBar,
    required this.body,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: AppColors.background,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppGradients.screenTealCyan),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          extendBody: true,
          appBar: appBar,
          body: body,
          floatingActionButton: floatingActionButton,
        ),
      ),
    );
  }
}

/// App bar with white title/icons on the gradient (matches profile / settings).
PreferredSizeWidget buildGradientAppBar({
  required String title,
  Widget? leading,
  List<Widget>? actions,
  bool centerTitle = true,
  bool automaticallyImplyLeading = true,
}) {
  return AppBar(
    backgroundColor: Colors.transparent,
    elevation: 0,
    scrolledUnderElevation: 0,
    surfaceTintColor: Colors.transparent,
    centerTitle: centerTitle,
    automaticallyImplyLeading: automaticallyImplyLeading,
    iconTheme: const IconThemeData(color: Colors.white),
    foregroundColor: Colors.white,
    leading: leading,
    title: Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    ),
    actions: actions,
  );
}

/// App bar with only a white back control (e.g. profile completion).
PreferredSizeWidget buildGradientBackOnlyAppBar({
  required VoidCallback onBack,
}) {
  return AppBar(
    backgroundColor: Colors.transparent,
    elevation: 0,
    scrolledUnderElevation: 0,
    surfaceTintColor: Colors.transparent,
    automaticallyImplyLeading: false,
    iconTheme: const IconThemeData(color: Colors.white),
    leading: IconButton(
      icon: const Icon(Icons.arrow_back, color: Colors.white),
      onPressed: onBack,
    ),
  );
}
