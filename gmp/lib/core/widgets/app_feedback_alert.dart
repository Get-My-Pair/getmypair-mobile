import 'package:flutter/material.dart';
import 'package:gmp/core/errors/user_facing_error.dart';
import 'package:gmp/core/theme/app_colors.dart';
import 'package:gmp/core/widgets/network_error_view.dart';

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
/// Failure messages are sanitized — raw backend / API text is never shown.
/// Network failures use the network-error visual dialog.
///
/// When [autoDismissAfter] is set, the OK button is hidden and the dialog
/// closes itself after that duration (then the returned future completes).
Future<void> showAppFeedbackAlert(
  BuildContext context, {
  required String message,
  AppFeedbackType type = AppFeedbackType.info,
  String? title,
  Duration? autoDismissAfter,
  VoidCallback? onRetry,
}) {
  if (!context.mounted) return Future.value();

  // Failures: never show backend/API payloads; network gets dedicated UI.
  if (type == AppFeedbackType.failure && autoDismissAfter == null) {
    return showUserFacingErrorDialog(
      context,
      error: message,
      onRetry: onRetry,
    );
  }

  final safeMessage = type == AppFeedbackType.failure
      ? UserFacingError.sanitize(message)
      : message;
  final resolvedTitle = title ??
      (type == AppFeedbackType.failure
          ? UserFacingError.titleFor(message)
          : _defaultTitle(type));
  final accent = type == AppFeedbackType.failure &&
          UserFacingError.isNetwork(message)
      ? AppColors.primary
      : _accentFor(type);
  final autoDismiss = autoDismissAfter != null;
  final icon = type == AppFeedbackType.failure &&
          UserFacingError.isNetwork(message)
      ? Icons.wifi_off_rounded
      : _iconFor(type);

  return showDialog<void>(
    context: context,
    barrierDismissible: !autoDismiss,
    builder: (ctx) {
      if (autoDismiss) {
        Future<void>.delayed(autoDismissAfter, () {
          if (ctx.mounted) Navigator.of(ctx).pop();
        });
      }
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 48, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 300),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: accent, size: 32),
                const SizedBox(height: 12),
                Text(
                  resolvedTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  safeMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
                if (!autoDismiss) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      style: FilledButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: _labelOnAccent(type),
                        minimumSize: const Size(0, 40),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('OK'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
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
