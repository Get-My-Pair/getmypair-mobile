import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../auth/presentation/pages/welcome_page.dart';
import '../../../../core/theme/app_colors.dart';

/// Home Page — lives in the outer features layer.
/// This is the landing tab shown to authenticated users on the main dashboard.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const WelcomePage()),
            (route) => false,
          );
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final userName = state is AuthAuthenticated
              ? state.user.name
              : state is AuthProfileCompleted
                  ? state.user.name
                  : '';

          return Scaffold(
            backgroundColor: AppColors.background,
            body: CustomScrollView(
              slivers: [
                // ── App Bar ──────────────────────────────────
                SliverAppBar(
                  pinned: true,
                  floating: false,
                  backgroundColor: AppColors.background,
                  elevation: 0,
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '📍 Pick Location',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    // Coin balance chip
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.primary),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.monetization_on,
                              color: AppColors.primary, size: 16),
                          SizedBox(width: 4),
                          Text(
                            '0 Coin',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    const CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.primaryLight,
                      child: Icon(Icons.person,
                          color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 16),
                  ],
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Welcome ──────────────────────────────
                        if (userName.isNotEmpty) ...[
                          Text(
                            'Hello, $userName 👋',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'What would you like to do today?',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],

                        // ── MAIN SERVICES label ──────────────────
                        const Center(
                          child: Text(
                            'MAIN SERVICES',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // ── Services Grid ────────────────────────
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 14,
                          childAspectRatio: 1.2,
                          children: const [
                            _ServiceCard(
                              icon: Icons.shopping_bag_outlined,
                              label: 'Shoe Inventory',
                              color: Color(0xFF6750A4),
                            ),
                            _ServiceCard(
                              icon: Icons.build_outlined,
                              label: 'Maintain & Repair',
                              color: Color(0xFF2196F3),
                            ),
                            _ServiceCard(
                              icon: Icons.recycling_outlined,
                              label: 'Recycle',
                              color: Color(0xFF4CAF50),
                            ),
                            _ServiceCard(
                              icon: Icons.card_giftcard_outlined,
                              label: 'Donate',
                              color: Color(0xFFFF9800),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // ── Rent (full width) ────────────────────
                        _ServiceCardWide(
                          icon: Icons.storefront_outlined,
                          label: 'Rent',
                          color: AppColors.secondary,
                          onTap: () {},
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _ServiceCard({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceCardWide extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ServiceCardWide({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
