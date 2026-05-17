import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bio_g/models/biog_telemetry.dart';
import 'package:bio_g/services/biog/identity/active_device_store.dart';
import 'package:bio_g/services/biog/identity/device_identity_repository.dart';

/// Supabase-backed implementation of [DeviceIdentityRepository].
///
/// Offline-first semantics:
///   - Every read returns the local cache immediately when possible.
///   - Every write touches the local cache FIRST (synchronously from
///     the UI's perspective), then fires a best-effort remote upsert.
///   - If the remote call fails, the local state remains the source
///     of truth; the next successful bootstrap will re-push it.
///
/// Conflict resolution (last-write-wins by updatedAt):
///   - On [loadDevices], if both local and remote contain the same
///     device, the record with the most recent `updated_at` wins.
///     The winner is written back to the losing side.
class SupabaseDeviceIdentityRepository implements DeviceIdentityRepository {
  SupabaseDeviceIdentityRepository({
    SupabaseClient? client,
    ActiveDeviceStore? activeDeviceStore,
  })  : _client = client ?? Supabase.instance.client,
        _activeDeviceStore = activeDeviceStore ?? ActiveDeviceStore();

  static const String _devicesTable = 'devices';
  static const String _membershipsTable = 'device_memberships';
  static const String _cachePrefix = 'biog_devices_cache_v1_';
  static const String _cacheGuest = 'biog_devices_cache_v1__guest';

  final SupabaseClient _client;
  final ActiveDeviceStore _activeDeviceStore;

  /// In-memory devices list, keyed by userId ("_guest" when unauthenticated).
  final Map<String, List<BioGDevice>> _inMemoryByUser =
      <String, List<BioGDevice>>{};

  /// In-memory active device id.
  String? _cachedActiveDeviceId;

  String _cacheKey(String? userId) {
    if (userId == null || userId.isEmpty) return _cacheGuest;
    return '$_cachePrefix$userId';
  }

  String _userKey(String? userId) => userId ?? '_guest';

  @override
  List<BioGDevice> cachedDevices({String? userId}) {
    final list = _inMemoryByUser[_userKey(userId)];
    if (list == null) return const <BioGDevice>[];
    return List<BioGDevice>.unmodifiable(list);
  }

  @override
  String? cachedActiveDeviceId() => _cachedActiveDeviceId;

