import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:gmp/core/navigation/customer_dashboard_tab_index.dart';
import 'package:gmp/core/theme/app_colors.dart';
import 'package:gmp/core/widgets/app_feedback_alert.dart';
import 'package:gmp/core/widgets/app_skeleton.dart';
import 'package:gmp/core/navigation/customer_cart_nav_hook.dart';
import 'package:gmp/features/profile/domain/entities/user_profile.dart';
import 'package:gmp/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:gmp/features/profile/presentation/bloc/profile_state.dart';
import 'package:gmp/features/profile/presentation/pages/profile_page.dart';

/// Pill-shaped floating bar: angular (conic) teal sweep from Figma `825:756`,
/// white icons, selected tab on a solid white circle (icon in dark teal).
/// Visual tabs: Home · Favorites · Rack · Cart · Profile.
///
/// A pixel shoe (Figma `3042:4603`) walks right→left along the top of the pill
/// (Figma `3042:4601`), flips at the left end, then walks back right.
///
/// [currentIndex] stays semantic: `0` home, `1` rack, `2` profile.
/// Favorites stays coming-soon; Cart calls [onCartTap] (wired to Cart page).
///
/// The exported SVG uses `foreignObject` + HTML conic-gradient; Flutter cannot
/// render that as an asset, so the same stops are applied via [SweepGradient].
class FloatingGradientBottomNav extends StatelessWidget {
  const FloatingGradientBottomNav({
    super.key,
    required this.currentIndex,
    required this.onChanged,
    this.showWalkingShoe = false,
    this.highlightCart = false,
    this.onCartTap,
  });

  /// Semantic dashboard tab: `0` home, `1` rack, `2` profile.
  /// Use `-1` with [highlightCart] when Cart is the active screen.
  final int currentIndex;
  final ValueChanged<int> onChanged;

  /// Pixel shoe + chat bubble — home screen only.
  final bool showWalkingShoe;

  /// When true, the Cart tab (visual index 3) shows as selected.
  final bool highlightCart;

  /// Opens the Cart screen (4th tab). Required for Cart to work.
  final VoidCallback? onCartTap;

  /// Inner pill from Figma: `rect … height="58" rx="29"` (`3042:4601`).
  static const double barHeight = 58;

  /// Walking shoe from Figma `3042:4603` (82 × 39) — base, never shrink below.
  static const double walkingShoeWidth = 82;
  static const double walkingShoeHeight = 39;

  /// Chat bubble from Figma `3042:4605` (~62 × 25), stacked above the shoe.
  static const double walkingBubbleHeight = 26;
  static const double walkingUnitHeight =
      walkingShoeHeight + walkingBubbleHeight - 6;

  /// Pill + walking unit height (home). Other screens use [barHeight].
  static const double totalHeight = barHeight + walkingUnitHeight;

  /// Tall phones: grow the shoe with available bottom space (never below 1.0).
  static double walkingShoeScaleOf(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height;
    if (h <= 850) return 1.0;
    return (1.0 + (h - 850) / 420).clamp(1.0, 1.38);
  }

  static double walkingShoeWidthOf(BuildContext context) =>
      walkingShoeWidth * walkingShoeScaleOf(context);

  static double walkingShoeHeightOf(BuildContext context) =>
      walkingShoeHeight * walkingShoeScaleOf(context);

  static double walkingUnitHeightOf(BuildContext context) {
    final s = walkingShoeScaleOf(context);
    return walkingShoeHeight * s + walkingBubbleHeight * s - 6;
  }

  static double heightFor({
    required bool showWalkingShoe,
    BuildContext? context,
  }) {
    if (!showWalkingShoe) return barHeight;
    if (context == null) return totalHeight;
    return barHeight + walkingUnitHeightOf(context);
  }

  static const double _pillRadius = barHeight / 2;
  static const double hitSize = 44;
  static const Color selectedIconColor = Color(0xFF08343A);
  static const String _homeIcon = 'assets/images/icons/home.svg';
  static const String _favoritesIcon = 'assets/images/heart.svg';
  static const String _middleShoeIcon = 'assets/images/icons/shoe.svg';
  static const String _cartIcon = 'assets/images/shopping-cart.svg';
  static const String _profileIcon = 'assets/images/icons/profile.svg';
  static const String _walkingShoeAsset =
      'assets/images/home/Gemini_Generated_Image_dzm88udzm88udzm8 1.png';

