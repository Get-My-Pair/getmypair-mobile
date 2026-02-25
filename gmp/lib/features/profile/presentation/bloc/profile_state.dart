import 'package:equatable/equatable.dart';
import '../../domain/entities/user_profile.dart';

abstract class ProfileState extends Equatable {
  const ProfileState();
  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileLoaded extends ProfileState {
  final UserProfile profile;
  const ProfileLoaded(this.profile);
  @override
  List<Object?> get props => [profile];
}

class ProfileUpdating extends ProfileState {
  final UserProfile profile;
  const ProfileUpdating(this.profile);
  @override
  List<Object?> get props => [profile];
}

class ProfileError extends ProfileState {
  final String message;
  final UserProfile? profile; // preserve old profile on error
  const ProfileError(this.message, {this.profile});
  @override
  List<Object?> get props => [message, profile];
}

class ProfileImageUploading extends ProfileState {
  final UserProfile profile;
  const ProfileImageUploading(this.profile);
  @override
  List<Object?> get props => [profile];
}

class AddressActionLoading extends ProfileState {
  final UserProfile profile;
  const AddressActionLoading(this.profile);
  @override
  List<Object?> get props => [profile];
}
