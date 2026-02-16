import 'package:equatable/equatable.dart';
import '../../domain/entities/user.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final User user;

  const AuthAuthenticated(this.user);

  @override
  List<Object?> get props => [user];
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthOTPSent extends AuthState {
  final String mobile;
  final String? otp; // OTP code (only in development mode)

  const AuthOTPSent(this.mobile, {this.otp});

  @override
  List<Object?> get props => [mobile, otp];
}

class AuthOTPVerified extends AuthState {
  final bool requiresProfileCompletion;
  final String mobile;
  final User? user;

  const AuthOTPVerified({
    required this.requiresProfileCompletion,
    required this.mobile,
    this.user,
  });

  @override
  List<Object?> get props => [requiresProfileCompletion, mobile, user];
}

class AuthProfileCompleted extends AuthState {
  final User user;

  const AuthProfileCompleted(this.user);

  @override
  List<Object?> get props => [user];
}

class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}

