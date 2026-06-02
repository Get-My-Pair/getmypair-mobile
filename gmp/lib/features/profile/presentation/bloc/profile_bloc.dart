import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/address.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/usecases/get_user_profile.dart';
import '../../domain/usecases/update_user_profile.dart';
import '../../domain/usecases/upload_profile_image.dart';
import '../../domain/usecases/address_usecases.dart';
import 'profile_event.dart';
import 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final GetUserProfile getUserProfile;
  final UpdateUserProfile updateUserProfile;
  final UploadProfileImage uploadProfileImage;
  final AddAddress addAddress;
  final UpdateAddress updateAddress;
  final DeleteAddress deleteAddress;
  final AddFamilyMember addFamilyMember;
  final UpdateFamilyMember updateFamilyMember;

  ProfileBloc({
    required this.getUserProfile,
    required this.updateUserProfile,
    required this.uploadProfileImage,
    required this.addAddress,
    required this.updateAddress,
    required this.deleteAddress,
    required this.addFamilyMember,
    required this.updateFamilyMember,
  }) : super(ProfileInitial()) {
    on<ProfileLoadRequested>(_onLoad);
    on<ProfileUpdateRequested>(_onUpdate);
    on<ProfileImageUploadRequested>(_onImageUpload);
    on<AddressAddRequested>(_onAddAddress);
    on<AddressUpdateRequested>(_onUpdateAddress);
    on<AddressDeleteRequested>(_onDeleteAddress);
    on<FamilyMemberAddRequested>(_onAddFamilyMember);
    on<FamilyMemberUpdateRequested>(_onUpdateFamilyMember);
  }

  UserProfile? _currentProfile() {
    final s = state;
    if (s is ProfileLoaded) return s.profile;
    if (s is ProfileUpdating) return s.profile;
    if (s is ProfileImageUploading) return s.profile;
    if (s is AddressActionLoading) return s.profile;
    if (s is ProfileError) return s.profile;
    return null;
  }

  Future<void> _onLoad(
      ProfileLoadRequested event, Emitter<ProfileState> emit) async {
    emit(ProfileLoading());
    try {
      final profile = await getUserProfile(event.accessToken);
      emit(ProfileLoaded(profile));
    } on ServerException catch (e) {
      emit(ProfileError(e.message, statusCode: e.statusCode));
    } catch (e) {
      emit(ProfileError('Failed to load profile: $e'));
    }
  }

  Future<void> _onUpdate(
      ProfileUpdateRequested event, Emitter<ProfileState> emit) async {
    final current = _currentProfile();
    if (current != null) emit(ProfileUpdating(current));
    try {
      final profile = await updateUserProfile(
        accessToken: event.accessToken,
        name: event.name,
        email: event.email,
        householdType: event.householdType,
      );
      emit(ProfileLoaded(profile));
    } on ServerException catch (e) {
      emit(ProfileError(e.message, profile: current));
    } catch (e) {
      emit(ProfileError('Failed to update profile: $e', profile: current));
    }
  }

  Future<void> _onImageUpload(
      ProfileImageUploadRequested event, Emitter<ProfileState> emit) async {
    final current = _currentProfile();
    if (current != null) emit(ProfileImageUploading(current));
    try {
      final imageUrl = await uploadProfileImage(
        accessToken: event.accessToken,
        imageBytes: event.imageBytes,
        fileName: event.fileName,
      );
      final updated = current?.copyWith(profileImage: imageUrl);
      if (updated != null) {
        emit(ProfileLoaded(updated));
      } else {
        // Reload profile from server
        final profile = await getUserProfile(event.accessToken);
        emit(ProfileLoaded(profile));
      }
    } on ServerException catch (e) {
      emit(ProfileError(e.message, profile: current));
    } catch (e) {
      emit(ProfileError('Failed to upload image: $e', profile: current));
    }
  }

  Future<void> _onAddAddress(
      AddressAddRequested event, Emitter<ProfileState> emit) async {
    final current = _currentProfile();
    if (current != null) emit(AddressActionLoading(current));
    try {
      final address = await addAddress(
        accessToken: event.accessToken,
        addressLine1: event.addressLine1,
        city: event.city,
        state: event.state,
        pincode: event.pincode,
      );
      final updatedAddresses = List<Address>.from(current?.addresses ?? [])
        ..add(address);
      final updated = current?.copyWith(addresses: updatedAddresses);
      emit(ProfileLoaded(updated ?? (await getUserProfile(event.accessToken))));
    } on ServerException catch (e) {
      emit(ProfileError(e.message, profile: current));
    } catch (e) {
      emit(ProfileError('Failed to add address: $e', profile: current));
    }
  }

  Future<void> _onUpdateAddress(
      AddressUpdateRequested event, Emitter<ProfileState> emit) async {
    final current = _currentProfile();
    if (current != null) emit(AddressActionLoading(current));
    try {
      final updatedAddr = await updateAddress(
        accessToken: event.accessToken,
        addressId: event.addressId,
        addressLine1: event.addressLine1,
        city: event.city,
        state: event.state,
        pincode: event.pincode,
      );
      final updatedAddresses = (current?.addresses ?? [])
          .map((a) => a.id == event.addressId ? updatedAddr : a)
          .toList();
      final updated = current?.copyWith(addresses: updatedAddresses);
      emit(ProfileLoaded(updated ?? (await getUserProfile(event.accessToken))));
    } on ServerException catch (e) {
      emit(ProfileError(e.message, profile: current));
    } catch (e) {
      emit(ProfileError('Failed to update address: $e', profile: current));
    }
  }

  Future<void> _onDeleteAddress(
      AddressDeleteRequested event, Emitter<ProfileState> emit) async {
    final current = _currentProfile();
    if (current != null) emit(AddressActionLoading(current));
    try {
      await deleteAddress(
        accessToken: event.accessToken,
        addressId: event.addressId,
      );
      final updatedAddresses = (current?.addresses ?? [])
          .where((a) => a.id != event.addressId)
          .toList();
      final updated = current?.copyWith(addresses: updatedAddresses);
      emit(ProfileLoaded(updated ?? (await getUserProfile(event.accessToken))));
    } on ServerException catch (e) {
      emit(ProfileError(e.message, profile: current));
    } catch (e) {
      emit(ProfileError('Failed to delete address: $e', profile: current));
    }
  }

  Future<void> _onAddFamilyMember(
      FamilyMemberAddRequested event, Emitter<ProfileState> emit) async {
    final current = _currentProfile();
    if (current != null) emit(AddressActionLoading(current));
    try {
      final member = await addFamilyMember(
        accessToken: event.accessToken,
        name: event.name,
        relation: event.relation,
      );
      final updatedMembers = List<FamilyMember>.from(current?.familyMembers ?? [])
        ..add(member);
      final updated = current?.copyWith(familyMembers: updatedMembers);
      emit(ProfileLoaded(updated ?? (await getUserProfile(event.accessToken))));
    } on ServerException catch (e) {
      emit(ProfileError(e.message, profile: current));
    } catch (e) {
      emit(ProfileError('Failed to add family member: $e', profile: current));
    }
  }

  Future<void> _onUpdateFamilyMember(
      FamilyMemberUpdateRequested event, Emitter<ProfileState> emit) async {
    final current = _currentProfile();
    if (current != null) emit(AddressActionLoading(current));
    try {
      final updatedMember = await updateFamilyMember(
        accessToken: event.accessToken,
        memberId: event.memberId,
        name: event.name,
        relation: event.relation,
      );
      final updatedMembers = (current?.familyMembers ?? [])
          .map((m) => m.id == event.memberId ? updatedMember : m)
          .toList();
      final updated = current?.copyWith(familyMembers: updatedMembers);
      emit(ProfileLoaded(updated ?? (await getUserProfile(event.accessToken))));
    } on ServerException catch (e) {
      emit(ProfileError(e.message, profile: current));
    } catch (e) {
      emit(ProfileError('Failed to update family member: $e', profile: current));
    }
  }
}
