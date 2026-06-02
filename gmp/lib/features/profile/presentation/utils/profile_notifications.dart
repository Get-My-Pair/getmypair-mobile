import '../../domain/entities/user_profile.dart';

class ProfileNotificationItem {
  final String id;
  final String title;
  final String message;

  const ProfileNotificationItem({
    required this.id,
    required this.title,
    required this.message,
  });
}

List<ProfileNotificationItem> buildProfileNotifications(UserProfile? profile) {
  if (profile == null) return const [];

  final hasFamilyHousehold = profile.householdType != 'just_me';
  final hasNoFamilyMembers = profile.familyMembers.isEmpty;

  if (hasFamilyHousehold && hasNoFamilyMembers) {
    return const [
      ProfileNotificationItem(
        id: 'create_family_profile',
        title: 'Create Family Profile',
        message:
            'You selected family setup in onboarding. Please create your family profile now.',
      ),
    ];
  }

  return const [];
}
