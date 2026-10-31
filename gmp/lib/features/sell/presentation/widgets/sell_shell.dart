import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gmp/core/bgtheme.dart';
import 'package:gmp/core/widgets/floating_gradient_bottom_nav.dart';
import 'package:google_fonts/google_fonts.dart';

class SellColors {
  static const Color ink = Color(0xFF062F35);
  static const Color teal = Color(0xFF0E7C8A);
  static const Color price = Color(0xFF12808C);
  static const Color panel = Color(0xFFF0F0F0);
  static const Color line = Color(0xFF8FD0DA);
  static const Color pending = Color(0xFFE99000);
  static const Color approved = Color(0xFF0FB800);
  static const Color rejected = Color(0xFFFF0000);

  static const BorderRadius panelRadius = BorderRadius.only(
    topLeft: Radius.circular(20),
    topRight: Radius.circular(20),
    bottomLeft: Radius.circular(50),
    bottomRight: Radius.circular(50),
  );

  static const String reviewIcon = 'assets/images/sellmypair/review.svg';
  static const String approvedIcon = 'assets/images/sellmypair/done.svg';
  static const String rejectedIcon = 'assets/images/sellmypair/reject.svg';
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

/// Status badge asset for the My Rack footwear thumb (top-right).
String sellStatusIconAsset(String status) {
  switch (status) {
    case 'approved':
      return SellColors.approvedIcon;
    case 'rejected':
      return SellColors.rejectedIcon;
    default:
      return SellColors.reviewIcon;
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

  /// Optional max width for the grey panel on tablets / desktop.
  static const double panelMaxWidth = 720;

  const SellFlowScaffold({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final width = size.width;
    final uiScale = (width / 390).clamp(0.84, 1.2).toDouble();
    final horizontalInset = (10.0 * uiScale).clamp(8.0, 20.0);
    final topInset = (40.0 * uiScale).clamp(28.0, 52.0);
    final contentPadH = (14.0 * uiScale).clamp(10.0, 20.0);
    final contentPadTop = (12.0 * uiScale).clamp(10.0, 16.0);
    final bottomNavH = dashboardLinkedBottomNavStackHeight(context);
    final contentPadBottom = bottomNavH + (12.0 * uiScale).clamp(8.0, 16.0);

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.hardEdge,
        children: [
          ...BgTheme.background(),
          Positioned.fill(
            child: SafeArea(
              bottom: false,
              child: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalInset,
                    topInset,
                    horizontalInset,
                    0,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: panelMaxWidth),
                    child: DecoratedBox(
                      decoration: const ShapeDecoration(
                        color: SellColors.panel,
                        shape: RoundedRectangleBorder(
                          borderRadius: SellColors.panelRadius,
                        ),
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
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final minBodyH = (constraints.maxHeight -
                                    contentPadTop -
                                    contentPadBottom)
                                .clamp(0.0, double.infinity);
                            // ClampingScrollPhysics: no bounce when content
                            // fits; scrolls only when the body overflows.
                            return SingleChildScrollView(
                              physics: const ClampingScrollPhysics(),
                              padding: EdgeInsets.fromLTRB(
                                contentPadH,
                                contentPadTop,
                                contentPadH,
                                contentPadBottom,
                              ),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minHeight: minBodyH,
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: children,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
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
    final width = MediaQuery.sizeOf(context).width;
    final uiScale = (width / 390).clamp(0.84, 1.2).toDouble();
    final titleSize = (24.0 * uiScale).clamp(20.0, 28.0);
    final subtitleSize = (14.0 * uiScale).clamp(12.0, 16.0);
    final iconSize = (22.0 * uiScale).clamp(18.0, 24.0);
    final backBox = (26.0 * uiScale).clamp(24.0, 30.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: onBack ?? () => Navigator.maybePop(context),
              padding: EdgeInsets.zero,
              constraints: BoxConstraints.tightFor(
                width: backBox,
                height: backBox,
              ),
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: SellColors.ink,
                size: iconSize,
              ),
            ),
            SizedBox(width: (4.0 * uiScale).clamp(2.0, 6.0)),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  title,
                  maxLines: 1,
                  style: GoogleFonts.boldonse(
                    color: SellColors.ink,
                    fontSize: titleSize,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
          ],
        ),
        if (subtitle != null)
          Padding(
            padding: EdgeInsets.only(
              left: (backBox + 8).clamp(28.0, 40.0),
              top: 2,
            ),
            child: Text(
              subtitle!,
              style: GoogleFonts.boldonse(
                color: SellColors.teal,
                fontSize: subtitleSize,
                height: 1.2,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
      ],
    );
  }
}

/// Same shelf chrome as home / article My Rack (grey fill, teal bottom edge).
class SellRackShelf extends StatelessWidget {
  final List<Widget> children;
  final double height;

  const SellRackShelf({
    super.key,
    required this.children,
    this.height = 104,
  });

  static const Color shelfBg = Color(0xFFF0F0F0);
  static const Color shelfBorder = Color(0xFF0F6876);
  static const BorderRadius shelfRadius = BorderRadius.only(
    bottomLeft: Radius.circular(10),
    bottomRight: Radius.circular(10),
  );

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final uiScale = (width / 390).clamp(0.84, 1.2).toDouble();
    final shelfH = (height * uiScale).clamp(88.0, 128.0);
    final hPad = (8.0 * uiScale).clamp(6.0, 12.0);
    final vPad = (10.0 * uiScale).clamp(8.0, 12.0);
    final gap = (2.0 * uiScale).clamp(1.0, 4.0);

    return Container(
      height: shelfH,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: shelfBg,
        border: Border(bottom: BorderSide(color: shelfBorder, width: 3)),
        borderRadius: shelfRadius,
      ),
      child: ClipRRect(
        borderRadius: shelfRadius,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: List.generate(3, (index) {
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: gap),
                  child: index < children.length
                      ? children[index]
                      : const SizedBox.shrink(),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

/// One footwear cell on a My Rack shelf, with sell status icon top-right.
class SellRackShoeCell extends StatelessWidget {
  final String? imageUrl;
  final String label;
  final String? status;
  final VoidCallback? onTap;

  const SellRackShoeCell({
    super.key,
    this.imageUrl,
    required this.label,
    this.status,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final uiScale = (width / 390).clamp(0.84, 1.2).toDouble();
    final nameSize = (12.5 * uiScale).clamp(10.5, 14.0);
    final labelGap = (3.0 * uiScale).clamp(2.0, 5.0);
    final badge = (20.0 * uiScale).clamp(16.0, 24.0);
    final short = label.length <= 10 ? label : '${label.substring(0, 9)}...';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Column(
          children: [
            Expanded(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
                      child: imageUrl != null && imageUrl!.isNotEmpty
                          ? Image.network(
                              imageUrl!,
                              fit: BoxFit.contain,
                              errorBuilder: (_, _, _) => const _FallbackShoe(),
                            )
                          : const _FallbackShoe(),
                    ),
                  ),
                  if (status != null)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: SvgPicture.asset(
                        sellStatusIconAsset(status!),
                        width: badge,
                        height: badge,
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(height: labelGap),
            Text(
              short,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: GoogleFonts.boldonse(
                color: const Color(0xFF11899B),
                fontSize: nameSize,
                fontWeight: FontWeight.w400,
                height: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SellShoeThumb extends StatelessWidget {
  final String? imageUrl;
  final Color? ringColor;
  /// When set, draws the sellmypair status SVG in the top-right.
  final String? status;

  const SellShoeThumb({
    super.key,
    this.imageUrl,
    this.ringColor,
    this.status,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final size = (72.0 * (width / 390)).clamp(60.0, 84.0);
    final badge = (22.0 * (width / 390)).clamp(18.0, 26.0);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: imageUrl != null && imageUrl!.isNotEmpty
                ? Image.network(
                    imageUrl!,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const _FallbackShoe(),
                  )
                : const _FallbackShoe(),
          ),
          if (status != null)
            Positioned(
              top: -2,
              right: -2,
              child: SvgPicture.asset(
                sellStatusIconAsset(status!),
                width: badge,
                height: badge,
              ),
            ),
        ],
      ),
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
