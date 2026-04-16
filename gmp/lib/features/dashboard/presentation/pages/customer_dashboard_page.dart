import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gmp/core/errors/failures.dart';
import 'package:gmp/core/navigation/customer_dashboard_tab_index.dart';
import 'package:gmp/core/theme/app_colors.dart';
import 'package:gmp/core/widgets/floating_gradient_bottom_nav.dart';
import 'package:gmp/features/auth/domain/usecases/get_valid_access_token.dart';
import 'package:gmp/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:gmp/features/auth/presentation/bloc/auth_event.dart';
import 'package:gmp/features/auth/presentation/bloc/auth_state.dart';
import 'package:gmp/features/auth/presentation/pages/mobile_otp_page.dart';
import 'package:gmp/features/articles/presentation/pages/article_list_page.dart';
import 'package:gmp/features/home/presentation/pages/home_page.dart';
import 'package:gmp/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:gmp/features/profile/presentation/bloc/profile_event.dart';
import 'package:gmp/features/profile/presentation/pages/profile_page.dart';
import 'package:gmp/injection_container.dart';

class CustomerDashboardPage extends StatefulWidget {
  const CustomerDashboardPage({super.key});

  @override
  State<CustomerDashboardPage> createState() => _CustomerDashboardPageState();
}

class _CustomerDashboardPageState extends State<CustomerDashboardPage> {
  int _currentIndex = 0;
  bool _profileLoadScheduled = false;

  void _onExternalTabIndexChanged() {
    final v = customerDashboardTabIndex.value.clamp(0, _pages.length - 1);
    if (v == _currentIndex) return;
    setState(() => _currentIndex = v);
  }

  @override
  void initState() {
    super.initState();
    customerDashboardTabIndex.addListener(_onExternalTabIndexChanged);
  }

  @override
  void dispose() {
    customerDashboardTabIndex.removeListener(_onExternalTabIndexChanged);
    super.dispose();
  }

  final List<Widget> _pages = const [
    HomePage(),
    ArticleListPage(showBottomBar: false),
    _ProfilePageWrapper(),
  ];

  /// Must use a [BuildContext] that sits *below* [BlocProvider<ProfileBloc>],
  /// not [State.context] (which is above the provider created in [build]).
  Future<void> _loadProfile(BuildContext context) async {
    final result = await sl<GetValidAccessToken>().call();
    if (!context.mounted) return;
    result.fold(
      (failure) {
        if (failure is AuthenticationFailure) {
          context.read<AuthBloc>().add(const AuthSessionExpired());
        }
      },
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
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 80),
        child: FloatingGradientBottomNav(
          currentIndex: index,
          onChanged: (i) {
            final c = i.clamp(0, _pages.length - 1);
            setState(() => _currentIndex = c);
            if (customerDashboardTabIndex.value != c) {
              customerDashboardTabIndex.value = c;
            }
          },
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
    return const ProfilePage(showBottomNav: false);
  }
}
