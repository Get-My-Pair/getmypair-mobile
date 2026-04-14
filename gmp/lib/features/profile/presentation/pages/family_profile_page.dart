import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/floating_gradient_bottom_nav.dart';
import '../../domain/entities/user_profile.dart';
import '../bloc/profile_bloc.dart';
import 'edit_profile_page.dart';

class FamilyProfilePage extends StatelessWidget {
  final UserProfile profile;
  final String accessToken;

  const FamilyProfilePage({
    super.key,
    required this.profile,
    required this.accessToken,
  });

  static const LinearGradient _kGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [Color(0xFF22D3EE), Color(0xFF0F6876), Color(0xFF062F35)],
    stops: [0.0, 0.48, 1.0],
  );

  @override
  Widget build(BuildContext context) {
    final names = <String>[
      profile.name.trim().isEmpty ? 'Profile' : profile.name.trim(),
      'Mohan Ramaratnam',
      'Vignesh R',
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  gradient: _kGradient,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(22),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.22),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Family Profile',
                              style: GoogleFonts.boldonse(
                                fontSize: 24,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFFDFE7E9),
                                height: 1,
                              ),
                            ),
                          ),
                          _AvatarCluster(profile: profile),
                        ],
                      ),
                      const SizedBox(height: 28),
                      for (final name in names)
                        _FamilyRow(
                          title: name,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BlocProvider.value(
                                  value: context.read<ProfileBloc>(),
                                  child: EditProfilePage(
                                    profile: profile,
                                    accessToken: accessToken,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const DashboardLinkedBottomNav(),
          ],
        ),
      ),
    );
  }
}

class _FamilyRow extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const _FamilyRow({
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.white.withValues(alpha: 0.5)),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.montserrat(
                    fontSize: 20,
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                    height: 1,
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

class _AvatarCluster extends StatelessWidget {
  final UserProfile profile;

  const _AvatarCluster({required this.profile});

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
    final letter = profile.name.isNotEmpty ? profile.name[0].toUpperCase() : 'U';
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

