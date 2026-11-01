import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Add/Edit footwear Colour field: pill + Material-style swatch grid.
/// Stores a `#RRGGBB` string (or empty when nothing selected).
class FootwearColourPicker extends StatefulWidget {
  const FootwearColourPicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.glassShell,
  });

  /// Current colour as `#RRGGBB` or a named colour; null/empty = none.
  final String? value;
  final ValueChanged<String?> onChanged;
  final bool enabled;

  /// Optional wrapper matching the form’s glass input chrome.
  final Widget Function(Widget child)? glassShell;

  @override
  State<FootwearColourPicker> createState() => _FootwearColourPickerState();
}

class _FootwearColourPickerState extends State<FootwearColourPicker> {
  bool _expanded = false;

  Color? get _selectedColor => parseFootwearColour(widget.value);

  String get _displayLabel {
    final c = _selectedColor;
    if (c == null) return 'Select colour';
    return colourToHex(c);
  }

  void _toggle() {
    if (!widget.enabled) return;
    setState(() => _expanded = !_expanded);
  }

  void _pick(Color color) {
    if (!widget.enabled) return;
    widget.onChanged(colourToHex(color));
    setState(() => _expanded = false);
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedColor;
    final field = InkWell(
      onTap: widget.enabled ? _toggle : null,
      borderRadius: BorderRadius.circular(100),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            if (selected != null) ...[
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: selected,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.55),
                    width: 1,
                  ),
                ),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Text(
                _displayLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: selected != null ? Colors.white : Colors.white70,
                ),
              ),
            ),
            Icon(
              _expanded
                  ? Icons.keyboard_arrow_up
                  : Icons.keyboard_arrow_down,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 6),
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'Colour',
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                TextSpan(
                  text: '*',
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (widget.glassShell != null) widget.glassShell!(field) else field,
        if (_expanded) ...[
          const SizedBox(height: 12),
          _ColourSwatchGrid(
            selected: selected,
            onSelect: _pick,
          ),
        ],
      ],
    );
  }
}

class _ColourSwatchGrid extends StatelessWidget {
  const _ColourSwatchGrid({
    required this.selected,
    required this.onSelect,
  });

  final Color? selected;
  final ValueChanged<Color> onSelect;

  static const int _cols = 12;
  static const int _rows = 10;

  static List<Color> get _swatches {
    final out = <Color>[];
    // Top row: grayscale white → black (matches Material / screenshot).
    for (var c = 0; c < _cols; c++) {
      final v = (255 - (c * 255 / (_cols - 1))).round().clamp(0, 255);
      out.add(Color.fromARGB(255, v, v, v));
    }
    // Remaining rows: hue across, value down.
    for (var r = 1; r < _rows; r++) {
      final value = 1.0 - ((r - 1) / (_rows - 2)) * 0.85;
      for (var c = 0; c < _cols; c++) {
        final hue = (c / _cols) * 360.0;
        out.add(HSVColor.fromAHSV(1, hue, 0.85, value.clamp(0.15, 1.0)).toColor());
      }
    }
    return out;
  }

  bool _isSelected(Color a, Color? b) {
    if (b == null) return false;
    return a.toARGB32() == b.toARGB32();
  }

  @override
  Widget build(BuildContext context) {
    final colors = _swatches;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF09DFFF), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF09DFFF).withValues(alpha: 0.28),
            blurRadius: 10,
            spreadRadius: 0.5,
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final gap = 2.0;
          final cellW =
              (constraints.maxWidth - gap * (_cols - 1)) / _cols;
          final cellH = (cellW * 0.72).clamp(14.0, 22.0);
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (final color in colors)
                GestureDetector(
                  onTap: () => onSelect(color),
                  child: Container(
                    width: cellW,
                    height: cellH,
                    decoration: BoxDecoration(
                      color: color,
                      border: _isSelected(color, selected)
                          ? Border.all(color: Colors.black, width: 2)
                          : Border.all(
                              color: Colors.black.withValues(alpha: 0.12),
                              width: 0.5,
                            ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

String colourToHex(Color color) {
  final r = (color.r * 255).round().clamp(0, 255);
  final g = (color.g * 255).round().clamp(0, 255);
  final b = (color.b * 255).round().clamp(0, 255);
  return '#${r.toRadixString(16).padLeft(2, '0')}'
          '${g.toRadixString(16).padLeft(2, '0')}'
          '${b.toRadixString(16).padLeft(2, '0')}'
      .toUpperCase();
}

Color? parseFootwearColour(String? raw) {
  if (raw == null) return null;
  final s = raw.trim();
  if (s.isEmpty) return null;

  final hex = s.startsWith('#') ? s.substring(1) : s;
  if (RegExp(r'^[0-9A-Fa-f]{6}$').hasMatch(hex)) {
    return Color(int.parse(hex, radix: 16) + 0xFF000000);
  }
  if (RegExp(r'^[0-9A-Fa-f]{8}$').hasMatch(hex)) {
    return Color(int.parse(hex, radix: 16));
  }

  const named = <String, Color>{
    'black': Color(0xFF1A1A1A),
    'white': Color(0xFFF5F5F5),
    'brown': Color(0xFF5C4033),
    'navy': Color(0xFF0F2540),
    'denim': Color(0xFF11253F),
    'grey': Color(0xFF6B7280),
    'gray': Color(0xFF6B7280),
    'green': Color(0xFF2E6B3C),
    'red': Color(0xFFB83232),
    'blue': Color(0xFF1E4A7A),
    'tan': Color(0xFFC4A77D),
    'pink': Color(0xFFC97B9A),
    'yellow': Color(0xFFE6C84A),
    'orange': Color(0xFFD97736),
  };
  return named[s.toLowerCase()];
}
