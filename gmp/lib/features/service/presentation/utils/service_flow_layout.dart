import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:gmp/core/widgets/floating_gradient_bottom_nav.dart';

/// Top padding above the grey service-flow panel (matches page shells).
const double kServiceFlowTopInset = 52.0;

const double _kLayoutReferenceHeight = 640.0;

/// UI scale for repair/donate service flows. Uses full screen height so opening
/// the keyboard does not shrink typography and controls.
double serviceFlowLayoutScale(
  BuildContext context, {
  double? uiScale,
}) {
  final width = MediaQuery.sizeOf(context).width;
  final scale = uiScale ?? (width / 390).clamp(0.84, 1.12).toDouble();
  final navH = dashboardLinkedBottomNavStackHeight(context);
  final media = MediaQuery.of(context);
  final panelH = media.size.height - media.padding.top - kServiceFlowTopInset;
  return math
      .min(scale, ((panelH - navH) / _kLayoutReferenceHeight).clamp(0.55, 1.0))
      .toDouble();
}
