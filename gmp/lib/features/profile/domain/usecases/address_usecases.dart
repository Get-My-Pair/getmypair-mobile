import 'dart:typed_data';

import '../entities/address.dart';
import '../entities/user_profile.dart';
import '../repositories/profile_repository.dart';

class AddAddress {
  final ProfileRepository repository;
  AddAddress(this.repository);

  Future<Address> call({
    required String accessToken,
    required String addressLine1,
    required String city,
    required String state,
    required String pincode,
  }) =>
      repository.addAddress(
        accessToken: accessToken,
        addressLine1: addressLine1,
        city: city,
        state: state,
        pincode: pincode,
      );
}

class UpdateAddress {
  final ProfileRepository repository;
  UpdateAddress(this.repository);

  Future<Address> call({
    required String accessToken,
    required String addressId,
    String? addressLine1,
    String? city,
    String? state,
    String? pincode,
  }) =>
      repository.updateAddress(
        accessToken: accessToken,
        addressId: addressId,
        addressLine1: addressLine1,
        city: city,
        state: state,
        pincode: pincode,
      );
}

class DeleteAddress {
  final ProfileRepository repository;
  DeleteAddress(this.repository);

  Future<void> call({
    required String accessToken,
    required String addressId,
  }) =>
      repository.deleteAddress(
        accessToken: accessToken,
        addressId: addressId,
      );
}

class AddFamilyMember {
  final ProfileRepository repository;
  AddFamilyMember(this.repository);

  Future<FamilyMember> call({
    required String accessToken,
    required String name,
    required String relation,
    required String gender,
    required DateTime dateOfBirth,
  }) =>
      repository.addFamilyMember(
        accessToken: accessToken,
        name: name,
        relation: relation,
        gender: gender,
        dateOfBirth: dateOfBirth,
      );
}

class UpdateFamilyMember {
  final ProfileRepository repository;
  UpdateFamilyMember(this.repository);

  Future<FamilyMember> call({
    required String accessToken,
    required String memberId,
    String? name,
    String? relation,
    String? gender,
    DateTime? dateOfBirth,
  }) =>
      repository.updateFamilyMember(
        accessToken: accessToken,
        memberId: memberId,
        name: name,
        relation: relation,
        gender: gender,
        dateOfBirth: dateOfBirth,
      );
}

class DeleteFamilyMember {
  final ProfileRepository repository;
  DeleteFamilyMember(this.repository);

  Future<void> call({
    required String accessToken,
    required String memberId,
  }) =>
      repository.deleteFamilyMember(
        accessToken: accessToken,
        memberId: memberId,
      );
}

class SwitchActiveProfile {
  final ProfileRepository repository;
  SwitchActiveProfile(this.repository);

  Future<UserProfile> call({
    required String accessToken,
    required String profileId,
  }) =>
      repository.switchActiveProfile(
        accessToken: accessToken,
        profileId: profileId,
      );
}

class UploadFamilyMemberImage {
  final ProfileRepository repository;
  UploadFamilyMemberImage(this.repository);

  Future<String> call({
    required String accessToken,
    required String memberId,
    required Uint8List imageBytes,
    required String fileName,
  }) =>
      repository.uploadFamilyMemberImage(
        accessToken: accessToken,
        memberId: memberId,
        imageBytes: imageBytes,
        fileName: fileName,
      );
}