  /// Hydrate the in-memory cache from local SharedPreferences. Safe
  /// to call multiple times — subsequent calls are idempotent.
  Future<List<BioGDevice>> loadLocalCache({required String? userId}) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheKey(userId));

    List<BioGDevice> devices = const <BioGDevice>[];
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw) as List<dynamic>;
        devices = decoded
            .map((e) => _fromCacheJson(e as Map<String, dynamic>))
            .whereType<BioGDevice>()
            .toList(growable: false);
      } catch (_) {
        devices = const <BioGDevice>[];
      }
    }

    _inMemoryByUser[_userKey(userId)] = devices;

    _cachedActiveDeviceId = await _activeDeviceStore.load(userId: userId);

    return List<BioGDevice>.unmodifiable(devices);
  }

  @override
  Future<List<BioGDevice>> loadDevices({required String? userId}) async {
    // Make sure the local cache is hydrated before anything else so we
    // always have something to fall back on.
    if (!_inMemoryByUser.containsKey(_userKey(userId))) {
      await loadLocalCache(userId: userId);
    }

    final List<BioGDevice> local =
        List<BioGDevice>.from(_inMemoryByUser[_userKey(userId)] ?? const []);

    if (userId == null || userId.isEmpty) {
      // Unauthenticated: only local cache is available.
      return List<BioGDevice>.unmodifiable(local);
    }

    try {
      // Pull memberships for the current user, then join with the
      // devices table. Using two calls keeps this robust to RLS rules
      // and avoids relying on nested resource embedding.
      final memberships = await _client
          .from(_membershipsTable)
          .select('device_id')
          .eq('user_id', userId);

      final List<String> deviceIds = <String>[];
      for (final row in (memberships as List<dynamic>)) {
        final m = row as Map<String, dynamic>;
        final id = m['device_id'] as String?;
        if (id != null && id.isNotEmpty) deviceIds.add(id);
      }

      List<Map<String, dynamic>> rows = <Map<String, dynamic>>[];
      if (deviceIds.isNotEmpty) {
        final data = await _client
            .from(_devicesTable)
            .select()
            .inFilter('id', deviceIds);
        rows = ((data as List<dynamic>)).cast<Map<String, dynamic>>();
      }

      final List<BioGDevice> remote = rows
          .map(_fromSupabaseRow)
          .whereType<BioGDevice>()
          .toList(growable: false);

      // Last-write-wins merge by updatedAt.
      final List<BioGDevice> merged = _mergeByUpdatedAt(
        local: local,
        remote: remote,
      );

      _inMemoryByUser[_userKey(userId)] = merged;
      await _writeLocalCache(userId, merged);

      // Push back any local-wins or local-only records so remote catches up.
      final Map<String, BioGDevice> remoteById = <String, BioGDevice>{
        for (final d in remote) d.id: d,
      };
      for (final d in merged) {
        final r = remoteById[d.id];
        if (r == null || _moreRecent(d, r)) {
          unawaited(_uploadDevice(userId, d));
        }
      }

      return List<BioGDevice>.unmodifiable(merged);
    } catch (_) {
      // Network / RLS / schema error — stick with local cache.
      return List<BioGDevice>.unmodifiable(local);
    }
  }

  @override
  Future<BioGDevice> upsertDevice({
    required String? userId,
    required BioGDevice device,
  }) async {
    // Stamp the write time so LWW reconciliation on a later boot can
    // tell that this record was the most recent local edit. Without
    // this, the in-memory copy and the on-disk cache would keep the
    // older `updatedAt` (or none at all) and lose future comparisons
    // against a remote row that Supabase automatically stamped.
    final BioGDevice stamped = device.copyWith(
      updatedAt: DateTime.now().toUtc(),
    );

    final key = _userKey(userId);
    final List<BioGDevice> list =
        List<BioGDevice>.from(_inMemoryByUser[key] ?? const <BioGDevice>[]);

    final int idx = list.indexWhere((d) => d.id == stamped.id);
    if (idx >= 0) {
      list[idx] = stamped;
    } else {
      list.add(stamped);
    }

    _inMemoryByUser[key] = list;
    await _writeLocalCache(userId, list);

    if (userId != null && userId.isNotEmpty) {
      unawaited(_uploadDevice(userId, stamped));
    }

    return stamped;
  }

  @override
  Future<void> removeDevice({
    required String? userId,
    required String deviceId,
  }) async {
    final key = _userKey(userId);
    final List<BioGDevice> list =
        List<BioGDevice>.from(_inMemoryByUser[key] ?? const <BioGDevice>[]);
    list.removeWhere((d) => d.id == deviceId);
    _inMemoryByUser[key] = list;
    await _writeLocalCache(userId, list);

    if (_cachedActiveDeviceId == deviceId) {
      _cachedActiveDeviceId = list.isEmpty ? null : list.first.id;
      if (_cachedActiveDeviceId != null) {
        await _activeDeviceStore.save(
          deviceId: _cachedActiveDeviceId!,
          userId: userId,
        );
      } else {
        await _activeDeviceStore.clear(userId: userId);
      }
    }

    if (userId == null || userId.isEmpty) return;

    try {
      await _client
          .from(_membershipsTable)
          .delete()
          .eq('user_id', userId)
          .eq('device_id', deviceId);
    } catch (_) {
      // Best-effort.
    }

    try {
      await _client.from(_devicesTable).delete().eq('id', deviceId);
    } catch (_) {
      // Best-effort; device may still be referenced by other users.
    }
  }

  @override
  Future<void> setActiveDeviceId({
    required String? userId,
    required String deviceId,
  }) async {
    _cachedActiveDeviceId = deviceId;
    await _activeDeviceStore.save(deviceId: deviceId, userId: userId);
  }

  @override
  void clearInMemory() {
    _inMemoryByUser.clear();
    _cachedActiveDeviceId = null;
  }

  // ---------------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------------

  Future<void> _writeLocalCache(
    String? userId,
    List<BioGDevice> devices,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(
      devices.map(_toCacheJson).toList(growable: false),
    );
    await prefs.setString(_cacheKey(userId), encoded);
  }

  Future<void> _uploadDevice(String userId, BioGDevice device) async {
    try {
      await _client.from(_devicesTable).upsert(<String, dynamic>{
        'id': device.id,
        'user_id': userId,
        'name': device.name,
        'location_name': device.locationName,
        'status': _statusToDb(device.status),
        'seed_id': device.seedId,
        'profile_id': device.profileId,
        'updated_at': (device.updatedAt ?? DateTime.now().toUtc())
            .toIso8601String(),
      }, onConflict: 'id');
    } catch (_) {
      // Best-effort.
    }

    try {
      await _client.from(_membershipsTable).upsert(<String, dynamic>{
        'user_id': userId,
        'device_id': device.id,
        'role': 'owner',
      }, onConflict: 'user_id,device_id');
    } catch (_) {
      // Best-effort. If the unique constraint differs, plain insert is
      // still tolerated — duplicates are silently ignored.
    }
  }

  List<BioGDevice> _mergeByUpdatedAt({
    required List<BioGDevice> local,
    required List<BioGDevice> remote,
  }) {
    final Map<String, BioGDevice> byId = <String, BioGDevice>{};

    for (final d in local) {
      byId[d.id] = d;
    }

    for (final r in remote) {
      final existing = byId[r.id];
      if (existing == null) {
        byId[r.id] = r;
      } else if (_moreRecent(r, existing)) {
        byId[r.id] = r;
      }
    }

    return byId.values.toList(growable: false);
  }

  /// Returns true when [a] is strictly more recent than [b], comparing
  /// `updatedAt` first and falling back to `createdAt` when the backend
  /// (or a legacy cache entry) didn't persist `updatedAt`.
  bool _moreRecent(BioGDevice a, BioGDevice b) {
    final aTs = _lwwStamp(a);
    final bTs = _lwwStamp(b);
    return aTs.isAfter(bTs);
  }

  DateTime _lwwStamp(BioGDevice d) {
    return d.updatedAt ??
        d.createdAt ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  BioGDevice? _fromSupabaseRow(Map<String, dynamic> row) {
    try {
      final id = row['id'] as String?;
      if (id == null || id.isEmpty) return null;

      return BioGDevice(
        id: id,
        name: (row['name'] as String?) ?? 'BioG',
        locationName: (row['location_name'] as String?) ?? 'Parcela',
        seedId: (row['seed_id'] as String?) ?? 'UNCONFIGURED',
        profileId: (row['profile_id'] as String?) ?? 'unconfigured',
        telemetryDeviceIdOverride: _validTelemetryDeviceIdFrom(<dynamic>[
          row['telemetry_device_id'],
          row['telemetryDeviceId'],
          row['hardware_device_id'],
          row['hardwareDeviceId'],
          row['device_uuid'],
          row['deviceUuid'],
        ]),
        status: _statusFromDb(row['status'] as String?),
        createdAt: _parseDate(row['created_at']),
        updatedAt: _parseDate(row['updated_at']),
      );
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> _toCacheJson(BioGDevice d) => <String, dynamic>{
        'id': d.id,
        'name': d.name,
        'location_name': d.locationName,
        'seed_id': d.seedId,
        'profile_id': d.profileId,
        'telemetry_device_id': d.telemetryDeviceIdOverride,
        'status': _statusToDb(d.status),
        'created_at': d.createdAt?.toIso8601String(),
        'updated_at': d.updatedAt?.toIso8601String(),
      };

  BioGDevice? _fromCacheJson(Map<String, dynamic> json) {
    try {
      final id = json['id'] as String?;
      if (id == null || id.isEmpty) return null;

      return BioGDevice(
        id: id,
        name: (json['name'] as String?) ?? 'BioG',
        locationName: (json['location_name'] as String?) ?? 'Parcela',
        seedId: (json['seed_id'] as String?) ?? 'UNCONFIGURED',
        profileId: (json['profile_id'] as String?) ?? 'unconfigured',
        telemetryDeviceIdOverride: _validTelemetryDeviceIdFrom(<dynamic>[
          json['telemetry_device_id'],
          json['telemetryDeviceId'],
          json['hardware_device_id'],
          json['hardwareDeviceId'],
          json['device_uuid'],
          json['deviceUuid'],
        ]),
        status: _statusFromDb(json['status'] as String?),
        createdAt: _parseDate(json['created_at']),
        updatedAt: _parseDate(json['updated_at']),
      );
    } catch (_) {
      return null;
    }
  }

  String? _validTelemetryDeviceIdFrom(Iterable<dynamic> values) {
    for (final value in values) {
      final text = value?.toString().trim();
      if (text == null || text.isEmpty || text.toLowerCase() == 'null') {
        continue;
      }
      if (BioGDevice.isTelemetryDeviceId(text)) return text;
    }
    return null;
  }

  BioGDeviceStatus _statusFromDb(String? raw) {
    switch (raw) {
      case 'pending_config':
      case 'pendingConfig':
        return BioGDeviceStatus.pendingConfig;
      case 'offline':
        return BioGDeviceStatus.offline;
      case 'active':
      default:
        return BioGDeviceStatus.active;
    }
  }

  String _statusToDb(BioGDeviceStatus status) {
    switch (status) {
      case BioGDeviceStatus.pendingConfig:
        return 'pending_config';
      case BioGDeviceStatus.offline:
        return 'offline';
      case BioGDeviceStatus.active:
        return 'active';
    }
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}
