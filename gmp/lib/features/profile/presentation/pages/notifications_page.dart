import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/chevron_screen_back_button.dart';
import '../../domain/entities/user_profile.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_state.dart';
import '../utils/profile_notifications.dart';
import '../utils/notification_navigation_helper.dart';
import '../utils/user_notifications.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  bool _loading = true;
  List<UserNotificationItem> _apiItems = const [];
  String? _error;

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
      _apiItems = result.items;
      _loading = false;
    });
  }

  UserProfile? _profileFromState(ProfileState state) {
    if (state is ProfileLoaded) return state.profile;
    if (state is ProfileUpdating) return state.profile;
    if (state is ProfileImageUploading) return state.profile;
    if (state is AddressActionLoading) return state.profile;
    if (state is ProfileError) return state.profile;
    return null;
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

  String? _formatTime(DateTime? dt) {
    if (dt == null) return null;
    return DateFormat('d MMM yyyy · h:mm a').format(dt.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.footwearHeroStart,
          elevation: 0,
          leadingWidth: 56,
          leading: const Padding(
            padding: EdgeInsets.only(left: 8),
            child: ChevronScreenBackButton(iconColor: Colors.white),
          ),
          title: Text(
            'Notifications',
            style: GoogleFonts.boldonse(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        body: BlocBuilder<ProfileBloc, ProfileState>(
          builder: (context, state) {
            final profile = _profileFromState(state);
            final profileItems = buildProfileNotifications(profile);

            if (_loading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (_error != null) {
              return Center(
                child: Text(
                  _error!,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              );
            }

            if (_apiItems.isEmpty && profileItems.isEmpty) {
              return const Center(
                child: Text(
                  'No notifications',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  ..._apiItems.map((item) {
                    final timeLabel = _formatTime(item.createdAt);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _NotificationCard(
                        title: item.title,
                        message: item.message,
                        timeLabel: timeLabel,
                        isUnread: !item.isRead,
                        actionLabel: item.actionLabel,
                        onTap: () => _onApiNotificationTap(item),
                      ),
                    );
                  }),
                  ...profileItems.map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _NotificationCard(
                        title: item.title,
                        message: item.message,
                      ),
                    );
                  }),
                ],
              ),
            );
          },
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
  final VoidCallback? onTap;

  const _NotificationCard({
    required this.title,
    required this.message,
    this.timeLabel,
    this.isUnread = false,
    this.actionLabel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isUnread ? AppColors.primaryDark : AppColors.border,
              width: isUnread ? 1.5 : 1,
            ),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: isUnread ? FontWeight.w800 : FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  if (isUnread)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryDark,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              if (timeLabel != null) ...[
                const SizedBox(height: 8),
                Text(
                  timeLabel!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              if (actionLabel != null) ...[
                const SizedBox(height: 10),
                Text(
                  actionLabel!,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
