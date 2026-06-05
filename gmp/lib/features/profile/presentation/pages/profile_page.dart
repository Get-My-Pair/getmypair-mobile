import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/bgtheme.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/chevron_screen_back_button.dart';
import '../../../../core/widgets/app_feedback_alert.dart';
import '../../../../core/widgets/floating_gradient_bottom_nav.dart';
import '../../../auth/domain/usecases/get_valid_access_token.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../auth/presentation/pages/mobile_otp_page.dart';
import '../../../../injection_container.dart' as di;
import '../../domain/entities/user_profile.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../bloc/profile_state.dart';
import '../profile_screen_system_ui.dart';
import 'edit_profile_page.dart';
import 'saved_addresses_page.dart';
// MVP: single profile only — restore for family / multi-profile.
// import 'family_profile_page.dart';
import 'notifications_page.dart';
import 'manage_devices_page.dart';
import 'faq_page.dart';
import 'license_page.dart';
import '../../../auth/presentation/pages/terms_of_service_page.dart';
import '../../../service/presentation/pages/service_request_list_page.dart';
import '../../../payment/presentation/bloc/payment_bloc.dart';
import '../../../payment/presentation/pages/payment_history_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, this.showBottomNav = true});

  /// When this profile page is shown as a standalone route (not inside
  /// `CustomerDashboardPage`), we render the floating bottom navigation.
  /// The dashboard renders it itself.
  final bool showBottomNav;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? _accessToken;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initAndLoad();
    });
  }

  Future<void> _initAndLoad() async {
    final result = await di.sl<GetValidAccessToken>().call();
    if (!mounted) return;
    await result.fold(
      (failure) async {
        if (!context.mounted) return;
        await showAppFeedbackAlert(
          context,
          message: failure.message,
          type: AppFeedbackType.failure,
        );
      },
      (token) async {
        if (!mounted) return;
        setState(() => _accessToken = token);
        context.read<ProfileBloc>().add(ProfileLoadRequested(token));
      },
    );
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Log Out',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthBloc>().add(const AuthLogout());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.textOnPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }

  String _subtitleLine(UserProfile profile) {
    final e = profile.email?.trim();
    if (e != null && e.isNotEmpty) return e;
    return profile.phone;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const MobileOTPPage()),
            (route) => false,
          );
        }
      },
      child: BlocConsumer<ProfileBloc, ProfileState>(
        listener: (context, state) async {
          if (state is ProfileError) {
            await showAppFeedbackAlert(
              context,
              message: state.message,
              type: AppFeedbackType.failure,
            );
          }
        },
        builder: (context, state) {
          if (state is ProfileLoading || state is ProfileInitial) {
            return const AnnotatedRegion<SystemUiOverlayStyle>(
              value: kProfileLightScaffoldSystemUi,
              child: Scaffold(
                body: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ),
            );
          }

          final profile = state is ProfileLoaded
              ? state.profile
              : state is ProfileUpdating
              ? state.profile
              : state is ProfileImageUploading
              ? state.profile
              : state is AddressActionLoading
              ? state.profile
              : state is ProfileError && state.profile != null
              ? state.profile!
              : null;

          if (profile == null) {
            return AnnotatedRegion<SystemUiOverlayStyle>(
              value: kProfileLightScaffoldSystemUi,
              child: Scaffold(
                body: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: AppColors.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          state is ProfileError
                              ? state.message
                              : 'Failed to load profile',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _initAndLoad,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.textOnPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }

          final token = _accessToken ?? '';
          // MVP: single profile only — restore householdType branching later.
          // final isJustMe = profile.householdType == 'just_me';

          final statusTop = MediaQuery.paddingOf(context).top;
          final deviceTextScale = MediaQuery.textScalerOf(context).scale(1.0);

          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: kProfileGradientHeaderSystemUi,
            child: Scaffold(
              extendBody: true,
              body: SafeArea(
                top: false,
                bottom: false,
                child: Column(
                  children: [
                    Expanded(
                      child: Container(
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(22),
                            ),
                            image: const DecorationImage(
                              image: AssetImage(BgTheme.backgroundImageAsset),
                              fit: BoxFit.cover,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.22),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                            final widthScale = (constraints.maxWidth / 390)
                                .clamp(0.84, 1.06);
                            final heightScale = (constraints.maxHeight / 760)
                                .clamp(0.58, 1.0);
                            final textScaleTightness = (1.08 / deviceTextScale)
                                .clamp(0.82, 1.04);
                            final layoutScale = (math.min(
                              widthScale,
                              heightScale,
                            ) *
                                    textScaleTightness)
                                .clamp(0.58, 1.0);

                            final horizontalLeft =
                                ArticleStyleHeaderInsets.titleLeftInsetOf(
                              context,
                            );
                            final horizontalRight =
                                ArticleStyleHeaderInsets.headerRightInsetOf(
                              context,
                            );
                            final topPadding = statusTop +
                                30 +
                                ArticleStyleHeaderInsets.topTitleGapOf(context);
                            final embeddedBottomNavReserve = widget.showBottomNav
                                ? 0.0
                                : (FloatingGradientBottomNav.barHeight +
                                        dashboardBottomNavOuterInsets(context)
                                            .bottom +
                                        8)
                                    .toDouble();
                            final bottomPadding = (20 * layoutScale).clamp(
                                  4.0,
                                  18.0,
                                ) +
                                embeddedBottomNavReserve;
                            const titleSize = 24.0;
                            final subtitleSize = (14 * layoutScale).clamp(
                              11.0,
                              14.0,
                            );

                              return Padding(
                                padding: EdgeInsets.fromLTRB(
                                  horizontalLeft,
                                  topPadding,
                                  horizontalRight,
                                  bottomPadding,
                                ),
                                child: Column(
                                  children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: EdgeInsets.only(
                                          top: (2 * layoutScale).clamp(
                                            0.0,
                                            4.0,
                                          ),
                                        ),
                                        child: const ChevronScreenBackButton(
                                          iconColor: Color(0xFFDFE7E9),
                                        ),
                                      ),
                                      const SizedBox(width: 7),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              profile.name,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.boldonse(
                                                fontSize: titleSize,
                                                fontWeight: FontWeight.w400,
                                                color: const Color(0xFFDFE7E9),
                                              ),
                                            ),
                                            SizedBox(
                                              height: (8 * layoutScale).clamp(
                                                4.0,
                                                8.0,
                                              ),
                                            ),
                                            Text(
                                              _subtitleLine(profile),
                                              maxLines: 1,
                                              overflow: TextOverflow.fade,
                                              softWrap: false,
                                              style: GoogleFonts.montserrat(
                                                fontSize: subtitleSize,
                                                fontWeight: FontWeight.w400,
                                                color: const Color(0xFFDFE7E9),
                                                height: 1.1,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(
                                        width: (12 * layoutScale).clamp(
                                          6.0,
                                          12.0,
                                        ),
                                      ),
                                      _OverlappingAvatarCluster(
                                        profile: profile,
                                        scale: (layoutScale * 0.9).clamp(
                                          0.68,
                                          1.0,
                                        ),
                                        onTap: token.isNotEmpty
                                            ? () => _openEditProfile(
                                                  context,
                                                  profile,
                                                  token,
                                                )
                                            : null,
                                      ),
                                    ],
                                  ),
                                  SizedBox(
                                    height: (16 * layoutScale).clamp(
                                      4.0,
                                      16.0,
                                    ),
                                  ),
                                  Expanded(
                                    child: SingleChildScrollView(
                                      physics: const ClampingScrollPhysics(),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          _MenuSection(
                                            scale: layoutScale,
                                            children: [
                                              _GradientMenuTile(
                                                iconAssetPath:
                                                    'assets/images/icons/profile/familyprofile.svg',
                                                title: 'Profile',
                                                scale: layoutScale,
                                                onTap: () => _openEditProfile(
                                                  context,
                                                  profile,
                                                  token,
                                                ),
                                              ),
                                              // MVP: family profile — restore when multi-profile ships.
                                              // _GradientMenuTile(
                                              //   iconAssetPath:
                                              //       'assets/images/icons/profile/familyprofile.svg',
                                              //   title: isJustMe ? 'Profile' : 'Family Profile',
                                              //   scale: layoutScale,
                                              //   onTap: () {
                                              //     if (isJustMe) {
                                              //       _openEditProfile(context, profile, token);
                                              //       return;
                                              //     }
                                              //     _openFamilyProfile(context, profile, token);
                                              //   },
                                              // ),
                                              _GradientMenuTile(
                                                iconAssetPath:
                                                    'assets/images/icons/profile/bell.svg',
                                                title: 'Notifications',
                                                scale: layoutScale,
                                                onTap: () => Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) => BlocProvider.value(
                                                      value: context.read<ProfileBloc>(),
                                                      child: const NotificationsPage(),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              _GradientMenuTile(
                                                iconAssetPath:
                                                    'assets/images/icons/profile/location.svg',
                                                title: 'Location',
                                                scale: layoutScale,
                                                onTap: () => _openSavedAddresses(
                                                  context,
                                                  profile,
                                                  token,
                                                ),
                                              ),
                                              _GradientMenuTile(
                                                iconAssetPath:
                                                    'assets/images/icons/profile/payment.svg',
                                                title: 'Payment',
                                                scale: layoutScale,
                                                onTap: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (_) =>
                                                          BlocProvider(
                                                        create: (_) => di
                                                            .sl<PaymentBloc>(),
                                                        child:
                                                            const PaymentHistoryPage(),
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                              _GradientMenuTile(
                                                icon: Icons
                                                    .assignment_turned_in_outlined,
                                                title: 'My Orders',
                                                scale: layoutScale,
                                                onTap: () =>
                                                    _openServiceRequests(context),
                                              ),
                                              _GradientMenuTile(
                                                iconAssetPath:
                                                    'assets/images/icons/profile/managedevice.svg',
                                                title: 'Manage Devices',
                                                scale: layoutScale,
                                                onTap: () =>
                                                    _openManageDevices(context),
                                              ),
                                            ],
                                          ),
                                          SizedBox(
                                            height: (10 * layoutScale).clamp(
                                              3.0,
                                              10.0,
                                            ),
                                          ),
                                          _MenuSection(
                                            scale: layoutScale,
                                            children: [
                                              _GradientMenuTile(
                                                iconAssetPath:
                                                    'assets/images/icons/profile/faq.svg',
                                                title: 'FAQ',
                                                scale: layoutScale,
                                                onTap: () => Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        const FaqPage(),
                                                  ),
                                                ),
                                              ),
                                              _GradientMenuTile(
                                                iconAssetPath:
                                                    'assets/images/icons/profile/termscondition.svg',
                                                title: 'Terms & Conditions',
                                                scale: layoutScale,
                                                onTap: () => Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        const TermsOfServicePage(),
                                                  ),
                                                ),
                                              ),
                                              _GradientMenuTile(
                                                iconAssetPath:
                                                    'assets/images/icons/profile/license.svg',
                                                title: 'License',
                                                scale: layoutScale,
                                                onTap: () => Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        const AppLicensePage(),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    height: (8 * layoutScale).clamp(4.0, 12.0),
                                  ),
                                  _MenuSection(
                                    scale: layoutScale,
                                    showDivider: false,
                                    children: [
                                      _GradientMenuTile(
                                        iconAssetPath:
                                            'assets/images/icons/profile/log-out.svg',
                                        title: 'Log Out',
                                        scale: layoutScale,
                                        onTap: _logout,
                                      ),
                                    ],
                                  ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                    ),
                    if (widget.showBottomNav) ...[
                      const SizedBox(height: 14),
                      const DashboardLinkedBottomNav(selectedTabIndex: 2),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // MVP: single profile only — restore for family / multi-profile.
  // void _openFamilyProfile(
  //   BuildContext context,
  //   UserProfile profile,
  //   String token,
  // ) {
  //   Navigator.push(
  //     context,
  //     MaterialPageRoute(
  //       builder: (_) => BlocProvider.value(
  //         value: context.read<ProfileBloc>(),
  //         child: FamilyProfilePage(profile: profile, accessToken: token),
  //       ),
  //     ),
  //   );
  // }

  void _openSavedAddresses(
    BuildContext context,
    UserProfile profile,
    String token,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<ProfileBloc>(),
          child: SavedAddressesPage(profile: profile, accessToken: token),
        ),
      ),
    );
  }

  void _openManageDevices(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ManageDevicesPage()),
    );
  }

  void _openServiceRequests(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ServiceRequestListPage()),
    );
  }

  void _openEditProfile(
    BuildContext context,
    UserProfile profile,
    String token,
  ) {
    if (token.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider.value(
          value: context.read<ProfileBloc>(),
          child: EditProfilePage(profile: profile, accessToken: token),
        ),
      ),
    );
  }
}

class _OverlappingAvatarCluster extends StatelessWidget {
  const _OverlappingAvatarCluster({
    required this.profile,
    this.scale = 1.0,
    this.onTap,
  });

  final UserProfile profile;
  final double scale;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    // Single profile avatar — family ring icons hidden (see family profile module).
    final mainRadius = (39.5 * scale).clamp(28.0, 39.5);
    const border = BorderSide.none;

    final cluster = SizedBox(
      width: mainRadius * 2,
      height: mainRadius * 2,
      child: _RingAvatar(
        radius: mainRadius,
        border: border,
        child: profile.profileImage != null
            ? ClipOval(
                child: Image.network(
                  profile.profileImage!,
                  width: mainRadius * 2,
                  height: mainRadius * 2,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      _initialsAvatar(profile, mainRadius),
                ),
              )
            : _initialsAvatar(profile, mainRadius),
      ),
    );

    // Family emoji cluster — commented out; one profile only.
    // final clusterW = (156 * scale).clamp(112.0, 156.0);
    // final clusterH = (92 * scale).clamp(68.0, 92.0);
    // final smallRadius = (22 * scale).clamp(16.0, 22.0);
    // final cluster = SizedBox(
    //   width: clusterW,
    //   height: clusterH,
    //   child: Stack(
    //     clipBehavior: Clip.none,
    //     children: [
    //       Positioned(
    //         right: 0,
    //         top: 0,
    //         child: _RingAvatar(
    //           radius: smallRadius,
    //           border: border,
    //           child: _smallFill(Icons.person, (14 * scale).clamp(10.0, 14.0)),
    //         ),
    //       ),
    //       Positioned(
    //         right: (31 * scale).clamp(20.0, 31.0),
    //         top: (6 * scale).clamp(3.0, 6.0),
    //         child: _RingAvatar(
    //           radius: mainRadius,
    //           border: BorderSide.none,
    //           child: profile.profileImage != null
    //               ? ClipOval(
    //                   child: Image.network(
    //                     profile.profileImage!,
    //                     width: mainRadius * 2,
    //                     height: mainRadius * 2,
    //                     fit: BoxFit.cover,
    //                     errorBuilder: (context, error, stackTrace) =>
    //                         _initialsAvatar(profile, mainRadius),
    //                   ),
    //                 )
    //               : _initialsAvatar(profile, mainRadius),
    //         ),
    //       ),
    //       Positioned(
    //         right: 0,
    //         bottom: 0,
    //         child: _RingAvatar(
    //           radius: smallRadius,
    //           border: border,
    //           child: _smallFill(
    //             Icons.child_care_outlined,
    //             (18 * scale).clamp(12.0, 18.0),
    //           ),
    //         ),
    //       ),
    //     ],
    //   ),
    // );

    if (onTap == null) return cluster;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: cluster,
      ),
    );
  }

  Widget _initialsAvatar(UserProfile profile, double radius) {
    final letter = profile.name.isNotEmpty
        ? profile.name[0].toUpperCase()
        : 'U';
    return Container(
      width: radius * 2,
      height: radius * 2,
      color: Colors.white.withValues(alpha: 0.25),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: TextStyle(
          fontSize: radius * 0.85,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }

  // Widget _smallFill(IconData icon, double size) {
  //   return Container(
  //     color: Colors.white.withValues(alpha: 0.22),
  //     alignment: Alignment.center,
  //     child: Icon(icon, color: Colors.white, size: size),
  //   );
  // }
}

class _RingAvatar extends StatelessWidget {
  const _RingAvatar({
    required this.radius,
    required this.border,
    required this.child,
  });

  final double radius;
  final BorderSide border;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.fromBorderSide(border),
      ),
      child: ClipOval(child: child),
    );
  }
}

