import 'package:flutter/material.dart';
import 'package:gmp/core/theme/app_colors.dart';

/// Semantic feedback for [showAppFeedbackAlert].
enum AppFeedbackType {
  success,
  failure,
  warning,
  info,
}

/// Standard dialog when a screen action is not built yet.
Future<void> showComingSoon(
  BuildContext context, {
  required String feature,
}) {
  if (!context.mounted) return Future.value();
  return showAppFeedbackAlert(
    context,
    title: 'Coming soon',
    message: '$feature is coming soon.',
    type: AppFeedbackType.info,
  );
}

/// Single-action alert dialog for consistent success / error / warning / info UX.
///
/// When [autoDismissAfter] is set, the OK button is hidden and the dialog
/// closes itself after that duration (then the returned future completes).
Future<void> showAppFeedbackAlert(
  BuildContext context, {
  required String message,
  AppFeedbackType type = AppFeedbackType.info,
  String? title,
  Duration? autoDismissAfter,
}) {
  if (!context.mounted) return Future.value();
  final resolvedTitle = title ?? _defaultTitle(type);
  final accent = _accentFor(type);
  final autoDismiss = autoDismissAfter != null;

  return showDialog<void>(
    context: context,
    barrierDismissible: !autoDismiss,
    builder: (ctx) {
      if (autoDismiss) {
        Future<void>.delayed(autoDismissAfter, () {
          if (ctx.mounted) Navigator.of(ctx).pop();
        });
      }
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: Icon(_iconFor(type), color: accent, size: 36),
        title: Text(
          resolvedTitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            fontSize: 18,
          ),
        ),
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 15,
            height: 1.35,
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: autoDismiss
            ? const <Widget>[]
            : [
                FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: FilledButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: _labelOnAccent(type),
                    minimumSize: const Size(120, 44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('OK'),
                ),
              ],
      );
    },
  );
}

String _defaultTitle(AppFeedbackType type) {
  return switch (type) {
    AppFeedbackType.success => 'Success',
    AppFeedbackType.failure => 'Something went wrong',
    AppFeedbackType.warning => 'Attention',
    AppFeedbackType.info => 'Notice',
  };
}

Color _accentFor(AppFeedbackType type) {
  return switch (type) {
    AppFeedbackType.success => AppColors.success,
    AppFeedbackType.failure => AppColors.error,
    AppFeedbackType.warning => AppColors.warning,
    AppFeedbackType.info => AppColors.primary,
  };
}

IconData _iconFor(AppFeedbackType type) {
  return switch (type) {
    AppFeedbackType.success => Icons.check_circle_outline_rounded,
    AppFeedbackType.failure => Icons.error_outline_rounded,
    AppFeedbackType.warning => Icons.warning_amber_rounded,
    AppFeedbackType.info => Icons.info_outline_rounded,
  };
}

Color _labelOnAccent(AppFeedbackType type) {
  if (type == AppFeedbackType.warning) {
    return AppColors.textPrimary;
  }
  return AppColors.textOnPrimary;
}
