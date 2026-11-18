import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_skeleton.dart';

class PaymentLoader extends StatelessWidget {
  final String? message;

  const PaymentLoader({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    final messageWidget = message == null
        ? null
        : Padding(
            padding: const EdgeInsets.fromLTRB(32, 0, 32, 24),
            child: Text(
              message!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.35,
              ),
            ),
          );

    return LayoutBuilder(
      builder: (context, constraints) {
        final cards = const SingleChildScrollView(
          physics: NeverScrollableScrollPhysics(),
          child: AppSkeletonCards(),
        );
        if (!constraints.maxHeight.isFinite) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AppSkeletonCards(),
              ?messageWidget,
            ],
          );
        }
        return Column(
          children: [
            Expanded(child: cards),
            ?messageWidget,
          ],
        );
      },
    );
  }
}

class PaymentInlineLoader extends StatelessWidget {
  final String? label;

  const PaymentInlineLoader({super.key, this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(
          width: 18,
          height: 18,
          child: AppSkeletonPulse(
            child: AppSkeletonBone(width: 18, height: 18, radius: 9),
          ),
        ),
        if (label != null) ...[
          const SizedBox(width: 10),
          Text(
            label!,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}
