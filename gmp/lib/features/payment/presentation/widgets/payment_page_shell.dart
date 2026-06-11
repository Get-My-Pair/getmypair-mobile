import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../service/presentation/widgets/service_request_bg_layer.dart';

/// Shared visual tokens for payment flow screens (matches service request UI).
abstract class PaymentPageTheme {
  PaymentPageTheme._();

  static const panelRadius = BorderRadius.only(
    topLeft: Radius.circular(20),
    topRight: Radius.circular(20),
    bottomLeft: Radius.circular(50),
    bottomRight: Radius.circular(50),
  );

  static const titleColor = Color(0xFF062F35);
  static const accentColor = Color(0xFF12899B);
  static const loaderColor = Color(0xFF11999E);

  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0F6876), Color(0xFF062F35)],
  );

  static const buttonGradient = LinearGradient(
    begin: Alignment.centerRight,
    end: Alignment.centerLeft,
    colors: [Color(0xFF0CADC5), Color(0xFF063239)],
  );

  static BoxDecoration surfaceCardDecoration({double radius = 14}) =>
      BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: const Color(0xFF0F6876).withValues(alpha: 0.35),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      );
}

/// Frosted panel over [ServiceRequestBgLayer] — same shell as service flows.
class PaymentPageShell extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Color? subtitleColor;
  final List<Widget>? actions;
  final Widget body;
  final Widget? bottomBar;
  final bool expandBody;

  const PaymentPageShell({
    super.key,
    required this.title,
    this.subtitle,
    this.subtitleColor,
    this.actions,
    required this.body,
    this.bottomBar,
    this.expandBody = true,
  });

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true,
        body: Stack(
          children: [
            ...ServiceRequestBgLayer.stackBehind(),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 30, 10, 0),
                child: DecoratedBox(
                  decoration: ShapeDecoration(
                    color: ServiceRequestBgLayer.panelFill,
                    shape: const RoundedRectangleBorder(
                      borderRadius: PaymentPageTheme.panelRadius,
                    ),
                    shadows: const [
                      BoxShadow(
                        color: Color(0x19000000),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: PaymentPageTheme.panelRadius,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 12, 8, 0),
                          child: Row(
                            children: [
                              IconButton(
                                onPressed: () => Navigator.maybePop(context),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints.tightFor(
                                  width: 26,
                                  height: 26,
                                ),
                                icon: const Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  color: PaymentPageTheme.titleColor,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  title,
                                  style: GoogleFonts.boldonse(
                                    color: PaymentPageTheme.titleColor,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ),
                              if (actions != null) ...actions!,
                            ],
                          ),
                        ),
                        if (subtitle != null)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                            child: Text(
                              subtitle!,
                              style: GoogleFonts.montserrat(
                                color: subtitleColor ??
                                    Colors.black.withValues(alpha: 0.55),
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        if (expandBody) Expanded(child: body) else body,
                        if (bottomBar != null) bottomBar!,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PaymentAmountHero extends StatelessWidget {
  final String label;
  final String amountText;
  final String? caption;

  const PaymentAmountHero({
    super.key,
    required this.label,
    required this.amountText,
    this.caption,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: PaymentPageTheme.heroGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.montserrat(
              color: AppColors.onGradientMuted,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            amountText,
            style: GoogleFonts.boldonse(
              fontSize: 32,
              fontWeight: FontWeight.w400,
              color: Colors.white,
            ),
          ),
          if (caption != null) ...[
            const SizedBox(height: 8),
            Text(
              caption!,
              style: GoogleFonts.montserrat(
                color: AppColors.onGradientMuted,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class PaymentSurfaceCard extends StatelessWidget {
  final String? title;
  final Widget child;
  final EdgeInsetsGeometry padding;

  const PaymentSurfaceCard({
    super.key,
    this.title,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: PaymentPageTheme.surfaceCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: GoogleFonts.montserrat(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: PaymentPageTheme.accentColor,
              ),
            ),
            const SizedBox(height: 10),
          ],
          child,
        ],
      ),
    );
  }
}

class PaymentDetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;

  const PaymentDetailRow({
    super.key,
    required this.label,
    required this.value,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: GoogleFonts.montserrat(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                color: PaymentPageTheme.titleColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PaymentStepRow extends StatelessWidget {
  final String step;
  final String text;

  const PaymentStepRow({super.key, required this.step, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: PaymentPageTheme.accentColor.withValues(alpha: 0.15),
            child: Text(
              step,
              style: GoogleFonts.montserrat(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: PaymentPageTheme.accentColor,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.montserrat(
                fontSize: 14,
                color: PaymentPageTheme.titleColor,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PaymentResultIcon extends StatelessWidget {
  final IconData icon;
  final Color color;

  const PaymentResultIcon({
    super.key,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Icon(icon, size: 48, color: color),
    );
  }
}

class PaymentSecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const PaymentSecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: PaymentPageTheme.titleColor,
          side: BorderSide(
            color: PaymentPageTheme.accentColor.withValues(alpha: 0.45),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
