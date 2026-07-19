// test/core/succulent/succulent_integration_test.dart
//
// Contratos de la integración de Suculenta (segunda ornamental de BIO-G).
//
// Regla que estas pruebas blindan: LA SUCULENTA SE COMPORTA COMO FRIJOL.
// Mismas unidades, mismas bandas, mismas claves de alerta, mismo motor de
// nutrición. Lo único distinto es que NO es cíclica (establecimiento →
// mantenimiento, sin cosecha ni rendimiento), igual que el cactus y el árbol.
//
// Y la regla que blinda al CACTUS: se copia su arquitectura, NO sus números.

import 'package:flutter_test/flutter_test.dart';

import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/agro/npk_caps.dart';
import 'package:bio_g/core/crops/cactus/cactus_catalog.dart';
import 'package:bio_g/core/crops/cactus/cactus_universal_profile.dart';
import 'package:bio_g/core/crops/catalog/crop_catalog.dart';
import 'package:bio_g/core/crops/crop_registry.dart';
import 'package:bio_g/core/crops/crop_types.dart';
import 'package:bio_g/core/crops/ornamental/ornamental_crops.dart';
import 'package:bio_g/core/crops/succulent/succulent_agro_score_engine.dart';
import 'package:bio_g/core/crops/succulent/succulent_catalog.dart';
import 'package:bio_g/core/crops/succulent/succulent_crop_definition.dart';
import 'package:bio_g/core/crops/succulent/succulent_lifecycle.dart';
import 'package:bio_g/core/crops/succulent/succulent_stage_resolver.dart';
import 'package:bio_g/core/crops/succulent/succulent_universal_profile.dart';
import 'package:bio_g/core/plant_health/catalog/succulent_syndromes.dart';
import 'package:bio_g/core/plant_health/plant_health_ids.dart';
import 'package:bio_g/core/plant_health/plant_health_models.dart';
import 'package:bio_g/core/plant_health/plant_health_registry.dart';
import 'package:bio_g/core/plant_health/plant_health_stage_adapter.dart';
import 'package:bio_g/core/plant_health/plant_health_stage_bucket.dart';
import 'package:bio_g/models/biog_telemetry.dart';
import 'package:bio_g/models/device_crop_context.dart';

const List<String> _allStages = <String>[
  SucculentStageIds.installationEstablishment,
  SucculentStageIds.rootEstablishment,
  SucculentStageIds.activeGrowth,
  SucculentStageIds.maintenance,
  SucculentStageIds.rest,
  SucculentStageIds.unknown,
];

BioGTelemetry _telemetry({
  double moisture = 24,
  double soilTemp = 24,
  double ph = 6.2,
  double ec = 0.8,
  double resistance = 0.6,
  double n = 24,
  double p = 18,
  double k = 110,
  double airTemp = 26,
  double airHumidity = 45,
}) {
  return BioGTelemetry(
    deviceId: 'dev-succulent',
    timestamp: DateTime(2026, 7, 13, 9),
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
  String stage = SucculentStageIds.maintenance,
  String? profileId,
}) {
  return SucculentAgroScoreEngine.evaluate(
    t: t,
    stageId: stage,
    stageLabelEs: succulentStageDisplayName(stage),
    targets: resolveSucculentTargets(stage),
    weights: resolveSucculentStageWeights(stage, profileId: profileId),
    cropLabel: 'Suculenta',
    profileId: profileId,
  );
}

