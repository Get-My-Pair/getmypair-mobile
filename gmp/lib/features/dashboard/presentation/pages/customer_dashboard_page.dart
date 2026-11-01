import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gmp/core/navigation/customer_dashboard_tab_index.dart';
import 'package:gmp/core/theme/app_colors.dart';
import 'package:gmp/core/widgets/floating_gradient_bottom_nav.dart';
import 'package:gmp/features/auth/domain/usecases/get_valid_access_token.dart';
import 'package:gmp/features/auth/presentation/bloc/auth_bloc.dart';
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

  /// Full viewport height while the keyboard is closed. Android `adjustResize`
  /// shrinks [MediaQuery.size] and was painting a light slab over home content
  /// / walking-shoe tips when the search field focused.
  double? _layoutViewportHeight;

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

  bool _isKeyboardVisible(MediaQueryData mediaQuery) =>
      mediaQuery.viewInsets.bottom > 0;

  bool _isViewportShrunkByKeyboard(MediaQueryData mediaQuery) {
    final cached = _layoutViewportHeight;
    if (cached == null) return false;
    return mediaQuery.size.height < cached * 0.9;
  }

  void _syncLayoutViewportHeight(MediaQueryData mediaQuery) {
    final height = mediaQuery.size.height;
    if (_isKeyboardVisible(mediaQuery) ||
        _isViewportShrunkByKeyboard(mediaQuery)) {
      _layoutViewportHeight ??= height;
      return;
    }
    _layoutViewportHeight = height;
  }

  /// Must use a [BuildContext] that sits *below* [BlocProvider<ProfileBloc>],
  /// not [State.context] (which is above the provider created in [build]).
  Future<void> _loadProfile(BuildContext context) async {
    final result = await sl<GetValidAccessToken>().call();
    if (!context.mounted) return;
    result.fold(
      (failure) {},
      (token) => context.read<ProfileBloc>().add(ProfileLoadRequested(token)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    _syncLayoutViewportHeight(mediaQuery);
    final layoutHeight = _layoutViewportHeight ?? mediaQuery.size.height;
    final layoutMediaQuery = mediaQuery.copyWith(
      size: Size(mediaQuery.size.width, layoutHeight),
      viewInsets: EdgeInsets.zero,
    );

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
      child: _DashboardProfileHost(
        child: MediaQuery(
          data: layoutMediaQuery,
          child: Builder(
            builder: (innerContext) {
              if (!_profileLoadScheduled) {
                _profileLoadScheduled = true;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!innerContext.mounted) return;
                  _loadProfile(innerContext);
                });
              }
              // Keep home / tips laid out at the closed-keyboard height so the
              // IME overlays content instead of replacing it with a light slab.
              return ClipRect(
                child: OverflowBox(
                  alignment: Alignment.topCenter,
                  minHeight: layoutHeight,
                  maxHeight: layoutHeight,
                  child: SizedBox(
                    height: layoutHeight,
                    width: layoutMediaQuery.size.width,
                    child: Scaffold(
                      resizeToAvoidBottomInset: false,
                      backgroundColor: AppColors.background,
                      extendBody: true,
                      body: IndexedStack(
                        index: _currentIndex.clamp(0, _pages.length - 1),
                        children: _pages,
                      ),
                      bottomNavigationBar: _buildBottomNav(innerContext),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    final index = _currentIndex.clamp(0, _pages.length - 1);
    return Padding(
      padding: dashboardBottomNavOuterInsets(context),
      child: FloatingGradientBottomNav(
        currentIndex: index,
        showWalkingShoe: index == 0,
        onChanged: (i) {
          final c = i.clamp(0, _pages.length - 1);
          if (c == 2) {
            final profileBloc = context.read<ProfileBloc>();
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => BlocProvider.value(
                  value: profileBloc,
                  child: const ProfilePage(),
                ),
              ),
            );
            return;
          }
          setState(() => _currentIndex = c);
          if (customerDashboardTabIndex.value != c) {
            customerDashboardTabIndex.value = c;
          }
        },
      ),
    );
  }
}

/// Keeps one [ProfileBloc] for the dashboard and registers it so pushed
/// pages can show the same photo or name initial in the bottom bar.
class _DashboardProfileHost extends StatefulWidget {
  const _DashboardProfileHost({required this.child});

  final Widget child;

  @override
  State<_DashboardProfileHost> createState() => _DashboardProfileHostState();
}

class _DashboardProfileHostState extends State<_DashboardProfileHost> {
  late final ProfileBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = sl<ProfileBloc>();
    ProfileBlocAnchor.attach(_bloc);
  }

  @override
  void dispose() {
    ProfileBlocAnchor.detach(_bloc);
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ProfileBloc>.value(
      value: _bloc,
      child: widget.child,
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
