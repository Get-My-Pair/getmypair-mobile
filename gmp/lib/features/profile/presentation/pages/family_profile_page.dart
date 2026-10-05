import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/bgtheme.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/widgets/app_feedback_alert.dart';
import '../../../../core/widgets/app_skeleton.dart';
import '../../../../core/widgets/chevron_screen_back_button.dart';
import '../../../../core/widgets/floating_gradient_bottom_nav.dart';
import '../../../../routes.dart';
import '../../domain/entities/user_profile.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../bloc/profile_state.dart';
import '../profile_screen_system_ui.dart';

const Color _kSheetTeal = Color(0xFF12899B);
const Color _kSheetBg = Color(0xFFF5F5F5);
const Color _kSheetDivider = Color(0xFFE0E0E0);
const Color _kListDivider = Color(0x66FFFFFF);
const Color _kSubtitle = Color(0xB3DFE7E9);

class FamilyProfilePage extends StatefulWidget {
  final UserProfile profile;
  final String accessToken;

  const FamilyProfilePage({
    super.key,
    required this.profile,
    required this.accessToken,
  });

  @override
  State<FamilyProfilePage> createState() => _FamilyProfilePageState();
}

class _FamilyProfilePageState extends State<FamilyProfilePage> {
  Future<void> _openAddRelationSheet() async {
    final relation = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return const _AddRelationBottomSheet();
      },
    );
    if (relation == null || !mounted) return;
    await Navigator.of(context).pushNamed(
      AppRoutes.addFamilyProfile,
      arguments: <String, dynamic>{
        'accessToken': widget.accessToken,
        'relation': relation,
        'bloc': context.read<ProfileBloc>(),
      },
    );
  }

  void _switchTo(String profileId, String activeId) {
    if (profileId == activeId) return;
    context.read<ProfileBloc>().add(
          ActiveProfileSwitchRequested(
            accessToken: widget.accessToken,
            profileId: profileId,
          ),
        );
  }

  Future<void> _confirmDelete(SwitchableAppProfile item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0B3A4A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete profile',
          style: GoogleFonts.boldonse(
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        content: Text(
          'Remove ${item.name} from your family profiles?',
          style: GoogleFonts.montserrat(
            color: Colors.white70,
            fontSize: 15,
            height: 1.35,
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancel',
              style: GoogleFonts.montserrat(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Delete',
              style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    context.read<ProfileBloc>().add(
          FamilyMemberDeleteRequested(
            accessToken: widget.accessToken,
            memberId: item.id,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileBloc, ProfileState>(
      listener: (context, state) async {
        if (state is ProfileError) {
          if (!(ModalRoute.of(context)?.isCurrent ?? false)) return;
          await showAppFeedbackAlert(
            context,
            message: userFacingFamilyProfileError(state.message),
            type: AppFeedbackType.failure,
          );
        }
      },
      builder: (context, state) {
        final currentProfile = state is ProfileLoaded
            ? state.profile
            : state is ProfileUpdating
                ? state.profile
                : state is ProfileImageUploading
                    ? state.profile
                    : state is AddressActionLoading
                        ? state.profile
                        : state is ProfileSwitching
                            ? state.profile
                            : state is ProfileError && state.profile != null
                                ? state.profile!
                                : widget.profile;
        final profiles = switchableProfilesOf(currentProfile);
        final activeId = currentProfile.isSelfActive
            ? kSelfProfileId
            : currentProfile.activeProfileId;
        final switching =
            state is AddressActionLoading || state is ProfileSwitching;

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
                          final widthScale =
                              (constraints.maxWidth / 390).clamp(0.84, 1.06);
                          final heightScale =
                              (constraints.maxHeight / 760).clamp(0.58, 1.0);
                          final textScaleTightness =
                              (1.08 / deviceTextScale).clamp(0.82, 1.04);
                          final layoutScale =
                              (math.min(widthScale, heightScale) *
                                      textScaleTightness)
                                  .clamp(0.82, 1.0);
                          final horizontalLeft =
                              ArticleStyleHeaderInsets.titleLeftInsetOf(
                                  context);
                          final horizontalRight =
                              ArticleStyleHeaderInsets.headerRightInsetOf(
                            context,
                          );
                          final topPadding = statusTop +
                              24 +
                              ArticleStyleHeaderInsets.topTitleGapOf(context);

                          return Padding(
                            padding: EdgeInsets.fromLTRB(
                              horizontalLeft,
                              topPadding,
                              horizontalRight,
                              (20 * layoutScale).clamp(4.0, 18.0),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const ChevronScreenBackButton(
                                      iconColor: Colors.white,
                                    ),
                                    const SizedBox(width: 2),
                                    Expanded(
                                      child: Text(
                                        'Family Profile',
                                        textAlign: TextAlign.left,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.boldonse(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w400,
                                          color: const Color(0xFFDFE7E9),
                                          height: 1,
                                        ),
                                      ),
                                    ),
                                    Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: switching
                                            ? null
                                            : _openAddRelationSheet,
                                        customBorder: const CircleBorder(),
                                        child: Opacity(
                                          opacity: switching ? 0.45 : 1,
                                          child: Image.asset(
                                            'assets/images/icons/profile/add-profile.png',
                                            width: 36,
                                            height: 36,
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(
                                  height: (18 * layoutScale).clamp(10.0, 22.0),
                                ),
                                Expanded(
                                  child: state is ProfileSwitching
                                      ? AppSkeletonList(
                                          itemCount: 4,
                                          color: Colors.white
                                              .withValues(alpha: 0.35),
                                          padding: const EdgeInsets.only(top: 8),
                                        )
                                      : ListView.builder(
                                    itemCount: profiles.length,
                                    itemBuilder: (context, index) {
                                      final item = profiles[index];
                                      final subtitle = item.isSelf
                                          ? 'Primary'
                                          : item.label;
                                      return _ProfileSwitchRow(
                                        title: item.name,
                                        subtitle: subtitle,
                                        imageUrl: item.imageUrl,
                                        onTap: switching
                                            ? null
                                            : () =>
                                                _switchTo(item.id, activeId),
                                        onLongPress: item.isSelf || switching
                                            ? null
                                            : () => _confirmDelete(item),
                                      );
                                    },
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
      },
    );
  }
}

class _AddRelationBottomSheet extends StatelessWidget {
  const _AddRelationBottomSheet();

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Container(
      decoration: const BoxDecoration(
        color: _kSheetBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(20, 24, 20, 16 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'For whom are we',
                textAlign: TextAlign.left,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.visible,
                style: GoogleFonts.boldonse(
                  color: _kSheetTeal,
                  fontSize: 20,
                  fontWeight: FontWeight.w400,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'creating this profile?',
                textAlign: TextAlign.left,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.visible,
                style: GoogleFonts.boldonse(
                  color: _kSheetTeal,
                  fontSize: 20,
                  fontWeight: FontWeight.w400,
                  height: 1.35,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          _sheetOption(context, 'partner', 'My Partner', showDivider: true),
          _sheetOption(context, 'child', 'My Kids', showDivider: true),
          _sheetOption(context, 'elder', 'Elderly', showDivider: false),
        ],
      ),
    );
  }

  Widget _sheetOption(
    BuildContext context,
    String value,
    String label, {
    required bool showDivider,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: () => Navigator.pop(context, value),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    textAlign: TextAlign.left,
                    style: GoogleFonts.montserrat(
                      color: _kSheetTeal,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: _kSheetTeal,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          const Divider(
            height: 1,
            thickness: 1,
            color: _kSheetDivider,
          ),
      ],
    );
  }
}

class _ProfileSwitchRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? imageUrl;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const _ProfileSwitchRow({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: _kListDivider, width: 0.8),
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: Colors.white.withValues(alpha: 0.22),
                backgroundImage: hasImage ? NetworkImage(imageUrl!) : null,
                child: hasImage
                    ? null
                    : Text(
                        title.isNotEmpty ? title[0].toUpperCase() : 'U',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.montserrat(
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: GoogleFonts.montserrat(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w400,
                        color: _kSubtitle,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.white.withValues(alpha: 0.55),
                size: 26,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
