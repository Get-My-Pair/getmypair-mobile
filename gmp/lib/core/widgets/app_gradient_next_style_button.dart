import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Primary call-to-action pill button used across the Articles flow.
///
/// Visually mirrors the "Verify OTP" gradient pill: teal → cyan horizontal
/// gradient, white `boldonse` label, optional [leading] icon on the left and
/// an optional trailing chevron-right ("Next" style). When [isBusy] is true,
/// a circular progress indicator replaces the label and presses are ignored.
class AppGradientNextStyleButton extends StatelessWidget {
  const AppGradientNextStyleButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.leading,
    this.isBusy = false,
    this.minWidth,
    this.showTrailingIcon = true,
    this.height = 48,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? leading;
  final bool isBusy;
  final double? minWidth;
  final bool showTrailingIcon;
  final double height;

  static const Color _onGradient = Color(0xFFFFFFFF);
  static const LinearGradient _gradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF12899B), Color(0xFF09E0FF)],
  );

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !isBusy;

    final width = MediaQuery.sizeOf(context).width;
    final uiScale = (width / 390).clamp(0.84, 1.12).toDouble();
    final labelSize = (14.0 * uiScale).clamp(13.0, 16.0);

    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: minWidth ?? 0),
      child: SizedBox(
        height: height,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(100),
            gradient: _gradient,
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A000000),
                blurRadius: 4,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: enabled ? onPressed : null,
              borderRadius: BorderRadius.circular(100),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (leading != null) ...[
                      leading!,
                      const SizedBox(width: 10),
                    ],
                    if (isBusy)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(_onGradient),
                        ),
                      )
                    else
                      Flexible(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.boldonse(
                            fontSize: labelSize,
                            fontWeight: FontWeight.w400,
                            color: _onGradient,
                          ),
                        ),
                      ),
                    if (!isBusy && showTrailingIcon) ...[
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: _onGradient,
                        size: 22,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
