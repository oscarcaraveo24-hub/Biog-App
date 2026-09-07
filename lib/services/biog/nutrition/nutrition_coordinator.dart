// lib/services/biog/nutrition/nutrition_coordinator.dart
//
// Une las piezas del manejo nutricional: runtime del cultivo → telemetría →
// libro de ventanas → decisión → memoria → aviso.
//
// Es el espejo de `IrrigationCoordinator`, y por las mismas razones:
//  - [decisionFor] es síncrono y no toca red ni disco. Se puede llamar en cada
//    reconstrucción del Panel. Trabaja con lo que [sync] dejó en memoria (libro
//    de ventanas, historial de telemetría, época de instalación) y memoiza la
//    evaluación para no barrer la telemetría en cada fotograma.
//  - [sync] hace el trabajo asíncrono: carga memoria, recalcula, persiste las
//    ventanas que cambiaron y solo notifica si la decisión cambió.
//
// NO HAY REGISTRO MANUAL. Aquí no existe ningún método «registrar aplicación»:
// la única fuente de «se fertilizó» es la firma que el sensor detecta.
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'package:bio_g/core/agro/nutrition/nutrition_guide_catalog.dart';
import 'package:bio_g/core/agro/nutrition/nutrition_readiness_engine.dart';
import 'package:bio_g/core/agro/nutrition/nutrition_types.dart';
import 'package:bio_g/core/agro/nutrition/site_learning.dart';
import 'package:bio_g/core/crops/crop_runtime_snapshot.dart';
import 'package:bio_g/core/crops/crop_stage_models.dart';
import 'package:bio_g/core/crops/crop_target_models.dart';
import 'package:bio_g/core/crops/crop_types.dart';
import 'package:bio_g/core/telemetry/soil_sensor_spec.dart';
import 'package:bio_g/models/biog_telemetry.dart';
import 'package:bio_g/models/device_crop_context.dart';
import 'package:bio_g/services/biog/nutrition/nutrition_local_storage.dart';
import 'package:bio_g/services/biog/storage/telemetry_local_storage.dart';

class NutritionCoordinator extends ChangeNotifier {
  NutritionCoordinator({
    NutritionLocalStorage? storage,
    TelemetryLocalStorage? telemetryStorage,
    DateTime Function()? clock,
  }) : _storage = storage ?? NutritionLocalStorage(),
       _telemetry = telemetryStorage ?? TelemetryLocalStorage(),
       _now = clock ?? DateTime.now;

  final NutritionLocalStorage _storage;
  final TelemetryLocalStorage _telemetry;
  final DateTime Function() _now;

  /// Cada cuánto se vuelve a barrer aunque no llegue lectura nueva: una
  /// ventana puede cerrar su gracia o su horizonte de respuesta con el reloj.
  static const Duration _recheckInterval = Duration(minutes: 15);

  NutritionDecision? _decision;
  NutritionDecision? get decision => _decision;

  /// Memoria cargada por el último [sync], acotada a un sitio+temporada.
  String? _memoryKey;
  List<NutritionWindowRecord> _windows = const <NutritionWindowRecord>[];
  List<BioGTelemetry> _history = const <BioGTelemetry>[];
  InstallationEpoch? _epoch;

  /// Memoización de [decisionFor]: barrer la telemetría cuesta, y el Panel
  /// reconstruye a menudo.
  String? _evalKey;
  NutritionEvaluation? _eval;

  String? _lastSignature;
  bool _syncing = false;
  String? _lastSyncKey;

  /// Libro de ventanas del dispositivo activo, todas las temporadas cargadas
  /// (solo lectura, para pantallas).
  List<NutritionWindowRecord> get windows => _windows;

  /// Época de instalación vigente del dispositivo activo.
  InstallationEpoch? get epoch => _epoch;

  /// Calcula la decisión con la memoria que YA está cargada.
  ///
  /// En el primer fotograma —antes de que [sync] haya leído disco— decide sin
  /// libro ni historial: el motor lo sabe tratar (ventana observable = no) y en
  /// cuanto [sync] resuelve, notifica y la siguiente reconstrucción ya lo trae.
  NutritionDecision? decisionFor(
    CropRuntimeSnapshot runtime, {
    DateTime? now,
  }) {
    if (runtime.device == null) return null;
    final DateTime at = now ?? _now();
    final NutritionEvaluation? eval = _evaluate(runtime, at);
    return eval?.decision;
  }

