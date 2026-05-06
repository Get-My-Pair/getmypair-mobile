import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/bgtheme.dart';
import '../../../../core/widgets/chevron_screen_back_button.dart';
import '../../../../core/widgets/floating_gradient_bottom_nav.dart';
import '../../domain/entities/user_profile.dart';
import '../bloc/profile_bloc.dart';
import '../profile_screen_system_ui.dart';
import 'edit_profile_page.dart';

class FamilyProfilePage extends StatelessWidget {
  final UserProfile profile;
  final String accessToken;

  const FamilyProfilePage({
    super.key,
    required this.profile,
    required this.accessToken,
  });

  @override
  Widget build(BuildContext context) {
    final names = <String>[
      profile.name.trim().isEmpty ? 'Profile' : profile.name.trim(),
      'Mohan Ramaratnam',
      'Vignesh R',
    ];

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
                          .clamp(0.82, 1.0);

                      final horizontalLeft =
                          ArticleStyleHeaderInsets.titleLeftInsetOf(context);
                      final horizontalRight =
                          ArticleStyleHeaderInsets.headerRightInsetOf(context);
                      final topPadding = statusTop +
                          30 +
                          ArticleStyleHeaderInsets.topTitleGapOf(context);
                      final bottomPadding = (20 * layoutScale).clamp(4.0, 18.0);
                      const titleSize = 20.0;

                      return Padding(
                        padding: EdgeInsets.fromLTRB(
                          horizontalLeft,
                          topPadding,
                          horizontalRight,
                          bottomPadding,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const ChevronScreenBackButton(
                                  iconColor: Colors.white,
                                ),
                                const SizedBox(width: 7),
                                Expanded(
                                  child: FittedBox(
                                    alignment: Alignment.center,
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      'Family Profile',
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      softWrap: false,
                                      overflow: TextOverflow.visible,
                                      style: GoogleFonts.boldonse(
                                        fontSize: titleSize,
                                        fontWeight: FontWeight.w400,
                                        color: const Color(0xFFDFE7E9),
                                        height: 1,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: (12 * layoutScale).clamp(6.0, 12.0),
                                ),
                                _AvatarCluster(
                                  profile: profile,
                                  scale: layoutScale,
                                ),
                              ],
                            ),
                            SizedBox(
                              height: (16 * layoutScale).clamp(4.0, 16.0),
                            ),
                            Expanded(
                              child: SingleChildScrollView(
                                physics: const ClampingScrollPhysics(),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    for (final name in names)
                                      _FamilyRow(
                                        title: name,
                                        scale: layoutScale,
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  BlocProvider.value(
                                                value: context
                                                    .read<ProfileBloc>(),
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
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const DashboardLinkedBottomNav(selectedTabIndex: 2),
            ],
          ),
        ),
      ),
    );
  }
}

class _FamilyRow extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  final double scale;

  const _FamilyRow({
    required this.title,
    required this.onTap,
    this.scale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: (22 * scale).clamp(18.0, 24.0)),
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
                    fontSize: (17 * scale).clamp(16.0, 18.0),
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                    height: 1,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.white.withValues(alpha: 0.96),
                size: (30 * scale).clamp(24.0, 30.0),
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
  final double scale;

  const _AvatarCluster({required this.profile, this.scale = 1.0});

  static const _border = BorderSide(color: Colors.white, width: 2);

  @override
  Widget build(BuildContext context) {
    final clusterW = (156 * scale).clamp(112.0, 156.0);
    final clusterH = (92 * scale).clamp(68.0, 92.0);
    final smallRadius = (22 * scale).clamp(16.0, 22.0);
    final mainRadius = (39.5 * scale).clamp(28.0, 39.5);
    final border = BorderSide(
      color: Colors.white,
      width: (2 * scale).clamp(1.3, 2.0),
    );
    return SizedBox(
      width: clusterW,
      height: clusterH,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: 0,
            top: 0,
            child: _RingAvatar(
              radius: smallRadius,
              border: border,
              child: _smallFill(Icons.person, (14 * scale).clamp(10.0, 14.0)),
            ),
          ),
          Positioned(
            right: (31 * scale).clamp(20.0, 31.0),
            top: (6 * scale).clamp(3.0, 6.0),
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
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: _RingAvatar(
              radius: smallRadius,
              border: border,
              child: _smallFill(
                Icons.child_care_outlined,
                (18 * scale).clamp(12.0, 18.0),
              ),
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
