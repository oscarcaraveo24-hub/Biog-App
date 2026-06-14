import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bio_g/models/device_crop_context.dart';

/// Syncs [DeviceCropContext] with the `device_crop_contexts` Supabase
/// table. SharedPreferences remains the primary local source of truth;
/// this sync is best-effort.
///
/// Schema note (verified against the live Supabase project):
/// the table uses *flat, typed columns* — NOT a single `context_json`
/// blob — so every field maps to its own column. An earlier version
/// of this file wrote a non-existent `context_json` column, which made
/// the whole sync a silent no-op.
///
/// Offline-first policy:
///   - Every write first updates local storage (handled upstream),
///     then fires a best-effort upsert here.
///   - Every read returns whatever Supabase has. The caller is
///     responsible for last-write-wins merging against the local
///     cache using [DeviceCropContext.updatedAt].
class CropContextSupabaseSync {
  static const String _table = 'device_crop_contexts';

  SupabaseClient get _client => Supabase.instance.client;

  String? get _userId => _client.auth.currentUser?.id;

  /// Upload a single crop context to Supabase.
  Future<void> upload(DeviceCropContext context) async {
    final userId = _userId;
    if (userId == null) return;

    try {
      await _client
          .from(_table)
          .upsert(_toRow(userId, context), onConflict: 'user_id,device_id');
    } catch (_) {
      // Best-effort — local storage is the primary source.
    }
  }

  /// Upload all crop contexts for the current user.
  Future<void> uploadAll(Map<String, DeviceCropContext> contexts) async {
    final userId = _userId;
    if (userId == null) return;
    if (contexts.isEmpty) return;

    try {
      final rows = contexts.values.map((c) => _toRow(userId, c)).toList();
      await _client.from(_table).upsert(rows, onConflict: 'user_id,device_id');
    } catch (_) {
      // Best-effort.
    }
  }

  /// Download all crop contexts for the current user from Supabase.
  Future<Map<String, DeviceCropContext>> downloadAll() async {
    final userId = _userId;
    if (userId == null) return <String, DeviceCropContext>{};

    try {
      final data = await _client
          .from(_table)
          .select()
          .eq('user_id', userId)
          .order('updated_at', ascending: false)
          .limit(200);

      final result = <String, DeviceCropContext>{};

      for (final row in (data as List<dynamic>)) {
        final m = row as Map<String, dynamic>;
        final deviceId = m['device_id'] as String?;
        if (deviceId == null || deviceId.isEmpty) continue;

        try {
          result[deviceId] = _fromRow(m);
        } catch (_) {
          // Skip malformed rows.
        }
      }

      return result;
    } catch (_) {
      return <String, DeviceCropContext>{};
    }
  }

  /// Delete a specific device's crop context from Supabase.
  Future<void> delete(String deviceId) async {
    final userId = _userId;
    if (userId == null) return;

    try {
      await _client
          .from(_table)
          .delete()
          .eq('user_id', userId)
          .eq('device_id', deviceId);
    } catch (_) {
      // Best-effort.
    }
  }

  // ---------------------------------------------------------------------------
  // Row mapping
  // ---------------------------------------------------------------------------

  Map<String, dynamic> _toRow(String userId, DeviceCropContext c) {
    return <String, dynamic>{
      'user_id': userId,
      'device_id': c.deviceId,
      'crop_category_id': c.cropCategoryId,
      'crop_id': c.cropId,
      'profile_id': c.profileId,
      'variety_id': c.varietyId,
      'variety_alias': c.varietyAlias,
      'calendar_type_id': c.calendarTypeId,
      'lifecycle_status': c.lifecycleStatus.name,
      'sowing_date': c.sowingDate?.toIso8601String(),
      'planned_sowing_date': c.plannedSowingDate?.toIso8601String(),
      'sowing_date_confidence': c.sowingDateConfidence.name,
      'sowing_mode_id': c.sowingModeId,
      'timezone': c.timezone,
      'region_code': c.regionCode,
      'cycle_label': c.cycleLabel,
      // Contexto perenne (árboles). NULL para anuales: no altera su semántica.
      'perennial_state_id': c.perennialStateId,
      'phenology_stage_id': c.phenologyStageId,
      'perennial_anchor_date': c.perennialAnchorDate?.toIso8601String(),
      'perennial_anchor_type_id': c.perennialAnchorTypeId,
      'catalog_version': c.catalogVersion,
      'source': c.source.name,
      'configured_at': c.configuredAt.toIso8601String(),
      'updated_at': c.updatedAt.toIso8601String(),
    };
  }

  DeviceCropContext _fromRow(Map<String, dynamic> row) {
    return DeviceCropContext(
      deviceId: row['device_id'] as String,
      cropCategoryId: (row['crop_category_id'] as String?) ?? 'grain',
      cropId: row['crop_id'] as String,
      profileId: (row['profile_id'] as String?) ?? '',
      varietyId: row['variety_id'] as String?,
      varietyAlias: row['variety_alias'] as String?,
      calendarTypeId: row['calendar_type_id'] as String?,
      lifecycleStatus: _lifecycleFromName(row['lifecycle_status'] as String?),
      sowingDate: _parseDate(row['sowing_date']),
      plannedSowingDate: _parseDate(row['planned_sowing_date']),
      sowingDateConfidence: _dateConfidenceFromName(
        row['sowing_date_confidence'] as String?,
      ),
      sowingModeId: row['sowing_mode_id'] as String?,
      timezone: row['timezone'] as String?,
      regionCode: row['region_code'] as String?,
      cycleLabel: row['cycle_label'] as String?,
      // Contexto perenne (árboles). Filas antiguas/anuales no traen estas claves
      // y quedan null de forma segura.
      perennialStateId: row['perennial_state_id'] as String?,
      phenologyStageId: row['phenology_stage_id'] as String?,
      perennialAnchorDate: _parseDate(row['perennial_anchor_date']),
      perennialAnchorTypeId: row['perennial_anchor_type_id'] as String?,
      catalogVersion: (row['catalog_version'] as String?) ?? 'v1',
      source: _sourceFromName(row['source'] as String?),
      configuredAt: _parseDate(row['configured_at']) ?? DateTime.now().toUtc(),
      updatedAt: _parseDate(row['updated_at']) ?? DateTime.now().toUtc(),
    );
  }

  CropLifecycleStatus _lifecycleFromName(String? raw) {
    if (raw == null) return CropLifecycleStatus.fallow;
    try {
      return CropLifecycleStatus.values.byName(raw);
    } catch (_) {
      return CropLifecycleStatus.fallow;
    }
  }

  DateConfidence _dateConfidenceFromName(String? raw) {
    if (raw == null) return DateConfidence.unknown;
    try {
      return DateConfidence.values.byName(raw);
    } catch (_) {
      return DateConfidence.unknown;
    }
  }

  CropConfigSource _sourceFromName(String? raw) {
    if (raw == null) return CropConfigSource.wizard;
    try {
      return CropConfigSource.values.byName(raw);
    } catch (_) {
      return CropConfigSource.wizard;
    }
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}
