import 'package:equatable/equatable.dart';
import 'dart:typed_data';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();
  @override
  List<Object?> get props => [];
}

class ProfileLoadRequested extends ProfileEvent {
  final String accessToken;
  const ProfileLoadRequested(this.accessToken);
  @override
  List<Object?> get props => [accessToken];
}

class ProfileUpdateRequested extends ProfileEvent {
  final String accessToken;
  final String? name;
  final String? email;
  final String? householdType;
  const ProfileUpdateRequested({
    required this.accessToken,
    this.name,
    this.email,
    this.householdType,
  });
  @override
  List<Object?> get props => [accessToken, name, email, householdType];
}

class ProfileImageUploadRequested extends ProfileEvent {
  final String accessToken;
  final Uint8List imageBytes;
  final String fileName;
  const ProfileImageUploadRequested({
    required this.accessToken,
    required this.imageBytes,
    required this.fileName,
  });
  @override
  List<Object?> get props => [accessToken, fileName];
}

class AddressAddRequested extends ProfileEvent {
  final String accessToken;
  final String addressLine1;
  final String city;
  final String state;
  final String pincode;
  const AddressAddRequested({
    required this.accessToken,
    required this.addressLine1,
    required this.city,
    required this.state,
    required this.pincode,
  });
  @override
  List<Object?> get props => [accessToken, addressLine1, city, state, pincode];
}

class AddressUpdateRequested extends ProfileEvent {
  final String accessToken;
  final String addressId;
  final String? addressLine1;
  final String? city;
  final String? state;
  final String? pincode;
  const AddressUpdateRequested({
    required this.accessToken,
    required this.addressId,
    this.addressLine1,
    this.city,
    this.state,
    this.pincode,
  });
  @override
  List<Object?> get props => [accessToken, addressId];
}

class AddressDeleteRequested extends ProfileEvent {
  final String accessToken;
  final String addressId;
  const AddressDeleteRequested({
    required this.accessToken,
    required this.addressId,
  });
  @override
  List<Object?> get props => [accessToken, addressId];
}

class FamilyMemberAddRequested extends ProfileEvent {
  final String accessToken;
  final String name;
  final String relation;
  const FamilyMemberAddRequested({
    required this.accessToken,
    required this.name,
    required this.relation,
  });
  @override
  List<Object?> get props => [accessToken, name, relation];
}

class FamilyMemberUpdateRequested extends ProfileEvent {
  final String accessToken;
  final String memberId;
  final String name;
  final String relation;
  const FamilyMemberUpdateRequested({
    required this.accessToken,
    required this.memberId,
    required this.name,
    required this.relation,
  });
  @override
  List<Object?> get props => [accessToken, memberId, name, relation];
}
