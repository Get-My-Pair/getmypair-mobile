import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gmp/core/theme/app_colors.dart';
import 'package:gmp/features/auth/domain/usecases/get_valid_access_token.dart';
import 'package:gmp/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:gmp/features/auth/presentation/bloc/auth_event.dart';
import 'package:gmp/features/auth/presentation/bloc/auth_state.dart';
import 'package:gmp/features/auth/presentation/pages/mobile_otp_page.dart';
import 'package:gmp/features/home/presentation/pages/home_page.dart';
import 'package:gmp/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:gmp/features/profile/presentation/bloc/profile_event.dart';
import 'package:gmp/features/profile/presentation/pages/profile_page.dart';
import 'package:gmp/features/service/presentation/pages/service_request_list_page.dart';
import 'package:gmp/injection_container.dart';

class CustomerDashboardPage extends StatefulWidget {
  const CustomerDashboardPage({super.key});

  @override
  State<CustomerDashboardPage> createState() => _CustomerDashboardPageState();
}

class _CustomerDashboardPageState extends State<CustomerDashboardPage> {
  int _currentIndex = 0;
  bool _profileLoadScheduled = false;

  final List<Widget> _pages = const [
    HomePage(),
    ServiceRequestListPage(),
    _CatalogPlaceholder(),
    _CartPlaceholder(),
    _ProfilePageWrapper(),
  ];

  /// Must use a [BuildContext] that sits *below* [BlocProvider<ProfileBloc>],
  /// not [State.context] (which is above the provider created in [build]).
  Future<void> _loadProfile(BuildContext context) async {
    final result = await sl<GetValidAccessToken>().call();
    if (!context.mounted) return;
    result.fold(
      (_) => context.read<AuthBloc>().add(const AuthSessionExpired()),
      (token) => context.read<ProfileBloc>().add(ProfileLoadRequested(token)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => const MobileOTPPage(),
            ),
            (route) => false,
          );
        }
      },
      child: BlocProvider<ProfileBloc>(
        create: (_) => sl<ProfileBloc>(),
        child: Builder(
          builder: (innerContext) {
            if (!_profileLoadScheduled) {
              _profileLoadScheduled = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!innerContext.mounted) return;
                _loadProfile(innerContext);
              });
            }
            return Scaffold(
              backgroundColor: AppColors.background,
              extendBody: true,
              body: IndexedStack(
                index: _currentIndex.clamp(0, _pages.length - 1),
                children: _pages,
              ),
              bottomNavigationBar: _buildBottomNav(context),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    final index = _currentIndex.clamp(0, _pages.length - 1);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: _FloatingGradientBottomNav(
          currentIndex: index,
          onChanged: (i) => setState(() => _currentIndex = i.clamp(0, _pages.length - 1)),
        ),
      ),
    );
  }
}

/// Pill-shaped floating bar: dark teal → cyan gradient, white outline icons,
/// selected tab on a solid white circle (icon in dark teal).
class _FloatingGradientBottomNav extends StatelessWidget {
  const _FloatingGradientBottomNav({
    required this.currentIndex,
    required this.onChanged,
  });

  final int currentIndex;
  final ValueChanged<int> onChanged;

  static const double _barHeight = 56;
  static const double _hitSize = 44;
  static const Color _selectedIconColor = Color(0xFF08343A);

  @override
  Widget build(BuildContext context) {
    final items = <({IconData outlined, IconData filled})>[
      (outlined: Icons.home_outlined, filled: Icons.home_rounded),
      (outlined: Icons.favorite_border_rounded, filled: Icons.favorite_rounded),
      (outlined: Icons.checkroom_outlined, filled: Icons.checkroom_rounded),
      (outlined: Icons.shopping_cart_outlined, filled: Icons.shopping_cart_rounded),
      (outlined: Icons.person_outline_rounded, filled: Icons.person_rounded),
    ];

    return Material(
      color: Colors.transparent,
      elevation: 0,
      child: Container(
        height: _barHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_barHeight / 2),
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Color(0xFF08343A),
              Color(0xFF0F6876),
              Color(0xFF00E0FF),
            ],
            stops: [0.0, 0.42, 1.0],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: 18,
              offset: const Offset(0, 8),
              spreadRadius: -4,
            ),
            BoxShadow(
              color: const Color(0xFF0A6C78).withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(items.length, (i) {
              final selected = i == currentIndex;
              final pair = items[i];
              return Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => onChanged(i),
                    customBorder: const CircleBorder(),
                    splashColor: Colors.white24,
                    highlightColor: Colors.white10,
                    child: Center(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutCubic,
                        width: _hitSize,
                        height: _hitSize,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: selected ? Colors.white : Colors.transparent,
                          boxShadow: selected
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.12),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Icon(
                          selected ? pair.filled : pair.outlined,
                          size: 24,
                          color: selected ? _selectedIconColor : Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

/// Profile tab uses the dashboard's ProfileBloc from context.
class _ProfilePageWrapper extends StatelessWidget {
  const _ProfilePageWrapper();

  @override
  Widget build(BuildContext context) {
    return const ProfilePage();
  }
}

class _CatalogPlaceholder extends StatelessWidget {
  const _CatalogPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.grid_view_outlined, size: 64, color: AppColors.textTertiary),
            SizedBox(height: 16),
            Text(
              'Catalog',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Coming soon',
              style: TextStyle(color: AppColors.textTertiary),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartPlaceholder extends StatelessWidget {
  const _CartPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart_outlined, size: 64, color: AppColors.textTertiary),
            SizedBox(height: 16),
            Text(
              'Cart',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Your cart is empty',
              style: TextStyle(color: AppColors.textTertiary),
            ),
          ],
        ),
      ),
    );
  }
}
