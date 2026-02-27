class User {
  final String id;
  final String mobile;
  final String name;
  final DateTime dateOfBirth;
  final String gender;
  final String? email;
  final String role;
  final bool isPhoneVerified;
  final bool isActive;
  final DateTime? lastLogin;
  final DateTime createdAt;
  final DateTime updatedAt;

  const User({
    required this.id,
    required this.mobile,
    required this.name,
    required this.dateOfBirth,
    required this.gender,
    this.email,
    required this.role,
    required this.isPhoneVerified,
    required this.isActive,
    this.lastLogin,
    required this.createdAt,
    required this.updatedAt,
  });
}

