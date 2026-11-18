import 'package:equatable/equatable.dart';
import 'address.dart';

const kSelfProfileId = 'self';

class FamilyMember extends Equatable {
  final String id;
  final String name;
  final String relation;
  final String? gender;
  final DateTime? dateOfBirth;
  final String? profileImage;

  const FamilyMember({
    required this.id,
    required this.name,
    required this.relation,
    this.gender,
    this.dateOfBirth,
    this.profileImage,
  });

  FamilyMember copyWith({
    String? id,
    String? name,
    String? relation,
    String? gender,
    DateTime? dateOfBirth,
    String? profileImage,
  }) {
    return FamilyMember(
      id: id ?? this.id,
      name: name ?? this.name,
      relation: relation ?? this.relation,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      profileImage: profileImage ?? this.profileImage,
    );
  }

  @override
  List<Object?> get props =>
      [id, name, relation, gender, dateOfBirth, profileImage];
}

class SwitchableAppProfile extends Equatable {
  final String id;
  final String name;
  final String? imageUrl;
  final String label;
  final bool isSelf;

  const SwitchableAppProfile({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.label,
    required this.isSelf,
  });

  @override
  List<Object?> get props => [id, name, imageUrl, label, isSelf];
}

String familyRelationLabel(String relation) {
  switch (relation) {
    case 'partner':
      return 'My Partner';
    case 'child':
      return 'My Kids';
    case 'elder':
      return 'Elderly';
    default:
      return relation;
  }
}

List<SwitchableAppProfile> switchableProfilesOf(UserProfile profile) {
  return [
    SwitchableAppProfile(
      id: kSelfProfileId,
      name: profile.name,
      imageUrl: profile.profileImage,
      label: 'My Profile',
      isSelf: true,
    ),
    ...profile.familyMembers.map(
      (m) => SwitchableAppProfile(
        id: m.id,
        name: m.name,
        imageUrl: m.profileImage,
        label: familyRelationLabel(m.relation),
        isSelf: false,
      ),
    ),
  ];
}

class UserProfile extends Equatable {
  final String id;
  final String userId;
  final String name;
  final String phone;
  final String? email;
  final String? profileImage;
  final List<Address> addresses;
  final String householdType;
  final List<FamilyMember> familyMembers;
  final String activeProfileId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserProfile({
    required this.id,
    required this.userId,
    required this.name,
    required this.phone,
    this.email,
    this.profileImage,
    required this.addresses,
    this.householdType = 'just_me',
    this.familyMembers = const [],
    this.activeProfileId = kSelfProfileId,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isSelfActive =>
      activeProfileId.isEmpty || activeProfileId == kSelfProfileId;

  FamilyMember? get activeFamilyMember {
    if (isSelfActive) return null;
    for (final member in familyMembers) {
      if (member.id == activeProfileId) return member;
    }
    return null;
  }

  String get activeDisplayName {
    return activeFamilyMember?.name ?? name;
  }

  String? get activeProfileImage {
    final member = activeFamilyMember;
    if (member != null) {
      final url = member.profileImage?.trim();
      if (url != null && url.isNotEmpty) return url;
      return null;
    }
    return profileImage;
  }

  String get activeSubtitle {
    final member = activeFamilyMember;
    if (member != null) return familyRelationLabel(member.relation);
    final e = email?.trim();
    if (e != null && e.isNotEmpty) return e;
    return phone;
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        name,
        phone,
        email,
        profileImage,
        addresses,
        householdType,
        familyMembers,
        activeProfileId,
        createdAt,
        updatedAt,
      ];

  UserProfile copyWith({
    String? id,
    String? userId,
    String? name,
    String? phone,
    String? email,
    String? profileImage,
    List<Address>? addresses,
    String? householdType,
    List<FamilyMember>? familyMembers,
    String? activeProfileId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      profileImage: profileImage ?? this.profileImage,
      addresses: addresses ?? this.addresses,
      householdType: householdType ?? this.householdType,
      familyMembers: familyMembers ?? this.familyMembers,
      activeProfileId: activeProfileId ?? this.activeProfileId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
