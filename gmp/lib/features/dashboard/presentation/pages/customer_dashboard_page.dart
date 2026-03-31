import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gmp/core/theme/app_colors.dart';
import 'package:gmp/features/auth/domain/usecases/get_valid_access_token.dart';
import 'package:gmp/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:gmp/features/auth/presentation/bloc/auth_event.dart';
import 'package:gmp/features/auth/presentation/bloc/auth_state.dart';
import 'package:gmp/features/auth/presentation/pages/welcome_page.dart';
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
              builder: (context) => const WelcomePage(),
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
              body: IndexedStack(
                index: _currentIndex.clamp(0, _pages.length - 1),
                children: _pages,
              ),
              bottomNavigationBar: _buildBottomNav(),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex.clamp(0, _pages.length - 1),
        onTap: (index) {
          final safeIndex = index.clamp(0, _pages.length - 1);
          setState(() => _currentIndex = safeIndex);
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textTertiary,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment_outlined), label: 'Requests'),
          BottomNavigationBarItem(icon: Icon(Icons.grid_view_outlined), label: 'Catalog'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart_outlined), label: 'Cart'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Account'),
        ],
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