  /// Carga memoria, recalcula, persiste y avisa si cambió.
  ///
  /// Seguro de llamar en cada reconstrucción: sale de inmediato si el estado
  /// relevante no cambió.
  Future<void> sync({
    required CropRuntimeSnapshot runtime,
    String? userId,
    bool force = false,
  }) async {
    if (_syncing) return;
    final device = runtime.device;
    if (device == null) return;

    _syncing = true;
    try {
      final DateTime now = _now();
      final String? telemetryId = device.telemetryDeviceId;
      final String seasonKey = _seasonKeyFor(runtime, now);
      final String memoryKey = '${device.id}|$seasonKey|${userId ?? '-'}';

      final int bucket =
          now.millisecondsSinceEpoch ~/ _recheckInterval.inMilliseconds;
      final String key = <Object?>[
        memoryKey,
        runtime.live?.timestamp.millisecondsSinceEpoch,
        runtime.cropContext?.cropId,
        runtime.cropContext?.updatedAt.millisecondsSinceEpoch,
        runtime.stageResult?.stageKey,
        bucket,
      ].join('|');
      if (!force && key == _lastSyncKey) return;

      // Memoria del sitio. Se recarga completa cuando cambia el sitio o la
      // temporada; entre tanto, las filas que escribimos ya están en memoria.
      _history = telemetryId == null
          ? const <BioGTelemetry>[]
          : await _telemetry.load(telemetryId);

      if (memoryKey != _memoryKey || force) {
        // Libro completo del dispositivo, no solo la temporada: el libro de
        // la temporada decide el score, pero la «respuesta habitual del
        // sitio» (magnitud típica de firmas anteriores) se aprende entre
        // temporadas de la misma época de instalación (§15, §22).
        _windows = await _storage.loadDevice(
          deviceId: device.id,
          userId: userId,
        );
        _epoch = await _storage.currentEpoch(device.id, userId: userId);
        if (_epoch == null) {
          // Primera vez que vemos este dispositivo: abre la época inicial.
          // Sin esto no hay LEARNING ni «desde cuándo» para el sitio. Se ancla
          // a la lectura más antigua que tengamos, no a hoy: si la sonda lleva
          // semanas transmitiendo, el sitio ya no está en aprendizaje.
          final DateTime start = _earliestTelemetryAt() ?? now;
          final InstallationEpoch initial = InstallationEpoch(
            deviceId: device.id,
            startedAt: start,
            epochId: start.toUtc().millisecondsSinceEpoch.toString(),
            reasonEs: 'Instalación inicial',
          );
          await _storage.saveEpoch(initial, userId: userId);
          _epoch = initial;
        }
        _memoryKey = memoryKey;
      }
      _evalKey = null; // memoria nueva: la memoización anterior ya no vale

      final NutritionEvaluation? next = _evaluate(runtime, now);
      _lastSyncKey = key;
      if (next == null) return;

      if (next.changedWindows.isNotEmpty) {
        await _storage.upsertWindows(next.changedWindows, userId: userId);
        // La reconciliación devuelve solo la temporada actual; las demás se
        // conservan en memoria para la respuesta habitual del sitio.
        _windows = <NutritionWindowRecord>[
          ..._windows.where((w) => w.seasonKey != seasonKey),
          ...next.windows,
        ];
      }

      final String signature = next.decision.identityKey;
      final bool changed = signature != _lastSignature;
      _decision = next.decision;
      _lastSignature = signature;
      if (changed) notifyListeners();
    } catch (_) {
      // La memoria nutricional nunca puede tumbar el Panel: la decisión
      // anterior sigue siendo válida hasta la próxima sincronización.
    } finally {
      _syncing = false;
    }
  }

  Future<void> refresh({required CropRuntimeSnapshot runtime, String? userId}) {
    return sync(runtime: runtime, userId: userId, force: true);
  }

  /// «Reubicar BIO-G»: la sonda cambió de punto. Cierra la época anterior y
  /// abre una nueva; el historial viejo se conserva pero deja de compararse
  /// como si fuera el mismo sitio (Guía v0.4, §22).
  Future<void> relocate({
    required String deviceId,
    String? userId,
    DateTime? at,
  }) async {
    final DateTime when = at ?? _now();
    final InstallationEpoch epoch = InstallationEpoch(
      deviceId: deviceId,
      startedAt: when,
      epochId: when.toUtc().millisecondsSinceEpoch.toString(),
      reasonEs: 'Reubicación',
    );
    await _storage.saveEpoch(epoch, userId: userId);
    _epoch = epoch;
    _evalKey = null;
    _lastSyncKey = null;
    notifyListeners();
  }

