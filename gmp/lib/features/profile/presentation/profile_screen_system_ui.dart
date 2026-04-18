import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/bgtheme.dart';
import '../../../core/theme/app_colors.dart';

/// Status bar over teal profile gradients (edge-to-edge; light icons).
const SystemUiOverlayStyle kProfileGradientHeaderSystemUi =
    SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: AppColors.background,
      systemNavigationBarIconBrightness: Brightness.dark,
    );

/// Status bar over [AppColors.background] (loading, errors, plain scaffolds).
const SystemUiOverlayStyle kProfileLightScaffoldSystemUi = SystemUiOverlayStyle(
  statusBarColor: Colors.transparent,
  statusBarIconBrightness: Brightness.dark,
  statusBarBrightness: Brightness.light,
  systemNavigationBarColor: AppColors.background,
  systemNavigationBarIconBrightness: Brightness.dark,
);
