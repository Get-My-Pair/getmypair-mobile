import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gmp/core/theme/app_colors.dart';
import 'package:gmp/core/widgets/app_feedback_alert.dart';

const Color _kOtpDevPrimary = Color(0xFF062F35);

/// Development OTP popup shown when the API returns the code in the response.
Future<void> showDevOtpDialog({
  required BuildContext context,
  required String otp,
  required VoidCallback onPrimary,
  String primaryActionLabel = 'Continue',
  String? secondaryActionLabel,
  Future<void> Function(BuildContext dialogContext)? onSecondary,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return Dialog(
        alignment: Alignment.center,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'OTP Code (Development)',
                textAlign: TextAlign.center,
                style: GoogleFonts.boldonse(
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                  color: _kOtpDevPrimary,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Your OTP code is:',
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textSecondary,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 12),
              SelectableText(
                otp.isEmpty ? '—' : otp,
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: _kOtpDevPrimary,
                  letterSpacing: 4,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 22),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (secondaryActionLabel != null && onSecondary != null)
                    TextButton(
                      onPressed: () => onSecondary(dialogContext),
                      child: Text(
                        secondaryActionLabel,
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  FilledButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      onPrimary();
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textOnPrimary,
                      minimumSize: const Size(120, 44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      primaryActionLabel,
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Copy OTP, close dialog, show feedback, then run [onAfterCopy].
Future<void> copyOtpAndCloseDialog({
  required BuildContext dialogContext,
  required BuildContext hostContext,
  required String otp,
  required Future<void> Function() onAfterCopy,
}) async {
  await Clipboard.setData(ClipboardData(text: otp));
  if (dialogContext.mounted) {
    Navigator.of(dialogContext).pop();
  }
  if (!hostContext.mounted) return;
  await showAppFeedbackAlert(
    hostContext,
    message: 'OTP copied to clipboard',
    type: AppFeedbackType.success,
  );
  if (!hostContext.mounted) return;
  await onAfterCopy();
}
