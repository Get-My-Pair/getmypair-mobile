import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String? hintText;
  final String? labelText;
  final TextInputType keyboardType;
  final bool autofocus;
  final FocusNode? focusNode;
  final int? maxLength;
  final String? errorText;
  final List<TextInputFormatter>? inputFormatters;
  final void Function(String)? onChanged;
  final bool obscureText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;

  const CustomTextField({
    super.key,
    required this.controller,
    this.hintText,
    this.labelText,
    this.keyboardType = TextInputType.text,
    this.autofocus = false,
    this.focusNode,
    this.maxLength,
    this.errorText,
    this.inputFormatters,
    this.onChanged,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (labelText != null) ...[
          Text(
            labelText!,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
        ],
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          autofocus: autofocus,
          focusNode: focusNode,
          maxLength: maxLength,
          obscureText: obscureText,
          inputFormatters: inputFormatters,
          onChanged: onChanged,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: AppColors.textTertiary,
            ),
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            counterText: '',
            errorText: errorText,
            filled: true,
            fillColor: AppColors.surfaceVariant,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.error, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
