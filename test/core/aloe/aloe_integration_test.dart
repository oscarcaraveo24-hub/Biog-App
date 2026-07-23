// test/core/aloe/aloe_integration_test.dart
//
// Contratos de la integración de Sábila / Aloe (tercera ornamental de BIO-G).
//
// Regla que estas pruebas blindan: LA SÁBILA SE COMPORTA COMO FRIJOL.
// Mismas unidades, mismas bandas, mismas claves de alerta, mismo motor de
// nutrición. Lo único distinto es que NO es cíclica (establecimiento →
// mantenimiento, sin cosecha ni rendimiento), igual que el cactus, la suculenta
// y el árbol.
//
// Y la regla que blinda a los demás: se copia su arquitectura, NO sus números.

import 'package:flutter_test/flutter_test.dart';

import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/agro/npk_caps.dart';
import 'package:bio_g/core/crops/cactus/cactus_universal_profile.dart';
import 'package:bio_g/core/crops/succulent/succulent_catalog.dart';
import 'package:bio_g/core/crops/succulent/succulent_universal_profile.dart';
import 'package:bio_g/core/crops/catalog/crop_catalog.dart';
import 'package:bio_g/core/crops/crop_registry.dart';
import 'package:bio_g/core/crops/crop_types.dart';
import 'package:bio_g/core/crops/ornamental/ornamental_crops.dart';
import 'package:bio_g/core/crops/aloe/aloe_agro_score_engine.dart';
import 'package:bio_g/core/crops/aloe/aloe_catalog.dart';
import 'package:bio_g/core/crops/aloe/aloe_crop_definition.dart';
import 'package:bio_g/core/crops/aloe/aloe_lifecycle.dart';
import 'package:bio_g/core/crops/aloe/aloe_stage_resolver.dart';
import 'package:bio_g/core/crops/aloe/aloe_universal_profile.dart';
import 'package:bio_g/core/plant_health/catalog/aloe_syndromes.dart';
import 'package:bio_g/core/plant_health/plant_health_ids.dart';
import 'package:bio_g/core/plant_health/plant_health_models.dart';
import 'package:bio_g/core/plant_health/plant_health_registry.dart';
import 'package:bio_g/core/plant_health/plant_health_stage_adapter.dart';
import 'package:bio_g/core/plant_health/plant_health_stage_bucket.dart';
import 'package:bio_g/models/biog_telemetry.dart';
import 'package:bio_g/models/device_crop_context.dart';

const List<String> _allStages = <String>[
  AloeStageIds.installationEstablishment,
  AloeStageIds.rootEstablishment,
  AloeStageIds.activeGrowth,
  AloeStageIds.maintenance,
  AloeStageIds.rest,
  AloeStageIds.unknown,
];

BioGTelemetry _telemetry({
  double moisture = 26,
  double soilTemp = 24,
  double ph = 6.4,
  double ec = 0.9,
  double resistance = 0.6,
  double n = 26,
  double p = 18,
  double k = 120,
  double airTemp = 26,
  double airHumidity = 45,
}) {
  return BioGTelemetry(
    deviceId: 'dev-aloe',
    timestamp: DateTime(2026, 7, 18, 9),
    airTempC: airTemp,
    airHumidityPct: airHumidity,
    soilMoisturePct: moisture,
    soilTempC: soilTemp,
    ph: ph,
    ec: ec,
    resistance: resistance,
    n: n,
    p: p,
    k: k,
    batteryPct: 80,
    signalRssi: -50,
  );
}

({AgroEvalResult eval, AlertsState nextAlertsState}) _evaluate({
  required BioGTelemetry t,
  String stage = AloeStageIds.maintenance,
  String? profileId,
}) {
  return AloeAgroScoreEngine.evaluate(
    t: t,
    stageId: stage,
    stageLabelEs: aloeStageDisplayName(stage),
    targets: resolveAloeTargets(stage),
    weights: resolveAloeStageWeights(stage, profileId: profileId),
    cropLabel: 'Sábila',
    profileId: profileId,
  );
}

