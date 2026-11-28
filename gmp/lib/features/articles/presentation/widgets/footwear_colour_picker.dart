import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Add/Edit footwear Colour field: pill + full-spectrum picker.
/// Stores the **exact colour picked** as `#RRGGBB` (any colour, not limited to
/// a fixed list of names). Older articles that saved a name (e.g. `Navy`) are
/// still read and shown as that name.
class FootwearColourPicker extends StatefulWidget {
  const FootwearColourPicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.glassShell,
  });

  /// Current colour as `#RRGGBB` (or a legacy name); null/empty = none.
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
    final raw = widget.value?.trim() ?? '';
    if (raw.isEmpty) return 'Select colour';
    return footwearColourDisplayName(raw);
  }

  void _toggle() {
    if (!widget.enabled) return;
    setState(() => _expanded = !_expanded);
  }

  /// Dragging the custom picker: update live and keep the panel open.
  void _pickCustom(Color color) {
    if (!widget.enabled) return;
    widget.onChanged(colourToHex(color));
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
          _CustomColourPicker(
            color: selected,
            onChanged: _pickCustom,
          ),
        ],
      ],
    );
  }
}

/// Full-spectrum picker: saturation/brightness square + hue bar.
/// Lets the user pick **any** colour.
class _CustomColourPicker extends StatefulWidget {
  const _CustomColourPicker({
    required this.color,
    required this.onChanged,
  });

  final Color? color;
  final ValueChanged<Color> onChanged;

  @override
  State<_CustomColourPicker> createState() => _CustomColourPickerState();
}

class _CustomColourPickerState extends State<_CustomColourPicker> {
  static const double _areaHeight = 150;
  static const double _barHeight = 24;
  static const double _thumb = 22;

  late HSVColor _hsv;

  @override
  void initState() {
    super.initState();
    _hsv = widget.color != null
        ? HSVColor.fromColor(widget.color!)
        : const HSVColor.fromAHSV(1, 200, 0.85, 0.85);
  }

  @override
  void didUpdateWidget(covariant _CustomColourPicker old) {
    super.didUpdateWidget(old);
    final incoming = widget.color;
    // The saved colour changed from outside (e.g. the article loaded): follow it. (Our own drags produce the same
    // colour, so the hue never jumps while dragging.)
    if (incoming != null && incoming.toARGB32() != _hsv.toColor().toARGB32()) {
      _hsv = HSVColor.fromColor(incoming);
    }
  }

  void _emit(HSVColor next) {
    setState(() => _hsv = next);
    widget.onChanged(next.toColor());
  }

