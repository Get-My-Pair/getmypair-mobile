import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Standardized dropdown used across article / profile forms.
///
/// Supports glass (on gradient) and light (on white) variants so behavior and
/// chrome stay consistent while matching the surrounding surface.
class AppDropdown<T> extends StatelessWidget {
  const AppDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.label,
    this.hint,
    this.enabled = true,
    this.variant = AppDropdownVariant.glass,
    this.isExpanded = true,
  });

  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String? label;
  final String? hint;
  final bool enabled;
  final AppDropdownVariant variant;
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    final field = variant == AppDropdownVariant.glass
        ? _glassField(_dropdown())
        : _lightField(_dropdown());

    if (label == null) return field;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 6),
          child: Text(
            label!,
            style: GoogleFonts.montserrat(
              fontSize: AppSpacing.labelFontSize,
              fontWeight: FontWeight.w400,
              color: variant == AppDropdownVariant.glass
                  ? Colors.white
                  : AppColors.textPrimary,
            ),
          ),
        ),
        field,
      ],
    );
  }

  Widget _dropdown() {
    final textColor = variant == AppDropdownVariant.glass
        ? Colors.white
        : AppColors.textPrimary;
    final menuColor = variant == AppDropdownVariant.glass
        ? const Color(0xFF0D5B68)
        : AppColors.surface;

    return DropdownButtonFormField<T>(
      value: value,
      isExpanded: isExpanded,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.transparent,
        isDense: true,
        hintText: hint,
        hintStyle: GoogleFonts.montserrat(
          color: textColor.withValues(alpha: 0.7),
          fontSize: AppSpacing.inputFontSize,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
      ),
      dropdownColor: menuColor,
      style: GoogleFonts.montserrat(
        color: textColor,
        fontSize: AppSpacing.inputFontSize,
        fontWeight: FontWeight.w400,
      ),
      iconEnabledColor: textColor,
      iconDisabledColor: textColor.withValues(alpha: 0.4),
      items: items,
      onChanged: enabled ? onChanged : null,
    );
  }

  Widget _glassField(Widget child) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          constraints: const BoxConstraints(minHeight: AppSpacing.fieldHeight),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _lightField(Widget child) {
    return Container(
      constraints: const BoxConstraints(minHeight: AppSpacing.fieldHeight),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

enum AppDropdownVariant { glass, light }
