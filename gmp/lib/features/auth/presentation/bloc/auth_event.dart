import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthCheckStatus extends AuthEvent {
  const AuthCheckStatus();
}

class AuthSendOTP extends AuthEvent {
  final String mobile;

  const AuthSendOTP(this.mobile);

  @override
  List<Object?> get props => [mobile];
}

class AuthVerifyOTP extends AuthEvent {
  final String mobile;
  final String otp;

  const AuthVerifyOTP({
    required this.mobile,
    required this.otp,
  });

  @override
  List<Object?> get props => [mobile, otp];
}

class AuthLoginWithEmail extends AuthEvent {
  final String email;
  final String password;

  const AuthLoginWithEmail({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [email, password];
}

class AuthCompleteProfile extends AuthEvent {
  final String mobile;
  final String name;
  final DateTime dateOfBirth;
  final String gender;
  final Map<String, dynamic>? location;

  const AuthCompleteProfile({
    required this.mobile,
    required this.name,
    required this.dateOfBirth,
    required this.gender,
    this.location,
  });

  @override
  List<Object?> get props => [mobile, name, dateOfBirth, gender, location];
}

class AuthLogout extends AuthEvent {
  const AuthLogout();
}

/// Session expired (e.g. refresh token failed). Clear local data only and show login; do not call logout API.
class AuthSessionExpired extends AuthEvent {
  const AuthSessionExpired();
}

class AuthClearError extends AuthEvent {
  const AuthClearError();
}