class _GradientMenuTile extends StatelessWidget {
  const _GradientMenuTile({
    this.icon,
    this.iconAssetPath,
    required this.title,
    required this.onTap,
    this.scale = 1.0,
  }) : assert(icon != null || iconAssetPath != null);

  final IconData? icon;
  final String? iconAssetPath;
  final String title;
  final VoidCallback onTap;
  final double scale;
  @override
  Widget build(BuildContext context) {
    final vPad = (10 * scale).clamp(4.0, 13.0);
    final iconSize = (20 * scale).clamp(16.0, 24.0);
    final textSize = (14 * scale).clamp(11.0, 16.0);
    final gap = (10 * scale).clamp(6.0, 14.0);
    final chevronSize = (22 * scale).clamp(16.0, 25.0);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        splashColor: Colors.white24,
        highlightColor: Colors.white10,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: vPad),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: (30 * scale).clamp(22.0, 38.0),
            ),
            child: Row(
              children: [
                if (iconAssetPath != null)
                  SvgPicture.asset(
                    iconAssetPath!,
                    width: iconSize,
                    height: iconSize,
                    fit: BoxFit.contain,
                    colorFilter: const ColorFilter.mode(
                      Colors.white,
                      BlendMode.srcIn,
                    ),
                    errorBuilder: (_, __, ___) =>
                        Icon(Icons.circle_outlined, color: Colors.white, size: iconSize),
                  )
                else
                  Icon(icon, color: Colors.white, size: iconSize),
                SizedBox(width: gap),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.montserrat(
                      fontSize: textSize,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white.withValues(alpha: 0.96),
                  size: chevronSize,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GradientSectionDivider extends StatelessWidget {
  const _GradientSectionDivider({this.scale = 1.0});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: (7 * scale).clamp(3.0, 7.0)),
      child: Container(height: 1, color: Colors.white.withValues(alpha: 0.42)),
    );
  }
}

class _MenuSection extends StatelessWidget {
  const _MenuSection({
    required this.children,
    this.scale = 1.0,
    this.showDivider = true,
  });

  final List<Widget> children;
  final double scale;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final menuHInset = (16 * scale).clamp(12.0, 20.0);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: menuHInset),
      child: Column(
        children: [
          ...children,
          if (showDivider) _GradientSectionDivider(scale: scale),
        ],
      ),
    );
  }
}
