import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../auth/presentation/pages/welcome_page.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../bloc/profile_state.dart';
import '../widgets/edit_profile_widget.dart';
import '../widgets/saved_addresses_page.dart';

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
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.accessTokenKey);
    if (mounted) {
      setState(() => _accessToken = token);
      if (token != null) {
        context.read<ProfileBloc>().add(ProfileLoadRequested(token));
      }
    }
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
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }

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
                          foregroundColor: Colors.white,
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
            body: CustomScrollView(
              slivers: [
                // ── App Bar ──────────────────────────────────────
                SliverAppBar(
                  expandedHeight: 0,
                  floating: true,
                  pinned: true,
                  backgroundColor: AppColors.background,
                  elevation: 0,
                  centerTitle: true,
                  title: const Text(
                    'PROFILE',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: 1,
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        const SizedBox(height: 16),

                        // ── Profile Header ────────────────────────
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border),
                            boxShadow: const [
                              BoxShadow(
                                color: AppColors.shadow,
                                blurRadius: 12,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 32,
                                backgroundColor: AppColors.primaryLight,
                                backgroundImage: profile.profileImage != null
                                    ? NetworkImage(profile.profileImage!)
                                    : null,
                                child: profile.profileImage == null
                                    ? Text(
                                        profile.name.isNotEmpty
                                            ? profile.name[0].toUpperCase()
                                            : 'U',
                                        style: const TextStyle(
                                          fontSize: 26,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      profile.name,
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      profile.phone,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // ── Quick Actions ─────────────────────────
                        Row(
                          children: [
                            _QuickActionChip(
                              icon: Icons.receipt_long_outlined,
                              label: 'My Orders',
                              onTap: () {},
                            ),
                            const SizedBox(width: 12),
                            _QuickActionChip(
                              icon: Icons.favorite_border,
                              label: 'Wishlist',
                              onTap: () {},
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _QuickActionChip(
                              icon: Icons.eco_outlined,
                              label: 'Carbon Credits',
                              onTap: () {},
                            ),
                            const SizedBox(width: 12),
                            _QuickActionChip(
                              icon: Icons.help_outline,
                              label: 'Help Center',
                              onTap: () {},
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // ── Account Settings ──────────────────────
                        _SectionHeader(title: 'Account Settings'),
                        const SizedBox(height: 8),
                        _SettingsCard(children: [
                          _SettingTile(
                            icon: Icons.person_outline,
                            title: 'Edit Profile',
                            onTap: () =>
                                _openEditProfile(context, profile, token),
                          ),
                          _SettingDivider(),
                          _SettingTile(
                            icon: Icons.location_on_outlined,
                            title: 'Saved Addresses',
                            subtitle:
                                '${profile.addresses.length} address${profile.addresses.length != 1 ? 'es' : ''}',
                            onTap: () => _openSavedAddresses(
                                context, profile, token),
                          ),
                          _SettingDivider(),
                          _SettingTile(
                            icon: Icons.devices_outlined,
                            title: 'Manage Devices',
                            onTap: () {},
                          ),
                          _SettingDivider(),
                          _SettingTile(
                            icon: Icons.language_outlined,
                            title: 'Select Language',
                            onTap: () {},
                          ),
                          _SettingDivider(),
                          _SettingTile(
                            icon: Icons.credit_card_outlined,
                            title: 'Saved Cards / Debit Cards',
                            onTap: () {},
                          ),
                          _SettingDivider(),
                          _SettingTile(
                            icon: Icons.notifications_outlined,
                            title: 'Notification Settings',
                            onTap: () {},
                          ),
                        ]),
                        const SizedBox(height: 20),

                        // ── Feedback & Information ────────────────
                        _SectionHeader(title: 'Feedback & Information'),
                        const SizedBox(height: 8),
                        _SettingsCard(children: [
                          _SettingTile(
                            icon: Icons.policy_outlined,
                            title: 'Terms & Policies',
                            onTap: () {},
                          ),
                          _SettingDivider(),
                          _SettingTile(
                            icon: Icons.info_outline,
                            title: 'Licenses',
                            onTap: () {},
                          ),
                          _SettingDivider(),
                          _SettingTile(
                            icon: Icons.quiz_outlined,
                            title: 'Browse FAQs',
                            onTap: () {},
                          ),
                        ]),
                        const SizedBox(height: 20),

                        // ── Logout ────────────────────────────────
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: OutlinedButton.icon(
                            onPressed: _logout,
                            icon: const Icon(Icons.logout,
                                color: AppColors.error),
                            label: const Text(
                              'LOG OUT',
                              style: TextStyle(
                                color: AppColors.error,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.error),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
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

  void _openEditProfile(BuildContext context, dynamic profile, String token) {
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
      BuildContext context, dynamic profile, String token) {
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
}

// ── Sub-widgets ─────────────────────────────────────────────────────

class _QuickActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _SettingTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: AppColors.primary, size: 22),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textTertiary),
            )
          : null,
      trailing: const Icon(Icons.chevron_right,
          color: AppColors.textTertiary, size: 20),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    );
  }
}

class _SettingDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      thickness: 1,
      color: AppColors.border,
      indent: 52,
    );
  }
}