  /// Limpia el estado al cambiar de usuario o de dispositivo activo.
  void reset() {
    _decision = null;
    _lastSignature = null;
    _lastSyncKey = null;
    _memoryKey = null;
    _windows = const <NutritionWindowRecord>[];
    _history = const <BioGTelemetry>[];
    _epoch = null;
    _evalKey = null;
    _eval = null;
    notifyListeners();
  }

  /// Borra la memoria nutricional de un usuario (cerrar sesión / eliminar
  /// cuenta).
  Future<void> purgeForUser(String? userId) async {
    reset();
    if (userId != null && userId.isNotEmpty) {
      await _storage.deleteForUser(userId);
    }
  }

  // ═════════════════════════════════════════════════════════════════════════
  // EVALUACIÓN
  // ═════════════════════════════════════════════════════════════════════════

  NutritionEvaluation? _evaluate(CropRuntimeSnapshot runtime, DateTime now) {
    final device = runtime.device;
    if (device == null) return null;

    final int bucket =
        now.millisecondsSinceEpoch ~/ _recheckInterval.inMilliseconds;
    final String key = <Object?>[
      device.id,
      runtime.live?.timestamp.millisecondsSinceEpoch,
      runtime.cropContext?.cropId,
      runtime.cropContext?.updatedAt.millisecondsSinceEpoch,
      runtime.stageResult?.stageKey,
      runtime.stageResult?.stageProgressPct?.toStringAsFixed(2),
      _memoryKey,
      _history.length,
      _windows.length,
      bucket,
    ].join('|');
    if (key == _evalKey && _eval != null) return _eval;

    final NutritionReadinessInput input = buildInput(
      runtime: runtime,
      now: now,
      windows: _windows,
      history: _history,
      epoch: _epoch,
    );
    final NutritionEvaluation? eval = NutritionReadinessEngine.evaluate(input);
    _evalKey = key;
    _eval = eval;
    return eval;
  }

  /// Construye la entrada del motor a partir del runtime. Público para que el
  /// registro de eventos y las pruebas construyan exactamente lo mismo.
  static NutritionReadinessInput buildInput({
    required CropRuntimeSnapshot runtime,
    required DateTime now,
    List<NutritionWindowRecord> windows = const <NutritionWindowRecord>[],
    List<BioGTelemetry> history = const <BioGTelemetry>[],
    InstallationEpoch? epoch,
  }) {
    final CropStageResult? stage = runtime.stageResult;
    final DeviceCropContext? ctx = runtime.cropContext;
    final bool isPerennial = _isPerennial(runtime);

    // Etapa siguiente anticipada (anuales): el mismo motor fenológico, unos
    // días después del fin previsto de la etapa actual.
    String? nextStageKey;
    String? nextStageLabel;
    StageTargets? nextTargets;
    final definition = runtime.definition;
    final profile = runtime.profile;
    final DateTime? sowing = runtime.engineSowingDate;
    if (definition != null &&
        profile != null &&
        stage != null &&
        sowing != null &&
        stage.expectedDaysToEnd >= 0 &&
        stage.expectedDaysToEnd <= NutritionReadinessEngine.upcomingWindowDays) {
      try {
        final CropStageResult next = definition.engine.compute(
          sowingDate: sowing,
          today: now.add(Duration(days: stage.expectedDaysToEnd + 1)),
          profile: profile,
        );
        if (next.stageKey != stage.stageKey) {
          nextStageKey = next.stageKey;
          nextStageLabel = next.stageLabelEs;
          nextTargets = definition.resolveTargets(next);
        }
      } catch (_) {
        // Un motor que no puede anticipar no rompe la decisión de hoy.
      }
    }

    return NutritionReadinessInput(
      now: now,
      isPlanted: runtime.isPlanted,
      isGuideMode: runtime.isGuideMode,
      isGenericMode: runtime.isGenericMode,
      cropKey: runtime.cropKeyName,
      cropLabel: runtime.cropLabel,
      stageKey: stage?.stageKey,
      stageLabelEs: stage?.stageLabelEs ?? runtime.stageLabel,
      daysToStageEnd: stage?.expectedDaysToEnd,
      stageProgress01: stage?.stageProgressPct,
      stageStartedAt: stageStartedAt(stage, now),
      targets: runtime.targets,
      nextStageKey: nextStageKey,
      nextStageLabelEs: nextStageLabel,
      nextTargets: nextTargets,
      guide: NutritionGuideCatalog.forCrop(runtime.cropKeyName),
      live: runtime.live,
      eval: runtime.eval,
      cultivationScaleId: ctx?.cultivationScaleId,
      profileId: runtime.effectiveProfileId,
      varietyId: runtime.effectiveVarietyId,
      varietyAlias: runtime.effectiveVarietyAlias,
      calendarId: ctx?.calendarTypeId,
      isPerennial: isPerennial,
      deviceId: runtime.device?.id,
      seasonKey: _seasonKeyFor(runtime, now),
      epochId: epoch?.epochId,
      windows: windows,
      history: history,
      learning: SiteLearningStatus.resolve(startedAt: epoch?.startedAt, now: now),
      // Contrato del sensor (fase 3): si la sonda entregara CE sin compensar,
      // el detector la lleva a 25 °C. Hoy el catálogo tiene una sola sonda y
      // el dispositivo no declara modelo de sonda; cuando lo haga, resolver
      // aquí con `SoilSensorSpec.byId`.
      compensateEcTemperature:
          !SoilSensorSpec.defaultSpec.ecTemperatureCompensated,
    );
  }

