/// User roles in the application
enum UserRole {
  customer('customer', 'Customer'),
  cobbler('cobbler', 'Cobbler'),
  delivery('delivery', 'Delivery Partner'),
  admin('admin', 'Admin');

  final String value;
  final String displayName;

  const UserRole(this.value, this.displayName);

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (role) => role.value == value.toLowerCase(),
      orElse: () => UserRole.customer,
    );
  }
}

/// Gender enum
enum Gender {
  male('male', 'Male'),
  female('female', 'Female'),
  other('other', 'Other'),
  preferNotToSay('prefer_not_to_say', 'Prefer not to say');

  final String value;
  final String displayName;

  const Gender(this.value, this.displayName);

  static Gender? fromString(String? value) {
    if (value == null) return null;
    return Gender.values.firstWhere(
      (g) => g.value == value.toLowerCase(),
      orElse: () => Gender.preferNotToSay,
    );
  }
}

/// Vehicle types for delivery partners
enum VehicleType {
  bicycle('bicycle', 'Bicycle', '🚲'),
  bike('bike', 'Motorcycle/Scooter', '🏍️'),
  car('car', 'Car', '🚗'),
  van('van', 'Van/Tempo', '🚐');

  final String value;
  final String displayName;
  final String emoji;

  const VehicleType(this.value, this.displayName, this.emoji);

  static VehicleType fromString(String value) {
    return VehicleType.values.firstWhere(
      (v) => v.value == value.toLowerCase(),
      orElse: () => VehicleType.bike,
    );
  }
}

/// Cobbler skills
enum CobblerSkill {
  polishing('polishing', 'Shoe Polishing', '✨'),
  stitching('stitching', 'Stitching & Sewing', '🪡'),
  soleing('soleing', 'Sole Replacement', '👟'),
  heelRepair('heel_repair', 'Heel Repair', '👠'),
  cleaning('cleaning', 'Deep Cleaning', '🧽'),
  dyeing('dyeing', 'Color/Dyeing', '🎨'),
  stretching('stretching', 'Stretching', '↔️'),
  waterproofing('waterproofing', 'Waterproofing', '💧'),
  zipper('zipper', 'Zipper Repair', '🔗'),
  laceReplacement('lace_replacement', 'Lace Replacement', '🎀');

  final String value;
  final String displayName;
  final String emoji;

  const CobblerSkill(this.value, this.displayName, this.emoji);

  static CobblerSkill fromString(String value) {
    return CobblerSkill.values.firstWhere(
      (s) => s.value == value.toLowerCase(),
      orElse: () => CobblerSkill.polishing,
    );
  }
}
