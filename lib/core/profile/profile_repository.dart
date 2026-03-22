import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bio_g/models/user_profile.dart';

class ProfileRepository {
  ProfileRepository(this._client);

  final SupabaseClient _client;

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

    return UserProfile.fromMap(data);
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
