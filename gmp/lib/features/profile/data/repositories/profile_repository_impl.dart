import 'dart:typed_data';
import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/address.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_datasource.dart';
import '../models/address_model.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource remoteDataSource;

  ProfileRepositoryImpl({required this.remoteDataSource});

  @override
  Future<UserProfile> getProfile(String accessToken) async {
    try {
      return await remoteDataSource.getProfile(accessToken);
    } on ServerException catch (e) {
      throw ServerException(e.message);
    }
  }

  @override
  Future<UserProfile> updateProfile({
    required String accessToken,
    String? name,
    String? email,
  }) async {
    try {
      return await remoteDataSource.updateProfile(
        accessToken: accessToken,
        name: name,
        email: email,
      );
    } on ServerException catch (e) {
      throw ServerException(e.message);
    }
  }

  @override
  Future<String> uploadProfileImage({
    required String accessToken,
    required Uint8List imageBytes,
    required String fileName,
  }) async {
    try {
      return await remoteDataSource.uploadProfileImage(
        accessToken: accessToken,
        imageBytes: imageBytes,
        fileName: fileName,
      );
    } on ServerException catch (e) {
      throw ServerException(e.message);
    }
  }

  @override
  Future<Address> addAddress({
    required String accessToken,
    required String addressLine1,
    required String city,
    required String state,
    required String pincode,
  }) async {
    try {
      return await remoteDataSource.addAddress(
        accessToken: accessToken,
        addressLine1: addressLine1,
        city: city,
        state: state,
        pincode: pincode,
      );
    } on ServerException catch (e) {
      throw ServerException(e.message);
    }
  }

  @override
  Future<Address> updateAddress({
    required String accessToken,
    required String addressId,
    String? addressLine1,
    String? city,
    String? state,
    String? pincode,
  }) async {
    try {
      return await remoteDataSource.updateAddress(
        accessToken: accessToken,
        addressId: addressId,
        addressLine1: addressLine1,
        city: city,
        state: state,
        pincode: pincode,
      );
    } on ServerException catch (e) {
      throw ServerException(e.message);
    }
  }

  @override
  Future<void> deleteAddress({
    required String accessToken,
    required String addressId,
  }) async {
    try {
      await remoteDataSource.deleteAddress(
        accessToken: accessToken,
        addressId: addressId,
      );
    } on ServerException catch (e) {
      throw ServerException(e.message);
    }
  }
}