  @override
  Widget build(BuildContext context) {
    final hueOnly = HSVColor.fromAHSV(1, _hsv.hue, 1, 1).toColor();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF09DFFF), width: 1.4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pick any colour',
            style: GoogleFonts.montserrat(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 8),
          // Saturation (left → right) × brightness (bottom → top).
          LayoutBuilder(
            builder: (context, c) {
              final w = c.maxWidth;
              void update(Offset p) {
                final s = (p.dx / w).clamp(0.0, 1.0);
                final v = 1 - (p.dy / _areaHeight).clamp(0.0, 1.0);
                _emit(_hsv.withSaturation(s).withValue(v));
              }

              return GestureDetector(
                onPanStart: (d) => update(d.localPosition),
                onPanUpdate: (d) => update(d.localPosition),
                onTapDown: (d) => update(d.localPosition),
                child: SizedBox(
                  width: w,
                  height: _areaHeight,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.white, hueOnly],
                              ),
                            ),
                            child: const DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [Colors.transparent, Colors.black],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: _hsv.saturation * w - _thumb / 2,
                        top: (1 - _hsv.value) * _areaHeight - _thumb / 2,
                        child: _thumbDot(_hsv.toColor()),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 14),
          // Hue spectrum.
          LayoutBuilder(
            builder: (context, c) {
              final w = c.maxWidth;
              void update(Offset p) {
                final h = (p.dx / w).clamp(0.0, 1.0) * 360;
                _emit(_hsv.withHue(h >= 360 ? 359.99 : h));
              }

              return GestureDetector(
                onPanStart: (d) => update(d.localPosition),
                onPanUpdate: (d) => update(d.localPosition),
                onTapDown: (d) => update(d.localPosition),
                child: SizedBox(
                  width: w,
                  height: _barHeight,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(_barHeight / 2),
                            gradient: LinearGradient(
                              colors: [
                                for (var i = 0; i <= 6; i++)
                                  HSVColor.fromAHSV(1, i * 60.0, 1, 1).toColor(),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: (_hsv.hue / 360) * w - _thumb / 2,
                        top: (_barHeight - _thumb) / 2,
                        child: _thumbDot(hueOnly),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _thumbDot(Color fill) {
    return Container(
      width: _thumb,
      height: _thumb,
      decoration: BoxDecoration(
        color: fill,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: const [
          BoxShadow(color: Colors.black38, blurRadius: 4),
        ],
      ),
    );
  }
}

/// Canonical footwear colour names → swatch.
const Map<String, Color> kFootwearNamedColours = {
  'Black': Color(0xFF1A1A1A),
  'White': Color(0xFFF5F5F5),
  'Grey': Color(0xFF6B7280),
  'Charcoal': Color(0xFF36454F),
  'Silver': Color(0xFFC0C0C0),
  'Brown': Color(0xFF5C4033),
  'Tan': Color(0xFFC4A77D),
  'Beige': Color(0xFFD8C3A5),
  'Cream': Color(0xFFFFFDD0),
  'Navy': Color(0xFF0F2540),
  'Denim': Color(0xFF11253F),
  'Blue': Color(0xFF1E4A7A),
  'Sky Blue': Color(0xFF5BA3D9),
  'Teal': Color(0xFF15808D),
  'Green': Color(0xFF2E6B3C),
  'Olive': Color(0xFF556B2F),
  'Red': Color(0xFFB83232),
  'Maroon': Color(0xFF800000),
  'Burgundy': Color(0xFF6D1A2A),
  'Pink': Color(0xFFC97B9A),
  'Orange': Color(0xFFD97736),
  'Yellow': Color(0xFFE6C84A),
  'Gold': Color(0xFFD4AF37),
  'Purple': Color(0xFF6B3FA0),
};

String colourToHex(Color color) {
  final r = (color.r * 255).round().clamp(0, 255);
  final g = (color.g * 255).round().clamp(0, 255);
  final b = (color.b * 255).round().clamp(0, 255);
  return '#${r.toRadixString(16).padLeft(2, '0')}'
          '${g.toRadixString(16).padLeft(2, '0')}'
          '${b.toRadixString(16).padLeft(2, '0')}'
      .toUpperCase();
}

double _colourDistance(Color a, Color b) {
  final dr = (a.r - b.r) * 255;
  final dg = (a.g - b.g) * 255;
  final db = (a.b - b.b) * 255;
  return math.sqrt(dr * dr + dg * dg + db * db);
}

/// Closest canonical name for [color] (Title Case).
String nearestFootwearColourName(Color color) {
  var bestName = 'Black';
  var bestDist = double.infinity;
  for (final entry in kFootwearNamedColours.entries) {
    final d = _colourDistance(color, entry.value);
    if (d < bestDist) {
      bestDist = d;
      bestName = entry.key;
    }
  }
  return bestName;
}

/// Label for UI: the saved name if it is one, otherwise the exact `#RRGGBB`
/// the user picked (no rounding to a nearest name).
String footwearColourDisplayName(String? raw) {
  if (raw == null) return 'Select colour';
  final s = raw.trim();
  if (s.isEmpty) return 'Select colour';

  final lower = s.toLowerCase();
  for (final entry in kFootwearNamedColours.entries) {
    if (entry.key.toLowerCase() == lower) return entry.key;
  }
  if (lower == 'gray') return 'Grey';

  final parsed = parseFootwearColour(s);
  if (parsed != null) return colourToHex(parsed);

  // Unknown free-text name from API — show as typed, not as hex.
  if (!RegExp(r'^#?[0-9A-Fa-f]{6,8}$').hasMatch(s.replaceAll(' ', ''))) {
    if (s.length == 1) return s.toUpperCase();
    return s[0].toUpperCase() + s.substring(1);
  }
  return nearestFootwearColourName(parsed ?? const Color(0xFF1A1A1A));
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

  final lower = s.toLowerCase();
  for (final entry in kFootwearNamedColours.entries) {
    if (entry.key.toLowerCase() == lower) return entry.value;
  }
  if (lower == 'gray') return kFootwearNamedColours['Grey'];
  return null;
}
