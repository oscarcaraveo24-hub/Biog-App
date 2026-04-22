import 'package:shared_preferences/shared_preferences.dart';

/// Persists the currently active BioG device id per authenticated user.
///
/// This is the local source of truth for the active device selection.
/// It is intentionally tiny and offline-first: writes are local and
/// synchronous from the UI's perspective.
///
/// A value is kept per [userId] so that if another user signs in on the
/// same device, they won't inherit the previous user's selection.
class ActiveDeviceStore {
  static const String _prefix = 'biog_active_device_id_v1_';
  static const String _guestKey = 'biog_active_device_id_v1__guest';

  String _keyFor(String? userId) {
    if (userId == null || userId.isEmpty) return _guestKey;
    return '$_prefix$userId';
  }

  Future<String?> load({String? userId}) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyFor(userId));
    if (raw == null || raw.isEmpty) return null;
    return raw;
  }

  Future<void> save({required String deviceId, String? userId}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyFor(userId), deviceId);
  }

  Future<void> clear({String? userId}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyFor(userId));
  }
}
