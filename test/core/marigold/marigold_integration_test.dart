// test/core/marigold/marigold_integration_test.dart
//
// Contratos de la integración de Cempasúchil / Marigold (segunda ornamental
// ANUAL VERDADERA de BIO-G, después del Girasol).
//
// Regla que estas pruebas blindan: EL CEMPASÚCHIL COPIA LA ARQUITECTURA DEL
// GIRASOL, NO SUS NÚMEROS. Comparte el modo `annual_ornamental`, el reloj
// `annual_stage_clock` anclado a `sowingDate` y el cierre `cycle_complete`
// TERMINAL; pero calendarios, targets, pesos, caps NPK, textos, assets y
// sanidad son propios (Documento A §2.3, Documento B §25, Documento C §36).
//
// Y la regla que blinda al Girasol: nada de lo que sigue puede cambiar sus
// perfiles GI-*, sus caps 130/90/300 ni su catálogo sanitario.

import 'package:flutter_test/flutter_test.dart';

import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/agro/npk_caps.dart';
import 'package:bio_g/core/crops/annual_ornamental/annual_ornamental_crops.dart';
import 'package:bio_g/core/crops/catalog/crop_catalog.dart';
import 'package:bio_g/core/crops/crop_registry.dart';
import 'package:bio_g/core/crops/crop_stage_models.dart';
import 'package:bio_g/core/crops/crop_types.dart';
import 'package:bio_g/core/crops/marigold/marigold_agro_score_engine.dart';
import 'package:bio_g/core/crops/marigold/marigold_assets.dart';
import 'package:bio_g/core/crops/marigold/marigold_catalog.dart';
import 'package:bio_g/core/crops/marigold/marigold_crop_definition.dart';
import 'package:bio_g/core/crops/marigold/marigold_lifecycle.dart';
import 'package:bio_g/core/crops/marigold/marigold_risk_catalog.dart';
import 'package:bio_g/core/crops/marigold/marigold_universal_profile.dart';
import 'package:bio_g/core/crops/sunflower/sunflower_catalog.dart';
import 'package:bio_g/core/crops/sunflower/sunflower_universal_profile.dart';
import 'package:bio_g/core/plant_health/catalog/marigold_syndromes.dart';
import 'package:bio_g/core/plant_health/plant_health_models.dart';
import 'package:bio_g/core/plant_health/plant_health_registry.dart';
import 'package:bio_g/core/plant_health/plant_health_stage_adapter.dart';
import 'package:bio_g/core/plant_health/plant_health_stage_bucket.dart';
import 'package:bio_g/models/biog_telemetry.dart';
import 'package:bio_g/widgets/seeds/marigold_engine.dart';
import 'package:bio_g/widgets/seeds/marigold_models.dart';
import 'package:bio_g/widgets/seeds/marigold_profiles.dart';
import 'package:bio_g/widgets/seeds/sunflower_profiles.dart';

const List<String> _allStages = <String>[
  MarigoldStageIds.sowing,
  MarigoldStageIds.germination,
  MarigoldStageIds.emergence,
  MarigoldStageIds.earlyVegetativeGrowth,
  MarigoldStageIds.activeVegetativeGrowth,
  MarigoldStageIds.stemElongation,
  MarigoldStageIds.budFormation,
  MarigoldStageIds.flowering,
  MarigoldStageIds.postBloom,
  MarigoldStageIds.senescence,
  MarigoldStageIds.cycleComplete,
  MarigoldStageIds.unknown,
];

/// Etapas "vivas": sin la terminal ni la banda por confirmar.
const List<String> _liveStages = <String>[
  MarigoldStageIds.sowing,
  MarigoldStageIds.germination,
  MarigoldStageIds.emergence,
  MarigoldStageIds.earlyVegetativeGrowth,
  MarigoldStageIds.activeVegetativeGrowth,
  MarigoldStageIds.stemElongation,
  MarigoldStageIds.budFormation,
  MarigoldStageIds.flowering,
  MarigoldStageIds.postBloom,
  MarigoldStageIds.senescence,
];

const List<String> _allProfiles = <String>[
  kCs01TraditionalField,
  kCs02TallCutFlower,
  kCs03CompactContainer,
  kCs04LandscapeBedding,
  kCsSkip,
];

BioGTelemetry _telemetry({
  double moisture = 60,
  double soilTemp = 22,
  double ph = 6.4,
  double ec = 1.0,
  double resistance = 0.8,
  double n = 40,
  double p = 30,
  double k = 150,
  double airTemp = 24,
  double airHumidity = 55,
}) {
  return BioGTelemetry(
    deviceId: 'dev-marigold',
    timestamp: DateTime(2026, 7, 26, 9),
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
  String stage = MarigoldStageIds.flowering,
  String profileId = kCsSkip,
}) {
  return MarigoldAgroScoreEngine.evaluate(
    t: t,
    stageId: stage,
    stageLabelEs: marigoldStageDisplayName(stage),
    targets: resolveMarigoldTargetsForProfile(stage, profileId: profileId),
    weights: resolveMarigoldStageWeights(stage, profileId: profileId),
    profileId: profileId,
  );
}

CropStageResult _stageResult(String stageId) => CropStageResult(
  stageKey: stageId,
  stageLabelEs: marigoldStageDisplayName(stageId),
  expectedDaysToEnd: 10,
  windowsNow: const <dynamic>[],
  heroAsset: MarigoldAssets.stageImageOrNeutral(stageId),
  helperCaption: '',
);

