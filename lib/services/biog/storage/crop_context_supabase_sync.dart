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
///     then enqueues the upsert here. Las ESCRITURAS ([upload], [delete])
///     propagan el error: quien las llama es `PendingSyncQueue` y necesita la
///     excepción para conservar y reintentar el pendiente. No volver a
///     envolverlas en `catch (_)` — eso reintroduce la pérdida silenciosa.
///   - Las LECTURAS sí son best-effort y devuelven vacío ante un fallo: no
///     hay nada que perder porque el dato local sigue siendo el bueno.
///   - Every read returns whatever Supabase has. The caller is
///     responsible for last-write-wins merging against the local
///     cache using [DeviceCropContext.updatedAt].
class CropContextSupabaseSync {
  static const String _table = 'device_crop_contexts';

  SupabaseClient get _client => Supabase.instance.client;

  String? get _userId => _client.auth.currentUser?.id;

  /// Upload a single crop context to Supabase.
  ///
  /// PROPAGA EL ERROR A PROPÓSITO. Esta escritura sólo se invoca desde
  /// `PendingSyncQueue`, y el contrato de esa cola es "lanza = reintenta":
  /// una operación se borra de la bandeja únicamente si el handler termina
  /// sin excepción. Mientras aquí hubo un `catch (_)`, un fallo de red se
  /// veía desde la cola exactamente igual que un éxito, así que la operación
  /// se descartaba al primer intento: el cultivo que el agricultor configuró
  /// sin señal no llegaba nunca a la nube y el backoff era código
  /// inalcanzable. El guardado local ya ocurrió antes de llamar aquí, así que
  /// dejar subir la excepción no pierde nada — sólo conserva el pendiente.
  Future<void> upload(DeviceCropContext context) async {
    final userId = _userId;
    // Sin sesión no hay escritura posible. Antes esto era un `return` mudo que
    // la cola interpretaba como subida confirmada, de modo que todo lo editado
    // mientras el token aún no estaba restaurado se borraba de la bandeja.
    if (userId == null) {
      throw StateError('crop context upload: sin sesión');
    }

    await _client
        .from(_table)
        .upsert(
          toRowForSync(userId, context),
          onConflict: 'user_id,device_id',
        );
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
  ///
  /// Propaga el error por el mismo motivo que [upload]: la cola necesita la
  /// excepción para conservar el borrado pendiente. Si se tragaba, el cultivo
  /// borrado en el teléfono seguía vivo en la nube y volvía a bajar en el
  /// siguiente `downloadAll`, resucitado.
  Future<void> delete(String deviceId) async {
    final userId = _userId;
    if (userId == null) {
      throw StateError('crop context delete: sin sesión');
    }

    await _client
        .from(_table)
        .delete()
        .eq('user_id', userId)
        .eq('device_id', deviceId);
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
  /// DEUDA TÉCNICA CONOCIDA (Guía de Ornamentales §50, decisión diferida
  /// "definir si el baseline hídrico se guarda local, en Supabase o en ambas"):
  /// conviene crear columnas
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
      // Estas columnas ya existían en `device_crop_contexts` y ningún punto del
      // código las escribía, así que llegaban siempre en null: la escala de
      // cultivo, la ubicación de la parcela y el estado del alta se quedaban
      // sólo dentro del teléfono. Un BioG ES una parcela; su ubicación vive
      // aquí y no en una entidad `plots` aparte.
      'cultivation_scale': c.cultivationScaleId,
      'location_label': c.locationLabel,
      'location_source': c.locationSource,
      'geo_lat': c.geoLat,
      'geo_lng': c.geoLng,
      // Tipo de suelo. Nullable y sin valor por defecto a propósito: NULL
      // significa «contexto anterior a esta versión» y `'unknown'` significa
      // «el productor dijo que no la sabe». Ver la migración
      // `20260811_add_soil_texture.sql`.
      'soil_texture_id': c.soilTextureId,
      'soil_texture_source': c.soilTextureSource,
      'soil_local_descriptors': c.soilLocalDescriptors.isEmpty
          ? null
          : c.soilLocalDescriptors,
      'soil_local_other': c.soilLocalOther,
      'setup_status': c.setupStatus,
      'setup_completed_at': c.setupCompletedAt?.toIso8601String(),
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
      cultivationScaleId: row['cultivation_scale'] as String?,
      locationLabel: row['location_label'] as String?,
      locationSource: row['location_source'] as String?,
      geoLat: (row['geo_lat'] as num?)?.toDouble(),
      geoLng: (row['geo_lng'] as num?)?.toDouble(),
      soilTextureId: _nonEmptyText(row['soil_texture_id']),
      soilTextureSource: _nonEmptyText(row['soil_texture_source']),
      soilLocalDescriptors: _textList(row['soil_local_descriptors']),
      soilLocalOther: _nonEmptyText(row['soil_local_other']),
      setupStatus: (row['setup_status'] as String?) ?? kCropSetupDraft,
      setupCompletedAt: _parseDate(row['setup_completed_at']),
    );
  }

  String? _nonEmptyText(Object? raw) {
    if (raw is! String) return null;
    final v = raw.trim();
    return v.isEmpty ? null : v;
  }

  List<String> _textList(Object? raw) {
    if (raw is! List) return const <String>[];
    final out = <String>[];
    for (final e in raw) {
      if (e is! String) continue;
      final v = e.trim();
      if (v.isNotEmpty && !out.contains(v)) out.add(v);
    }
    return List<String>.unmodifiable(out);
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
    if (normalized == 'crop_agave' ||
        normalized == 'agave' ||
        normalized == 'maguey') {
      return 'crop_agave';
    }
    // El nopal faltaba, y sí usa `ornamentalStageId`: `NopalStageResolver` lo
    // lee y lo escribe. Al no cruzar este puente, `toRowForSync` mandaba
    // `perennial_state_id` (null) en su lugar y `fromRowForSync` devolvía la
    // etapa vacía. Efecto real: un nopal PERDÍA su etapa y su ancla al
    // reinstalar la app o cambiar de teléfono, que es justo lo que la Guía de
    // Ornamentales exige que no pase ("los datos persisten y se restauran sin
    // perder etapa, baseline ni memoria").
    if (normalized == 'crop_nopal' ||
        normalized == 'nopal' ||
        normalized == 'orn_nopal') {
      // `orn_nopal` es el id heredado y sigue vivo: lo reconocen npk_caps,
      // crop_catalog y crop_registry, y hay una prueba que lo exige. Dejarlo
      // fuera habría arreglado el round-trip solo para las fichas nuevas.
      return 'crop_nopal';
    }
    return null;
  }

  bool _isOrnamentalCropId(String? value) =>
      _ornamentalCropIdOrNull(value) != null;
}