  static const _tabs = <_NavTab>[
    _NavTab(svgAsset: _homeIcon, semanticIndex: 0),
    _NavTab(
      svgAsset: _favoritesIcon,
      comingSoonFeature: 'Favorites',
    ),
    _NavTab(svgAsset: _middleShoeIcon, semanticIndex: 1),
    _NavTab(
      svgAsset: _cartIcon,
      isCart: true,
    ),
    _NavTab(svgAsset: _profileIcon, semanticIndex: 2),
  ];

  static int _visualIndexFor(int semanticIndex) {
    if (semanticIndex < 0) return -1;
    return switch (semanticIndex.clamp(0, 2)) {
      0 => 0,
      1 => 2,
      _ => 4,
    };
  }

  @override
  Widget build(BuildContext context) {
    final selectedVisual =
        highlightCart ? 3 : _visualIndexFor(currentIndex);
    final shoeW = showWalkingShoe ? walkingShoeWidthOf(context) : walkingShoeWidth;
    final shoeH =
        showWalkingShoe ? walkingShoeHeightOf(context) : walkingShoeHeight;
    final unitH =
        showWalkingShoe ? walkingUnitHeightOf(context) : walkingUnitHeight;
    final stackHeight = heightFor(
      showWalkingShoe: showWalkingShoe,
      context: context,
    );

    return SizedBox(
      height: stackHeight,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: barHeight,
            child: Material(
              color: Colors.transparent,
              elevation: 0,
              child: Container(
                height: barHeight,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(_pillRadius),
                  gradient: AppColors.figma825AngularSweep,
                  // Matches SVG filter: `feOffset dy="4"` + `feGaussianBlur stdDeviation="6"`.
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFABABAB).withValues(alpha: 0.55),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: (barHeight - hitSize) / 2,
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final tabCount = _tabs.length;
                      final slotWidth = constraints.maxWidth / tabCount;
                      final dynamicHitSize =
                          slotWidth.clamp(28.0, hitSize).toDouble();
                      final iconBase =
                          (dynamicHitSize * 0.50).clamp(14.0, 22.0).toDouble();
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(tabCount, (i) {
                          final tab = _tabs[i];
                          final selected = i == selectedVisual;
                          final iconColor =
                              selected ? selectedIconColor : Colors.white;
                          final iconSize =
                              tab.semanticIndex == 2 ? iconBase + 1 : iconBase;
                          final avatarSize =
                              (dynamicHitSize * (selected ? 0.82 : 0.74))
                                  .clamp(22.0, 36.0);
                          return SizedBox(
                            width: dynamicHitSize,
                            height: hitSize,
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  if (tab.isCart) {
                                    if (highlightCart) return;
                                    if (onCartTap != null) {
                                      onCartTap!();
                                    } else {
                                      showComingSoon(
                                        context,
                                        feature: 'Cart',
                                      );
                                    }
                                    return;
                                  }
                                  final semantic = tab.semanticIndex;
                                  if (semantic == null) {
                                    showComingSoon(
                                      context,
                                      feature: tab.comingSoonFeature ?? 'This',
                                    );
                                    return;
                                  }
                                  onChanged(semantic);
                                },
                                customBorder: const CircleBorder(),
                                splashColor: Colors.white24,
                                highlightColor: Colors.white10,
                                child: Center(
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    curve: Curves.easeOutCubic,
                                    width: dynamicHitSize,
                                    height: dynamicHitSize,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: selected
                                          ? Colors.white
                                          : Colors.transparent,
                                      boxShadow: selected
                                          ? [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withValues(alpha: 0.12),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: tab.semanticIndex == 2
                                        ? _BottomNavProfileAvatar(
                                            size: avatarSize,
                                            selected: selected,
                                            fallback: SvgPicture.asset(
                                              _profileIcon,
                                              width: iconSize,
                                              height: iconSize,
                                              colorFilter: ColorFilter.mode(
                                                iconColor,
                                                BlendMode.srcIn,
                                              ),
                                            ),
                                          )
                                        : tab.svgAsset != null
                                        ? SvgPicture.asset(
                                            tab.svgAsset!,
                                            width: iconSize,
                                            height: iconSize,
                                            colorFilter: ColorFilter.mode(
                                              iconColor,
                                              BlendMode.srcIn,
                                            ),
                                          )
                                        : Icon(
                                            tab.materialIcon,
                                            size: iconSize,
                                            color: iconColor,
                                          ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          // Home only: shoe + bubble walk along the top of the pill.
          // Size grows with tall viewports — never below Figma base.
          if (showWalkingShoe)
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: unitH,
              child: IgnorePointer(
                child: _WalkingNavShoe(
                  asset: _walkingShoeAsset,
                  shoeWidth: shoeW,
                  shoeHeight: shoeH,
                  unitHeight: unitH,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Pixel shoe + Figma bubble that walk right→left, flip, then left→right.
/// Bubble text cycles through [_kWalkingShoeMessages] every few seconds.
class _WalkingNavShoe extends StatefulWidget {
  const _WalkingNavShoe({
    required this.asset,
    required this.shoeWidth,
    required this.shoeHeight,
    required this.unitHeight,
  });

  final String asset;
  final double shoeWidth;
  final double shoeHeight;
  final double unitHeight;

  @override
  State<_WalkingNavShoe> createState() => _WalkingNavShoeState();
}

const List<String> _kWalkingShoeMessages = [
  "Let's Style...",
  'Fresh kicks?',
  'Care MyPair',
  'Rehome Pair',
  'Thrift finds',
];

class _WalkingNavShoeState extends State<_WalkingNavShoe>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  int _messageIndex = 0;
  Timer? _messageTimer;

  /// `true` while walking right→left; `false` while walking left→right.
  /// Flips at each end so the shoe always faces the travel direction.
  bool _movingLeft = true;
  double _lastValue = 0;

  @override
  void initState() {
    super.initState();
    // value 0 = right edge, value 1 = left edge; reverse walks back right.
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 8200),
    )..addListener(_onTick)..repeat(reverse: true);
    _messageTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      setState(() {
        _messageIndex = (_messageIndex + 1) % _kWalkingShoeMessages.length;
      });
    });
  }

  void _onTick() {
    final v = _controller.value;
    // Detect direction from value delta so flip happens at both ends.
    var nextMovingLeft = _movingLeft;
    if (v > _lastValue + 0.0001) {
      // Forward: toward left.
      nextMovingLeft = true;
    } else if (v < _lastValue - 0.0001) {
      // Reverse: toward right.
      nextMovingLeft = false;
    }
    _lastValue = v;
    if (nextMovingLeft != _movingLeft && mounted) {
      setState(() => _movingLeft = nextMovingLeft);
    }
  }

  @override
  void dispose() {
    _messageTimer?.cancel();
    _controller
      ..removeListener(_onTick)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Bubble leads in the travel direction; scale with shoe on tall phones.
    final shoeScale =
        (widget.shoeWidth / FloatingGradientBottomNav.walkingShoeWidth)
            .clamp(1.0, 1.38);
    final bubbleLead = 56.0 * shoeScale;
    final unitWidth = widget.shoeWidth + bubbleLead;

    return LayoutBuilder(
      builder: (context, constraints) {
        final travel = math.max(0.0, constraints.maxWidth - unitWidth);
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = Curves.easeInOut.transform(_controller.value);
            // Start at the right and move left; reverse returns to the right.
            final left = (1.0 - t) * travel;
            final movingLeft = _movingLeft;
            // Left→right: mirrored shoe, bubble leads on the left.
            // Right→left: natural shoe, bubble leads on the right.
            final shoeScaleX = movingLeft ? 1.0 : -1.0;
            final shoeLeft = movingLeft ? 0.0 : bubbleLead;
            final bubbleLeft = movingLeft ? widget.shoeWidth : 0.0;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: left,
                  bottom: 0,
                  width: unitWidth,
                  height: widget.unitHeight,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        left: shoeLeft,
                        bottom: 0,
                        width: widget.shoeWidth,
                        height: widget.shoeHeight,
                        child: Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.diagonal3Values(shoeScaleX, 1, 1),
                          child: Image.asset(
                            widget.asset,
                            width: widget.shoeWidth,
                            height: widget.shoeHeight,
                            // Fill the reserved box — never shrink in leftover space.
                            fit: BoxFit.fill,
                            filterQuality: FilterQuality.none,
                            gaplessPlayback: true,
                            alignment: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                      Positioned(
                        left: bubbleLeft,
                        top: 0,
                        child: Transform.scale(
                          scale: shoeScale,
                          alignment: movingLeft
                              ? Alignment.topRight
                              : Alignment.topLeft,
                          child: _WalkingShoeBubble(
                            message: _kWalkingShoeMessages[_messageIndex],
                            messageKey: ValueKey<int>(_messageIndex),
                            mirrorTail: movingLeft,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

/// Figma `3042:4605` Bubble Chat — white chip with asymmetric radii.
class _WalkingShoeBubble extends StatelessWidget {
  const _WalkingShoeBubble({
    required this.message,
    required this.messageKey,
    this.mirrorTail = false,
  });

  final String message;
  final Key messageKey;

  /// When walking right, mirror the pointed corner onto the left side.
  final bool mirrorTail;

  @override
  Widget build(BuildContext context) {
    final radius = mirrorTail
        ? const BorderRadius.only(
            topLeft: Radius.circular(10),
            topRight: Radius.circular(13),
            bottomLeft: Radius.circular(1),
            bottomRight: Radius.circular(13),
          )
        : const BorderRadius.only(
            topLeft: Radius.circular(13),
            topRight: Radius.circular(10),
            bottomLeft: Radius.circular(13),
            bottomRight: Radius.circular(1),
          );
    return Container(
      constraints: const BoxConstraints(minWidth: 62, minHeight: 25),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6.5),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE0E0E0), width: 0.8),
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE0E0E0).withValues(alpha: 0.25),
            blurRadius: 6.5,
            offset: const Offset(0, 3.3),
          ),
        ],
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 450),
        switchInCurve: Curves.easeInOut,
        switchOutCurve: Curves.easeInOut,
        child: Text(
          message,
          key: messageKey,
          textAlign: TextAlign.center,
          style: GoogleFonts.montserrat(
            color: Colors.black,
            fontSize: 10,
            fontWeight: FontWeight.w400,
            height: 1.1,
          ),
        ),
      ),
    );
  }
}

/// Active profile photo on the Profile tab. Every page uses the dashboard
/// profile: the photo when one exists, otherwise the first letter of the name.
class _BottomNavProfileAvatar extends StatelessWidget {
  const _BottomNavProfileAvatar({
    required this.size,
    required this.selected,
    required this.fallback,
  });

  final double size;
  final bool selected;
  final Widget fallback;

  @override
  Widget build(BuildContext context) {
    ProfileBloc? bloc;
    try {
      bloc = context.read<ProfileBloc>();
    } catch (_) {
      bloc = null;
    }
    bloc ??= ProfileBlocAnchor.current;
    if (bloc == null || bloc.isClosed) return fallback;

    return BlocBuilder<ProfileBloc, ProfileState>(
      bloc: bloc,
      builder: (context, state) {
        final profile = _profileFromState(state);
        final url = profile?.activeProfileImage?.trim();
        final letter = _profileInitial(profile);
        if (url == null || url.isEmpty) {
          return letter == null ? fallback : _letterAvatar(letter);
        }

        return SizedBox(
          width: size,
          height: size,
          child: DecoratedBox(
            position: DecorationPosition.foreground,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: selected
                  ? null
                  : Border.all(color: Colors.white, width: 1.5),
            ),
            child: ClipOval(
              child: Image.network(
                url,
                width: size,
                height: size,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const AppSkeletonPulse(
                    child: ColoredBox(color: Color(0xFFB7C9CE)),
                  );
                },
                errorBuilder: (context, error, stackTrace) =>
                    letter == null ? fallback : _letterAvatar(letter),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _letterAvatar(String letter) {
    final color = selected
        ? FloatingGradientBottomNav.selectedIconColor
        : Colors.white;
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selected ? Colors.transparent : const Color(0x33FFFFFF),
          border: selected
              ? null
              : Border.all(color: Colors.white, width: 1.5),
        ),
        child: Center(
          child: Text(
            letter,
            style: GoogleFonts.boldonse(
              color: color,
              fontSize: (size * 0.46).clamp(11.0, 16.0),
              height: 1,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}

String? _profileInitial(UserProfile? profile) {
  final name = profile?.activeDisplayName.trim() ?? '';
  if (name.isEmpty) return null;
  return name[0].toUpperCase();
}

UserProfile? _profileFromState(ProfileState state) {
  if (state is ProfileLoaded) return state.profile;
  if (state is ProfileUpdating) return state.profile;
  if (state is ProfileImageUploading) return state.profile;
  if (state is ProfileError) return state.profile;
  if (state is AddressActionLoading) return state.profile;
  if (state is ProfileSwitching) return state.profile;
  return null;
}

class _NavTab {
  const _NavTab({
    this.svgAsset,
    this.materialIcon,
    this.semanticIndex,
    this.comingSoonFeature,
    this.isCart = false,
  });

  final String? svgAsset;
  final IconData? materialIcon;
  /// `0` home, `1` rack, `2` profile. Null means the tab is not wired yet.
  final int? semanticIndex;
  final String? comingSoonFeature;
  final bool isCart;
}

/// Outer padding around [FloatingGradientBottomNav] on [CustomerDashboardPage]
/// and on pushed stack pages that use [DashboardLinkedBottomNav].
///
/// Horizontal insets scale down on narrow devices so the pill does not overflow,
/// while keeping the bar a bit wider on most phones.
EdgeInsets dashboardBottomNavOuterInsets(BuildContext context) {
  final w = MediaQuery.sizeOf(context).width;
  final safeBottom = MediaQuery.viewPaddingOf(context).bottom;
  const minBarBody = 300.0;
  final side = ((w - minBarBody) * 0.5).clamp(12.0, 28.0);
  // Scale bottom inset with width + safe-area so spacing feels consistent
  // across compact phones and larger screens.
  final widthFactor = ((w - 320.0) / 160.0).clamp(0.0, 1.0);
  final baseBottom = 14.5 + (widthFactor * 6.3);
  final bottom = safeBottom <= 0
      ? baseBottom
      : (baseBottom + (safeBottom * 0.72)).clamp(16.0, 36.0).toDouble();
  return EdgeInsets.fromLTRB(side, 7, side, bottom);
}

/// Total vertical extent of [DashboardLinkedBottomNav] (outer padding + bar height).
///
/// Use with [LayoutBuilder] / [Column] so panel content stays above the floating bar
/// when [Scaffold.extendBody] is true.
double dashboardLinkedBottomNavStackHeight(
  BuildContext context, {
  bool showWalkingShoe = false,
}) {
  final e = dashboardBottomNavOuterInsets(context);
  return e.top +
      FloatingGradientBottomNav.heightFor(
        showWalkingShoe: showWalkingShoe,
        context: context,
      ) +
      e.bottom;
}

/// Same bar as the dashboard, wired to [customerDashboardTabIndex] and root pop.
/// Use on profile stack pages so Home / Rack / Profile match main navigation.
class DashboardLinkedBottomNav extends StatelessWidget {
  const DashboardLinkedBottomNav({
    super.key,
    this.selectedTabIndex = 2,
    this.highlightCart = false,
    this.onCartTap,
    this.onProfileTabWhenCannotPop,
  });

  /// Highlight while this route is visible (profile flow → 2).
  /// Use `-1` with [highlightCart] on the Cart screen.
  final int selectedTabIndex;

  /// Cart tab selected (4th visual button).
  final bool highlightCart;

  /// Opens Cart. Defaults to [openCustomerCartPage] when null — pass explicitly
  /// from call sites that import cart navigation to avoid cycles.
  final VoidCallback? onCartTap;

  /// When the user taps Profile (tab 2) and this navigator cannot pop, run this
  /// instead of only syncing tab — e.g. open Edit Profile from the root profile screen.
  final VoidCallback? onProfileTabWhenCannotPop;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: dashboardBottomNavOuterInsets(context),
      child: FloatingGradientBottomNav(
        currentIndex: selectedTabIndex < 0 ? -1 : selectedTabIndex.clamp(0, 2),
        highlightCart: highlightCart,
        onCartTap: onCartTap ??
            () {
              if (openCustomerCartHook != null) {
                invokeOpenCustomerCart(context);
              } else {
                showComingSoon(context, feature: 'Cart');
              }
            },
        onChanged: (i) {
          final tab = i.clamp(0, 2);
          if (!highlightCart && tab == selectedTabIndex) return;
          customerDashboardTabIndex.value = tab;
          final nav = Navigator.of(context);
          if (tab == 2) {
            if (onProfileTabWhenCannotPop != null && !nav.canPop()) {
              onProfileTabWhenCannotPop!();
              return;
            }
            final resolved = () {
              try {
                return context.read<ProfileBloc>();
              } catch (_) {
                return ProfileBlocAnchor.current;
              }
            }();
            if (resolved == null || resolved.isClosed) return;
            nav.push(
              MaterialPageRoute(
                builder: (_) => BlocProvider.value(
                  value: resolved,
                  child: const ProfilePage(),
                ),
              ),
            );
            return;
          }
          nav.popUntil((route) => route.isFirst);
        },
      ),
    );
  }
}
