import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../config/payment_config.dart';
import '../../domain/entities/zoho_payment_mode.dart';

/// Bottom sheet for choosing sandbox, live, or simulated Zoho checkout.
Future<ZohoPaymentMode?> showPaymentModeSheet(BuildContext context) {
  return showModalBottomSheet<ZohoPaymentMode>(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              PaymentConfig.isProductionFlow
                  ? 'Choose payment mode'
                  : 'Choose payment mode (dev)',
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              PaymentConfig.isProductionFlow
                  ? 'Live Zoho checkout only.'
                  : 'Pick one of the checkout methods below.',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            ...PaymentConfig.selectableModes.map((mode) {
              final isLast = mode == PaymentConfig.selectableModes.last;
              return Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
                child: _PaymentModeTile(
                  mode: mode,
                  icon: switch (mode) {
                    ZohoPaymentMode.live => Icons.payments_outlined,
                    ZohoPaymentMode.sandbox => Icons.science_outlined,
                    ZohoPaymentMode.simulate =>
                      Icons.play_circle_outline_rounded,
                  },
                  onTap: () => Navigator.of(ctx).pop(mode),
                ),
              );
            }),
          ],
        ),
      ),
    ),
  );
}

class _PaymentModeTile extends StatelessWidget {
  const _PaymentModeTile({
    required this.mode,
    required this.icon,
    required this.onTap,
  });

  final ZohoPaymentMode mode;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Method ${mode.methodNumber} · ${mode.title}',
                      style: GoogleFonts.montserrat(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      mode.subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
