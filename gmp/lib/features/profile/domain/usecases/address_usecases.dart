import '../entities/address.dart';
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
