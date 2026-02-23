import '../../domain/entities/user_profile.dart';
import 'address_model.dart';

class UserProfileModel extends UserProfile {
  const UserProfileModel({
    required super.id,
    required super.userId,
    required super.name,
    required super.phone,
    super.email,
    super.profileImage,
    required super.addresses,
    required super.createdAt,
    required super.updatedAt,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    final addressList = (json['addresses'] as List<dynamic>? ?? [])
        .map((a) => AddressModel.fromJson(a as Map<String, dynamic>))
        .toList();

    return UserProfileModel(
      id: json['_id'] ?? json['id'] ?? '',
      userId: json['userId'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'],
      profileImage: json['profileImage'],
      addresses: addressList,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'userId': userId,
      'name': name,
      'phone': phone,
      'email': email,
      'profileImage': profileImage,
      'addresses': addresses
          .map((a) => AddressModel(
                id: a.id,
                addressLine1: a.addressLine1,
                city: a.city,
                state: a.state,
                pincode: a.pincode,
              ).toJson())
          .toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
