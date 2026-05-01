import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.mobile,
    required super.name,
    required super.dateOfBirth,
    required super.gender,
    super.email,
    required super.role,
    required super.isPhoneVerified,
    required super.isActive,
    super.lastLogin,
    required super.createdAt,
    required super.updatedAt,
  });

  /// Backend may return `role` as an ObjectId string, or a populated `{ _id, name }`.
  static String _roleFromJson(dynamic role) {
    if (role == null) return 'user';
    if (role is String) {
      final s = role.trim();
      if (s.isEmpty) return 'user';
      return s;
    }
    if (role is Map) {
      final name = role['name'];
      if (name is String && name.isNotEmpty) {
        return name.toLowerCase();
      }
      final id = role['_id'];
      if (id != null) return id.toString();
    }
    return role.toString();
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] ?? json['id'] ?? '',
      mobile: json['mobile'] ?? '',
      name: json['name'] ?? '',
      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.parse(json['dateOfBirth'].toString())
          : DateTime.now(),
      gender: json['gender'] ?? '',
      email: json['email'],
      role: _roleFromJson(json['role']),
      isPhoneVerified: json['isPhoneVerified'] ?? false,
      isActive: json['isActive'] ?? true,
      lastLogin: json['lastLogin'] != null
          ? DateTime.parse(json['lastLogin'])
          : null,
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
      'id': id,
      'mobile': mobile,
      'name': name,
      'dateOfBirth': dateOfBirth.toIso8601String(),
      'gender': gender,
      'email': email,
      'role': role,
      'isPhoneVerified': isPhoneVerified,
      'isActive': isActive,
      'lastLogin': lastLogin?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

