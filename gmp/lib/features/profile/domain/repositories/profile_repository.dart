import 'dart:typed_data';
import '../entities/user_profile.dart';
import '../entities/address.dart';

abstract class ProfileRepository {
  /// GET /api/user/profile/me
  Future<UserProfile> getProfile(String accessToken);

  /// PUT /api/user/profile/update
  Future<UserProfile> updateProfile({
    required String accessToken,
    String? name,
    String? email,
    String? householdType,
  });

  /// POST /api/user/profile/upload-image (multipart)
  Future<String> uploadProfileImage({
    required String accessToken,
    required Uint8List imageBytes,
    required String fileName,
  });

  /// POST /api/user/profile/address/add
  Future<Address> addAddress({
    required String accessToken,
    required String addressLine1,
    required String city,
    required String state,
    required String pincode,
  });

  /// PUT /api/user/profile/address/update
  Future<Address> updateAddress({
    required String accessToken,
    required String addressId,
    String? addressLine1,
    String? city,
    String? state,
    String? pincode,
  });

  /// DELETE /api/user/profile/address/delete/:addressId
  Future<void> deleteAddress({
    required String accessToken,
    required String addressId,
  });

  Future<FamilyMember> addFamilyMember({
    required String accessToken,
    required String name,
    required String relation,
  });

  Future<FamilyMember> updateFamilyMember({
    required String accessToken,
    required String memberId,
    String? name,
    String? relation,
  });

  Future<void> deleteFamilyMember({
    required String accessToken,
    required String memberId,
  });
}
