import 'package:equatable/equatable.dart';
import 'address.dart';

class FamilyMember extends Equatable {
  final String id;
  final String name;
  final String relation;
  final String? profileImage;

  const FamilyMember({
    required this.id,
    required this.name,
    required this.relation,
    this.profileImage,
  });

  @override
  List<Object?> get props => [id, name, relation, profileImage];
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
    required this.createdAt,
    required this.updatedAt,
  });

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
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
