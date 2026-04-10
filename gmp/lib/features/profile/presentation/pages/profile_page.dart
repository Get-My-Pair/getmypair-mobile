import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/theme/app_colors.dart';
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
import 'saved_addresses_page.dart';
import 'family_profile_page.dart';
import 'manage_devices_page.dart';

const LinearGradient _kProfileCardGradient = LinearGradient(
  begin: Alignment.topRight,
  end: Alignment.bottomLeft,
  colors: [Color(0xFF22D3EE), Color(0xFF0F6876), Color(0xFF062F35)],
  stops: [0.0, 0.48, 1.0],
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

          return Scaffold(
            backgroundColor: AppColors.background,
            body: SafeArea(
              child: Container(
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  borderRadius:
                      const BorderRadius.vertical(bottom: Radius.circular(22)),
                  gradient: _kProfileCardGradient,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.22),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 30),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  profile.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontFamily: 'Boldonse',
                                    fontSize: 24,
                                    height: 1.02,
                                    color: Color(0xFFDFE7E9),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _subtitleLine(profile),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontFamily: 'Montserrat',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                    color: Color(0xFFDFE7E9),
                                    height: 1.1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          _OverlappingAvatarCluster(profile: profile),
                        ],
                      ),
                      const SizedBox(height: 34),
                      _MenuSection(
                        children: [
                          _GradientMenuTile(
                            icon: Icons.account_circle_outlined,
                            title: 'Family Profile',
                            onTap: () =>
                                _openFamilyProfile(context, profile, token),
                          ),
                          _GradientMenuTile(
                            icon: Icons.notifications_none_rounded,
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
                            icon: Icons.devices_other_outlined,
                            title: 'Manage Devices',
                            onTap: () => _openManageDevices(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      _MenuSection(
                        children: [
                          _GradientMenuTile(
                            icon: Icons.help_outline_rounded,
                            title: 'FAQ',
                            onTap: () {},
                          ),
                          _GradientMenuTile(
                            icon: Icons.error_outline_rounded,
                            title: 'Terms & Conditions',
                            onTap: () {},
                          ),
                          _GradientMenuTile(
                            icon: Icons.workspace_premium_outlined,
                            title: 'License',
                            onTap: () {},
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      _MenuSection(
                        children: [
                          _GradientMenuTile(
                            icon: Icons.logout_rounded,
                            title: 'Log Out',
                            onTap: _logout,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _openFamilyProfile(
      BuildContext context, UserProfile profile, String token) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<ProfileBloc>(),
          child: FamilyProfilePage(profile: profile, accessToken: token),
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

class _OverlappingAvatarCluster extends StatelessWidget {
  const _OverlappingAvatarCluster({required this.profile});

  final UserProfile profile;

  static const _border = BorderSide(color: Colors.white, width: 2);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 156,
      height: 92,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: 0,
            top: 0,
            child: _RingAvatar(
              radius: 22,
              border: _border,
              child: _smallFill(Icons.person, 14),
            ),
          ),
          Positioned(
            right: 31,
            top: 6,
            child: _RingAvatar(
              radius: 39.5,
              border: _border,
              child: profile.profileImage != null
                  ? ClipOval(
                      child: Image.network(
                        profile.profileImage!,
                        width: 79,
                        height: 79,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _initialsAvatar(profile, 39.5),
                      ),
                    )
                  : _initialsAvatar(profile, 39.5),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: _RingAvatar(
              radius: 22,
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
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        splashColor: Colors.white24,
        highlightColor: Colors.white10,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 24),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.white.withValues(alpha: 0.96),
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
  const _GradientSectionDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Container(
        height: 1,
        color: Colors.white.withValues(alpha: 0.42),
      ),
    );
  }
}

class _MenuSection extends StatelessWidget {
  const _MenuSection({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ...children,
        const _GradientSectionDivider(),
      ],
    );
  }
}
