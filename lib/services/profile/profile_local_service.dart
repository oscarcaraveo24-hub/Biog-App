import 'package:shared_preferences/shared_preferences.dart';

class ProfileLocalSnapshot {
  final String? avatarPath;
  final bool syncActive;
  final String location;
  final String phone;
  final bool notifications;
  final bool useCelsius;

  const ProfileLocalSnapshot({
    required this.avatarPath,
    required this.syncActive,
    required this.location,
    required this.phone,
    required this.notifications,
    required this.useCelsius,
  });
}

class ProfileLocalService {
  static const String kAvatarPathKey = 'profile_avatar_path';
  static const String kSyncActiveKey = 'profile_sync_active';
  static const String kLocationKey = 'profile_location';
  static const String kPhoneKey = 'profile_phone';
  static const String kNotificationsKey = 'profile_notifications';
  static const String kUseCelsiusKey = 'profile_use_celsius';

  const ProfileLocalService();

  Future<ProfileLocalSnapshot> loadProfile({
    String defaultLocation = '—',
    String defaultPhone = '—',
    bool defaultSyncActive = true,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final rawAvatarPath = prefs.getString(kAvatarPathKey);
    final normalizedAvatarPath = _normalizeNullable(rawAvatarPath);

    return ProfileLocalSnapshot(
      avatarPath: normalizedAvatarPath,
      syncActive: prefs.getBool(kSyncActiveKey) ?? defaultSyncActive,
      location: prefs.getString(kLocationKey) ?? defaultLocation,
      phone: prefs.getString(kPhoneKey) ?? defaultPhone,
      notifications: prefs.getBool(kNotificationsKey) ?? true,
      useCelsius: prefs.getBool(kUseCelsiusKey) ?? true,
    );
  }

  Future<void> saveAvatarPath(String? value) async {
    final prefs = await SharedPreferences.getInstance();
    final normalized = _normalizeNullable(value);

    if (normalized == null) {
      await prefs.remove(kAvatarPathKey);
      return;
    }

    await prefs.setString(kAvatarPathKey, normalized);
  }

  Future<void> saveSyncActive(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kSyncActiveKey, value);
  }

  Future<void> saveLocation(String? value) async {
    final prefs = await SharedPreferences.getInstance();
    final normalized = _normalizeNullable(value);

    if (normalized == null) {
      await prefs.remove(kLocationKey);
      return;
    }

    await prefs.setString(kLocationKey, normalized);
  }

  Future<void> savePhone(String? value) async {
    final prefs = await SharedPreferences.getInstance();
    final normalized = _normalizeNullable(value);

    if (normalized == null) {
      await prefs.remove(kPhoneKey);
      return;
    }

    await prefs.setString(kPhoneKey, normalized);
  }

  Future<void> saveNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kNotificationsKey, value);
  }

  Future<void> saveUseCelsius(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kUseCelsiusKey, value);
  }

  String? _normalizeNullable(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) return null;
    return normalized;
  }
}
