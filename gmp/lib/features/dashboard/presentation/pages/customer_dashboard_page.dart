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

/// Soft Reels-like page snap — lower stiffness = slower settle after a swipe.
/// Clamps the top edge so Home cannot overscroll upward (no white pull-down).
class _ReelsPageScrollPhysics extends PageScrollPhysics {
  const _ReelsPageScrollPhysics({super.parent});

  @override
  _ReelsPageScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return _ReelsPageScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  double applyBoundaryConditions(ScrollMetrics position, double value) {
    // Block top → bottom pull past Home (min extent). Bottom → top to My Rack stays.
    if (value < position.minScrollExtent) {
      return value - position.minScrollExtent;
    }
    return super.applyBoundaryConditions(position, value);
  }

  @override
  SpringDescription get spring => const SpringDescription(
        mass: 1.15,
        stiffness: 52,
        damping: 1.15,
      );
}

class CustomerDashboardPage extends StatefulWidget {
  const CustomerDashboardPage({super.key});

  @override
  State<CustomerDashboardPage> createState() => _CustomerDashboardPageState();
}

class _CustomerDashboardPageState extends State<CustomerDashboardPage> {
  static const int _homeRackPageCount = 2;
  static const Duration _tabAnimDuration = Duration(milliseconds: 720);
  static const Curve _tabAnimCurve = Curves.easeOutCubic;

  int _currentIndex = 0;
  bool _profileLoadScheduled = false;
  bool _rackAllowsHomeSwipe = true;
  bool _animatingFromTab = false;
  bool _bridgingRackOverscroll = false;

  late final PageController _pageController;

  /// Full viewport height while the keyboard is closed. Android `adjustResize`
  /// shrinks [MediaQuery.size] and was painting a light slab over home content
  /// / walking-shoe tips when the search field focused.
  double? _layoutViewportHeight;

  void _onExternalTabIndexChanged() {
    if (_animatingFromTab) return;
    final v = customerDashboardTabIndex.value.clamp(0, _homeRackPageCount - 1);
    final visualPage = _pageController.hasClients
        ? (_pageController.page?.round() ?? _currentIndex)
        : _currentIndex;
    if (v == _currentIndex && v == visualPage) return;
    _animateToHomeRackPage(v);
  }

  void _onRackSwipeGateChanged() {
    final allowed = myRackAllowsHomeSwipe.value;
    if (allowed == _rackAllowsHomeSwipe) return;
    setState(() => _rackAllowsHomeSwipe = allowed);
  }

  Future<void> _animateToHomeRackPage(int page) async {
    final target = page.clamp(0, _homeRackPageCount - 1);
    _animatingFromTab = true;
    if (_currentIndex != target) {
      setState(() => _currentIndex = target);
    }
    try {
      if (_pageController.hasClients) {
        await _pageController.animateToPage(
          target,
          duration: _tabAnimDuration,
          curve: _tabAnimCurve,
        );
      }
    } finally {
      _animatingFromTab = false;
      if (customerDashboardTabIndex.value != target) {
        customerDashboardTabIndex.value = target;
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _currentIndex = customerDashboardTabIndex.value.clamp(0, _homeRackPageCount - 1);
    _pageController = PageController(initialPage: _currentIndex);
    _rackAllowsHomeSwipe = myRackAllowsHomeSwipe.value;
    customerDashboardTabIndex.addListener(_onExternalTabIndexChanged);
    myRackAllowsHomeSwipe.addListener(_onRackSwipeGateChanged);
  }

  @override
  void dispose() {
    customerDashboardTabIndex.removeListener(_onExternalTabIndexChanged);
    myRackAllowsHomeSwipe.removeListener(_onRackSwipeGateChanged);
    _pageController.dispose();
    super.dispose();
  }

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

  ScrollPhysics _homeRackPhysics() {
    // Home: PageView owns the upward swipe into My Rack.
    // My Rack: list owns vertical scroll; top overscroll is bridged into the
    // page controller so the return swipe still follows the finger slowly.
    // Clamping (not bouncing) keeps Home fixed on top→bottom pull — no white gap.
    if (_currentIndex == 1) {
      return const NeverScrollableScrollPhysics();
    }
    return const _ReelsPageScrollPhysics(parent: ClampingScrollPhysics());
  }

  bool _onRackOverscrollBridge(ScrollNotification notification) {
    if (_currentIndex != 1 ||
        !_rackAllowsHomeSwipe ||
        !_pageController.hasClients) {
      return false;
    }

    if (notification is OverscrollNotification &&
        notification.metrics.axis == Axis.vertical &&
        notification.metrics.pixels <= 0 &&
        notification.overscroll < 0 &&
        notification.dragDetails != null) {
      final pos = _pageController.position;
      final next = (pos.pixels + notification.overscroll)
          .clamp(pos.minScrollExtent, pos.maxScrollExtent);
      if (next != pos.pixels) {
        _bridgingRackOverscroll = true;
        pos.jumpTo(next);
      }
      return true;
    }

    if (_bridgingRackOverscroll && notification is ScrollEndNotification) {
      _bridgingRackOverscroll = false;
      final page = _pageController.page ?? 1;
      // Settle slowly like Reels after the finger lifts.
      _animateToHomeRackPage(page < 0.72 ? 0 : 1);
      return false;
    }

    return false;
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
                      body: PageView(
                        scrollDirection: Axis.vertical,
                        controller: _pageController,
                        physics: _homeRackPhysics(),
                        allowImplicitScrolling: true,
                        onPageChanged: (i) {
                          final page = i.clamp(0, _homeRackPageCount - 1);
                          if (_currentIndex != page) {
                            setState(() => _currentIndex = page);
                          }
                          if (!_animatingFromTab &&
                              customerDashboardTabIndex.value != page) {
                            customerDashboardTabIndex.value = page;
                          }
                        },
                        children: [
                          const HomePage(),
                          NotificationListener<ScrollNotification>(
                            onNotification: _onRackOverscrollBridge,
                            child: const ArticleListPage(showBottomBar: false),
                          ),
                        ],
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
    final index = _currentIndex.clamp(0, 2);
    return Padding(
      padding: dashboardBottomNavOuterInsets(context),
      child: FloatingGradientBottomNav(
        currentIndex: index,
        showWalkingShoe: index == 0,
        onChanged: (i) {
          final c = i.clamp(0, 2);
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
          if (customerDashboardTabIndex.value != c) {
            customerDashboardTabIndex.value = c;
          } else {
            _animateToHomeRackPage(c);
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
