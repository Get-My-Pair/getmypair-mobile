import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/chevron_screen_back_button.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_state.dart';
import '../utils/profile_notifications.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

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
            final profile = state is ProfileLoaded
                ? state.profile
                : state is ProfileUpdating
                    ? state.profile
                    : state is ProfileImageUploading
                        ? state.profile
                        : state is AddressActionLoading
                            ? state.profile
                            : state is ProfileError
                                ? state.profile
                                : null;
            final items = buildProfileNotifications(profile);
            if (items.isEmpty) {
              return const Center(
                child: Text(
                  'No notifications',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = items[index];
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.message,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
