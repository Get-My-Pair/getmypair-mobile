import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Light cyan gradient border + grey fill — disabled “Save Footwear” reference UI.
class GreyedButtonShell extends StatelessWidget {
  final double height;
  final double borderRadius;
  final Widget child;

  const GreyedButtonShell({
    super.key,
    required this.height,
    this.borderRadius = 100,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    const borderWidth = AppColors.greyedButtonBorderWidth;
    final innerRadius = (borderRadius - borderWidth).clamp(0.0, borderRadius);

    return SizedBox(
      height: height,
      child: DecoratedBox(
        decoration: AppColors.greyedButtonOuterDecoration(borderRadius),
        child: Padding(
          padding: const EdgeInsets.all(borderWidth),
          child: DecoratedBox(
            decoration: AppColors.greyedButtonInnerDecoration(innerRadius),
            child: child,
          ),
        ),
      ),
    );
  }
}
