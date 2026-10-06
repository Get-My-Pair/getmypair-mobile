import 'package:flutter/material.dart';
import 'package:gmp/core/bgtheme.dart';
import 'package:gmp/core/widgets/floating_gradient_bottom_nav.dart';
import 'package:google_fonts/google_fonts.dart';

class SellColors {
  static const Color ink = Color(0xFF062F35);
  static const Color teal = Color(0xFF0E7C8A);
  static const Color price = Color(0xFF12808C);
  static const Color panel = Color(0xFFF0F0F0);
  static const Color line = Color(0xFF8FD0DA);
  static const Color pending = Color(0xFFF5C400);
  static const Color approved = Color(0xFF1FA84A);
  static const Color rejected = Color(0xFFE53935);

  static const BorderRadius panelRadius = BorderRadius.only(
    topLeft: Radius.circular(20),
    topRight: Radius.circular(20),
    bottomLeft: Radius.circular(50),
    bottomRight: Radius.circular(50),
  );
}

Color sellStatusColor(String status) {
  switch (status) {
    case 'approved':
      return SellColors.approved;
    case 'rejected':
      return SellColors.rejected;
    default:
      return SellColors.pending;
  }
}

String sellStatusLabel(String status) {
  switch (status) {
    case 'approved':
      return 'Approved';
    case 'rejected':
      return 'Rejected';
    default:
      return 'In review';
  }
}

String formatInr(num value) {
  final digits = value.round().abs().toString();
  if (digits.length <= 3) return digits;
  final last3 = digits.substring(digits.length - 3);
  var rest = digits.substring(0, digits.length - 3);
  final parts = <String>[];
  while (rest.length > 2) {
    parts.insert(0, rest.substring(rest.length - 2));
    rest = rest.substring(0, rest.length - 2);
  }
  if (rest.isNotEmpty) parts.insert(0, rest);
  return '${parts.join(',')},$last3';
}

int? parseInr(String value) {
  final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.isEmpty) return null;
  return int.tryParse(digits);
}

class SellFlowScaffold extends StatelessWidget {
  final List<Widget> children;

  const SellFlowScaffold({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final horizontalInset = (10.0 * (width / 390)).clamp(8.0, 16.0);

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          ...BgTheme.background(),
          Positioned.fill(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(horizontalInset, 52, horizontalInset, 0),
                child: DecoratedBox(
                  decoration: const ShapeDecoration(
                    color: SellColors.panel,
                    shape: RoundedRectangleBorder(borderRadius: SellColors.panelRadius),
                    shadows: [
                      BoxShadow(
                        color: Color(0x19000000),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: SellColors.panelRadius,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 130),
                      children: children,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: DashboardLinkedBottomNav(selectedTabIndex: 1),
          ),
        ],
      ),
    );
  }
}

class SellPageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onBack;

  const SellPageHeader({super.key, required this.title, this.subtitle, this.onBack});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: onBack ?? () => Navigator.maybePop(context),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 26, height: 26),
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: SellColors.ink,
                size: 22,
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.boldonse(
                  color: SellColors.ink,
                  fontSize: 24,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
        if (subtitle != null)
          Padding(
            padding: const EdgeInsets.only(left: 34, top: 2),
            child: Text(
              subtitle!,
              style: GoogleFonts.boldonse(
                color: SellColors.teal,
                fontSize: 14,
                height: 1.2,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
      ],
    );
  }
}

class SellShoeThumb extends StatelessWidget {
  final String? imageUrl;
  final Color? ringColor;

  const SellShoeThumb({super.key, this.imageUrl, this.ringColor});

  @override
  Widget build(BuildContext context) {
    final image = imageUrl != null && imageUrl!.isNotEmpty
        ? Image.network(
            imageUrl!,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => const _FallbackShoe(),
          )
        : const _FallbackShoe();
    return Container(
      width: 72,
      height: 72,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: ringColor ?? Colors.transparent,
          width: ringColor == null ? 0 : 3,
        ),
      ),
      child: image,
    );
  }
}

class _FallbackShoe extends StatelessWidget {
  const _FallbackShoe();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/icons/myrack/shoe.png',
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => const Icon(Icons.ice_skating, color: SellColors.teal),
    );
  }
}
