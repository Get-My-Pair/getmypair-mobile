import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/address_model.dart';
import '../models/user_profile_model.dart';

abstract class ProfileRemoteDataSource {
  Future<UserProfileModel> getProfile(String accessToken);
  Future<UserProfileModel> updateProfile({
    required String accessToken,
    String? name,
    String? email,
  });
  Future<String> uploadProfileImage({
    required String accessToken,
    required Uint8List imageBytes,
    required String fileName,
  });
  Future<AddressModel> addAddress({
    required String accessToken,
    required String addressLine1,
    required String city,
    required String state,
    required String pincode,
  });
  Future<AddressModel> updateAddress({
    required String accessToken,
    required String addressId,
    String? addressLine1,
    String? city,
    String? state,
    String? pincode,
  });
  Future<void> deleteAddress({
    required String accessToken,
    required String addressId,
  });
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  static const Duration _timeout = Duration(seconds: 30);

  Map<String, String> _headers(String accessToken) => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $accessToken',
      };

  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.body.isEmpty) {
      throw ServerException('Empty response from server');
    }
    try {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return json;
      }
      throw ServerException(json['message'] ?? 'Server error: ${response.statusCode}');
    } on FormatException {
      throw ServerException('Invalid response from server');
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Unexpected error: $e');
    }
  }

  @override
  Future<UserProfileModel> getProfile(String accessToken) async {
    try {
      final response = await http
          .get(Uri.parse(ApiEndpoints.userProfileMe),
              headers: _headers(accessToken))
          .timeout(_timeout);
      final json = _handleResponse(response);
      return UserProfileModel.fromJson(json['data']['profile'] as Map<String, dynamic>);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Failed to get profile: $e');
    }
  }

  @override
  Future<UserProfileModel> updateProfile({
    required String accessToken,
    String? name,
    String? email,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (email != null) body['email'] = email;

      final response = await http
          .put(Uri.parse(ApiEndpoints.userProfileUpdate),
              headers: _headers(accessToken),
              body: jsonEncode(body))
          .timeout(_timeout);
      final json = _handleResponse(response);
      return UserProfileModel.fromJson(json['data']['profile'] as Map<String, dynamic>);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Failed to update profile: $e');
    }
  }

  @override
  Future<String> uploadProfileImage({
    required String accessToken,
    required Uint8List imageBytes,
    required String fileName,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiEndpoints.userProfileUploadImage),
      );
      request.headers['Authorization'] = 'Bearer $accessToken';
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        imageBytes,
        filename: fileName,
      ));
      final streamedResponse = await request.send().timeout(_timeout);
      final response = await http.Response.fromStream(streamedResponse);
      final json = _handleResponse(response);
      return json['data']['profileImage'] as String;
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Failed to upload image: $e');
    }
  }

  @override
  Future<AddressModel> addAddress({
    required String accessToken,
    required String addressLine1,
    required String city,
    required String state,
    required String pincode,
  }) async {
    try {
      final response = await http
          .post(Uri.parse(ApiEndpoints.userProfileAddAddress),
              headers: _headers(accessToken),
              body: jsonEncode({
                'addressLine1': addressLine1,
                'city': city,
                'state': state,
                'pincode': pincode,
              }))
          .timeout(_timeout);
      final json = _handleResponse(response);
      return AddressModel.fromJson(json['data']['address'] as Map<String, dynamic>);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Failed to add address: $e');
    }
  }

  @override
  Future<AddressModel> updateAddress({
    required String accessToken,
    required String addressId,
    String? addressLine1,
    String? city,
    String? state,
    String? pincode,
  }) async {
    try {
      final body = <String, dynamic>{'addressId': addressId};
      if (addressLine1 != null) body['addressLine1'] = addressLine1;
      if (city != null) body['city'] = city;
      if (state != null) body['state'] = state;
      if (pincode != null) body['pincode'] = pincode;

      final response = await http
          .put(Uri.parse(ApiEndpoints.userProfileUpdateAddress),
              headers: _headers(accessToken),
              body: jsonEncode(body))
          .timeout(_timeout);
      final json = _handleResponse(response);
      return AddressModel.fromJson(json['data']['address'] as Map<String, dynamic>);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Failed to update address: $e');
    }
  }

  @override
  Future<void> deleteAddress({
    required String accessToken,
    required String addressId,
  }) async {
    try {
      final response = await http
          .delete(
              Uri.parse(ApiEndpoints.userProfileDeleteAddress(addressId)),
              headers: _headers(accessToken))
          .timeout(_timeout);
      _handleResponse(response);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Failed to delete address: $e');
    }
  }
}
