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
          .upsert(
            toRowForSync(userId, context),
            onConflict: 'user_id,device_id',
          );
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
      final rows = contexts.values.map((c) => toRowForSync(userId, c)).toList();
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
          result[deviceId] = fromRowForSync(m);
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

  /// Visible for the directed persistence contract test. The live table does
  /// not yet expose dedicated ornamental columns, so the ornamentals (cactus,
  /// suculenta) use the existing nullable perennial compatibility slots. The
  /// `crop_id` column keeps them apart, so each plant decodes back into its own
  /// domain. Trees and annual crops retain their exact mapping.
  ///
  /// DEUDA TÉCNICA CONOCIDA (guía de ornamentales §9): conviene crear columnas
  /// ornamentales propias antes de que un perenne futuro choque aquí.
  Map<String, dynamic> toRowForSync(String userId, DeviceCropContext c) {
    final isCactus = _isOrnamentalCropId(c.cropId);
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
      'sowing_date_confidence': isCactus
          ? (c.ornamentalAnchorDateConfidence ?? DateConfidence.unknown).name
          : c.sowingDateConfidence.name,
      'sowing_mode_id': c.sowingModeId,
      'timezone': c.timezone,
      'region_code': c.regionCode,
      'cycle_label': c.cycleLabel,
      // Puente compatible de Cactus hasta que la tabla tenga columnas
      // ornamentales propias. Nunca se mezclan ambos dominios en el modelo al
      // decodificar: para Cactus vuelven a ornamental*, para árboles a
      // perennial*/phenology*.
      'perennial_state_id': isCactus ? c.ornamentalStageId : c.perennialStateId,
      'phenology_stage_id': isCactus ? null : c.phenologyStageId,
      'perennial_anchor_date':
          (isCactus ? c.ornamentalAnchorDate : c.perennialAnchorDate)
              ?.toIso8601String(),
      'perennial_anchor_type_id': isCactus
          ? c.ornamentalAnchorTypeId
          : c.perennialAnchorTypeId,
      'catalog_version': c.catalogVersion,
      'source': c.source.name,
      'configured_at': c.configuredAt.toIso8601String(),
      'updated_at': c.updatedAt.toIso8601String(),
    };
  }

  /// Visible for the directed persistence contract test.
  DeviceCropContext fromRowForSync(Map<String, dynamic> row) {
    final cropId = row['crop_id'] as String;
    // El puente perenne es compartido por las ornamentales; `crop_id` es lo que
    // las separa al decodificar (cactus vuelve a cactus, suculenta a suculenta).
    final String? ornamentalCropId = _ornamentalCropIdOrNull(cropId);
    final bool isCactus = ornamentalCropId != null;
    final String resolvedCropId = ornamentalCropId ?? cropId;
    final lifecycle = _lifecycleFromName(row['lifecycle_status'] as String?);
    final dateConfidence = _dateConfidenceFromName(
      row['sowing_date_confidence'] as String?,
    );
    return DeviceCropContext(
      deviceId: row['device_id'] as String,
      cropCategoryId: isCactus
          ? 'ornamental'
          : (row['crop_category_id'] as String?) ?? 'grain',
      cropId: resolvedCropId,
      profileId: (row['profile_id'] as String?) ?? '',
      varietyId: row['variety_id'] as String?,
      varietyAlias: row['variety_alias'] as String?,
      calendarTypeId: row['calendar_type_id'] as String?,
      lifecycleStatus: isCactus && lifecycle == CropLifecycleStatus.fallow
          ? CropLifecycleStatus.planted
          : lifecycle,
      sowingDate: isCactus ? null : _parseDate(row['sowing_date']),
      plannedSowingDate: isCactus
          ? null
          : _parseDate(row['planned_sowing_date']),
      sowingDateConfidence: isCactus ? DateConfidence.unknown : dateConfidence,
      sowingModeId: isCactus ? null : row['sowing_mode_id'] as String?,
      timezone: row['timezone'] as String?,
      regionCode: row['region_code'] as String?,
      cycleLabel: row['cycle_label'] as String?,
      // Contexto perenne (árboles). Filas antiguas/anuales no traen estas claves
      // y quedan null de forma segura.
      perennialStateId: isCactus ? null : row['perennial_state_id'] as String?,
      phenologyStageId: isCactus ? null : row['phenology_stage_id'] as String?,
      perennialAnchorDate: isCactus
          ? null
          : _parseDate(row['perennial_anchor_date']),
      perennialAnchorTypeId: isCactus
          ? null
          : row['perennial_anchor_type_id'] as String?,
      lifecycleModeId: isCactus ? 'establishment_maintenance' : null,
      ornamentalStageId: isCactus ? row['perennial_state_id'] as String? : null,
      ornamentalAnchorDate: isCactus
          ? _parseDate(row['perennial_anchor_date'])
          : null,
      ornamentalAnchorTypeId: isCactus
          ? row['perennial_anchor_type_id'] as String?
          : null,
      ornamentalAnchorDateConfidence: isCactus ? dateConfidence : null,
      ornamentalStageConfidence: isCactus ? 0.25 : null,
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

  /// Ornamentales de establecimiento + mantenimiento que viajan por el puente
  /// perenne. Devuelve el cropId canónico, o `null` si no es una de ellas.
  String? _ornamentalCropIdOrNull(String? value) {
    final normalized = value?.trim().toLowerCase();
    if (normalized == 'crop_cactus' || normalized == 'cactus') {
      return 'crop_cactus';
    }
    if (normalized == 'crop_succulent' ||
        normalized == 'succulent' ||
        normalized == 'suculenta') {
      return 'crop_succulent';
    }
    if (normalized == 'crop_aloe' ||
        normalized == 'aloe' ||
        normalized == 'sabila' ||
        normalized == 'sábila') {
      return 'crop_aloe';
    }
    return null;
  }

  bool _isOrnamentalCropId(String? value) =>
      _ornamentalCropIdOrNull(value) != null;
}
