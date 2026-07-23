// test/core/agave/agave_integration_test.dart
//
// Contratos de la integración de Maguey / Agave (cuarta ornamental de BIO-G).
//
// Regla que estas pruebas blindan: EL MAGUEY SE COMPORTA COMO FRIJOL en unidades
// y motor (mismas bandas, mismas claves de alerta, mismo motor de nutrición),
// pero NO es cíclico: establecimiento → mantenimiento abierto, sin cosecha, sin
// rendimiento y sin jima (Doc A/B/C, paquete Maguey MG v1.0).
//
// Y la regla que blinda a los demás: se copia su arquitectura, NO sus números.

import 'package:flutter_test/flutter_test.dart';

import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/agro/npk_caps.dart';
import 'package:bio_g/core/crops/catalog/crop_catalog.dart';
import 'package:bio_g/core/crops/crop_registry.dart';
import 'package:bio_g/core/crops/crop_types.dart';
import 'package:bio_g/core/crops/agave/agave_agro_score_engine.dart';
import 'package:bio_g/core/crops/agave/agave_catalog.dart';
import 'package:bio_g/core/crops/agave/agave_crop_definition.dart';
import 'package:bio_g/core/crops/agave/agave_lifecycle.dart';
import 'package:bio_g/core/crops/agave/agave_universal_profile.dart';
import 'package:bio_g/core/plant_health/catalog/agave_syndromes.dart';
import 'package:bio_g/core/plant_health/plant_health_models.dart';
import 'package:bio_g/core/plant_health/plant_health_registry.dart';
import 'package:bio_g/models/biog_telemetry.dart';

const List<String> _allStages = <String>[
  AgaveStageIds.installationEstablishment,
  AgaveStageIds.rootEstablishment,
  AgaveStageIds.activeGrowth,
  AgaveStageIds.maintenance,
  AgaveStageIds.rest,
  AgaveStageIds.unknown,
];

const List<String> _allProfiles = <String>[
  kAgave01CompactSculptural,
  kAgave02LargeSpinyLandscape,
  kAgave03BlueNarrowField,
  kAgave04SoftSpinelessWarm,
  kAgaveSkip,
];

BioGTelemetry _telemetry({
  double moisture = 24,
  double soilTemp = 24,
  double ph = 6.8,
  double ec = 0.9,
  double resistance = 0.6,
  double n = 30,
  double p = 18,
  double k = 130,
  double airTemp = 26,
  double airHumidity = 45,
}) {
  return BioGTelemetry(
    deviceId: 'dev-agave',
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
  String stage = AgaveStageIds.maintenance,
  String? profileId,
}) {
  return AgaveAgroScoreEngine.evaluate(
    t: t,
    stageId: stage,
    stageLabelEs: agaveStageDisplayName(stage),
    targets: resolveAgaveTargets(stage),
    weights: resolveAgaveStageWeights(stage, profileId: profileId),
    cropLabel: 'Maguey',
    profileId: profileId,
  );
}

