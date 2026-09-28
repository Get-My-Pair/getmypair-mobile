import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/address.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/usecases/get_user_profile.dart';
import '../../domain/usecases/update_user_profile.dart';
import '../../domain/usecases/upload_profile_image.dart';
import '../../domain/usecases/address_usecases.dart';
import '../utils/active_profile_store.dart';
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
  final SwitchActiveProfile switchActiveProfile;
  final UploadFamilyMemberImage uploadFamilyMemberImage;
  final DeleteFamilyMember deleteFamilyMember;

  ProfileBloc({
    required this.getUserProfile,
    required this.updateUserProfile,
    required this.uploadProfileImage,
    required this.addAddress,
    required this.updateAddress,
    required this.deleteAddress,
    required this.addFamilyMember,
    required this.updateFamilyMember,
    required this.switchActiveProfile,
    required this.uploadFamilyMemberImage,
    required this.deleteFamilyMember,
  }) : super(ProfileInitial()) {
    on<ProfileLoadRequested>(_onLoad);
    on<ProfileUpdateRequested>(_onUpdate);
    on<ProfileImageUploadRequested>(_onImageUpload);
    on<AddressAddRequested>(_onAddAddress);
    on<AddressUpdateRequested>(_onUpdateAddress);
    on<AddressDeleteRequested>(_onDeleteAddress);
    on<FamilyMemberAddRequested>(_onAddFamilyMember);
    on<FamilyMemberUpdateRequested>(_onUpdateFamilyMember);
    on<ActiveProfileSwitchRequested>(_onSwitchActiveProfile);
    on<FamilyMemberDeleteRequested>(_onDeleteFamilyMember);
  }

  UserProfile? _currentProfile() {
    final s = state;
    if (s is ProfileLoaded) return s.profile;
    if (s is ProfileUpdating) return s.profile;
    if (s is ProfileImageUploading) return s.profile;
    if (s is AddressActionLoading) return s.profile;
    if (s is ProfileSwitching) return s.profile;
    if (s is ProfileError) return s.profile;
    return null;
  }

  UserProfile _withStoredActive(UserProfile profile) =>
      ActiveProfileStore.apply(profile);

  Future<UserProfile> _reloadProfile(String accessToken) async {
    await ActiveProfileStore.ensureReady();
    return _withStoredActive(await getUserProfile(accessToken));
  }

  Future<void> _rememberActive(UserProfile profile) {
    return ActiveProfileStore.save(
      profile.userId,
      profile.isSelfActive ? kSelfProfileId : profile.activeProfileId,
      profileDocId: profile.id,
    );
  }

  Future<void> _onLoad(
      ProfileLoadRequested event, Emitter<ProfileState> emit) async {
    emit(ProfileLoading());
    try {
      final profile = await _reloadProfile(event.accessToken);
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
      final next = _withStoredActive(profile);
      await _rememberActive(next);
      emit(ProfileLoaded(next));
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
      if (current != null && !current.isSelfActive) {
        final memberId = current.activeProfileId;
        final imageUrl = await uploadFamilyMemberImage(
          accessToken: event.accessToken,
          memberId: memberId,
          imageBytes: event.imageBytes,
          fileName: event.fileName,
        );
        var members = current.familyMembers
            .map((m) => m.id == memberId
                ? m.copyWith(profileImage: imageUrl)
                : m)
            .toList();
        var updated = current.copyWith(familyMembers: members);
        await _rememberActive(updated);
        try {
          updated = ActiveProfileStore.forceActive(
            await _reloadProfile(event.accessToken),
            memberId,
          );
          members = updated.familyMembers
              .map((m) => m.id == memberId &&
                      (m.profileImage == null || m.profileImage!.isEmpty)
                  ? m.copyWith(profileImage: imageUrl)
                  : m)
              .toList();
          updated = updated.copyWith(familyMembers: members);
        } catch (_) {}
        await _rememberActive(updated);
        emit(ProfileLoaded(updated));
        return;
      }

      final imageUrl = await uploadProfileImage(
        accessToken: event.accessToken,
        imageBytes: event.imageBytes,
        fileName: event.fileName,
      );
      final updated = current?.copyWith(profileImage: imageUrl);
      if (updated != null) {
        await _rememberActive(updated);
        emit(ProfileLoaded(updated));
      } else {
        emit(ProfileLoaded(await _reloadProfile(event.accessToken)));
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
      emit(ProfileLoaded(
          updated ?? (await _reloadProfile(event.accessToken))));
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
      emit(ProfileLoaded(
          updated ?? (await _reloadProfile(event.accessToken))));
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
      emit(ProfileLoaded(
          updated ?? (await _reloadProfile(event.accessToken))));
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
        gender: event.gender,
        dateOfBirth: event.dateOfBirth,
      );
      final imageBytes = event.imageBytes;
      final imageFileName = event.imageFileName;
      if (imageBytes != null &&
          imageBytes.isNotEmpty &&
          imageFileName != null &&
          imageFileName.isNotEmpty) {
        try {
          await uploadFamilyMemberImage(
            accessToken: event.accessToken,
            memberId: member.id,
            imageBytes: imageBytes,
            fileName: imageFileName,
          );
        } on ServerException catch (e) {
          // Live API still serves add/update/delete, but not
          // POST /family-members/upload-image yet.
          if (!isUnregisteredRouteMessage(e.message)) rethrow;
        }
      }
      final profile = await _reloadProfile(event.accessToken);
      emit(ProfileLoaded(profile));
    } on ServerException catch (e) {
      emit(ProfileError(userFacingFamilyProfileError(e.message),
          profile: current));
    } catch (e) {
      emit(ProfileError('Failed to add family member: $e', profile: current));
    }
  }

  Future<void> _onUpdateFamilyMember(
      FamilyMemberUpdateRequested event, Emitter<ProfileState> emit) async {
    final current = _currentProfile();
    if (current != null) emit(ProfileUpdating(current));
    try {
      final updatedMember = await updateFamilyMember(
        accessToken: event.accessToken,
        memberId: event.memberId,
        name: event.name,
        relation: event.relation,
      );
      final updatedMembers = (current?.familyMembers ?? [])
          .map((m) {
            if (m.id != event.memberId) return m;
            final image = (updatedMember.profileImage != null &&
                    updatedMember.profileImage!.isNotEmpty)
                ? updatedMember.profileImage
                : m.profileImage;
            return updatedMember.copyWith(profileImage: image);
          })
          .toList();
      var updated = current?.copyWith(familyMembers: updatedMembers);
      if (updated != null) {
        await _rememberActive(updated);
      }
      emit(ProfileLoaded(
          updated ?? (await _reloadProfile(event.accessToken))));
    } on ServerException catch (e) {
      emit(ProfileError(userFacingFamilyProfileError(e.message),
          profile: current));
    } catch (e) {
      emit(ProfileError('Failed to update family member: $e', profile: current));
    }
  }

  Future<void> _onSwitchActiveProfile(
      ActiveProfileSwitchRequested event, Emitter<ProfileState> emit) async {
    final current = _currentProfile();
    if (current == null) {
      emit(const ProfileError('Profile not loaded'));
      return;
    }
    final targetName = _displayNameFor(current, event.profileId);
    emit(ProfileSwitching(
      profile: current,
      targetProfileId: event.profileId,
      targetName: targetName,
    ));
    final pending = ActiveProfileStore.forceActive(current, event.profileId);
    await _rememberActive(pending);
    try {
      await switchActiveProfile(
        accessToken: event.accessToken,
        profileId: event.profileId,
      );
    } on ServerException catch (e) {
      if (!isUnregisteredRouteMessage(e.message) &&
          (e.statusCode == 401 || e.statusCode == 403)) {
        await _rememberActive(current);
        emit(ProfileError(userFacingFamilyProfileError(e.message),
            profile: current));
        return;
      }
    } catch (_) {}
    try {
      final reloaded = ActiveProfileStore.forceActive(
        await _reloadProfile(event.accessToken),
        event.profileId,
      );
      await _rememberActive(reloaded);
      emit(ProfileLoaded(reloaded));
    } catch (_) {
      emit(ProfileLoaded(pending));
    }
  }

  String _displayNameFor(UserProfile profile, String profileId) {
    if (profileId == kSelfProfileId || profileId.isEmpty) {
      return profile.name;
    }
    for (final member in profile.familyMembers) {
      if (member.id == profileId) return member.name;
    }
    return 'profile';
  }

  Future<void> _onDeleteFamilyMember(
      FamilyMemberDeleteRequested event, Emitter<ProfileState> emit) async {
    final current = _currentProfile();
    if (current != null) emit(AddressActionLoading(current));
    try {
      await deleteFamilyMember(
        accessToken: event.accessToken,
        memberId: event.memberId,
      );
      if (current != null && current.activeProfileId == event.memberId) {
        await _rememberActive(
          current.copyWith(activeProfileId: kSelfProfileId),
        );
      }
      emit(ProfileLoaded(await _reloadProfile(event.accessToken)));
    } on ServerException catch (e) {
      emit(ProfileError(userFacingFamilyProfileError(e.message),
          profile: current));
    } catch (e) {
      emit(ProfileError('Failed to delete family member: $e', profile: current));
    }
  }
}
