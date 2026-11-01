import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

/// Shared gradient pill search used on Care / Save / Rehome hubs (and home).
///
/// Fixes clipped hint/input text inside the fixed-height pill and avoids the
/// keyboard shoving / crushing the hub layout when the field is focused.
class HubGradientSearchBar extends StatefulWidget {
  final String hintText;
  final ValueChanged<String>? onChanged;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final bool showClear;
  final VoidCallback? onClear;
  final VoidCallback? onSubmitted;

  const HubGradientSearchBar({
    super.key,
    required this.hintText,
    this.onChanged,
    this.controller,
    this.focusNode,
    this.showClear = false,
    this.onClear,
    this.onSubmitted,
  });

  @override
  State<HubGradientSearchBar> createState() => _HubGradientSearchBarState();
}

class _HubGradientSearchBarState extends State<HubGradientSearchBar> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  late final bool _ownsController;
  late final bool _ownsFocusNode;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _ownsFocusNode = widget.focusNode == null;
    _controller = widget.controller ?? TextEditingController();
    _focusNode = widget.focusNode ?? FocusNode();
    if (widget.showClear) {
      _controller.addListener(_onTextTick);
    }
  }

  void _onTextTick() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    if (widget.showClear) {
      _controller.removeListener(_onTextTick);
    }
    if (_ownsController) _controller.dispose();
    if (_ownsFocusNode) _focusNode.dispose();
    super.dispose();
  }

  void _dismissKeyboard() {
    if (!_focusNode.hasFocus) return;
    _focusNode.unfocus();
    FocusManager.instance.primaryFocus?.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final uiScale = (width / 390).clamp(0.84, 1.12).toDouble();
    // Tall enough that Montserrat 16 never clips inside the pill.
    final searchHeight = (46.0 * uiScale).clamp(42.0, 50.0);
    final fontSize = (15.0 * uiScale).clamp(13.0, 16.0);
    final showClear = widget.showClear && _controller.text.isNotEmpty;

    return Container(
      height: searchHeight,
      padding: const EdgeInsets.all(1.2),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFF0F6876), Color(0xFF09E0FF)],
        ),
        borderRadius: BorderRadius.circular(100),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              SvgPicture.asset(
                'assets/images/search.svg',
                width: 20,
                height: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  onChanged: widget.onChanged,
                  autofocus: false,
                  textInputAction: TextInputAction.search,
                  textAlignVertical: TextAlignVertical.center,
                  // Keep hub chrome stable when IME opens.
                  scrollPadding: EdgeInsets.zero,
                  onSubmitted: (_) {
                    widget.onSubmitted?.call();
                    _dismissKeyboard();
                  },
                  onTapOutside: (_) => _dismissKeyboard(),
                  style: GoogleFonts.montserrat(
                    fontSize: fontSize,
                    color: Colors.black87,
                    fontWeight: FontWeight.w400,
                  ),
                  // Match home search: avoid isCollapsed (clips hint glyphs).
                  decoration: InputDecoration(
                    isDense: true,
                    isCollapsed: false,
                    filled: false,
                    fillColor: Colors.transparent,
                    contentPadding: const EdgeInsets.symmetric(vertical: 9),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    hintText: widget.hintText,
                    hintStyle: GoogleFonts.montserrat(
                      color: Colors.black.withValues(alpha: 0.34),
                      fontSize: fontSize,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
              if (showClear) ...[
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () {
                    _controller.clear();
                    widget.onChanged?.call('');
                    widget.onClear?.call();
                    _dismissKeyboard();
                  },
                  child: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: Colors.black.withValues(alpha: 0.34),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
