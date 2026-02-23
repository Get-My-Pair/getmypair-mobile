import '../../domain/entities/address.dart';

class AddressModel extends Address {
  const AddressModel({
    required super.id,
    required super.addressLine1,
    required super.city,
    required super.state,
    required super.pincode,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['_id'] ?? json['id'] ?? '',
      addressLine1: json['addressLine1'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      pincode: json['pincode'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'addressLine1': addressLine1,
      'city': city,
      'state': state,
      'pincode': pincode,
    };
  }
}
