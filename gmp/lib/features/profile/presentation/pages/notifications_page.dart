import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/bgtheme.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_skeleton.dart';
import '../../../../core/widgets/chevron_screen_back_button.dart';
import '../../../../core/widgets/floating_gradient_bottom_nav.dart';
import '../../../../injection_container.dart' as di;
import '../../../../routes.dart';
import '../../../auth/domain/usecases/get_valid_access_token.dart';
import '../../domain/entities/user_profile.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_state.dart';
import '../utils/profile_notifications.dart';
import '../utils/notification_navigation_helper.dart';
import '../utils/user_notifications.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({
    super.key,
    this.selectedTabIndex = 2,
  });

  /// Dashboard tab highlight for the floating bottom nav.
  final int selectedTabIndex;

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  bool _loading = true;
  List<UserNotificationItem> _apiItems = const [];
  final Set<String> _dismissedIds = <String>{};
  String? _error;

  static const Color _titleColor = Color(0xFFDFE7E9);
  static const Color _cardBorder = Color(0xFF7FD4E0);
  static const Color _clearAllBorder = Color(0xFFB8E8F0);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await fetchUserNotifications();
    if (!mounted) return;
    setState(() {
      _apiItems = result.items
          .where((n) => !_dismissedIds.contains(n.id))
          .toList(growable: false);
      _loading = false;
    });
  }

  UserProfile? _profileFromState(ProfileState state) {
    if (state is ProfileLoaded) return state.profile;
    if (state is ProfileUpdating) return state.profile;
    if (state is ProfileImageUploading) return state.profile;
    if (state is AddressActionLoading) return state.profile;
    if (state is ProfileSwitching) return state.profile;
    if (state is ProfileError) return state.profile;
    return null;
  }

  List<ProfileNotificationItem> _visibleProfileItems(UserProfile? profile) {
    return buildProfileNotifications(profile)
        .where((n) => !_dismissedIds.contains(n.id))
        .toList(growable: false);
  }

  int _newCount({
    required List<UserNotificationItem> apiItems,
    required List<ProfileNotificationItem> profileItems,
  }) {
    final unreadApi = apiItems.where((n) => !n.isRead).length;
    return unreadApi + profileItems.length;
  }

  Future<void> _onApiNotificationTap(UserNotificationItem item) async {
    if (!item.isRead) {
      await markUserNotificationRead(item.id);
      if (!mounted) return;
      setState(() {
        _apiItems = _apiItems
            .map(
              (n) => n.id == item.id
                  ? UserNotificationItem(
                      id: n.id,
                      type: n.type,
                      title: n.title,
                      message: n.message,
                      serviceRequestId: n.serviceRequestId,
                      actualCost: n.actualCost,
                      amount: n.amount,
                      isRead: true,
                      createdAt: n.createdAt,
                    )
                  : n,
            )
            .toList();
      });
    }

    if (!mounted) return;
    await navigateFromUserNotification(context, item);
    if (mounted) await _load();
  }

  Future<void> _onProfileNotificationTap(
    ProfileNotificationItem item,
    UserProfile profile,
  ) async {
    if (item.id != 'create_family_profile') return;
    final result = await di.sl<GetValidAccessToken>().call();
    if (!mounted) return;
    await result.fold(
      (_) async {},
      (token) async {
        if (!mounted) return;
        await Navigator.pushNamed(
          context,
          AppRoutes.familyProfile,
          arguments: <String, dynamic>{
            'profile': profile,
            'accessToken': token,
            'bloc': context.read<ProfileBloc>(),
          },
        );
      },
    );
  }

  Future<void> _dismissApiItem(UserNotificationItem item) async {
    _dismissedIds.add(item.id);
    setState(() {
      _apiItems = _apiItems.where((n) => n.id != item.id).toList();
    });
    if (!item.isRead) {
      await markUserNotificationRead(item.id);
    }
  }

  void _dismissProfileItem(ProfileNotificationItem item) {
    setState(() {
      _dismissedIds.add(item.id);
    });
  }

  Future<void> _clearAll({
    required List<UserNotificationItem> apiItems,
    required List<ProfileNotificationItem> profileItems,
  }) async {
    final unread = apiItems.where((n) => !n.isRead).toList(growable: false);
    setState(() {
      for (final n in apiItems) {
        _dismissedIds.add(n.id);
      }
      for (final n in profileItems) {
        _dismissedIds.add(n.id);
      }
      _apiItems = const [];
    });
    for (final n in unread) {
      await markUserNotificationRead(n.id);
    }
  }

  String? _formatTime(DateTime? dt) {
    if (dt == null) return null;
    return DateFormat('d MMM yyyy · h:mm a').format(dt.toLocal());
  }

  String _subtitleForCount(int count) {
    if (count <= 0) return 'You\'re all caught up.';
    if (count == 1) return 'You have 1 new notification.';
    return 'You have $count new notifications.';
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: BgTheme.scaffoldBackgroundColor,
        body: SafeArea(
          top: false,
          bottom: false,
          child: Column(
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    image: const DecorationImage(
                      image: AssetImage(BgTheme.backgroundImageAsset),
                      fit: BoxFit.cover,
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.22),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: BlocBuilder<ProfileBloc, ProfileState>(
                    builder: (context, state) {
                      final profile = _profileFromState(state);
                      final profileItems = _visibleProfileItems(profile);
                      final newCount = _newCount(
                        apiItems: _apiItems,
                        profileItems: profileItems,
                      );
                      final isEmpty =
                          !_loading && _apiItems.isEmpty && profileItems.isEmpty;

                      return RefreshIndicator(
                        color: AppColors.secondary,
                        backgroundColor: AppColors.footwearHeroStart,
                        onRefresh: _load,
                        child: CustomScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          slivers: [
                            SliverPadding(
                              padding:
                                  ArticleStyleHeaderInsets.scrollContentPadding(
                                context,
                              ),
                              sliver: SliverList(
                                delegate: SliverChildListDelegate([
                                  _buildHeader(
                                    newCount: newCount,
                                    canClear: !isEmpty && !_loading,
                                    onClearAll: () => _clearAll(
                                      apiItems: _apiItems,
                                      profileItems: profileItems,
                                    ),
                                  ),
                                  const SizedBox(height: 28),
                                  if (_loading)
                                    AppSkeletonList(
                                      itemCount: 4,
                                      shrinkWrap: true,
                                      showAvatar: false,
                                      color: Colors.white.withValues(alpha: 0.38),
                                      padding: EdgeInsets.zero,
                                    )
                                  else if (_error != null)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 32,
                                      ),
                                      child: Text(
                                        _error!,
                                        style: GoogleFonts.montserrat(
                                          color: AppColors.onGradientMuted,
                                          fontSize: 14,
                                        ),
                                      ),
                                    )
                                  else if (isEmpty)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 48,
                                      ),
                                      child: Center(
                                        child: Text(
                                          'No notifications',
                                          style: GoogleFonts.montserrat(
                                            color: AppColors.onGradientBody,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    )
                                  else ...[
                                    ..._apiItems.map((item) {
                                      final timeLabel =
                                          _formatTime(item.createdAt);
                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 14),
                                        child: _NotificationCard(
                                          title: item.title,
                                          message: item.message,
                                          timeLabel: timeLabel,
                                          isUnread: !item.isRead,
                                          actionLabel: item.actionLabel,
                                          borderColor: _cardBorder,
                                          onTap: () =>
                                              _onApiNotificationTap(item),
                                          onDismiss: () =>
                                              _dismissApiItem(item),
                                        ),
                                      );
                                    }),
                                    ...profileItems.map((item) {
                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 14),
                                        child: _NotificationCard(
                                          title: item.title,
                                          message: item.message,
                                          isUnread: true,
                                          borderColor: _cardBorder,
                                          onTap: profile == null
                                              ? null
                                              : () =>
                                                  _onProfileNotificationTap(
                                                    item,
                                                    profile,
                                                  ),
                                          onDismiss: () =>
                                              _dismissProfileItem(item),
                                        ),
                                      );
                                    }),
                                  ],
                                ]),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              DashboardLinkedBottomNav(
                selectedTabIndex: widget.selectedTabIndex,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader({
    required int newCount,
    required bool canClear,
    required VoidCallback onClearAll,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ChevronScreenBackButton(iconColor: _titleColor),
        const SizedBox(width: 7),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text(
                'Notifications',
                style: GoogleFonts.boldonse(
                  color: _titleColor,
                  fontSize: 24,
                  fontWeight: FontWeight.w400,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _subtitleForCount(newCount),
                style: GoogleFonts.montserrat(
                  color: AppColors.onGradientBody,
                  fontSize: 13,
                  fontWeight: FontWeight.w300,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: _ClearAllButton(
            enabled: canClear,
            borderColor: _clearAllBorder,
            onPressed: onClearAll,
          ),
        ),
      ],
    );
  }
}

class _ClearAllButton extends StatelessWidget {
  const _ClearAllButton({
    required this.enabled,
    required this.borderColor,
    required this.onPressed,
  });

  final bool enabled;
  final Color borderColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor, width: 1),
            ),
            child: Text(
              'Clear All',
              style: GoogleFonts.montserrat(
                color: AppColors.onGradientBody,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                height: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final String title;
  final String message;
  final String? timeLabel;
  final bool isUnread;
  final String? actionLabel;
  final Color borderColor;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  const _NotificationCard({
    required this.title,
    required this.message,
    required this.borderColor,
    this.timeLabel,
    this.isUnread = false,
    this.actionLabel,
    this.onTap,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: borderColor.withValues(alpha: isUnread ? 0.95 : 0.55),
                  width: isUnread ? 1.2 : 1,
                ),
              ),
              padding: const EdgeInsets.fromLTRB(16, 16, 28, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight:
                          isUnread ? FontWeight.w600 : FontWeight.w500,
                      color: Colors.white,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    style: GoogleFonts.montserrat(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: AppColors.onGradientBody,
                      height: 1.4,
                    ),
                  ),
                  if (timeLabel != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      timeLabel!,
                      style: GoogleFonts.montserrat(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: AppColors.onGradientMuted,
                      ),
                    ),
                  ],
                  if (actionLabel != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      actionLabel!,
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        if (onDismiss != null)
          Positioned(
            top: -8,
            right: -6,
            child: _DismissButton(onPressed: onDismiss!),
          ),
      ],
    );
  }
}

class _DismissButton extends StatelessWidget {
  const _DismissButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF7FD4E0).withValues(alpha: 0.85),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.55),
              width: 0.8,
            ),
          ),
          child: const Icon(
            Icons.close_rounded,
            size: 14,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
