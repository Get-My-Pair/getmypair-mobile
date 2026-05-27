import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Pickup mode toggle colors aligned with the service-create design reference.
abstract final class ServiceFlowPickupPillColors {
  /// Inactive pill — muted gray fill, border, and label (slightly darker than active).
  static const Color inactiveFill = Color(0xFFC9D4D6);
  static const Color inactiveBorder = Color(0xFF707070);
  static const Color inactiveText = Color(0xFF454545);

  /// Active pill — pale mint fill, teal border, dark teal label.
  static const Color activeFill = Color(0xFFE8F6F7);
  static const Color activeBorder = Color(0xFF12899B);
  static const Color activeText = Color(0xFF062F35);
}

/// Home Pickup / Cobblers Nearby pill used in repair, wash, maintain, and donate flows.
class ServiceFlowPickupPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final double height;
  final double fontSize;

  const ServiceFlowPickupPill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.height = 48,
    this.fontSize = 14,
  });

  @override
  Widget build(BuildContext context) {
    final fill = selected
        ? ServiceFlowPickupPillColors.activeFill
        : ServiceFlowPickupPillColors.inactiveFill;
    final border = selected
        ? ServiceFlowPickupPillColors.activeBorder
        : ServiceFlowPickupPillColors.inactiveBorder;
    final textColor = selected
        ? ServiceFlowPickupPillColors.activeText
        : ServiceFlowPickupPillColors.inactiveText;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(100),
      child: Container(
        height: height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(width: 1, color: border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x19000000),
              blurRadius: 4,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.boldonse(
            color: textColor,
            fontSize: fontSize,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