void main() {
  // ── Identidad congelada (Doc A §0.2, §22) ──────────────────────────────────
  group('Identidad', () {
    test('crop_agave resuelve CropKey.agave', () {
      final def = CropRegistry.byKeyName('crop_agave');
      expect(def, isA<AgaveCropDefinition>());
      expect(def!.cropKey, CropKey.agave);
      expect(def.category, CropCategory.ornamental);
      expect(def.displayName, 'Maguey');
    });

    test('aliases maguey / agave resuelven a crop_agave', () {
      for (final alias in <String>['maguey', 'agave', 'crop_agave', 'Maguey']) {
        expect(CropCatalog.canonicalCropKey(alias), CropCatalog.agaveCropId);
      }
    });

    test('lifecycleMode = establishment_maintenance y sin cosecha', () {
      expect(AgaveLifecycle.lifecycleMode, 'establishment_maintenance');
      expect(AgaveLifecycle.supportsYieldProjection, isFalse);
      expect(AgaveLifecycle.supportsHarvest, isFalse);
      expect(AgaveLifecycle.supportsRecurringBloom, isFalse);
      expect(AgaveLifecycle.supportsHydricCycle, isFalse);
      expect(AgaveLifecycle.supportsStressMemory, isFalse);
    });
  });

  // ── Perfiles (Doc A §4) ────────────────────────────────────────────────────
  group('Perfiles', () {
    test('cuatro perfiles + mg_skip, con mg_skip al final', () {
      expect(agaveProfileEntries.length, 5);
      expect(agaveProfileEntries.last.id, kAgaveSkip);
      expect(
        agaveProfileEntries.map((e) => e.id).toList(),
        <String>[
          kAgave01CompactSculptural,
          kAgave02LargeSpinyLandscape,
          kAgave03BlueNarrowField,
          kAgave04SoftSpinelessWarm,
          kAgaveSkip,
        ],
      );
    });

    test('el perfil general es el default y cae en mg_skip', () {
      final def = AgaveCropDefinition();
      expect(def.resolveProfile()?.id, kAgaveSkip);
      expect(def.resolveProfile(profileId: 'ruido inexistente')?.id, kAgaveSkip);
    });

    test('un nombre confirmado resuelve su perfil específico', () {
      final def = AgaveCropDefinition();
      expect(def.resolveProfile(varietyAlias: 'agave americana')?.id,
          kAgave02LargeSpinyLandscape);
      expect(def.resolveProfile(varietyAlias: 'agave attenuata')?.id,
          kAgave04SoftSpinelessWarm);
    });
  });

  // ── Ciclo de vida y ventanas (Doc A §7.4, §7.9) ────────────────────────────
  group('Ventanas de etapa', () {
    final now = DateTime(2026, 7, 18);
    String stageAt(int daysAgo) => estimateAgaveStageFromDate(
          plantingDate: now.subtract(Duration(days: daysAgo)),
          now: now,
        ).stageId;

    test('0 y 30 días → recién plantado', () {
      expect(stageAt(0), AgaveStageIds.installationEstablishment);
      expect(stageAt(30), AgaveStageIds.installationEstablishment);
    });
    test('31 y 180 días → echando raíz', () {
      expect(stageAt(31), AgaveStageIds.rootEstablishment);
      expect(stageAt(180), AgaveStageIds.rootEstablishment);
    });
    test('181 y 1095 días → creciendo y madurando', () {
      expect(stageAt(181), AgaveStageIds.activeGrowth);
      expect(stageAt(1095), AgaveStageIds.activeGrowth);
    });
    test('1096 días y 40 años → maduro y estable (sin fin de ciclo)', () {
      expect(stageAt(1096), AgaveStageIds.maintenance);
      expect(stageAt(365 * 40), AgaveStageIds.maintenance);
    });
    test('"ya está plantado" sin fecha → maduro y estable, no unknown', () {
      final e = resolveAgaveSetupStage(
        intentId: AgaveSetupIntentIds.alreadyPlanted,
        plantingDate: null,
        now: now,
      );
      expect(e.stageId, AgaveStageIds.maintenance);
    });
    test('etiquetas humanas de active y maintenance (Doc A §7.2)', () {
      expect(agaveStageDisplayName(AgaveStageIds.activeGrowth),
          'Creciendo y madurando');
      expect(
          agaveStageDisplayName(AgaveStageIds.maintenance), 'Maduro y estable');
    });
  });

  // ── Unidades reales (Doc B §3, §4) ─────────────────────────────────────────
  group('Unidades reales', () {
    test('EC en mS/cm (highMin < 5) y > 0', () {
      for (final stage in _allStages) {
        final ec = resolveAgaveTargets(stage).ec;
        expect(ec.highMin, lessThan(5));
        expect(ec.optimalMin, greaterThan(0));
      }
    });
    test('resistencia en MPa (highMin <= 2.1) y lowMax <= 0', () {
      for (final stage in _allStages) {
        final r = resolveAgaveTargets(stage).resistance;
        expect(r.highMin, lessThanOrEqualTo(2.1));
        expect(r.lowMax, lessThanOrEqualTo(0.0));
      }
    });
    test('NPK en mg/kg, demanda baja-moderada y K > N', () {
      for (final stage in _allStages) {
        final t = resolveAgaveTargets(stage);
        expect(t.nSoilPpmRange, isNotNull);
        expect(t.kSoilPpmRange, isNotNull);
        expect(t.nSoilPpmRange!.optimalMax, lessThanOrEqualTo(60));
        expect(t.kSoilPpmRange!.optimalMax,
            greaterThan(t.nSoilPpmRange!.optimalMax));
      }
    });
    test('todos los rangos cumplen lowMax < optMin <= optMax < highMin', () {
      for (final stage in _allStages) {
        final t = resolveAgaveTargets(stage);
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
          expect(r.lowMax, lessThan(r.optimalMin), reason: stage);
          expect(r.optimalMin, lessThanOrEqualTo(r.optimalMax));
          expect(r.optimalMax, lessThan(r.highMin), reason: stage);
        }
      }
    });
  });

  // ── NpkCaps propios (Doc B §5) ─────────────────────────────────────────────
  group('NpkCaps', () {
    test('crop_agave resuelve N=90 · P=55 · K=280', () {
      expect(NpkCaps.forCropMetric(cropKey: 'agave', metricKey: AgroMetricKey.n),
          90.0);
      expect(NpkCaps.forCropMetric(cropKey: 'agave', metricKey: AgroMetricKey.p),
          55.0);
      expect(NpkCaps.forCropMetric(cropKey: 'agave', metricKey: AgroMetricKey.k),
          280.0);
    });
    test('no hereda los caps de cactus/suculenta/sábila', () {
      final n = NpkCaps.forCropMetric(
          cropKey: 'agave', metricKey: AgroMetricKey.n);
      expect(n, isNot(60.0)); // cactus
      expect(n, isNot(70.0)); // suculenta
      expect(n, isNot(85.0)); // sábila
    });
  });

  // ── StageWeights (Doc B §6) ────────────────────────────────────────────────
  group('StageWeights', () {
    test('cada etapa suma 1.00, también con ajuste de perfil', () {
      for (final profile in <String?>[null, ..._allProfiles]) {
        for (final stage in _allStages) {
          expect(resolveAgaveStageWeights(stage, profileId: profile).sum,
              closeTo(1.0, 0.0001),
              reason: '$profile · $stage');
        }
      }
    });
    test('la humedad es el mayor peso individual en toda etapa', () {
      for (final stage in _allStages) {
        final w = resolveAgaveStageWeights(stage);
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
    test('el NPK pesa más en crecimiento activo que en cualquier otra etapa', () {
      double npk(String s) {
        final w = resolveAgaveStageWeights(s);
        return w.nutrientN + w.nutrientP + w.nutrientK;
      }

      final active = npk(AgaveStageIds.activeGrowth);
      for (final stage in _allStages) {
        if (stage == AgaveStageIds.activeGrowth) continue;
        expect(active, greaterThan(npk(stage)), reason: stage);
      }
    });
  });

  // ── AgroScore y claves canónicas (Doc B §8, §12) ───────────────────────────
  group('AgroScore', () {
    test('el exceso de humedad castiga más que la sequía', () {
      final wet = _evaluate(t: _telemetry(moisture: 95)).eval.soilControlScore01;
      final dry = _evaluate(t: _telemetry(moisture: 1)).eval.soilControlScore01;
      expect(wet, lessThan(dry));
    });

    test('ninguna clave de alerta empieza con el nombre del cultivo', () {
      final keys = _evaluate(
        t: _telemetry(moisture: 95, ec: 4.0, soilTemp: 1),
        stage: AgaveStageIds.rest,
      ).eval.suggestedAlertKeys;
      for (final k in keys) {
        for (final banned in <String>['agave', 'maguey', 'mg', 'tequila',
            'jima', 'quiote', 'ornamental']) {
          expect(k.startsWith('$banned.'), isFalse, reason: k);
        }
      }
    });

    test('una lectura sana no dispara alerta de suelo crítica', () {
      final keys = _evaluate(t: _telemetry()).eval.suggestedAlertKeys;
      expect(keys.where((k) => k.endsWith('.critical')), isEmpty);
    });
  });

  // ── Sanidad (Doc C) ────────────────────────────────────────────────────────
  group('Sanidad', () {
    test('crop_agave está registrado con 17 síndromes', () {
      final syn = PlantHealthRegistry.catalogForCrop(CropCatalog.agaveCropId);
      expect(identical(syn, agaveSyndromes), isTrue);
      expect(syn.length, 17);
    });

    test('cada síndrome tiene id único, disclaimer y 2..4 preguntas', () {
      final ids = <String>{};
      for (final s in agaveSyndromes) {
        expect(ids.add(s.id), isTrue, reason: 'id duplicado: ${s.id}');
        expect(s.disclaimerEs, isNotEmpty, reason: s.id);
        expect(s.confirmationChecksEs.length, inInclusiveRange(2, 4),
            reason: s.id);
        expect(s.baseActionsEs, isNotEmpty, reason: s.id);
        expect(s.cropId, CropCatalog.agaveCropId, reason: s.id);
      }
    });

    test('ningún síndrome escala a alto solo por el sensor: hay niveles bajos',
        () {
      // El quiote, la senescencia y el cambio benigno son informativos.
      final low = agaveSyndromes
          .where((s) => s.severity == PlantHealthSeverity.low)
          .map((s) => s.id)
          .toList();
      expect(low, contains('agave_flower_stalk_transition_01'));
      expect(low, contains('agave_benign_natural_change_01'));
    });
  });
}
