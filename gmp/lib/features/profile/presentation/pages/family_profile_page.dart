import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/bgtheme.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/widgets/app_feedback_alert.dart';
import '../../../../core/widgets/chevron_screen_back_button.dart';
import '../../../../core/widgets/floating_gradient_bottom_nav.dart';
import '../../../../routes.dart';
import '../../domain/entities/user_profile.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../bloc/profile_state.dart';
import '../profile_screen_system_ui.dart';
import '../utils/profile_switch_loading.dart';

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
      backgroundColor: const Color(0xFF0B3A4A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Add profile',
                  style: GoogleFonts.boldonse(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 16),
                _relationTile(ctx, 'partner', 'My Partner'),
                _relationTile(ctx, 'child', 'My Kids'),
                _relationTile(ctx, 'elder', 'Elderly'),
              ],
            ),
          ),
        );
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

  Widget _relationTile(BuildContext ctx, String value, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: () => Navigator.pop(ctx, value),
        tileColor: Colors.white.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          label,
          style: GoogleFonts.montserrat(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.white),
      ),
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
        ProfileSwitchLoading.sync(context, state);
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
                          final layoutScale = (math.min(widthScale, heightScale) *
                                  textScaleTightness)
                              .clamp(0.82, 1.0);
                          final horizontalLeft =
                              ArticleStyleHeaderInsets.titleLeftInsetOf(context);
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
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        'Family Profile',
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
                                    IconButton(
                                      onPressed: switching
                                          ? null
                                          : _openAddRelationSheet,
                                      tooltip: 'Add profile',
                                      icon: const Icon(
                                        Icons.add,
                                        color: Colors.white,
                                        size: 28,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(
                                  height: (10 * layoutScale).clamp(3.0, 12.0),
                                ),
                                Text(
                                  'Switch profile',
                                  style: GoogleFonts.montserrat(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                if (state is AddressActionLoading)
                                  const Padding(
                                    padding: EdgeInsets.only(bottom: 12),
                                    child: LinearProgressIndicator(
                                      minHeight: 2,
                                      color: Colors.white,
                                    ),
                                  ),
                                Expanded(
                                  child: ListView.builder(
                                    itemCount: profiles.length,
                                    itemBuilder: (context, index) {
                                      final item = profiles[index];
                                      final selected = item.id == activeId;
                                      return _ProfileSwitchRow(
                                        title: item.name,
                                        subtitle: item.label,
                                        imageUrl: item.imageUrl,
                                        selected: selected,
                                        canDelete: !item.isSelf,
                                        onTap: switching
                                            ? null
                                            : () =>
                                                _switchTo(item.id, activeId),
                                        onDelete: switching
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

class _ProfileSwitchRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? imageUrl;
  final bool selected;
  final bool canDelete;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const _ProfileSwitchRow({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.selected,
    required this.canDelete,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.white.withValues(alpha: 0.5)),
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
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
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ),
              if (canDelete)
                IconButton(
                  onPressed: onDelete,
                  tooltip: 'Delete profile',
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    Icons.delete_outline,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              if (selected)
                const Icon(Icons.check_circle, color: Colors.white)
              else
                Icon(
                  Icons.radio_button_unchecked,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