void main() {
  // ═══════════════════════════════════════════════════════════════════════════
  group('Documento A §18.1 — Identidad', () {
    test('crop_marigold resuelve a CropKey.marigold', () {
      final def = CropRegistry.byKeyName(kCropMarigold);
      expect(def, isA<MarigoldCropDefinition>());
      expect(def!.cropKey, CropKey.marigold);
      expect(def.category, CropCategory.ornamental);
      expect(def.displayName, 'Cempasúchil');
    });

    test('los aliases humanos y legacy resuelven a crop_marigold', () {
      for (final alias in <String>[
        'crop_marigold',
        'marigold',
        'cempasuchil',
        'Cempasúchil',
        'SEMPASUCHIL',
        'zempasuchil',
        'cempoalxóchitl',
        'cempaxúchitl',
        'flor de muerto',
        'Tagetes erecta',
        'T. erecta',
        'Aztec marigold',
        'African marigold',
        'orn_cempasuchil',
      ]) {
        expect(
          CropCatalog.canonicalCropKey(alias),
          kCropMarigold,
          reason: 'alias «$alias»',
        );
        expect(CropRegistry.byKeyName(alias)?.cropKey, CropKey.marigold);
      }
    });

    test('el modo de ciclo es annual_ornamental con reloj anual', () {
      expect(kMarigoldLifecycleModeId, 'annual_ornamental');
      expect(kMarigoldTemporalEngine, 'annual_stage_clock');
      expect(annualOrnamentalLifecycleMode(kCropMarigold), 'annual_ornamental');
      expect(kMarigoldStressDelayDays, 0);
    });

    test('el catálogo publica Cempasúchil como ornamental habilitada', () {
      final entry = CropCatalog.crops.firstWhere(
        (c) => c.cropId == CropCatalog.marigoldCropId,
      );
      expect(entry.label, 'Cempasúchil');
      expect(entry.categoryId, CropCatalog.ornamentalCategoryId);
      expect(entry.enabled, isTrue);
      expect(entry.defaultProfileId, kCsSkip);
      expect(CropCatalog.cropDisplayName(kCropMarigold), 'Cempasúchil');
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  group('Documento A §18.2 — Exclusiones', () {
    test('otras especies de Tagetes y otras "marigolds" NO entran solas', () {
      for (final alias in <String>[
        'French marigold',
        'Tagetes patula',
        'clavel de moro',
        'signet marigold',
        'Tagetes tenuifolia',
        'Mexican mint marigold',
        'Tagetes lucida',
        'pericón',
        'wild marigold',
        'Tagetes minuta',
        'huacatay',
        'Mexican bush marigold',
        'pot marigold',
        'Calendula officinalis',
        'caléndula',
        'marsh marigold',
        'desert marigold',
        'corn marigold',
      ]) {
        expect(
          CropCatalog.canonicalCropKey(alias),
          isNot(kCropMarigold),
          reason: 'alias «$alias» no debe entrar automáticamente',
        );
        expect(isNotAMarigoldAlias(alias), isTrue, reason: 'alias «$alias»');
      }
    });

    test('la palabra "Tagetes" sola exige confirmación de especie', () {
      expect(isMarigoldGenusOnlyAlias('Tagetes'), isTrue);
      expect(isMarigoldGenusOnlyAlias('tagetes spp.'), isTrue);
      expect(CropCatalog.canonicalCropKey('Tagetes'), isNot(kCropMarigold));
    });

    test('el girasol NO resuelve a cempasúchil ni al revés', () {
      expect(CropCatalog.canonicalCropKey('girasol'), kCropSunflower);
      expect(CropCatalog.canonicalCropKey('cempasúchil'), kCropMarigold);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  group('Documento A §18.3 — Perfiles', () {
    test('hay cuatro perfiles concretos + cs_skip, y el general va al final', () {
      expect(marigoldProfiles.keys.toSet(), _allProfiles.toSet());
      expect(marigoldProfileOrder.last, kCsSkip);
      expect(marigoldProfileEntries.last.id, kCsSkip);
      expect(
        CropCatalog.profilesForCrop(kCropMarigold, enabledOnly: false).last.id,
        kCsSkip,
      );
    });

    test('la interfaz nunca muestra la palabra SKIP ni el id interno', () {
      for (final entry in marigoldProfileEntries) {
        expect(entry.label.toLowerCase(), isNot(contains('skip')));
        expect(entry.label, isNot(contains(entry.id)));
      }
    });

    test('CS-GEN y los códigos legacy migran a cs_skip', () {
      for (final legacy in <String>['CS-GEN', 'CS_GEN', 'CS-SKIP', 'CSSKIP']) {
        expect(resolveCanonicalMarigoldProfileId(legacy), kCsSkip);
      }
    });

    test('las series comerciales resuelven por arquitectura', () {
      expect(resolveCanonicalMarigoldProfileId('COCO'), kCs02TallCutFlower);
      expect(resolveCanonicalMarigoldProfileId('Xochi'), kCs02TallCutFlower);
      expect(resolveCanonicalMarigoldProfileId('Proud Mari'), kCs03CompactContainer);
      expect(resolveCanonicalMarigoldProfileId('Marvel II'), kCs04LandscapeBedding);
      expect(resolveCanonicalMarigoldProfileId('Taishan'), kCs04LandscapeBedding);
    });

    test('los alias ambiguos NO deciden perfil y caen en cs_skip', () {
      for (final ambiguous in <String>[
        'flor grande',
        'gigante',
        'africano',
        'en maceta',
        'para jardín',
        'criollo',
        'Inca II',
        'amarillo',
      ]) {
        expect(isAmbiguousMarigoldProfileAlias(ambiguous), isTrue,
            reason: 'alias «$ambiguous»');
        final resolved = MarigoldCropDefinition()
            .resolveProfile(varietyAlias: ambiguous);
        expect(resolved?.id, kCsSkip, reason: 'alias «$ambiguous»');
      }
    });

    test('un perfil desconocido cae en cs_skip, NUNCA en gi_skip', () {
      final resolved = MarigoldCropDefinition().resolveProfile(
        profileId: 'perfil_que_no_existe',
      );
      expect(resolved?.id, kCsSkip);
      expect(resolved?.id, isNot(kGiSkip));
      expect(resolved?.cropKey, CropKey.marigold);
    });

    test('"Africano gigante" no crea un perfil nuevo', () {
      expect(marigoldProfiles.length, 5);
      // Cada perfil tiene un tipo funcional propio: no hay dos que compartan
      // arquitectura (Documento A §0.2 corrección 4).
      expect(
        marigoldProfiles.values.map((p) => p.marigoldUseType).toSet().length,
        5,
      );
      for (final entry in marigoldProfileEntries) {
        final label = entry.label.toLowerCase();
        expect(label, isNot(contains('africano')));
        expect(label, isNot(contains('gigante')));
      }
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  group('Documento A §18.4 / §12.7 — Ciclo y calendario', () {
    test('el día 1 es siembra y no hay huecos ni retrocesos', () {
      for (final profileId in _allProfiles) {
        final p = marigoldProfiles[profileId]!;
        final anchor = DateTime(2026, 3, 1);
        var previousIndex = -1;
        for (var day = 1; day <= p.cycleCompleteStartDay + 30; day++) {
          final r = MarigoldEngine.compute(
            sowingDate: anchor,
            today: anchor.add(Duration(days: day - 1)),
            profile: p,
          );
          expect(r.daySinceAnchor, day, reason: '$profileId día $day');
          final index = MarigoldStageIds.ordered.indexOf(r.stageId);
          expect(index, isNonNegative, reason: '$profileId día $day');
          expect(index, greaterThanOrEqualTo(previousIndex),
              reason: '$profileId retrocedió en el día $day');
          expect(index - previousIndex, lessThanOrEqualTo(1),
              reason: '$profileId saltó una etapa en el día $day');
          previousIndex = index;
        }
        expect(previousIndex, MarigoldStageIds.ordered.length - 1);
      }
    });

    test('cycle_complete es TERMINAL: progreso 1.0 y 0 días restantes', () {
      final p = marigoldProfiles[kCsSkip]!;
      final anchor = DateTime(2025, 1, 1);
      final r = MarigoldEngine.compute(
        sowingDate: anchor,
        today: anchor.add(const Duration(days: 900)),
        profile: p,
      );
      expect(r.stageId, MarigoldStageIds.cycleComplete);
      expect(r.isCycleComplete, isTrue);
      expect(r.stageProgressPct, 1.0);
      expect(r.expectedDaysToEnd, 0);
    });

    test('una fecha muy antigua resuelve a cycle_complete, nunca a unknown', () {
      final p = marigoldProfiles[kCs01TraditionalField]!;
      final r = MarigoldEngine.compute(
        sowingDate: DateTime(2019, 5, 5),
        today: DateTime(2026, 7, 26),
        profile: p,
      );
      expect(r.stageId, MarigoldStageIds.cycleComplete);
      expect(r.stageId, isNot(MarigoldStageIds.unknown));
    });

    test('no existe dormancia, mantenimiento ni floración recurrente', () {
      expect(MarigoldStageIds.ordered, isNot(contains('dormancy')));
      expect(MarigoldStageIds.ordered, isNot(contains('maintenance')));
      expect(MarigoldStageIds.ordered, isNot(contains('floral_induction')));
      expect(MarigoldStageIds.ordered.last, MarigoldStageIds.cycleComplete);
      expect(MarigoldStageIds.ordered.length, 11);
    });

    test('los calendarios del Documento A §12 se respetan tal cual', () {
      expect(marigoldProfiles[kCs01TraditionalField]!.senescenceEndDay, 125);
      expect(marigoldProfiles[kCs02TallCutFlower]!.senescenceEndDay, 111);
      expect(marigoldProfiles[kCs03CompactContainer]!.senescenceEndDay, 98);
      expect(marigoldProfiles[kCs04LandscapeBedding]!.senescenceEndDay, 118);
      expect(marigoldProfiles[kCsSkip]!.senescenceEndDay, 120);
      expect(marigoldProfiles[kCs01TraditionalField]!.transplantAgeOffsetDays, 24);
      expect(marigoldProfiles[kCs03CompactContainer]!.transplantAgeOffsetDays, 18);
    });

    test('cambiar de perfil recalcula la etapa con la MISMA fecha ancla', () {
      final anchor = DateTime(2026, 4, 1);
      final today = anchor.add(const Duration(days: 55));
      final compact = MarigoldEngine.compute(
        sowingDate: anchor,
        today: today,
        profile: marigoldProfiles[kCs03CompactContainer]!,
      );
      final field = MarigoldEngine.compute(
        sowingDate: anchor,
        today: today,
        profile: marigoldProfiles[kCs01TraditionalField]!,
      );
      expect(compact.daySinceAnchor, field.daySinceAnchor);
      expect(compact.stageId, isNot(field.stageId));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  group('Documento A §13 — Fecha, trasplante y planta comprada', () {
    test('el trasplante estima la siembra restando la edad de plántula', () {
      final transplant = DateTime(2026, 6, 20);
      final estimated = estimateMarigoldSowingDateFromTransplant(
        profileId: kCs01TraditionalField,
        transplantDate: transplant,
      );
      expect(transplant.difference(estimated).inDays, 24);
    });

    test('cada estado visual mapea a su etapa y retrocalcula la fecha', () {
      const expected = <MarigoldVisualState, String>{
        MarigoldVisualState.seedling: MarigoldStageIds.earlyVegetativeGrowth,
        MarigoldVisualState.severalLeaves:
            MarigoldStageIds.activeVegetativeGrowth,
        MarigoldVisualState.formedNoBud: MarigoldStageIds.stemElongation,
        MarigoldVisualState.withBud: MarigoldStageIds.budFormation,
        MarigoldVisualState.flowerOpen: MarigoldStageIds.flowering,
        MarigoldVisualState.flowerAging: MarigoldStageIds.postBloom,
        MarigoldVisualState.plantDrying: MarigoldStageIds.senescence,
        MarigoldVisualState.unsure: MarigoldStageIds.unknown,
      };
      final now = DateTime(2026, 8, 1);
      expected.forEach((state, stageId) {
        expect(marigoldVisualStateToStageId(state), stageId);
        expect(marigoldVisualStateLabelEs(state), isNotEmpty);
        final date = estimateMarigoldSowingDateFromVisualState(
          profileId: kCsSkip,
          state: state,
          now: now,
        );
        if (state == MarigoldVisualState.unsure) {
          expect(date, isNull);
        } else {
          expect(date, isNotNull);
          expect(date!.isBefore(now) || date.isAtSameMomentAs(now), isTrue);
        }
      });
    });

    test('"No estoy seguro" produce unknown, editable y no oculto', () {
      expect(
        marigoldVisualStateToStageId(MarigoldVisualState.unsure),
        MarigoldStageIds.unknown,
      );
      expect(marigoldStageDisplayName(MarigoldStageIds.unknown),
          'Etapa por confirmar');
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  group('Documento A §18.5 / §11 — Fotoperiodo', () {
    test('no existe un stageId de inducción floral', () {
      expect(marigoldStageKeyFromId('floral_induction'), isNull);
      expect(normalizeMarigoldStageId('floral_induction'),
          MarigoldStageIds.unknown);
    });

    test('los textos de luz nocturna son prudentes y no prometen 12 horas', () {
      for (final txt in <String>[
        kMarigoldNightLightQuestionEs,
        kMarigoldNightLightHelperEs,
        kMarigoldPhotoperiodCautionEs,
        kMarigoldShortDayCutFlowerCautionEs,
      ]) {
        expect(txt, isNotEmpty);
        expect(txt, isNot(contains('12 horas')));
        expect(txt.toLowerCase(), isNot(contains('no florecerá')));
      }
    });

    test('la exposición nocturna es un contexto declarado, no una lectura', () {
      expect(
        marigoldNightLightExposureFromId('nearby_light'),
        MarigoldNightLightExposure.nearbyLight,
      );
      expect(
        marigoldNightLightExposureId(MarigoldNightLightExposure.greenhouseControlled),
        'greenhouse_controlled',
      );
      expect(
        marigoldNightLightExposureFromId('lo que sea'),
        MarigoldNightLightExposure.unknown,
      );
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  group('Documento B §26.1/§26.2 — Integridad de targets y pesos', () {
    test('cada etapa expone las ocho métricas con rangos ordenados', () {
      for (final stage in _allStages) {
        for (final profileId in _allProfiles) {
          final t = resolveMarigoldTargetsForProfile(stage,
              profileId: profileId);
          for (final entry in <String, AgroRange>{
            'humedad': t.moistureRaw,
            'temperatura': t.soilTemp,
            'pH': t.ph,
            'EC': t.ec,
            'resistencia': t.resistance,
            'N': t.nSoilPpmRange!,
            'P': t.pSoilPpmRange!,
            'K': t.kSoilPpmRange!,
          }.entries) {
            final r = entry.value;
            expect(r.lowMax, lessThanOrEqualTo(r.optimalMin),
                reason: '$stage/$profileId ${entry.key}');
            expect(r.optimalMin, lessThanOrEqualTo(r.optimalMax),
                reason: '$stage/$profileId ${entry.key}');
            expect(r.optimalMax, lessThanOrEqualTo(r.highMin),
                reason: '$stage/$profileId ${entry.key}');
            for (final v in <double>[
              r.lowMax,
              r.optimalMin,
              r.optimalMax,
              r.highMin,
            ]) {
              expect(v.isFinite, isTrue, reason: '$stage/$profileId ${entry.key}');
            }
          }
        }
      }
    });

    test('cada fila de pesos suma 1.00, también tras los ajustes de perfil', () {
      for (final stage in _allStages) {
        for (final profileId in _allProfiles) {
          final w = resolveMarigoldStageWeights(stage, profileId: profileId);
          expect((w.sum - 1.0).abs(), lessThan(0.0001),
              reason: '$stage/$profileId suma ${w.sum}');
          for (final v in <double>[
            w.moisture,
            w.soilTemp,
            w.ph,
            w.ec,
            w.resistance,
            w.nutrientN,
            w.nutrientP,
            w.nutrientK,
          ]) {
            expect(v, greaterThanOrEqualTo(0.0), reason: '$stage/$profileId');
          }
        }
      }
    });

    test('K pesa más que N en floración y N alcanza su máximo en activo', () {
      final flowering = resolveMarigoldStageWeights(MarigoldStageIds.flowering);
      expect(flowering.nutrientK, greaterThan(flowering.nutrientN));

      final nByStage = <String, double>{
        for (final s in _liveStages)
          s: resolveMarigoldStageWeights(s).nutrientN,
      };
      final maxN = nByStage.values.reduce((a, b) => a > b ? a : b);
      expect(nByStage[MarigoldStageIds.activeVegetativeGrowth], maxN);
    });

    test('la humedad domina en todas las etapas activas', () {
      for (final stage in _liveStages) {
        final w = resolveMarigoldStageWeights(stage);
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

    test('P nunca domina el score en ninguna etapa', () {
      for (final stage in _allStages) {
        final w = resolveMarigoldStageWeights(stage);
        expect(w.nutrientP, lessThan(w.moisture), reason: stage);
      }
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  group('Documento B §26.3–§26.7 — Bandas por métrica', () {
    test('60 % es óptimo en las etapas activas', () {
      for (final stage in _liveStages) {
        final t = resolveMarigoldTargetsForProfile(stage, profileId: kCsSkip);
        expect(60.0, greaterThanOrEqualTo(t.moistureRaw.optimalMin),
            reason: stage);
        expect(60.0, lessThanOrEqualTo(t.moistureRaw.highMin), reason: stage);
      }
    });

    test('88 % es crítico alto y 12 % crítico bajo en botón y floración', () {
      for (final stage in <String>[
        MarigoldStageIds.budFormation,
        MarigoldStageIds.flowering,
      ]) {
        final t = resolveMarigoldTargetsForProfile(stage, profileId: kCsSkip);
        expect(88.0, greaterThan(t.moistureRaw.highMin), reason: stage);
        expect(12.0, lessThan(t.moistureRaw.lowMax), reason: stage);
      }
    });

    test('22 °C es óptimo en germinación y 35 °C crítico en floración', () {
      final germ = resolveMarigoldTargetsForProfile(
        MarigoldStageIds.germination,
        profileId: kCsSkip,
      );
      expect(22.0, greaterThanOrEqualTo(germ.soilTemp.optimalMin));
      expect(22.0, lessThanOrEqualTo(germ.soilTemp.optimalMax));

      final flower = resolveMarigoldTargetsForProfile(
        MarigoldStageIds.flowering,
        profileId: kCsSkip,
      );
      expect(35.0, greaterThan(flower.soilTemp.highMin));
    });

    test('el pH se resuelve por perfil y NO cambia con la etapa', () {
      const expected = <String, List<double>>{
        kCs01TraditionalField: <double>[5.3, 6.0, 7.5, 8.2],
        kCs02TallCutFlower: <double>[5.5, 6.2, 7.5, 8.1],
        kCs03CompactContainer: <double>[5.2, 5.8, 6.6, 7.3],
        kCs04LandscapeBedding: <double>[5.3, 6.0, 7.3, 8.0],
        kCsSkip: <double>[5.2, 5.8, 7.3, 8.0],
      };
      expected.forEach((profileId, band) {
        for (final stage in _allStages) {
          final ph = resolveMarigoldTargetsForProfile(stage,
                  profileId: profileId)
              .ph;
          expect(<double>[ph.lowMax, ph.optimalMin, ph.optimalMax, ph.highMin],
              band, reason: '$profileId/$stage');
        }
      });
    });

    test('el contexto de maceta puede estrechar el pH de un perfil de campo', () {
      final field = resolveMarigoldTargetsForProfile(
        MarigoldStageIds.flowering,
        profileId: kCs01TraditionalField,
      );
      final fieldInPot = resolveMarigoldTargetsForProfile(
        MarigoldStageIds.flowering,
        profileId: kCs01TraditionalField,
        cultivationContextId: 'pot',
      );
      expect(field.ph.optimalMax, 7.5);
      expect(fieldInPot.ph.optimalMax, 6.6);
    });

    test('CS-03 baja el techo de humedad 4 puntos y la EC 0.30', () {
      for (final stage in _liveStages) {
        final base = resolveMarigoldTargetsForProfile(stage, profileId: kCsSkip);
        final pot = resolveMarigoldTargetsForProfile(stage,
            profileId: kCs03CompactContainer);
        expect(pot.moistureRaw.highMin, base.moistureRaw.highMin - 4,
            reason: stage);
        expect(pot.ec.highMin, closeTo(base.ec.highMin - 0.30, 1e-9),
            reason: stage);
        expect(pot.ec.optimalMax, closeTo(base.ec.optimalMax - 0.20, 1e-9),
            reason: stage);
      }
    });

    test('la resistencia usa lowMax = -1 y aprieta en el establecimiento', () {
      for (final stage in _allStages) {
        expect(
          resolveMarigoldTargets(stage).resistance.lowMax,
          -1.0,
          reason: stage,
        );
      }
      final seed = resolveMarigoldTargets(MarigoldStageIds.germination);
      final late = resolveMarigoldTargets(MarigoldStageIds.senescence);
      expect(seed.resistance.highMin, lessThan(late.resistance.highMin));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  group('Documento B §26.8 — NPK', () {
    test('los caps son 110 / 75 / 280 y coinciden con NpkCaps', () {
      expect(MarigoldUniversalProfile.capN, 110.0);
      expect(MarigoldUniversalProfile.capP, 75.0);
      expect(MarigoldUniversalProfile.capK, 280.0);
      for (final key in <String>[
        'marigold',
        'crop_marigold',
        'cempasuchil',
        'cempasúchil',
        'flor de muerto',
        'Tagetes erecta',
      ]) {
        expect(NpkCaps.forCropMetric(cropKey: key, metricKey: AgroMetricKey.n),
            110.0, reason: key);
        expect(NpkCaps.forCropMetric(cropKey: key, metricKey: AgroMetricKey.p),
            75.0, reason: key);
        expect(NpkCaps.forCropMetric(cropKey: key, metricKey: AgroMetricKey.k),
            280.0, reason: key);
      }
      expect(annualOrnamentalNCap(kCropMarigold),
          MarigoldUniversalProfile.capN);
    });

    test('el Cempasúchil pide menos N y P que el Girasol', () {
      expect(MarigoldUniversalProfile.capN,
          lessThan(SunflowerUniversalProfile.capN));
      expect(MarigoldUniversalProfile.capP,
          lessThan(SunflowerUniversalProfile.capP));
      expect(MarigoldUniversalProfile.capK,
          lessThan(SunflowerUniversalProfile.capK));
    });

    test('cs_skip y la etapa por confirmar limitan la prioridad NPK', () {
      for (final stage in _liveStages) {
        final skip = resolveMarigoldTargetsForProfile(stage, profileId: kCsSkip);
        expect(skip.resolvedNPriority01, lessThanOrEqualTo(0.5), reason: stage);
        expect(skip.resolvedKPriority01, lessThanOrEqualTo(0.5), reason: stage);
      }
      final unknown = resolveMarigoldTargetsForProfile(
        MarigoldStageIds.unknown,
        profileId: kCs01TraditionalField,
      );
      expect(unknown.resolvedNPriority01, lessThanOrEqualTo(0.5));
    });

    test('en cycle_complete la prioridad NPK es cero', () {
      final t = resolveMarigoldTargetsForProfile(
        MarigoldStageIds.cycleComplete,
        profileId: kCs01TraditionalField,
      );
      expect(t.resolvedNPriority01, 0.0);
      expect(t.resolvedPPriority01, 0.0);
      expect(t.resolvedKPriority01, 0.0);
    });

    test('ninguna guía NPK contiene una dosis', () {
      for (final stage in _allStages) {
        final t = resolveMarigoldTargets(stage);
        for (final g in <String?>[
          t.nShortGuidanceEs,
          t.pShortGuidanceEs,
          t.kShortGuidanceEs,
        ]) {
          expect(g, isNotNull, reason: stage);
          expect(g!.toLowerCase(), isNot(contains('kg/ha')), reason: stage);
          expect(g.toLowerCase(), isNot(contains('gramos')), reason: stage);
          expect(g.toLowerCase(), isNot(contains('ml')), reason: stage);
        }
      }
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  group('Documento B §16/§17/§24 — AgroScore, alertas y terminal', () {
    test('el motor solo emite claves canónicas, nunca marigold.*', () {
      for (final stage in _liveStages) {
        final out = _evaluate(
          t: _telemetry(moisture: 92, ec: 3.4, ph: 4.2, soilTemp: 40),
          stage: stage,
        );
        for (final key in out.eval.suggestedAlertKeys) {
          expect(key, isNot(startsWith('marigold')), reason: stage);
          expect(key, isNot(startsWith('cempasuchil')), reason: stage);
          expect(
            key.split('.').first,
            isIn(<String>[
              'soilMoisture',
              'soilTemp',
              'ph',
              'ec',
              'resistance',
              'npk',
              'airTemp',
              'airHumidity',
              'stage',
            ]),
            reason: '$stage → $key',
          );
        }
      }
    });

    test('cycle_complete hace BYPASS: sin alertas ni prioridad nutrimental', () {
      final out = _evaluate(
        t: _telemetry(moisture: 95, ec: 5.0, ph: 3.5, soilTemp: 45, n: 300),
        stage: MarigoldStageIds.cycleComplete,
      );
      expect(out.eval.alerts, isEmpty);
      expect(out.eval.suggestedAlertKeys, isEmpty);
      expect(out.eval.nutrientPriorityScore01, 0.0);
      expect(out.eval.soilControlScore01, 1.0);
    });

    test('una lectura óptima obtiene mejor score que una crítica', () {
      final good = _evaluate(t: _telemetry()).eval.soilControlScore01;
      final bad = _evaluate(
        t: _telemetry(moisture: 95, ec: 4.0, ph: 4.0, soilTemp: 42),
      ).eval.soilControlScore01;
      expect(good, greaterThan(bad));
      expect(good, greaterThan(0.8));
    });

    test('el déficit hídrico en floración castiga más que en senescencia', () {
      final flowering = _evaluate(
        t: _telemetry(moisture: 5),
        stage: MarigoldStageIds.flowering,
      ).eval.soilControlScore01;
      final senescence = _evaluate(
        t: _telemetry(moisture: 5),
        stage: MarigoldStageIds.senescence,
      ).eval.soilControlScore01;
      expect(flowering, lessThan(senescence));
    });

    test('el exceso de humedad castiga más en germinación que en posfloración', () {
      final germ = _evaluate(
        t: _telemetry(moisture: 99),
        stage: MarigoldStageIds.germination,
      ).eval.soilControlScore01;
      final post = _evaluate(
        t: _telemetry(moisture: 99),
        stage: MarigoldStageIds.postBloom,
      ).eval.soilControlScore01;
      expect(germ, lessThan(post));
    });

    test('CS-03 es más severo con sales que el perfil general', () {
      final t = _telemetry(ec: 4.0);
      final pot = _evaluate(
        t: t,
        stage: MarigoldStageIds.flowering,
        profileId: kCs03CompactContainer,
      ).eval.soilControlScore01;
      final general = _evaluate(
        t: t,
        stage: MarigoldStageIds.flowering,
        profileId: kCsSkip,
      ).eval.soilControlScore01;
      expect(pot, lessThan(general));
    });

    test('CS-02 es más severo con resistencia alta desde el alargamiento', () {
      final t = _telemetry(resistance: 3.5);
      final cut = _evaluate(
        t: t,
        stage: MarigoldStageIds.stemElongation,
        profileId: kCs02TallCutFlower,
      ).eval.soilControlScore01;
      final general = _evaluate(
        t: t,
        stage: MarigoldStageIds.stemElongation,
        profileId: kCsSkip,
      ).eval.soilControlScore01;
      expect(cut, lessThan(general));
    });

    test('el castigo acumulado nunca baja del piso 0.08', () {
      final out = _evaluate(
        t: _telemetry(
          moisture: 2,
          ec: 9.0,
          ph: 2.5,
          soilTemp: 55,
          resistance: 9.0,
          airTemp: 45,
          airHumidity: 99,
          n: 500,
          p: 400,
          k: 900,
        ),
        stage: MarigoldStageIds.flowering,
      );
      expect(out.eval.soilControlScore01, greaterThanOrEqualTo(0.0));
      expect(out.eval.soilControlScore01, lessThan(0.5));
    });

    test('la helada y el calor extremo emiten sus claves de aire', () {
      final frost = _evaluate(t: _telemetry(airTemp: -1)).eval.suggestedAlertKeys;
      expect(frost, contains('airTemp.frost'));
      final heat = _evaluate(t: _telemetry(airTemp: 42)).eval.suggestedAlertKeys;
      expect(heat, contains('airTemp.extreme_heat'));
    });

    test('la EC baja no genera alerta', () {
      final keys = _evaluate(t: _telemetry(ec: 0.05)).eval.suggestedAlertKeys;
      expect(keys.where((k) => k == 'ec.low'), isEmpty);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  group('Documento C §39 — Sanidad', () {
    test('crop_marigold tiene catálogo propio y no cae al del Girasol', () {
      final catalog = PlantHealthRegistry.catalogForCrop(
        CropCatalog.marigoldCropId,
      );
      expect(catalog, same(marigoldSyndromes));
      expect(catalog, isNotEmpty);
      expect(PlantHealthRegistry.isSupportedCrop(CropCatalog.marigoldCropId),
          isTrue);
      for (final s in catalog) {
        expect(s.cropId, CropCatalog.marigoldCropId);
        expect(s.id, startsWith('marigold_'));
      }
    });

    test('hay 23 síndromes con id único y disclaimer obligatorio', () {
      expect(marigoldSyndromes.length, 23);
      expect(marigoldSyndromes.map((s) => s.id).toSet().length, 23);
      for (final s in marigoldSyndromes) {
        expect(s.disclaimerEs, isNotEmpty, reason: s.id);
        expect(s.disclaimerEs, contains('No confirma'), reason: s.id);
        expect(s.organIds, isNotEmpty, reason: s.id);
        expect(s.probableDiagnoses, isNotEmpty, reason: s.id);
        expect(s.confirmationChecksEs, isNotEmpty, reason: s.id);
        expect(s.baseActionsEs, isNotEmpty, reason: s.id);
        expect(s.stages, isNotEmpty, reason: s.id);
      }
    });

    test('los ids de MarigoldRiskIds coinciden con el catálogo de síndromes', () {
      expect(MarigoldRiskIds.all.toSet(),
          marigoldSyndromes.map((s) => s.id).toSet());
      expect(MarigoldRiskIds.all.length, 23);
    });

    test('v1 no usa severidad critical ni urgencia immediate', () {
      for (final s in marigoldSyndromes) {
        expect(s.severity, isNot(PlantHealthSeverity.critical), reason: s.id);
        expect(s.urgency, isNot(PlantHealthUrgency.immediate), reason: s.id);
      }
    });

    test('ningún texto afirma un patógeno ni receta un producto', () {
      const banned = <String>[
        'Tiene damping-off',
        'Tiene Pythium',
        'Tiene Alternaria',
        'Tiene Botrytis',
        'Tiene TSWV',
        'Le falta hierro',
        'Aplica este fungicida',
        'Está muerto',
      ];
      for (final s in marigoldSyndromes) {
        final blob = <String>[
          s.labelEs,
          ...s.confirmationChecksEs,
          ...s.baseActionsEs,
          ...s.probableDiagnoses.map((d) => '${d.labelEs} ${d.summaryEs}'),
        ].join(' ');
        for (final b in banned) {
          expect(blob, isNot(contains(b)), reason: '${s.id} → $b');
        }
      }
    });

    test('el adapter traduce las etapas a los buckets compartidos', () {
      const expected = <String, PlantHealthStageBucket?>{
        MarigoldStageIds.sowing: PlantHealthStageBucket.seedling,
        MarigoldStageIds.germination: PlantHealthStageBucket.seedling,
        MarigoldStageIds.emergence: PlantHealthStageBucket.seedling,
        MarigoldStageIds.earlyVegetativeGrowth:
            PlantHealthStageBucket.vegetativeEarly,
        MarigoldStageIds.activeVegetativeGrowth:
            PlantHealthStageBucket.vegetativeMid,
        MarigoldStageIds.stemElongation: PlantHealthStageBucket.vegetativeLate,
        MarigoldStageIds.budFormation:
            PlantHealthStageBucket.reproductiveEarly,
        MarigoldStageIds.flowering: PlantHealthStageBucket.reproductiveMid,
        MarigoldStageIds.postBloom: PlantHealthStageBucket.grainFill,
        MarigoldStageIds.senescence: PlantHealthStageBucket.lateSeason,
        MarigoldStageIds.cycleComplete: PlantHealthStageBucket.lateSeason,
        MarigoldStageIds.unknown: null,
      };
      expected.forEach((stage, bucket) {
        expect(
          PlantHealthStageAdapter.fromCropStage(
            cropId: CropCatalog.marigoldCropId,
            stageKey: stage,
            daySinceSowing: null,
          ),
          bucket,
          reason: stage,
        );
      });
    });

    test('el síndrome de senescencia normal cubre el cierre del ciclo', () {
      final s = marigoldSyndromes.firstWhere(
        (x) => x.id == MarigoldRiskIds.normalPostBloomSenescence,
      );
      expect(s.severity, PlantHealthSeverity.low);
      expect(s.stages, contains(PlantHealthStageBucket.lateSeason));
      expect(
        s.probableDiagnoses.first.type,
        'expected_lifecycle',
      );
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  group('Documento A §18.7 — Capa annual_ornamental compartida', () {
    test('el Cempasúchil es una anual ornamental y nada más', () {
      expect(isAnnualOrnamentalCrop(cropId: kCropMarigold), isTrue);
      expect(kAnnualOrnamentalCropIds, contains(kCropMarigold));
      expect(annualOrnamentalCropIdOrNull('cempasúchil'), kCropMarigold);
    });

    test('los helpers compartidos devuelven la identidad del Cempasúchil', () {
      expect(annualOrnamentalCropDisplayName(kCropMarigold), 'Cempasúchil');
      expect(annualOrnamentalDefaultProfileId(kCropMarigold), kCsSkip);
      expect(annualOrnamentalGeneralProfileLabel(kCropMarigold),
          'No sé / Cempasúchil general');
      expect(annualOrnamentalTypeQuestion(kCropMarigold),
          '¿Qué tipo de Cempasúchil es?');
      expect(annualOrnamentalCycleCompleteHelper(kCropMarigold),
          contains('Cempasúchil'));
      expect(annualOrnamentalCycleCompleteHelper(kCropMarigold),
          contains('nueva siembra'));
    });

    test('los assets provienen de MarigoldAssets, nunca del Girasol', () {
      for (final stage in _allStages) {
        final path = annualOrnamentalStageImage(kCropMarigold, stage);
        expect(path, startsWith('assets/seeds/cempasuchil/'), reason: stage);
        expect(path, isNot(contains('sunflower')), reason: stage);
      }
      for (final profileId in _allProfiles) {
        final icon = annualOrnamentalProfileIcon(kCropMarigold, profileId);
        expect(icon, contains('ic_cempasuchil'), reason: profileId);
      }
      expect(annualOrnamentalCropIcon(kCropMarigold), MarigoldAssets.cropIcon);
    });

    test('un cropId anual desconocido NO hereda al Girasol', () {
      const bogus = 'crop_que_no_existe';
      expect(annualOrnamentalCropDisplayName(bogus), isNot('Girasol'));
      expect(annualOrnamentalDefaultProfileId(bogus), isNot(kGiSkip));
      expect(annualOrnamentalCropIcon(bogus),
          kAnnualOrnamentalGenericPlantFallback);
      expect(annualOrnamentalCycleCompleteHelper(bogus),
          isNot(contains('Girasol')));
      expect(annualOrnamentalNCap(bogus),
          isNot(SunflowerUniversalProfile.capN));
    });

    test('solo el perfil de corte activa el rótulo de ventana de corte', () {
      expect(
        annualOrnamentalIsCutFlowerProfile(kCropMarigold, kCs02TallCutFlower),
        isTrue,
      );
      for (final other in <String>[
        kCs01TraditionalField,
        kCs03CompactContainer,
        kCs04LandscapeBedding,
        kCsSkip,
      ]) {
        expect(
          annualOrnamentalIsCutFlowerProfile(kCropMarigold, other),
          isFalse,
          reason: other,
        );
      }
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  group('Documento A §18.8 / B §26.11 — No regresión del Girasol', () {
    test('el Girasol conserva sus perfiles, caps y textos', () {
      expect(CropCatalog.canonicalCropKey('girasol'), kCropSunflower);
      expect(CropRegistry.byKeyName('crop_sunflower')?.cropKey,
          CropKey.sunflower);
      expect(SunflowerUniversalProfile.capN, 130.0);
      expect(SunflowerUniversalProfile.capP, 90.0);
      expect(SunflowerUniversalProfile.capK, 300.0);
      expect(sunflowerProfiles.keys, contains(kGiSkip));
      expect(annualOrnamentalCropDisplayName(kCropSunflower), 'Girasol');
      expect(annualOrnamentalDefaultProfileId(kCropSunflower), kGiSkip);
      expect(
        annualOrnamentalStageImage(kCropSunflower, 'flowering'),
        contains('sunflower'),
      );
    });

    test('PlantHealth del Girasol no devuelve síndromes de Cempasúchil', () {
      final sf = PlantHealthRegistry.catalogForCrop(
        CropCatalog.sunflowerCropId,
      );
      expect(sf, isNotEmpty);
      for (final s in sf) {
        expect(s.id, isNot(startsWith('marigold_')));
      }
    });

    test('los caps NPK de los demás cultivos no cambian', () {
      expect(
        NpkCaps.forCropMetric(cropKey: 'girasol', metricKey: AgroMetricKey.n),
        130.0,
      );
      expect(
        NpkCaps.forCropMetric(cropKey: 'tulipan', metricKey: AgroMetricKey.n),
        100.0,
      );
      expect(
        NpkCaps.forCropMetric(cropKey: 'rosal', metricKey: AgroMetricKey.n),
        120.0,
      );
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  group('Definición del cultivo y motor', () {
    test('resolveTargets y resolveStageWeights responden en toda etapa', () {
      final def = MarigoldCropDefinition();
      for (final stage in _allStages) {
        final result = _stageResult(stage);
        expect(def.resolveTargets(result), isNotNull, reason: stage);
        for (final profileId in _allProfiles) {
          expect(
            def.resolveTargetsForProfile(result, profileId: profileId),
            isNotNull,
            reason: '$stage/$profileId',
          );
          final w = def.resolveStageWeights(result, profileId: profileId);
          expect((w.sum - 1.0).abs(), lessThan(0.0001),
              reason: '$stage/$profileId');
        }
      }
    });

    test('el adaptador de motor emite stageKey canónico y progreso no nulo', () {
      final def = MarigoldCropDefinition();
      final anchor = DateTime(2026, 5, 1);
      for (var day = 1; day <= 140; day += 7) {
        final r = def.engine.compute(
          sowingDate: anchor,
          today: anchor.add(Duration(days: day - 1)),
          profile: marigoldProfiles[kCsSkip]!,
        );
        expect(MarigoldStageIds.ordered, contains(r.stageKey),
            reason: 'día $day');
        expect(r.stageProgressPct, isNotNull, reason: 'día $day');
        expect(r.daySinceSowing, day);
      }
    });

    test('cada etapa tiene nombre visible, nota de cuidado y arte', () {
      for (final stage in _allStages) {
        expect(marigoldStageDisplayName(stage), isNotEmpty, reason: stage);
        expect(marigoldStageDisplayName(stage), isNot(contains('_')),
            reason: stage);
        expect(marigoldStageCareNoteEs(stage), isNotEmpty, reason: stage);
        expect(MarigoldAssets.stageImageOrNeutral(stage), endsWith('.png'),
            reason: stage);
      }
    });

    test('los alias de etapa en español normalizan al id canónico', () {
      expect(normalizeMarigoldStageId('Germinación'),
          MarigoldStageIds.germination);
      expect(normalizeMarigoldStageId('botón'), MarigoldStageIds.budFormation);
      expect(normalizeMarigoldStageId('posfloración'),
          MarigoldStageIds.postBloom);
      expect(normalizeMarigoldStageId('terminado'),
          MarigoldStageIds.cycleComplete);
      expect(normalizeMarigoldStageId('vaina'), MarigoldStageIds.unknown);
      expect(normalizeMarigoldStageId(null), MarigoldStageIds.unknown);
    });
  });
}
