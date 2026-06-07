import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bio_g/models/user_profile.dart';

class ProfileRepository {
  ProfileRepository(this._client);

  final SupabaseClient _client;

  static const String _avatarBucket = 'avatars';

  /// How long signed avatar URLs stay valid (7 days). Refreshed every
  /// time the profile is loaded, so this only needs to outlive a session.
  static const int _avatarSignedUrlTtlSeconds = 60 * 60 * 24 * 7;

  String? get currentUserId => _client.auth.currentUser?.id;
  User? get _currentUser => _client.auth.currentUser;

  Future<UserProfile?> getMyProfile() async {
    final user = _currentUser;
    if (user == null) return null;

    final data = await _client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (data == null) {
      return _fallbackProfileFromAuthUser(user);
    }

    final profile = UserProfile.fromMap(data);
    return _withResolvedAvatarUrl(profile);
  }

  /// `profiles.avatar_url` stores the Storage object *path*
  /// (e.g. `{userId}/avatar.jpg`), not a public URL — the bucket is
  /// private. Resolve it to a short-lived signed URL the UI can render.
  /// If it already looks like an absolute URL (legacy / external) it is
  /// returned untouched.
  Future<UserProfile> _withResolvedAvatarUrl(UserProfile profile) async {
    final raw = profile.avatarUrl?.trim();
    if (raw == null || raw.isEmpty) return profile;
    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      return profile;
    }

    try {
      final signed = await _client.storage
          .from(_avatarBucket)
          .createSignedUrl(raw, _avatarSignedUrlTtlSeconds);
      return profile.copyWith(avatarUrl: signed);
    } catch (_) {
      // Storage unreachable / object missing — let the UI fall back to
      // its local cached avatar.
      return profile;
    }
  }

  /// Update the editable profile fields and persist them to Supabase.
  /// Only non-null arguments are written, so callers can patch a single
  /// field without clobbering the rest. Offline-first: the caller is
  /// expected to have already written the local cache; this is the
  /// durable mirror.
  Future<void> updateProfile({
    String? phone,
    String? location,
    String? avatarStoragePath,
    String? preferredLanguage,
    String? preferredUnits,
  }) async {
    final user = _currentUser;
    if (user == null) {
      throw StateError('No authenticated user.');
    }

    await _client.from('profiles').upsert({
      'id': user.id,
      'email': user.email,
      if (phone != null) 'phone': _emptyToNull(phone),
      if (location != null) 'location': _emptyToNull(location),
      if (avatarStoragePath != null)
        'avatar_url': _emptyToNull(avatarStoragePath),
      if (preferredLanguage != null) 'preferred_language': preferredLanguage,
      if (preferredUnits != null) 'preferred_units': preferredUnits,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'id');
  }

  /// Upload avatar bytes to the private `avatars` bucket under
  /// `{userId}/avatar.jpg` and return the storage object path to persist
  /// in `profiles.avatar_url`. Returns null if there is no session.
  Future<String?> uploadAvatar(Uint8List bytes, {String? contentType}) async {
    final user = _currentUser;
    if (user == null) return null;

    final objectPath = '${user.id}/avatar.jpg';
    await _client.storage.from(_avatarBucket).uploadBinary(
          objectPath,
          bytes,
          fileOptions: FileOptions(
            upsert: true,
            contentType: contentType ?? 'image/jpeg',
          ),
        );
    return objectPath;
  }

  /// Download the current user's avatar bytes straight from Storage.
  /// Used by the UI to re-materialise a local cache file after a reinstall
  /// (the avatar lives at the deterministic `{userId}/avatar.jpg`). Returns
  /// null when there is no session or no stored avatar.
  Future<Uint8List?> downloadAvatar() async {
    final user = _currentUser;
    if (user == null) return null;
    try {
      return await _client.storage
          .from(_avatarBucket)
          .download('${user.id}/avatar.jpg');
    } catch (_) {
      return null;
    }
  }

  /// Sign an arbitrary avatar storage path (used by the UI to refresh a
  /// renderable URL on demand). Returns null on failure.
  Future<String?> signedAvatarUrl(String storagePath) async {
    final trimmed = storagePath.trim();
    if (trimmed.isEmpty) return null;
    try {
      return await _client.storage
          .from(_avatarBucket)
          .createSignedUrl(trimmed, _avatarSignedUrlTtlSeconds);
    } catch (_) {
      return null;
    }
  }

  String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Future<void> ensureMyProfileExists({String? fullName}) async {
    final user = _currentUser;
    if (user == null) {
      throw StateError('No authenticated user.');
    }

    final String? resolvedFullName =
        _sanitizeNonEmpty(fullName) ??
        _sanitizeNonEmpty(user.userMetadata?['full_name']?.toString());

    await _client.from('profiles').upsert({
      'id': user.id,
      'email': user.email,
      if (resolvedFullName != null) 'full_name': resolvedFullName,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'id');
  }

  Future<void> markOnboardingCompleted() async {
    final user = _currentUser;
    if (user == null) {
      throw StateError('No authenticated user.');
    }

    final String? resolvedFullName = _sanitizeNonEmpty(
      user.userMetadata?['full_name']?.toString(),
    );

    await _client.from('profiles').upsert({
      'id': user.id,
      'email': user.email,
      if (resolvedFullName != null) 'full_name': resolvedFullName,
      'onboarding_completed': true,
      'onboarding_completed_at': DateTime.now().toUtc().toIso8601String(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'id');
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  UserProfile _fallbackProfileFromAuthUser(User user) {
    return UserProfile(
      id: user.id,
      email: user.email,
      fullName: _sanitizeNonEmpty(user.userMetadata?['full_name']?.toString()),
      phone: null,
      avatarUrl: null,
      location: null,
      preferredLanguage: 'es',
      preferredUnits: 'metric',
      subscriptionStatus: 'trial',
      onboardingCompleted: false,
      onboardingCompletedAt: null,
      createdAt: _parseDate(user.createdAt),
      updatedAt: null,
    );
  }

  String? _sanitizeNonEmpty(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}