void main() {
  // ── Contrato de unidades (§3.1 de la guía · Doc B §3) ──────────────────────
  group('Unidades reales', () {
    test('EC en mS/cm, no un índice comparable', () {
      for (final stage in _allStages) {
        final ec = resolveSucculentTargets(stage).ec;
        expect(ec.highMin, lessThan(5), reason: 'EC de $stage debe ser mS/cm');
        expect(ec.optimalMin, greaterThan(0));
      }
    });

    test('resistencia en MPa (highMin <= 2.0)', () {
      for (final stage in _allStages) {
        final r = resolveSucculentTargets(stage).resistance;
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
        final t = resolveSucculentTargets(stage);
        expect(t.nSoilPpmRange, isNotNull);
        expect(t.pSoilPpmRange, isNotNull);
        expect(t.kSoilPpmRange, isNotNull);
        expect(t.nSoilPpmRange!.optimalMax, lessThanOrEqualTo(45));
        expect(
          t.kSoilPpmRange!.optimalMax,
          greaterThan(t.nSoilPpmRange!.optimalMax),
        );
      }
    });

    test('todos los rangos cumplen lowMax < optMin <= optMax < highMin', () {
      for (final stage in _allStages) {
        final t = resolveSucculentTargets(stage);
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
        expect(resolveSucculentStageWeights(stage).sum, closeTo(1.0, 0.0001));
      }
    });

    test('un ajuste de perfil no rompe la suma', () {
      for (final profile in <String>[
        kSu01RosetteBrightLight,
        kSu02TrailingCascading,
        kSu03BranchingWoody,
        kSu04CompactFilteredLight,
        kSuSkip,
      ]) {
        for (final stage in _allStages) {
          expect(
            resolveSucculentStageWeights(stage, profileId: profile).sum,
            closeTo(1.0, 0.0001),
            reason: '$profile en $stage',
          );
        }
      }
    });

    test('la humedad es el mayor peso individual en toda etapa', () {
      for (final stage in _allStages) {
        final w = resolveSucculentStageWeights(stage);
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

    test('el NPK pesa más en crecimiento activo y menos en reposo', () {
      double npk(String stage) {
        final w = resolveSucculentStageWeights(stage);
        return w.nutrientN + w.nutrientP + w.nutrientK;
      }

      final active = npk(SucculentStageIds.activeGrowth);
      for (final stage in _allStages) {
        if (stage == SucculentStageIds.activeGrowth) continue;
        expect(active, greaterThan(npk(stage)), reason: stage);
      }
      expect(npk(SucculentStageIds.rest), lessThan(npk(SucculentStageIds.maintenance)));
    });

    test('la temperatura pesa más en reposo', () {
      final rest = resolveSucculentStageWeights(SucculentStageIds.rest).soilTemp;
      for (final stage in _allStages) {
        if (stage == SucculentStageIds.rest) continue;
        expect(
          rest,
          greaterThanOrEqualTo(resolveSucculentStageWeights(stage).soilTemp),
        );
      }
    });
  });

  // ── Bandas (Doc B §16: T14-T20, T26-T28, T30-T32, T35-T38) ─────────────────
  group('Clasificación de bandas', () {
    AgroBand band(AgroMetricKey key, BioGTelemetry t, {String? stage}) {
      final out = _evaluate(
        t: t,
        stage: stage ?? SucculentStageIds.maintenance,
      );
      return out.eval.metrics[key]!.band;
    }

    test('humedad en estable: 8 crítico · 14 y 58 óptimo · 76 crítico', () {
      // Recalibrado contra VWC real del sensor (0=aire, 100=agua): 60% ya no
      // es crítico para una suculenta; es humedad alta (aviso suave).
      expect(
        band(AgroMetricKey.soilMoisture, _telemetry(moisture: 8)),
        AgroBand.critical,
      );
      expect(
        band(AgroMetricKey.soilMoisture, _telemetry(moisture: 14)),
        AgroBand.optimal,
      );
      expect(
        band(AgroMetricKey.soilMoisture, _telemetry(moisture: 58)),
        AgroBand.optimal,
      );
      expect(
        band(AgroMetricKey.soilMoisture, _telemetry(moisture: 76)),
        AgroBand.critical,
      );
    });

    test('REGRESIÓN: 60% en suculenta estable es "alto", no crítico', () {
      expect(
        band(AgroMetricKey.soilMoisture, _telemetry(moisture: 60)),
        AgroBand.high,
        reason: '60% es humedad alta (aviso), no una alarma de exceso',
      );
    });

    test('crecimiento activo admite más agua que el reposo', () {
      expect(
        band(
          AgroMetricKey.soilMoisture,
          _telemetry(moisture: 60),
          stage: SucculentStageIds.activeGrowth,
        ),
        AgroBand.optimal,
      );
      expect(
        band(
          AgroMetricKey.soilMoisture,
          _telemetry(moisture: 70),
          stage: SucculentStageIds.rest,
        ),
        AgroBand.critical,
      );
    });

    test('temperatura: 18 óptimo y 10 crítico en crecimiento', () {
      expect(
        band(
          AgroMetricKey.soilTemp,
          _telemetry(soilTemp: 18),
          stage: SucculentStageIds.activeGrowth,
        ),
        AgroBand.optimal,
      );
      expect(
        band(
          AgroMetricKey.soilTemp,
          _telemetry(soilTemp: 10),
          stage: SucculentStageIds.activeGrowth,
        ),
        AgroBand.critical,
      );
    });

    test('EC: 0.4 óptimo y 2.0 crítico en estable', () {
      expect(band(AgroMetricKey.ec, _telemetry(ec: 0.4)), AgroBand.optimal);
      expect(band(AgroMetricKey.ec, _telemetry(ec: 2.0)), AgroBand.critical);
    });

    test('resistencia: 0.0 MPa óptimo y 2.0 MPa crítico en estable', () {
      expect(
        band(AgroMetricKey.resistance, _telemetry(resistance: 0.0)),
        AgroBand.optimal,
      );
      expect(
        band(AgroMetricKey.resistance, _telemetry(resistance: 2.0)),
        AgroBand.critical,
      );
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

  // ── Motor compartido y alertas canónicas (§3.4 de la guía · Doc B §12) ─────
  group('El motor se comporta como el de frijol', () {
    test('NINGUNA clave de alerta empieza con succulent/su/ornamental', () {
      final out = _evaluate(
        t: _telemetry(moisture: 95, soilTemp: 3, ec: 3.5, resistance: 2.6),
      );
      expect(out.eval.suggestedAlertKeys, isNotEmpty);
      for (final key in out.eval.suggestedAlertKeys) {
        expect(key.startsWith('succulent'), isFalse, reason: key);
        expect(key.startsWith('su.'), isFalse, reason: key);
        expect(key.startsWith('ornamental'), isFalse, reason: key);
      }
      expect(out.eval.suggestedAlertKeys, contains('soilMoisture.critical'));
    });

    test('una lectura mala SÍ produce alertas reales', () {
      final out = _evaluate(t: _telemetry(moisture: 95, soilTemp: 3, ec: 3.5));
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

    test('los caps NPK son propios: N=70 · P=60 · K=240', () {
      expect(
        NpkCaps.forCropMetric(cropKey: 'succulent', metricKey: AgroMetricKey.n),
        70.0,
      );
      expect(
        NpkCaps.forCropMetric(cropKey: 'succulent', metricKey: AgroMetricKey.p),
        60.0,
      );
      expect(
        NpkCaps.forCropMetric(cropKey: 'succulent', metricKey: AgroMetricKey.k),
        240.0,
      );
    });

    test('los caps NO se heredan del cactus', () {
      expect(
        NpkCaps.forCropMetric(cropKey: 'succulent', metricKey: AgroMetricKey.n),
        isNot(
          NpkCaps.forCropMetric(cropKey: 'cactus', metricKey: AgroMetricKey.n),
        ),
      );
    });
  });

  // ── Agronomía propia (Doc B §8 y §20) ──────────────────────────────────────
  group('Agronomía de la suculenta', () {
    test('el exceso de agua se castiga más que la sequía', () {
      final wet = _evaluate(t: _telemetry(moisture: 95));
      final dry = _evaluate(t: _telemetry(moisture: 2));
      expect(
        wet.eval.metrics[AgroMetricKey.soilMoisture]?.band,
        AgroBand.critical,
      );
      expect(wet.eval.soilControlScore01, lessThan(dry.eval.soilControlScore01));
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

    test('su_04 castiga el exceso de agua más que su_03', () {
      final compact = _evaluate(
        t: _telemetry(moisture: 90),
        profileId: kSu04CompactFilteredLight,
      );
      final jade = _evaluate(
        t: _telemetry(moisture: 90),
        profileId: kSu03BranchingWoody,
      );
      expect(
        compact.eval.soilControlScore01,
        lessThan(jade.eval.soilControlScore01),
      );
    });

    test('su_skip topa la prioridad NPK en "revisión"', () {
      final out = _evaluate(
        t: _telemetry(n: 1, p: 1, k: 5),
        profileId: kSuSkip,
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

    test('NO copia los targets del cactus (banda hídrica distinta)', () {
      final su = resolveSucculentTargets(SucculentStageIds.maintenance);
      final ca = resolveCactusTargets(SucculentStageIds.maintenance);
      expect(
        su.moistureRaw.optimalMin,
        greaterThan(ca.moistureRaw.optimalMin),
        reason: 'La suculenta usa una banda más húmeda que el cactus',
      );
      expect(su.ec.highMin, isNot(ca.ec.highMin));
    });
  });

  // ── Ciclo de vida (Doc A §5) ───────────────────────────────────────────────
  group('Progresión de vida (una sola pasada, sin reinicio)', () {
    final now = DateTime(2026, 7, 13);

    SucculentStageEstimate at(int days) => estimateSucculentStageFromDate(
      plantingDate: now.subtract(Duration(days: days)),
      now: now,
      profileId: kSu01RosetteBrightLight,
    );

    test('ventanas: 0-14 · 15-56 · 57-270 · >270', () {
      expect(at(1).stageId, SucculentStageIds.installationEstablishment);
      expect(at(14).stageId, SucculentStageIds.installationEstablishment);
      expect(at(15).stageId, SucculentStageIds.rootEstablishment);
      expect(at(56).stageId, SucculentStageIds.rootEstablishment);
      expect(at(57).stageId, SucculentStageIds.activeGrowth);
      expect(at(270).stageId, SucculentStageIds.activeGrowth);
      expect(at(271).stageId, SucculentStageIds.maintenance);
    });

    test('TODAS las etapas declaradas son alcanzables', () {
      // Por fecha: instalación, raíz, crecimiento y mantenimiento.
      final reachable = <String>{
        at(1).stageId,
        at(30).stageId,
        at(120).stageId,
        at(400).stageId,
      };
      expect(reachable, containsAll(<String>[
        SucculentStageIds.installationEstablishment,
        SucculentStageIds.rootEstablishment,
        SucculentStageIds.activeGrowth,
        SucculentStageIds.maintenance,
      ]));
      // `rest` y `unknown` son alcanzables por confirmación/fallback.
      expect(
        succulentAllowedStageTransitions[SucculentStageIds.maintenance],
        contains(SucculentStageIds.rest),
      );
      expect(normalizeSucculentStageId(null), SucculentStageIds.unknown);
    });

    test('ESTABLE ES PARA SIEMPRE: a 1, 5 y 20 años sigue estable', () {
      for (final years in <int>[1, 5, 20]) {
        expect(at(365 * years + 1).stageId, SucculentStageIds.maintenance);
      }
    });

    test('ninguna etapa vuelve a "Recién plantada"', () {
      for (final from in <String>[
        SucculentStageIds.rootEstablishment,
        SucculentStageIds.activeGrowth,
        SucculentStageIds.maintenance,
        SucculentStageIds.rest,
      ]) {
        expect(
          isAllowedSucculentStageTransition(
            from,
            SucculentStageIds.installationEstablishment,
          ),
          isFalse,
          reason: '$from no puede reiniciar la vida de la planta',
        );
      }
    });

    test('maintenance no cierra el ciclo, pero puede volver a crecer', () {
      expect(
        isAllowedSucculentStageTransition(
          SucculentStageIds.maintenance,
          SucculentStageIds.activeGrowth,
        ),
        isTrue,
      );
      expect(
        isAllowedSucculentStageTransition(
          SucculentStageIds.maintenance,
          SucculentStageIds.rest,
        ),
        isTrue,
      );
    });

    test('el reposo NO se infiere por fecha (solo por confirmación)', () {
      for (var d = 0; d <= 400; d += 7) {
        expect(at(d).stageId, isNot(SucculentStageIds.rest));
      }
    });

    test('estrés, recuperación y declive NO son etapas', () {
      for (final fake in <String>['stress', 'recovery', 'rot', 'decline']) {
        expect(normalizeSucculentStageId(fake), SucculentStageIds.unknown);
      }
      expect(SucculentStageIds.all, hasLength(6));
    });

    test('sin rendimiento, sin cosecha, sin microciclo, sin memoria', () {
      expect(SucculentLifecycle.supportsYieldProjection, isFalse);
      expect(SucculentLifecycle.supportsHarvest, isFalse);
      expect(SucculentLifecycle.supportsRecurringBloom, isFalse);
      expect(SucculentLifecycle.supportsHydricCycle, isFalse);
      expect(SucculentLifecycle.supportsStressMemory, isFalse);
      expect(
        SucculentLifecycle.lifecycleMode,
        'establishment_maintenance',
      );
    });
  });

  // ── Wizard (Doc A §6) ──────────────────────────────────────────────────────
  group('Wizard: la etapa corresponde con lo que eligió el usuario', () {
    final now = DateTime(2026, 7, 13);

    test('solo dos intenciones: plantar / ya plantada', () {
      expect(SucculentSetupIntentIds.all, hasLength(2));
      expect(
        normalizeSucculentSetupIntentId('repot'),
        SucculentSetupIntentIds.alreadyPlanted,
      );
      expect(
        succulentSetupIntentRequiresFutureDate(
          SucculentSetupIntentIds.plannedPlant,
        ),
        isTrue,
      );
      expect(
        succulentSetupIntentRequiresFutureDate(
          SucculentSetupIntentIds.alreadyPlanted,
        ),
        isFalse,
      );
    });

    test('"la voy a plantar" → Recién plantada', () {
      final e = resolveSucculentSetupStage(
        intentId: SucculentSetupIntentIds.plannedPlant,
        plantingDate: now.add(const Duration(days: 5)),
        now: now,
      );
      expect(e.stageId, SucculentStageIds.installationEstablishment);
    });

    test('"ya está plantada" sin fecha → Estable (nunca "por confirmar")', () {
      final e = resolveSucculentSetupStage(
        intentId: SucculentSetupIntentIds.alreadyPlanted,
        plantingDate: null,
        now: now,
      );
      expect(e.stageId, SucculentStageIds.maintenance);
      expect(e.stageId, isNot(SucculentStageIds.unknown));
    });

    test('"ya está plantada" hace 3 semanas → Echando raíz', () {
      final e = resolveSucculentSetupStage(
        intentId: SucculentSetupIntentIds.alreadyPlanted,
        plantingDate: now.subtract(const Duration(days: 21)),
        now: now,
      );
      expect(e.stageId, SucculentStageIds.rootEstablishment);
    });

    test('una etapa ya confirmada por el usuario se respeta', () {
      final e = resolveSucculentSetupStage(
        intentId: SucculentSetupIntentIds.alreadyPlanted,
        plantingDate: DateTime(2021, 3, 1),
        now: now,
        previousStageId: SucculentStageIds.rest,
      );
      expect(e.stageId, SucculentStageIds.rest);
    });
  });

  // ── Runtime: el resolver alimenta las pantallas ────────────────────────────
  group('SucculentStageResolver alimenta las pantallas', () {
    DeviceCropContext context({
      DateTime? anchor,
      String? storedStage,
      CropLifecycleStatus status = CropLifecycleStatus.planted,
      String profileId = kSu02TrailingCascading,
    }) {
      return DeviceCropContext(
        deviceId: 'dev-1',
        cropCategoryId: CropCatalog.ornamentalCategoryId,
        cropId: CropCatalog.succulentCropId,
        profileId: profileId,
        lifecycleStatus: status,
        sowingDateConfidence: DateConfidence.estimated,
        catalogVersion: 'v1',
        source: CropConfigSource.wizard,
        configuredAt: DateTime(2026, 7, 13),
        updatedAt: DateTime(2026, 7, 13),
        ornamentalStageId: storedStage,
        ornamentalAnchorDate: anchor,
      );
    }

    test('plantada el 2 de mayo → Echando raíz, con el día real', () {
      final result = SucculentStageResolver.resolve(
        context: context(anchor: DateTime(2026, 5, 2)),
        today: DateTime(2026, 7, 13),
      );
      expect(result.stageKey, SucculentStageIds.rootEstablishment);
      expect(result.stageLabelEs, 'Echando raíz');
      expect(result.daySinceSowing, 72);
    });

    test('un contexto guardado con "unknown" se AUTO-REPARA', () {
      final result = SucculentStageResolver.resolve(
        context: context(
          anchor: DateTime(2026, 5, 2),
          storedStage: SucculentStageIds.unknown,
        ),
        today: DateTime(2026, 7, 13),
      );
      expect(result.stageKey, SucculentStageIds.rootEstablishment);
    });

    test('no tiene día terminal de ciclo', () {
      final result = SucculentStageResolver.resolve(
        context: context(anchor: DateTime(2020, 1, 1)),
        today: DateTime(2026, 7, 13),
      );
      expect(result.stageKey, SucculentStageIds.maintenance);
      expect(result.expectedDaysToEnd, 0);
      expect(result.windowsNow, isEmpty);
      expect(result.stageProgressPct, isNull);
      expect(result.productiveState, isNull);
    });

    test('el runtime ornamental resuelve por MODO, no por cactus', () {
      expect(
        isEstablishmentMaintenanceCrop(cropId: CropCatalog.succulentCropId),
        isTrue,
      );
      expect(
        isEstablishmentMaintenanceCrop(cropId: CropCatalog.cactusCropId),
        isTrue,
      );
      expect(isEstablishmentMaintenanceCrop(cropId: 'bean'), isFalse);

      final result = resolveOrnamentalStageResult(
        context: context(anchor: DateTime(2026, 5, 2)),
        today: DateTime(2026, 7, 13),
      );
      expect(result.stageKey, SucculentStageIds.rootEstablishment);
    });
  });

  // ── Persistencia (Doc A §7) ────────────────────────────────────────────────
  group('Persistencia', () {
    DeviceCropContext ctx(String profileId, {String? varietyId, String? alias}) {
      return DeviceCropContext(
        deviceId: 'dev-1',
        cropCategoryId: 'ornamental',
        cropId: 'crop_succulent',
        profileId: profileId,
        varietyId: varietyId,
        varietyAlias: alias,
        lifecycleStatus: CropLifecycleStatus.planted,
        sowingDateConfidence: DateConfidence.estimated,
        catalogVersion: 'v1',
        source: CropConfigSource.wizard,
        configuredAt: DateTime(2026, 7, 13),
        updatedAt: DateTime(2026, 7, 13),
        ornamentalStageId: SucculentStageIds.activeGrowth,
        ornamentalAnchorDate: DateTime(2026, 3, 1),
      );
    }

    test('un roundtrip conserva el perfil específico', () {
      final restored = DeviceCropContext.fromJson(
        ctx(kSu03BranchingWoody).toJson(),
      );
      expect(restored.cropId, 'crop_succulent');
      expect(restored.profileId, kSu03BranchingWoody);
      expect(restored.ornamentalStageId, SucculentStageIds.activeGrowth);
      expect(restored.ornamentalAnchorDate, DateTime(2026, 3, 1));
      expect(restored.sowingDate, isNull, reason: 'No se siembra');
    });

    test('un su_skip heredado NO pisa una selección específica viva', () {
      final restored = DeviceCropContext.fromJson(
        ctx(kSuSkip, varietyId: kSu01RosetteBrightLight).toJson(),
      );
      expect(restored.profileId, kSu01RosetteBrightLight);
    });

    test('el alias visible nunca expone el id interno ni "SKIP"', () {
      final restored = DeviceCropContext.fromJson(
        ctx(kSu04CompactFilteredLight, alias: 'su_04').toJson(),
      );
      expect(restored.varietyAlias, 'Suculenta compacta de luz filtrada');
      expect(restored.varietyAlias!.toLowerCase(), isNot(contains('skip')));
      expect(restored.varietyAlias!.toLowerCase(), isNot(contains('su_')));
    });
  });

  // ── Identidad y catálogo (Doc A §11) ───────────────────────────────────────
  group('Identidad del cultivo', () {
    test('crop_succulent está en el catálogo y en el registry', () {
      final entry = CropCatalog.cropById(CropCatalog.succulentCropId);
      expect(entry, isNotNull);
      expect(entry!.categoryId, CropCatalog.ornamentalCategoryId);
      expect(entry.enabled, isTrue);
      expect(entry.label, 'Suculenta');

      final definition = CropRegistry.byKey(CropKey.succulent);
      expect(definition, isA<SucculentCropDefinition>());
      expect(definition!.displayName, 'Suculenta');
      expect(definition.category, CropCategory.ornamental);
    });

    test('los alias humanos resuelven a suculenta, no a cactus', () {
      for (final alias in <String>[
        'suculenta',
        'succulent',
        'crop_succulent',
        'planta crasa',
      ]) {
        expect(
          CropCatalog.canonicalCropKey(alias),
          CropCatalog.succulentCropId,
        );
        expect(
          CropCatalog.canonicalCropKey(alias),
          isNot(CropCatalog.cactusCropId),
        );
      }
    });

    test('4 perfiles específicos + el general AL FINAL', () {
      final profiles = CropCatalog.profilesForCrop(
        CropCatalog.succulentCropId,
        enabledOnly: false,
      );
      expect(profiles, hasLength(5));
      expect(profiles.last.id, kSuSkip);
      expect(profiles.first.id, isNot(kSuSkip));
    });

    test('ningún id usa el prefijo SC y el general nunca dice "SKIP"', () {
      for (final p in succulentProfileEntries) {
        expect(p.id.startsWith('sc_'), isFalse);
        expect(p.id.startsWith('su'), isTrue);
        expect(p.label.toLowerCase(), isNot(contains('skip')));
      }
      expect(kSucculentProfilePrefix, 'SU');
    });

    test('no existe un perfil "joven" ni "premium"', () {
      for (final p in succulentProfileEntries) {
        final l = p.label.toLowerCase();
        expect(l, isNot(contains('joven')));
        expect(l, isNot(contains('premium')));
      }
    });

    test('los aliases mapean a los perfiles correctos', () {
      String? resolve(String alias) =>
          CropCatalog.profileByAny(CropCatalog.succulentCropId, alias)?.id;

      expect(resolve('Curio rowleyanus'), kSu02TrailingCascading);
      expect(resolve('Crassula ovata'), kSu03BranchingWoody);
      expect(resolve('Haworthiopsis fasciata'), kSu04CompactFilteredLight);
      expect(resolve('Echeveria'), kSu01RosetteBrightLight);
    });

    test('Lithops y las piedras vivas NO entran como alias', () {
      expect(
        CropCatalog.profileByAny(CropCatalog.succulentCropId, 'lithops'),
        isNull,
      );
      expect(isSucculentDeferredGroupAlias('lithops'), isTrue);
      expect(isSucculentDeferredGroupAlias('conophytum'), isTrue);
    });

    test('cactus, nopal, sábila y maguey se redirigen', () {
      expect(isSucculentCactusAlias('cactus'), isTrue);
      expect(isSucculentNopalAlias('nopal'), isTrue);
      expect(isSucculentAloeAlias('sábila'), isTrue);
      expect(isSucculentAgaveAlias('maguey'), isTrue);
      expect(isSucculentRedirectAlias('aloe vera'), isTrue);
      // Y ninguno se cuela como perfil SU.
      for (final alias in <String>['cactus', 'nopal', 'aloe', 'agave']) {
        expect(
          CropCatalog.profileByAny(CropCatalog.succulentCropId, alias),
          isNull,
          reason: '"$alias" no debe resolver a un perfil de suculenta',
        );
      }
    });
  });

  // ── Lenguaje de agricultor (§3.7 de la guía) ──────────────────────────────
  group('Lenguaje de agricultor', () {
    test('las etapas se llaman en cristiano', () {
      expect(
        succulentStageDisplayName(SucculentStageIds.installationEstablishment),
        'Recién plantada',
      );
      expect(
        succulentStageDisplayName(SucculentStageIds.maintenance),
        'Estable',
      );
      expect(succulentStageDisplayName(SucculentStageIds.rest), 'En reposo');
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
          succulentStageDisplayName(s),
          succulentStageCareNoteEs(s),
          succulentStagePriorityText(s),
          succulentCriticalWindowLabel(s) ?? '',
        ],
        for (final p in succulentProfileEntries) ...<String>[
          p.label,
          p.subtitle ?? '',
        ],
      ];

      for (final text in texts) {
        final lower = text.toLowerCase();
        for (final word in forbidden) {
          // 'cam' sólo se busca como palabra suelta.
          final hit = word == 'cam'
              ? RegExp(r'\bcam\b').hasMatch(lower)
              : lower.contains(word);
          expect(hit, isFalse, reason: '"$text" no debe decir "$word"');
        }
      }
    });

    test('ningún texto promete tolerancia a helada ni cobertura de mercado', () {
      final texts = <String>[
        for (final p in succulentProfileEntries) p.subtitle ?? '',
        for (final s in _allStages) succulentStageCareNoteEs(s),
      ];
      for (final t in texts) {
        final lower = t.toLowerCase();
        expect(lower, isNot(contains('helada')));
        expect(lower, isNot(contains('%')));
      }
    });
  });

  // ── Sanidad (Doc C §14) ────────────────────────────────────────────────────
  group('Sanidad', () {
    test('crop_succulent está registrado en PlantHealthRegistry', () {
      expect(PlantHealthRegistry.isSupportedCrop('crop_succulent'), isTrue);
      expect(
        PlantHealthRegistry.catalogForCrop('crop_succulent'),
        same(succulentSyndromes),
      );
      expect(succulentSyndromes, hasLength(14));
    });

    test('el adaptador traduce TODAS las etapas del modo', () {
      for (final stage in <String>[
        SucculentStageIds.installationEstablishment,
        SucculentStageIds.rootEstablishment,
        SucculentStageIds.activeGrowth,
        SucculentStageIds.maintenance,
        SucculentStageIds.rest,
      ]) {
        expect(
          PlantHealthStageAdapter.fromCropStage(
            cropId: 'crop_succulent',
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
      for (final s in succulentSyndromes) {
        expect(ids.add(s.id), isTrue, reason: 'id duplicado: ${s.id}');
        expect(s.cropId, CropCatalog.succulentCropId);
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
        for (final s in succulentSyndromes) ...<String>[
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
      final out = _evaluate(t: _telemetry(moisture: 95, ec: 3.2));
      for (final s in succulentSyndromes) {
        expect(out.eval.suggestedAlertKeys, isNot(contains(s.id)));
      }
    });

    test('el sensor por sí solo no genera un cuadro sanitario alto', () {
      // Los síndromes de alta severidad exigen SIEMPRE una observación del
      // usuario (síntoma primario), nunca solo una lectura de humedad.
      for (final s in succulentSyndromes) {
        if (s.severity == PlantHealthSeverity.high) {
          expect(s.primarySymptomId.trim(), isNotEmpty);
          expect(s.strongSignals, isNotEmpty);
        }
      }
    });

    test('toda etiqueta humana existe (nunca se muestra el id crudo)', () {
      for (final s in succulentSyndromes) {
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
  group('El cactus y los demás cultivos siguen intactos', () {
    test('el cactus conserva su catálogo, su perfil general y sus caps', () {
      final profiles = CropCatalog.profilesForCrop(
        CropCatalog.cactusCropId,
        enabledOnly: false,
      );
      expect(profiles.last.id, kCaSkip);
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

    test('el frijol no hereda los caps de la suculenta', () {
      expect(
        NpkCaps.forCropMetric(cropKey: 'bean', metricKey: AgroMetricKey.n),
        isNot(70.0),
      );
    });

    test('la categoría ornamental expone cactus y suculenta', () {
      final crops = CropCatalog.cropsByCategory(
        CropCatalog.ornamentalCategoryId,
        enabledOnly: true,
      ).map((c) => c.cropId).toList();
      expect(crops, containsAll(<String>[
        CropCatalog.cactusCropId,
        CropCatalog.succulentCropId,
      ]));
    });
  });
}
