import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/active_profile_header.dart';
import '../../domain/entities/user_profile.dart';

/// Keeps the selected family/self profile across page opens and API reloads.
class ActiveProfileStore {
  ActiveProfileStore._();

  static const _prefix = 'active_app_profile_id_';
  static SharedPreferences? _prefs;

  static String _key(String userId) => '$_prefix$userId';

  static Future<void> ensureReady() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  static Future<void> save(
    String userId,
    String profileId, {
    String? profileDocId,
  }) async {
    final normalized = profileId.trim().isEmpty ? kSelfProfileId : profileId.trim();
    ActiveProfileHeader.currentId = normalized;
    await ensureReady();
    final id = userId.trim();
    if (id.isNotEmpty) {
      await _prefs!.setString(_key(id), normalized);
    }
    final docId = profileDocId?.trim() ?? '';
    if (docId.isNotEmpty && docId != id) {
      await _prefs!.setString(_key(docId), normalized);
    }
  }

  static String? read(String userId) {
    final id = userId.trim();
    if (id.isEmpty) return null;
    return _prefs?.getString(_key(id));
  }

  static UserProfile apply(UserProfile profile) {
    final stored = read(profile.userId) ?? read(profile.id);
    if (stored == null || stored.trim().isEmpty) {
      ActiveProfileHeader.currentId =
          profile.isSelfActive ? kSelfProfileId : profile.activeProfileId;
      return profile;
    }
    if (stored == kSelfProfileId) {
      ActiveProfileHeader.currentId = kSelfProfileId;
      return profile.copyWith(activeProfileId: kSelfProfileId);
    }
    final exists = profile.familyMembers.any((m) => m.id == stored);
    if (!exists) {
      ActiveProfileHeader.currentId = kSelfProfileId;
      return profile.copyWith(activeProfileId: kSelfProfileId);
    }
    ActiveProfileHeader.currentId = stored;
    return profile.copyWith(activeProfileId: stored);
  }

  static UserProfile forceActive(UserProfile profile, String profileId) {
    final wanted = profileId.trim().isEmpty ? kSelfProfileId : profileId.trim();
    if (wanted == kSelfProfileId) {
      ActiveProfileHeader.currentId = kSelfProfileId;
      return profile.copyWith(activeProfileId: kSelfProfileId);
    }
    final exists = profile.familyMembers.any((m) => m.id == wanted);
    if (!exists) {
      return apply(profile);
    }
    ActiveProfileHeader.currentId = wanted;
    return profile.copyWith(activeProfileId: wanted);
  }
}
