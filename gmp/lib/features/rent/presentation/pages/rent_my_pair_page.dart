import 'package:flutter/material.dart';
import 'package:gmp/core/bgtheme.dart';
import 'package:gmp/core/widgets/floating_gradient_bottom_nav.dart';
import 'package:gmp/features/rent/presentation/pages/available_rent_footwear_page.dart';
import 'package:gmp/features/rent/presentation/pages/rent_your_footwear_page.dart';
import 'package:google_fonts/google_fonts.dart';

/// Rent My Pair hub: list your pair, or browse approved pairs.
class RentMyPairPage extends StatelessWidget {
  const RentMyPairPage({super.key});

  static const BorderRadius _panelRadius = BorderRadius.only(
    topLeft: Radius.circular(20),
    topRight: Radius.circular(20),
    bottomLeft: Radius.circular(50),
    bottomRight: Radius.circular(50),
  );

  @override
  Widget build(BuildContext context) {
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
                padding: const EdgeInsets.fromLTRB(10, 52, 10, 0),
                child: DecoratedBox(
                  decoration: const ShapeDecoration(
                    color: Color(0xFFF0F0F0),
                    shape: RoundedRectangleBorder(borderRadius: _panelRadius),
                  ),
                  child: ClipRRect(
                    borderRadius: _panelRadius,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 120),
                      children: [
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => Navigator.maybePop(context),
                              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF062F35)),
                            ),
                            Text(
                              'RentMyPair',
                              style: GoogleFonts.boldonse(
                                color: const Color(0xFF062F35),
                                fontSize: 24,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'List a pair for rent, or rent one that has already been approved.',
                          style: GoogleFonts.montserrat(color: const Color(0xFF4E7F8A), fontSize: 14),
                        ),
                        const SizedBox(height: 20),
                        _OptionCard(
                          title: 'Rent your Footwear',
                          subtitle: 'Upload a photo, set a duration and price, then wait for approval.',
                          icon: Icons.add_a_photo_outlined,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const RentYourFootwearPage()),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        _OptionCard(
                          title: 'Available Rent Footwear',
                          subtitle: 'Browse approved pairs like a shop. Pay with Zoho. The request shows only after payment.',
                          icon: Icons.inventory_2_outlined,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const AvailableRentFootwearPage()),
                            );
                          },
                        ),
                      ],
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

class _OptionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _OptionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFDFE7E9),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF0F6876)),
          ),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF062F35), size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.boldonse(color: const Color(0xFF062F35), fontSize: 16),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: GoogleFonts.montserrat(color: const Color(0xFF062F35), fontSize: 13, height: 1.35),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Color(0xFF0F6876)),
            ],
          ),
        ),
      ),
    );
  }
}