  /// Inicio estimado de la etapa actual a partir de su progreso y de los días
  /// que le faltan. Si el motor no expone progreso, se toma «ahora»: la
  /// ventana se observa desde que BIO-G la vio.
  static DateTime stageStartedAt(CropStageResult? stage, DateTime now) {
    if (stage == null) return now;
    final double? progress = stage.stageProgressPct;
    if (progress == null || progress <= 0.0) return now;
    // transcurrido = restantes × p / (1 − p). Con p → 1 el cociente se
    // dispara y con restantes = 0 se anula, así que la fracción restante se
    // acota al 5 % y los días restantes a un mínimo de 1: una etapa que está
    // terminando empezó hace días, no «ahora».
    final double remainingFraction = math.max(1.0 - progress, 0.05);
    final double remainingDays = math.max(stage.expectedDaysToEnd, 1).toDouble();
    final double elapsedDays =
        (remainingDays * progress / remainingFraction).clamp(0.0, 400.0);
    return now.subtract(Duration(hours: (elapsedDays * 24).round()));
  }

  /// Identidad de la temporada: anuales por fecha de siembra; perennes y
  /// ornamentales por ciclo anual (febrero a enero), para que la memoria de
  /// ventanas no arrastre penalizaciones de años anteriores.
  static String _seasonKeyFor(CropRuntimeSnapshot runtime, DateTime now) {
    final String device = runtime.device?.id ?? 'device';
    final String crop = runtime.cropKeyName.isEmpty ? 'crop' : runtime.cropKeyName;
    if (_isPerennial(runtime) || runtime.definition?.category == CropCategory.ornamental) {
      final int cycleYear = now.month >= 2 ? now.year : now.year - 1;
      return '$device|$crop|ciclo-$cycleYear';
    }
    final DateTime? sowing = runtime.engineSowingDate ??
        runtime.cropContext?.sowingDate ??
        runtime.effectiveLifecycleDate;
    final String anchor = sowing == null
        ? '-'
        : '${sowing.year}-${sowing.month.toString().padLeft(2, '0')}-${sowing.day.toString().padLeft(2, '0')}';
    return '$device|$crop|$anchor';
  }

  static bool _isPerennial(CropRuntimeSnapshot runtime) {
    final category = runtime.definition?.category;
    if (category == CropCategory.tree || category == CropCategory.fruit) return true;
    return runtime.cropKeyName.endsWith('_tree');
  }

  DateTime? _earliestTelemetryAt() {
    if (_history.isEmpty) return null;
    DateTime? earliest;
    for (final BioGTelemetry t in _history) {
      if (earliest == null || t.timestamp.isBefore(earliest)) earliest = t.timestamp;
    }
    return earliest;
  }
}
