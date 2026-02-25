import 'package:equatable/equatable.dart';

class Address extends Equatable {
  final String id;
  final String addressLine1;
  final String city;
  final String state;
  final String pincode;

  const Address({
    required this.id,
    required this.addressLine1,
    required this.city,
    required this.state,
    required this.pincode,
  });

  @override
  List<Object?> get props => [id, addressLine1, city, state, pincode];

  Address copyWith({
    String? id,
    String? addressLine1,
    String? city,
    String? state,
    String? pincode,
  }) {
    return Address(
      id: id ?? this.id,
      addressLine1: addressLine1 ?? this.addressLine1,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
    );
  }
}
