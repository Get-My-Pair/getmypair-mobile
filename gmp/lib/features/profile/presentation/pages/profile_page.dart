import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive.dart';
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
import '../widgets/edit_profile_widget.dart';
import '../widgets/saved_addresses_page.dart';
import 'manage_devices_page.dart';

/// Teal → cyan profile shell (matches marketing / dashboard gradient).
const LinearGradient _kProfileCardGradient = LinearGradient(
  begin: Alignment.topRight,
  end: Alignment.bottomLeft,
  colors: [
    Color(0xFF00E5FF),
    Color(0xFF0F6876),
    Color(0xFF004D4D),
  ],
  stops: [0.0, 0.42, 1.0],
);

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

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
    result.fold(
      (failure) {
        if (failure is AuthenticationFailure) {
          context.read<AuthBloc>().add(const AuthSessionExpired());
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(failure.message),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      },
      (token) {
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
        title: const Text('Log Out',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
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
                  borderRadius: BorderRadius.circular(10)),
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
        listener: (context, state) {
          if (state is ProfileError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is ProfileLoading || state is ProfileInitial) {
            return const Scaffold(
              backgroundColor: AppColors.background,
              body: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
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

          final token = _accessToken ?? '';

          if (profile == null) {
            return Scaffold(
              backgroundColor: AppColors.background,
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 64, color: AppColors.error),
                      const SizedBox(height: 16),
                      Text(
                        state is ProfileError
                            ? state.message
                            : 'Failed to load profile',
                        textAlign: TextAlign.center,
                        style:
                            const TextStyle(color: AppColors.textSecondary),
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
            );
          }

          final hp = Responsive.horizontalPaddingOf(context);

          return Scaffold(
            backgroundColor: AppColors.background,
            body: SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(hp, 12, hp, 32),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: _kProfileCardGradient,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                        spreadRadius: -4,
                      ),
                      BoxShadow(
                        color: const Color(0xFF0A6C78).withValues(alpha: 0.35),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _OverlappingAvatarCluster(profile: profile),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      profile.name,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                        height: 1.2,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      _subtitleLine(profile),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w400,
                                        color: Colors.white.withValues(
                                            alpha: 0.92),
                                        height: 1.35,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),

                        _GradientMenuTile(
                          icon: Icons.account_circle_outlined,
                          title: 'Profile',
                          onTap: () =>
                              _openEditProfile(context, profile, token),
                        ),
                        _GradientMenuTile(
                          icon: Icons.notifications_outlined,
                          title: 'Notifications',
                          onTap: () {},
                        ),
                        _GradientMenuTile(
                          icon: Icons.location_on_outlined,
                          title: 'Location',
                          onTap: () =>
                              _openSavedAddresses(context, profile, token),
                        ),
                        _GradientMenuTile(
                          icon: Icons.credit_card_outlined,
                          title: 'Payment',
                          onTap: () {},
                        ),
                        _GradientMenuTile(
                          icon: Icons.devices_other,
                          title: 'Manage Devices',
                          onTap: () => _openManageDevices(context),
                        ),

                        _GradientSectionDivider(),

                        _GradientMenuTile(
                          icon: Icons.contact_support_outlined,
                          title: 'FAQ',
                          onTap: () {},
                        ),
                        _GradientMenuTile(
                          icon: Icons.info_outline,
                          title: 'Terms & Conditions',
                          onTap: () {},
                        ),
                        _GradientMenuTile(
                          icon: Icons.workspace_premium_outlined,
                          title: 'License',
                          onTap: () {},
                        ),

                        _GradientSectionDivider(),

                        _GradientMenuTile(
                          icon: Icons.privacy_tip_outlined,
                          title: 'Privacy Policy',
                          onTap: () {},
                        ),

                        _GradientSectionDivider(),

                        _GradientMenuTile(
                          icon: Icons.logout,
                          title: 'Log Out',
                          onTap: _logout,
                          showChevron: false,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _openEditProfile(
      BuildContext context, UserProfile profile, String token) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<ProfileBloc>(),
          child: EditProfileWidget(profile: profile, accessToken: token),
        ),
      ),
    );
  }

  void _openSavedAddresses(
      BuildContext context, UserProfile profile, String token) {
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
      MaterialPageRoute(
        builder: (_) => const ManageDevicesPage(),
      ),
    );
  }
}

/// Decorative cluster: main photo + two smaller circles (placeholder icons).
class _OverlappingAvatarCluster extends StatelessWidget {
  const _OverlappingAvatarCluster({required this.profile});

  final UserProfile profile;

  static const _border = BorderSide(color: Colors.white, width: 2);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 118,
      height: 100,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 62,
            top: 2,
            child: _RingAvatar(
              radius: 16,
              border: _border,
              child: _smallFill(Icons.person, 14),
            ),
          ),
          Positioned(
            left: 0,
            top: 10,
            child: _RingAvatar(
              radius: 38,
              border: _border,
              child: profile.profileImage != null
                  ? ClipOval(
                      child: Image.network(
                        profile.profileImage!,
                        width: 76,
                        height: 76,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _initialsAvatar(profile, 38),
                      ),
                    )
                  : _initialsAvatar(profile, 38),
            ),
          ),
          Positioned(
            left: 46,
            top: 54,
            child: _RingAvatar(
              radius: 21,
              border: _border,
              child: _smallFill(Icons.child_care_outlined, 18),
            ),
          ),
        ],
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

  Widget _smallFill(IconData icon, double size) {
    return Container(
      color: Colors.white.withValues(alpha: 0.22),
      alignment: Alignment.center,
      child: Icon(icon, color: Colors.white, size: size),
    );
  }
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
    required this.icon,
    required this.title,
    required this.onTap,
    this.showChevron = true,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: Colors.white24,
        highlightColor: Colors.white10,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                    letterSpacing: 0.15,
                  ),
                ),
              ),
              if (showChevron)
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white.withValues(alpha: 0.95),
                  size: 26,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GradientSectionDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Container(
        height: 1,
        color: Colors.white.withValues(alpha: 0.35),
      ),
    );
  }
}
