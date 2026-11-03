import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gmp/core/errors/user_facing_error.dart';
import 'package:gmp/core/theme/app_colors.dart';

/// Full-page / inline network (or generic) error content.
/// Hides raw backend messages — shows friendly copy + optional retry.
class NetworkErrorView extends StatelessWidget {
  const NetworkErrorView({
    super.key,
    this.error,
    this.onRetry,
    this.compact = false,
  });

  /// Raw error used only to choose network vs generic copy (never shown).
  final Object? error;
  final VoidCallback? onRetry;
  final bool compact;

  bool get _isNetwork => UserFacingError.isNetwork(error);

  @override
  Widget build(BuildContext context) {
    final title = UserFacingError.titleFor(error);
    final message = UserFacingError.messageFor(error);
    final iconSize = compact ? 56.0 : 88.0;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 28,
          vertical: compact ? 16 : 32,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _NetworkErrorVisual(
              isNetwork: _isNetwork,
              size: iconSize,
            ),
            SizedBox(height: compact ? 16 : 24),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: compact ? 17 : 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: compact ? 13 : 14,
                fontWeight: FontWeight.w400,
                height: 1.4,
                color: AppColors.textSecondary,
              ),
            ),
            if (onRetry != null) ...[
              SizedBox(height: compact ? 18 : 24),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 20),
                label: Text(
                  'Try again',
                  style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textOnPrimary,
                  minimumSize: const Size(160, 46),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NetworkErrorVisual extends StatefulWidget {
  const _NetworkErrorVisual({
    required this.isNetwork,
    required this.size,
  });

  final bool isNetwork;
  final double size;

  @override
  State<_NetworkErrorVisual> createState() => _NetworkErrorVisualState();
}

class _NetworkErrorVisualState extends State<_NetworkErrorVisual>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isNetwork ? AppColors.primary : AppColors.error;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = 0.85 + (_controller.value * 0.15);
        return Transform.scale(
          scale: t,
          child: child,
        );
      },
      child: Container(
        width: widget.size + 24,
        height: widget.size + 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.10),
        ),
        child: Icon(
          widget.isNetwork
              ? Icons.wifi_off_rounded
              : Icons.cloud_off_rounded,
          size: widget.size * 0.55,
          color: color,
        ),
      ),
    );
  }
}

/// Dialog version of [NetworkErrorView] (no raw API text).
Future<void> showUserFacingErrorDialog(
  BuildContext context, {
  Object? error,
  VoidCallback? onRetry,
}) {
  if (!context.mounted) return Future.value();
  final isNetwork = UserFacingError.isNetwork(error);
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      content: NetworkErrorView(
        error: error,
        compact: true,
        onRetry: onRetry == null
            ? null
            : () {
                Navigator.of(ctx).pop();
                onRetry();
              },
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        if (onRetry == null)
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: FilledButton.styleFrom(
              backgroundColor:
                  isNetwork ? AppColors.primary : AppColors.error,
              foregroundColor: AppColors.textOnPrimary,
              minimumSize: const Size(120, 44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('OK'),
          )
        else
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Close',
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
      ],
    ),
  );
}