void main() {
  // ── Contrato de unidades (§3.1 de la guía · Doc B §3) ──────────────────────
  group('Unidades reales', () {
    test('EC en mS/cm, no un índice comparable', () {
      for (final stage in _allStages) {
        final ec = resolveAloeTargets(stage).ec;
        expect(ec.highMin, lessThan(5), reason: 'EC de $stage debe ser mS/cm');
        expect(ec.optimalMin, greaterThan(0));
      }
    });

    test('resistencia en MPa (highMin <= 2.0)', () {
      for (final stage in _allStages) {
        final r = resolveAloeTargets(stage).resistance;
        expect(r.highMin, lessThanOrEqualTo(2.0));
        expect(
          r.lowMax,
          lessThanOrEqualTo(0.0),
          reason: 'Un sustrato muy suelto no se castiga',
        );
      }
    });

    test('NPK en mg/kg, con demanda baja-moderada y K > N', () {
      for (final stage in _allStages) {
        final t = resolveAloeTargets(stage);
        expect(t.nSoilPpmRange, isNotNull);
        expect(t.pSoilPpmRange, isNotNull);
        expect(t.kSoilPpmRange, isNotNull);
        // La sábila responde a N (Doc B §4.6): su óptimo llega más alto que en
        // suculenta, pero sigue lejos de un cultivo de rendimiento.
        expect(t.nSoilPpmRange!.optimalMax, lessThanOrEqualTo(60));
        expect(
          t.kSoilPpmRange!.optimalMax,
          greaterThan(t.nSoilPpmRange!.optimalMax),
        );
      }
    });

    test('todos los rangos cumplen lowMax < optMin <= optMax < highMin', () {
      for (final stage in _allStages) {
        final t = resolveAloeTargets(stage);
        for (final r in <AgroRange>[
          t.moistureRaw,
          t.soilTemp,
          t.ph,
          t.ec,
          t.resistance,
          t.nSoilPpmRange!,
          t.pSoilPpmRange!,
          t.kSoilPpmRange!,
        ]) {
          expect(r.lowMax, lessThan(r.optimalMin), reason: 'etapa $stage');
          expect(r.optimalMin, lessThanOrEqualTo(r.optimalMax));
          expect(r.optimalMax, lessThan(r.highMin), reason: 'etapa $stage');
        }
      }
    });
  });

  // ── Pesos (Doc B §6) ───────────────────────────────────────────────────────
  group('StageWeights', () {
    test('cada etapa suma 1.00', () {
      for (final stage in _allStages) {
        expect(resolveAloeStageWeights(stage).sum, closeTo(1.0, 0.0001));
      }
    });

    test('un ajuste de perfil no rompe la suma', () {
      for (final profile in <String>[
        kSa01BroadleafRosette,
        kSa02SmallClumping,
        kSa03ShrubbyBranching,
        kSa04SpottedLandscape,
        kSaSkip,
      ]) {
        for (final stage in _allStages) {
          expect(
            resolveAloeStageWeights(stage, profileId: profile).sum,
            closeTo(1.0, 0.0001),
            reason: '$profile en $stage',
          );
        }
      }
    });

    test('la humedad es el mayor peso individual en toda etapa', () {
      for (final stage in _allStages) {
        final w = resolveAloeStageWeights(stage);
        for (final other in <double>[
          w.soilTemp,
          w.ph,
          w.ec,
          w.resistance,
          w.nutrientN,
          w.nutrientP,
          w.nutrientK,
        ]) {
          expect(w.moisture, greaterThanOrEqualTo(other), reason: stage);
        }
      }
    });

    test('el pH es el menor peso individual en toda etapa (Doc B §6)', () {
      for (final stage in _allStages) {
        final w = resolveAloeStageWeights(stage);
        for (final other in <double>[
          w.moisture,
          w.soilTemp,
          w.ec,
          w.resistance,
          w.nutrientN,
          w.nutrientP,
          w.nutrientK,
        ]) {
          expect(w.ph, lessThanOrEqualTo(other), reason: stage);
        }
      }
    });

    test('el NPK pesa más en crecimiento activo y menos en reposo', () {
      double npk(String stage) {
        final w = resolveAloeStageWeights(stage);
        return w.nutrientN + w.nutrientP + w.nutrientK;
      }

      final active = npk(AloeStageIds.activeGrowth);
      for (final stage in _allStages) {
        if (stage == AloeStageIds.activeGrowth) continue;
        expect(active, greaterThan(npk(stage)), reason: stage);
      }
      expect(
        npk(AloeStageIds.rest),
        lessThan(npk(AloeStageIds.maintenance)),
      );
    });

    test('la temperatura pesa más en reposo', () {
      final rest = resolveAloeStageWeights(AloeStageIds.rest).soilTemp;
      for (final stage in _allStages) {
        if (stage == AloeStageIds.rest) continue;
        expect(
          rest,
          greaterThanOrEqualTo(resolveAloeStageWeights(stage).soilTemp),
        );
      }
    });
  });

  // ── Bandas (Doc B §4) ──────────────────────────────────────────────────────
  group('Clasificación de bandas', () {
    AgroBand band(AgroMetricKey key, BioGTelemetry t, {String? stage}) {
      final out = _evaluate(t: t, stage: stage ?? AloeStageIds.maintenance);
      return out.eval.metrics[key]!.band;
    }

    test('humedad en estable: 10 crítico · 16 y 64 óptimo · 80 crítico', () {
      // Calibrado contra VWC real (sensor 0=aire, 100=agua): la sábila crece
      // mejor cerca de capacidad de campo; 60% ya NO es crítico (ver regresión).
      expect(
        band(AgroMetricKey.soilMoisture, _telemetry(moisture: 10)),
        AgroBand.critical,
      );
      expect(
        band(AgroMetricKey.soilMoisture, _telemetry(moisture: 16)),
        AgroBand.optimal,
      );
      expect(
        band(AgroMetricKey.soilMoisture, _telemetry(moisture: 64)),
        AgroBand.optimal,
      );
      expect(
        band(AgroMetricKey.soilMoisture, _telemetry(moisture: 80)),
        AgroBand.critical,
      );
    });

    test('REGRESIÓN: 60% de humedad en sábila estable es ÓPTIMO, no crítico', () {
      // El bug que reportó el usuario: 60% marcaba "CRÍTICO 60%".
      final out = _evaluate(t: _telemetry(moisture: 60));
      expect(
        out.eval.metrics[AgroMetricKey.soilMoisture]?.band,
        AgroBand.optimal,
        reason: '60% es humedad sana para la sábila, no una alarma',
      );
    });

    test('crecimiento activo admite más agua que el reposo', () {
      expect(
        band(
          AgroMetricKey.soilMoisture,
          _telemetry(moisture: 66),
          stage: AloeStageIds.activeGrowth,
        ),
        AgroBand.optimal,
      );
      expect(
        band(
          AgroMetricKey.soilMoisture,
          _telemetry(moisture: 72),
          stage: AloeStageIds.rest,
        ),
        AgroBand.critical,
      );
    });

    test('EC estable: 0.5 óptimo y 3.0 crítico (tolera más sal)', () {
      expect(band(AgroMetricKey.ec, _telemetry(ec: 0.5)), AgroBand.optimal);
      expect(band(AgroMetricKey.ec, _telemetry(ec: 3.0)), AgroBand.critical);
      // A 2.0 la sábila sigue en óptimo, donde la suculenta ya sería crítica.
      expect(band(AgroMetricKey.ec, _telemetry(ec: 2.0)), AgroBand.optimal);
    });

    test('las 5 métricas de suelo se clasifican (nunca "sin baseline")', () {
      final out = _evaluate(t: _telemetry());
      for (final key in <AgroMetricKey>[
        AgroMetricKey.soilMoisture,
        AgroMetricKey.soilTemp,
        AgroMetricKey.ph,
        AgroMetricKey.ec,
        AgroMetricKey.resistance,
      ]) {
        expect(out.eval.metrics[key]?.band, isNot(AgroBand.unknown));
      }
    });
  });

  // ── Motor compartido y alertas canónicas (§3.4 de la guía · Doc B §8) ──────
  group('El motor se comporta como el de frijol', () {
    test('NINGUNA clave de alerta empieza con aloe/sa/sabila/ornamental', () {
      final out = _evaluate(
        t: _telemetry(moisture: 95, soilTemp: 3, ec: 3.6, resistance: 2.6),
      );
      expect(out.eval.suggestedAlertKeys, isNotEmpty);
      for (final key in out.eval.suggestedAlertKeys) {
        expect(key.startsWith('aloe'), isFalse, reason: key);
        expect(key.startsWith('sa.'), isFalse, reason: key);
        expect(key.startsWith('sabila'), isFalse, reason: key);
        expect(key.startsWith('ornamental'), isFalse, reason: key);
      }
      expect(out.eval.suggestedAlertKeys, contains('soilMoisture.critical'));
    });

    test('una lectura mala SÍ produce alertas reales', () {
      final out = _evaluate(t: _telemetry(moisture: 95, soilTemp: 3, ec: 3.6));
      expect(out.eval.alerts, isNotEmpty);
      for (final a in out.eval.alerts) {
        expect(a.title.trim(), isNotEmpty);
        expect(a.body.trim(), isNotEmpty);
      }
    });

    test('N, P y K reciben interpretación (no se anulan)', () {
      final out = _evaluate(t: _telemetry());
      for (final key in <AgroMetricKey>[
        AgroMetricKey.n,
        AgroMetricKey.p,
        AgroMetricKey.k,
      ]) {
        final m = out.eval.metrics[key];
        expect(m?.priorityLabel, isNotNull, reason: '$key sin priorityLabel');
        expect(m!.priorityLabel, isNot(NutrientPriorityLabel.unknown));
      }
    });

    test('los caps NPK son propios: N=85 · P=65 · K=270', () {
      expect(
        NpkCaps.forCropMetric(cropKey: 'aloe', metricKey: AgroMetricKey.n),
        85.0,
      );
      expect(
        NpkCaps.forCropMetric(cropKey: 'aloe', metricKey: AgroMetricKey.p),
        65.0,
      );
      expect(
        NpkCaps.forCropMetric(cropKey: 'aloe', metricKey: AgroMetricKey.k),
        270.0,
      );
    });

    test('los caps NO se heredan de cactus ni suculenta', () {
      final n = NpkCaps.forCropMetric(cropKey: 'aloe', metricKey: AgroMetricKey.n);
      expect(
        n,
        isNot(NpkCaps.forCropMetric(cropKey: 'cactus', metricKey: AgroMetricKey.n)),
      );
      expect(
        n,
        isNot(
          NpkCaps.forCropMetric(cropKey: 'succulent', metricKey: AgroMetricKey.n),
        ),
      );
    });
  });

  // ── Agronomía propia (Doc B §8 y §0.5) ─────────────────────────────────────
  group('Agronomía de la sábila', () {
    test('el exceso de agua se castiga más que la sequía', () {
      final wet = _evaluate(t: _telemetry(moisture: 95));
      final dry = _evaluate(t: _telemetry(moisture: 2));
      expect(
        wet.eval.metrics[AgroMetricKey.soilMoisture]?.band,
        AgroBand.critical,
      );
      expect(
        wet.eval.soilControlScore01,
        lessThan(dry.eval.soilControlScore01),
      );
    });

    test('frío + humedad castiga más que el frío solo', () {
      final coldWet = _evaluate(t: _telemetry(moisture: 85, soilTemp: 5));
      final coldDry = _evaluate(t: _telemetry(moisture: 20, soilTemp: 5));
      expect(
        coldWet.eval.soilControlScore01,
        lessThan(coldDry.eval.soilControlScore01),
      );
    });

    test('un NPK bajo aislado NO tira el score a alerta', () {
      final healthy = _evaluate(t: _telemetry());
      final lowN = _evaluate(t: _telemetry(n: 2));
      expect(
        lowN.eval.soilControlScore01,
        greaterThan(0.6),
        reason: 'El agua y las sales mandan; un N bajo no cambia el veredicto',
      );
      expect(
        lowN.eval.metrics[AgroMetricKey.n]?.priorityLabel,
        isNotNull,
        reason: 'Pero SÍ conserva su banda y su prioridad',
      );
      expect(healthy.eval.soilControlScore01, greaterThan(0.6));
    });

    test('sa_02 castiga el exceso de agua más que sa_03', () {
      final small = _evaluate(
        t: _telemetry(moisture: 90),
        profileId: kSa02SmallClumping,
      );
      final shrubby = _evaluate(
        t: _telemetry(moisture: 90),
        profileId: kSa03ShrubbyBranching,
      );
      expect(
        small.eval.soilControlScore01,
        lessThan(shrubby.eval.soilControlScore01),
      );
    });

    test('sa_skip topa la prioridad NPK en "revisión"', () {
      final out = _evaluate(
        t: _telemetry(n: 1, p: 1, k: 5),
        profileId: kSaSkip,
      );
      for (final key in <AgroMetricKey>[
        AgroMetricKey.n,
        AgroMetricKey.p,
        AgroMetricKey.k,
      ]) {
        final label = out.eval.metrics[key]?.priorityLabel;
        expect(label, isNotNull);
        expect(
          label,
          isNot(NutrientPriorityLabel.actionRecommended),
          reason: 'Sin perfil confirmado no se escala a acción',
        );
        expect(label, isNot(NutrientPriorityLabel.highPriority));
      }
    });

    test('NO copia los targets del cactus ni de la suculenta', () {
      final aloe = resolveAloeTargets(AloeStageIds.maintenance);
      final ca = resolveCactusTargets(AloeStageIds.maintenance);
      final su = resolveSucculentTargets(AloeStageIds.maintenance);
      // Banda hídrica más húmeda que ambas (Doc B §4.1).
      expect(aloe.moistureRaw.optimalMin, greaterThan(ca.moistureRaw.optimalMin));
      expect(aloe.moistureRaw.optimalMin, greaterThan(su.moistureRaw.optimalMin));
      // Tolera más sal: banda EC más amplia que la suculenta (Doc B §4.4).
      expect(aloe.ec.highMin, greaterThan(su.ec.highMin));
    });
  });

  // ── Ciclo de vida (Doc A §5) ───────────────────────────────────────────────
  group('Progresión de vida (una sola pasada, sin reinicio)', () {
    final now = DateTime(2026, 7, 18);

    AloeStageEstimate at(int days) => estimateAloeStageFromDate(
      plantingDate: now.subtract(Duration(days: days)),
      now: now,
      profileId: kSa01BroadleafRosette,
    );

    test('ventanas: 0-14 · 15-84 · 85-365 · >365', () {
      expect(at(1).stageId, AloeStageIds.installationEstablishment);
      expect(at(14).stageId, AloeStageIds.installationEstablishment);
      expect(at(15).stageId, AloeStageIds.rootEstablishment);
      expect(at(84).stageId, AloeStageIds.rootEstablishment);
      expect(at(85).stageId, AloeStageIds.activeGrowth);
      expect(at(365).stageId, AloeStageIds.activeGrowth);
      expect(at(366).stageId, AloeStageIds.maintenance);
    });

    test('TODAS las etapas declaradas son alcanzables', () {
      final reachable = <String>{
        at(1).stageId,
        at(40).stageId,
        at(200).stageId,
        at(500).stageId,
      };
      expect(reachable, containsAll(<String>[
        AloeStageIds.installationEstablishment,
        AloeStageIds.rootEstablishment,
        AloeStageIds.activeGrowth,
        AloeStageIds.maintenance,
      ]));
      expect(
        aloeAllowedStageTransitions[AloeStageIds.maintenance],
        contains(AloeStageIds.rest),
      );
      expect(normalizeAloeStageId(null), AloeStageIds.unknown);
    });

    test('ESTABLE ES PARA SIEMPRE: a 1, 5 y 20 años sigue estable', () {
      for (final years in <int>[1, 5, 20]) {
        expect(at(365 * years + 2).stageId, AloeStageIds.maintenance);
      }
    });

    test('ninguna etapa vuelve a "Recién plantada"', () {
      for (final from in <String>[
        AloeStageIds.rootEstablishment,
        AloeStageIds.activeGrowth,
        AloeStageIds.maintenance,
        AloeStageIds.rest,
      ]) {
        expect(
          isAllowedAloeStageTransition(
            from,
            AloeStageIds.installationEstablishment,
          ),
          isFalse,
          reason: '$from no puede reiniciar la vida de la planta',
        );
      }
    });

    test('maintenance no cierra el ciclo, pero puede volver a crecer', () {
      expect(
        isAllowedAloeStageTransition(
          AloeStageIds.maintenance,
          AloeStageIds.activeGrowth,
        ),
        isTrue,
      );
      expect(
        isAllowedAloeStageTransition(
          AloeStageIds.maintenance,
          AloeStageIds.rest,
        ),
        isTrue,
      );
    });

    test('el reposo NO se infiere por fecha (solo por confirmación)', () {
      for (var d = 0; d <= 500; d += 7) {
        expect(at(d).stageId, isNot(AloeStageIds.rest));
      }
    });

    test('estrés, recuperación y declive NO son etapas', () {
      for (final fake in <String>['stress', 'recovery', 'rot', 'decline']) {
        expect(normalizeAloeStageId(fake), AloeStageIds.unknown);
      }
      expect(AloeStageIds.all, hasLength(6));
    });

    test('sin rendimiento, sin cosecha, sin microciclo, sin memoria', () {
      expect(AloeLifecycle.supportsYieldProjection, isFalse);
      expect(AloeLifecycle.supportsHarvest, isFalse);
      expect(AloeLifecycle.supportsRecurringBloom, isFalse);
      expect(AloeLifecycle.supportsHydricCycle, isFalse);
      expect(AloeLifecycle.supportsStressMemory, isFalse);
      expect(AloeLifecycle.lifecycleMode, 'establishment_maintenance');
    });
  });

  // ── Wizard (Doc A §6) ──────────────────────────────────────────────────────
  group('Wizard: la etapa corresponde con lo que eligió el usuario', () {
    final now = DateTime(2026, 7, 18);

    test('solo dos intenciones: plantar / ya plantada', () {
      expect(AloeSetupIntentIds.all, hasLength(2));
      expect(
        normalizeAloeSetupIntentId('repot'),
        AloeSetupIntentIds.alreadyPlanted,
      );
      expect(
        aloeSetupIntentRequiresFutureDate(AloeSetupIntentIds.plannedPlant),
        isTrue,
      );
      expect(
        aloeSetupIntentRequiresFutureDate(AloeSetupIntentIds.alreadyPlanted),
        isFalse,
      );
    });

    test('"la voy a plantar" → Recién plantada', () {
      final e = resolveAloeSetupStage(
        intentId: AloeSetupIntentIds.plannedPlant,
        plantingDate: now.add(const Duration(days: 5)),
        now: now,
      );
      expect(e.stageId, AloeStageIds.installationEstablishment);
    });

    test('"ya está plantada" sin fecha → Estable (nunca "por confirmar")', () {
      final e = resolveAloeSetupStage(
        intentId: AloeSetupIntentIds.alreadyPlanted,
        plantingDate: null,
        now: now,
      );
      expect(e.stageId, AloeStageIds.maintenance);
      expect(e.stageId, isNot(AloeStageIds.unknown));
    });

    test('"ya está plantada" hace 30 días → Echando raíz', () {
      final e = resolveAloeSetupStage(
        intentId: AloeSetupIntentIds.alreadyPlanted,
        plantingDate: now.subtract(const Duration(days: 30)),
        now: now,
      );
      expect(e.stageId, AloeStageIds.rootEstablishment);
    });

    test('una etapa ya confirmada por el usuario se respeta', () {
      final e = resolveAloeSetupStage(
        intentId: AloeSetupIntentIds.alreadyPlanted,
        plantingDate: DateTime(2021, 3, 1),
        now: now,
        previousStageId: AloeStageIds.rest,
      );
      expect(e.stageId, AloeStageIds.rest);
    });
  });

  // ── Runtime: el resolver alimenta las pantallas ────────────────────────────
  group('AloeStageResolver alimenta las pantallas', () {
    DeviceCropContext context({
      DateTime? anchor,
      String? storedStage,
      CropLifecycleStatus status = CropLifecycleStatus.planted,
      String profileId = kSa01BroadleafRosette,
    }) {
      return DeviceCropContext(
        deviceId: 'dev-1',
        cropCategoryId: CropCatalog.ornamentalCategoryId,
        cropId: CropCatalog.aloeCropId,
        profileId: profileId,
        lifecycleStatus: status,
        sowingDateConfidence: DateConfidence.estimated,
        catalogVersion: 'v1',
        source: CropConfigSource.wizard,
        configuredAt: DateTime(2026, 7, 18),
        updatedAt: DateTime(2026, 7, 18),
        ornamentalStageId: storedStage,
        ornamentalAnchorDate: anchor,
      );
    }

    test('plantada el 8 de mayo → Echando raíz, con el día real', () {
      final result = AloeStageResolver.resolve(
        context: context(anchor: DateTime(2026, 5, 8)),
        today: DateTime(2026, 7, 18),
      );
      expect(result.stageKey, AloeStageIds.rootEstablishment);
      expect(result.stageLabelEs, 'Echando raíz');
      expect(result.daySinceSowing, 71);
    });

    test('un contexto guardado con "unknown" se AUTO-REPARA', () {
      final result = AloeStageResolver.resolve(
        context: context(
          anchor: DateTime(2026, 5, 8),
          storedStage: AloeStageIds.unknown,
        ),
        today: DateTime(2026, 7, 18),
      );
      expect(result.stageKey, AloeStageIds.rootEstablishment);
    });

    test('no tiene día terminal de ciclo', () {
      final result = AloeStageResolver.resolve(
        context: context(anchor: DateTime(2020, 1, 1)),
        today: DateTime(2026, 7, 18),
      );
      expect(result.stageKey, AloeStageIds.maintenance);
      expect(result.expectedDaysToEnd, 0);
      expect(result.windowsNow, isEmpty);
      expect(result.stageProgressPct, isNull);
      expect(result.productiveState, isNull);
    });

    test('el runtime ornamental resuelve por MODO, no por cactus', () {
      expect(
        isEstablishmentMaintenanceCrop(cropId: CropCatalog.aloeCropId),
        isTrue,
      );
      expect(
        isEstablishmentMaintenanceCrop(cropId: CropCatalog.cactusCropId),
        isTrue,
      );
      expect(
        isEstablishmentMaintenanceCrop(cropId: CropCatalog.succulentCropId),
        isTrue,
      );
      expect(isEstablishmentMaintenanceCrop(cropId: 'bean'), isFalse);

      final result = resolveOrnamentalStageResult(
        context: context(anchor: DateTime(2026, 5, 8)),
        today: DateTime(2026, 7, 18),
      );
      expect(result.stageKey, AloeStageIds.rootEstablishment);
      // El despacho por cropId NO cae en cactus: el nombre visible es "Sábila".
      expect(ornamentalCropDisplayName(CropCatalog.aloeCropId), 'Sábila');
    });
  });

  // ── Persistencia (Doc A §7) ────────────────────────────────────────────────
  group('Persistencia', () {
    DeviceCropContext ctx(String profileId, {String? varietyId, String? alias}) {
      return DeviceCropContext(
        deviceId: 'dev-1',
        cropCategoryId: 'ornamental',
        cropId: 'crop_aloe',
        profileId: profileId,
        varietyId: varietyId,
        varietyAlias: alias,
        lifecycleStatus: CropLifecycleStatus.planted,
        sowingDateConfidence: DateConfidence.estimated,
        catalogVersion: 'v1',
        source: CropConfigSource.wizard,
        configuredAt: DateTime(2026, 7, 18),
        updatedAt: DateTime(2026, 7, 18),
        ornamentalStageId: AloeStageIds.activeGrowth,
        ornamentalAnchorDate: DateTime(2026, 3, 1),
      );
    }

    test('un roundtrip conserva el perfil específico', () {
      final restored = DeviceCropContext.fromJson(
        ctx(kSa03ShrubbyBranching).toJson(),
      );
      expect(restored.cropId, 'crop_aloe');
      expect(restored.profileId, kSa03ShrubbyBranching);
      expect(restored.ornamentalStageId, AloeStageIds.activeGrowth);
      expect(restored.ornamentalAnchorDate, DateTime(2026, 3, 1));
      expect(restored.sowingDate, isNull, reason: 'No se siembra');
    });

    test('un sa_skip heredado NO pisa una selección específica viva', () {
      final restored = DeviceCropContext.fromJson(
        ctx(kSaSkip, varietyId: kSa01BroadleafRosette).toJson(),
      );
      expect(restored.profileId, kSa01BroadleafRosette);
    });

    test('el alias visible nunca expone el id interno ni "SKIP"', () {
      final restored = DeviceCropContext.fromJson(
        ctx(kSa04SpottedLandscape, alias: 'sa_04').toJson(),
      );
      expect(restored.varietyAlias, 'Sábila moteada de jardín');
      expect(restored.varietyAlias!.toLowerCase(), isNot(contains('skip')));
      expect(restored.varietyAlias!.toLowerCase(), isNot(contains('sa_')));
    });
  });

  // ── Identidad y catálogo (Doc A §3, §11) ───────────────────────────────────
  group('Identidad del cultivo', () {
    test('crop_aloe está en el catálogo y en el registry', () {
      final entry = CropCatalog.cropById(CropCatalog.aloeCropId);
      expect(entry, isNotNull);
      expect(entry!.categoryId, CropCatalog.ornamentalCategoryId);
      expect(entry.enabled, isTrue);
      expect(entry.label, 'Sábila');

      final definition = CropRegistry.byKey(CropKey.aloe);
      expect(definition, isA<AloeCropDefinition>());
      expect(definition!.displayName, 'Sábila');
      expect(definition.category, CropCategory.ornamental);
    });

    test('crop_aloe resuelve CropKey.aloe desde el registry por nombre', () {
      for (final alias in <String>[
        'crop_aloe',
        'aloe',
        'sabila',
        'sábila',
        'aloe vera',
      ]) {
        expect(CropRegistry.byKeyName(alias), isA<AloeCropDefinition>());
      }
    });

    test('los alias humanos resuelven a sábila, no a suculenta ni cactus', () {
      for (final alias in <String>['sábila', 'aloe', 'crop_aloe', 'aloe vera']) {
        expect(CropCatalog.canonicalCropKey(alias), CropCatalog.aloeCropId);
        expect(
          CropCatalog.canonicalCropKey(alias),
          isNot(CropCatalog.succulentCropId),
        );
        expect(
          CropCatalog.canonicalCropKey(alias),
          isNot(CropCatalog.cactusCropId),
        );
      }
    });

    test('4 perfiles específicos + el general AL FINAL', () {
      final profiles = CropCatalog.profilesForCrop(
        CropCatalog.aloeCropId,
        enabledOnly: false,
      );
      expect(profiles, hasLength(5));
      expect(profiles.last.id, kSaSkip);
      expect(profiles.first.id, isNot(kSaSkip));
    });

    test('prefijo SA; ningún id usa SV ni orn_; el general nunca dice "SKIP"', () {
      for (final p in aloeProfileEntries) {
        expect(p.id.startsWith('sv_'), isFalse);
        expect(p.id.startsWith('orn_'), isFalse);
        expect(p.id.startsWith('sa'), isTrue);
        expect(p.label.toLowerCase(), isNot(contains('skip')));
      }
      expect(kAloeProfilePrefix, 'SA');
    });

    test('no existe perfil "chinensis", "premium" ni "exterior seco"', () {
      for (final p in aloeProfileEntries) {
        final l = p.label.toLowerCase();
        expect(l, isNot(contains('chinensis')));
        expect(l, isNot(contains('premium')));
        expect(l, isNot(contains('miller')));
      }
    });

    test('los aliases mapean a los perfiles correctos', () {
      String? resolve(String alias) =>
          CropCatalog.profileByAny(CropCatalog.aloeCropId, alias)?.id;

      expect(resolve('Aloe barbadensis'), kSa01BroadleafRosette);
      expect(resolve('barbadensis miller'), kSa01BroadleafRosette);
      expect(resolve('Aloe arborescens'), kSa03ShrubbyBranching);
      expect(resolve('sábila pulpo'), kSa03ShrubbyBranching);
      expect(resolve('Aloe saponaria'), kSa04SpottedLandscape);
      expect(resolve('Aloe brevifolia'), kSa02SmallClumping);
    });

    test('maguey, nopal, cactus y suculenta se redirigen (no son perfiles SA)', () {
      expect(isAloeAgaveAlias('maguey'), isTrue);
      expect(isAloeAgaveAlias('agave'), isTrue);
      expect(isAloeNopalAlias('nopal'), isTrue);
      expect(isAloeCactusAlias('cactus'), isTrue);
      expect(isAloeSucculentAlias('suculenta'), isTrue);
      expect(isAloeRedirectAlias('maguey'), isTrue);
      for (final alias in <String>['maguey', 'nopal', 'cactus', 'suculenta']) {
        expect(
          CropCatalog.profileByAny(CropCatalog.aloeCropId, alias),
          isNull,
          reason: '"$alias" no debe resolver a un perfil de sábila',
        );
      }
    });

    test('la redirección de suculenta manda la sábila a crop_aloe', () {
      for (final alias in <String>[
        'aloe arborescens',
        'aloe maculata',
        'sábila pulpo',
        'zábila',
      ]) {
        expect(isSucculentAloeAlias(alias), isTrue, reason: alias);
        expect(isSucculentRedirectAlias(alias), isTrue, reason: alias);
      }
    });
  });

  // ── Lenguaje de agricultor (§3.7 de la guía) ──────────────────────────────
  group('Lenguaje de agricultor', () {
    test('las etapas se llaman en cristiano', () {
      expect(
        aloeStageDisplayName(AloeStageIds.installationEstablishment),
        'Recién plantada',
      );
      expect(aloeStageDisplayName(AloeStageIds.maintenance), 'Estable');
      expect(aloeStageDisplayName(AloeStageIds.rest), 'En reposo');
    });

    test('ningún texto usa la jerga prohibida', () {
      const forbidden = <String>[
        'baseline',
        'comparable',
        'no accionable',
        'electroconductividad',
        'microciclo',
        'orientativa',
        'etapa fenológica',
        'ornamental',
        'cam',
        'skip',
      ];

      final texts = <String>[
        for (final s in _allStages) ...<String>[
          aloeStageDisplayName(s),
          aloeStageCareNoteEs(s),
          aloeStagePriorityText(s),
          aloeCriticalWindowLabel(s) ?? '',
        ],
        for (final p in aloeProfileEntries) ...<String>[
          p.label,
          p.subtitle ?? '',
        ],
      ];

      for (final text in texts) {
        final lower = text.toLowerCase();
        for (final word in forbidden) {
          final hit = word == 'cam'
              ? RegExp(r'\bcam\b').hasMatch(lower)
              : lower.contains(word);
          expect(hit, isFalse, reason: '"$text" no debe decir "$word"');
        }
      }
    });

    test('ningún texto promete tolerancia a helada ni cobertura de mercado', () {
      final texts = <String>[
        for (final p in aloeProfileEntries) p.subtitle ?? '',
        for (final s in _allStages) aloeStageCareNoteEs(s),
      ];
      for (final t in texts) {
        final lower = t.toLowerCase();
        expect(lower, isNot(contains('helada')));
        expect(lower, isNot(contains('%')));
      }
    });
  });

  // ── Sanidad (Doc C §6, §14) ────────────────────────────────────────────────
  group('Sanidad', () {
    test('crop_aloe está registrado en PlantHealthRegistry con 13 síndromes', () {
      expect(PlantHealthRegistry.isSupportedCrop('crop_aloe'), isTrue);
      expect(
        PlantHealthRegistry.catalogForCrop('crop_aloe'),
        same(aloeSyndromes),
      );
      // 14 síndromes del Doc C menos SA-SYN-010 (perforaciones), diferido en v1.
      expect(aloeSyndromes, hasLength(13));
    });

    test('SA-SYN-010 (perforaciones) NO está en v1', () {
      for (final s in aloeSyndromes) {
        expect(s.id.contains('boring'), isFalse);
        expect(s.id.contains('puncture'), isFalse);
      }
    });

    test('el aporte exclusivo (ácaro de agalla) SÍ está', () {
      final gall = aloeSyndromes.where(
        (s) => s.id == 'aloe_warty_gall_distortion_01',
      );
      expect(gall, hasLength(1));
    });

    test('el adaptador traduce TODAS las etapas del modo', () {
      for (final stage in <String>[
        AloeStageIds.installationEstablishment,
        AloeStageIds.rootEstablishment,
        AloeStageIds.activeGrowth,
        AloeStageIds.maintenance,
        AloeStageIds.rest,
      ]) {
        expect(
          PlantHealthStageAdapter.fromCropStage(
            cropId: 'crop_aloe',
            stageKey: stage,
            daySinceSowing: null,
          ),
          isA<PlantHealthStageBucket>(),
          reason: 'la etapa $stage debe mapear a un bucket',
        );
      }
    });

    test('ids únicos, disclaimer y 2-4 preguntas por síndrome', () {
      final ids = <String>{};
      for (final s in aloeSyndromes) {
        expect(ids.add(s.id), isTrue, reason: 'id duplicado: ${s.id}');
        expect(s.cropId, CropCatalog.aloeCropId);
        expect(s.disclaimerEs.trim(), isNotEmpty);
        expect(s.confirmationChecksEs.length, inInclusiveRange(2, 4));
        expect(s.baseActionsEs, isNotEmpty);
      }
    });

    test('ningún síndrome diagnostica un patógeno ni receta un producto', () {
      const forbidden = <String>[
        'fusarium',
        'pythium',
        'phytophthora',
        'erwinia',
        'botrytis',
        'aceria',
        'fungicida',
        'insecticida',
        'ml',
        'dosis',
        'fumiga',
        'tiene pudrición',
        'es un hongo',
        'se recuperará',
      ];
      final texts = <String>[
        for (final s in aloeSyndromes) ...<String>[
          s.labelEs,
          s.disclaimerEs,
          ...s.confirmationChecksEs,
          ...s.baseActionsEs,
          for (final d in s.probableDiagnoses) ...<String>[
            d.labelEs,
            d.summaryEs,
            d.scientificName,
          ],
        ],
      ];
      for (final t in texts) {
        final lower = ' ${t.toLowerCase()} ';
        for (final word in forbidden) {
          expect(
            lower.contains(word == 'ml' ? ' ml ' : word),
            isFalse,
            reason: '"$t" contiene "$word"',
          );
        }
      }
    });

    test('ningún id de síndrome se usa como clave del AlertsEngine', () {
      final out = _evaluate(t: _telemetry(moisture: 95, ec: 3.4));
      for (final s in aloeSyndromes) {
        expect(out.eval.suggestedAlertKeys, isNot(contains(s.id)));
      }
    });

    test('el sensor por sí solo no genera un cuadro sanitario alto', () {
      for (final s in aloeSyndromes) {
        if (s.severity == PlantHealthSeverity.high) {
          expect(s.primarySymptomId.trim(), isNotEmpty);
          expect(s.strongSignals, isNotEmpty);
        }
      }
    });

    test('toda etiqueta humana existe (nunca se muestra el id crudo)', () {
      for (final s in aloeSyndromes) {
        expect(
          PlantHealthIds.symptomLabel(s.primarySymptomId),
          isNot(s.primarySymptomId),
          reason: 'falta la etiqueta humana de ${s.primarySymptomId}',
        );
        for (final signal in <String>{
          ...s.strongSignals,
          ...s.weakSignals,
          ...s.conflictingSignals,
        }) {
          expect(
            PlantHealthIds.signalLabel(signal),
            isNot(signal),
            reason: 'falta la etiqueta humana de $signal',
          );
        }
      }
    });
  });

  // ── No romper lo que ya existía ────────────────────────────────────────────
  group('Cactus y suculenta siguen intactos', () {
    test('cactus conserva su perfil general y sus caps', () {
      expect(
        NpkCaps.forCropMetric(cropKey: 'cactus', metricKey: AgroMetricKey.n),
        60.0,
      );
      expect(
        NpkCaps.forCropMetric(cropKey: 'cactus', metricKey: AgroMetricKey.k),
        220.0,
      );
      expect(CropCatalog.canonicalCropKey('cactus'), CropCatalog.cactusCropId);
    });

    test('suculenta conserva sus caps', () {
      expect(
        NpkCaps.forCropMetric(cropKey: 'succulent', metricKey: AgroMetricKey.n),
        70.0,
      );
      expect(
        NpkCaps.forCropMetric(cropKey: 'succulent', metricKey: AgroMetricKey.k),
        240.0,
      );
    });

    test('la categoría ornamental expone cactus, suculenta y sábila', () {
      final crops = CropCatalog.cropsByCategory(
        CropCatalog.ornamentalCategoryId,
        enabledOnly: true,
      ).map((c) => c.cropId).toList();
      expect(crops, containsAll(<String>[
        CropCatalog.cactusCropId,
        CropCatalog.succulentCropId,
        CropCatalog.aloeCropId,
      ]));
    });
  });
}
