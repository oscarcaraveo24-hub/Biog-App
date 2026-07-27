// test/core/nopal/nopal_integration_test.dart
//
// Contratos de la integración de Nopal (octava ornamental de BIO-G, quinta del
// modo establishment_maintenance).
//
// Regla que estas pruebas blindan: EL NOPAL SE COMPORTA COMO FRIJOL en unidades
// y motor (mismas bandas, mismas claves de alerta, mismo motor de nutrición),
// pero NO es cíclico: establecimiento → mantenimiento abierto, sin cosecha, sin
// rendimiento y sin fecha de corte (Doc A/B/C, paquete Nopal NO v1.0).
//
// Y la regla que blinda a los demás: se copia su arquitectura, NO sus números.
// En particular, Nopal NUNCA debe caer en el fallback silencioso de Cactus de
// `ornamental_crops.dart` (Doc A §2.9).

import 'package:flutter_test/flutter_test.dart';

import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/agro/npk_caps.dart';
import 'package:bio_g/core/crops/catalog/crop_catalog.dart';
import 'package:bio_g/core/crops/crop_registry.dart';
import 'package:bio_g/core/crops/crop_types.dart';
import 'package:bio_g/core/crops/cactus/cactus_assets.dart';
import 'package:bio_g/core/crops/nopal/nopal_agro_score_engine.dart';
import 'package:bio_g/core/crops/nopal/nopal_assets.dart';
import 'package:bio_g/core/crops/nopal/nopal_catalog.dart';
import 'package:bio_g/core/crops/nopal/nopal_crop_definition.dart';
import 'package:bio_g/core/crops/nopal/nopal_lifecycle.dart';
import 'package:bio_g/core/crops/nopal/nopal_universal_profile.dart';
import 'package:bio_g/core/crops/ornamental/ornamental_crops.dart';
import 'package:bio_g/core/plant_health/catalog/nopal_syndromes.dart';
import 'package:bio_g/core/plant_health/plant_health_ids.dart';
import 'package:bio_g/core/plant_health/plant_health_models.dart';
import 'package:bio_g/core/plant_health/plant_health_registry.dart';
import 'package:bio_g/core/plant_health/plant_health_stage_adapter.dart';
import 'package:bio_g/core/plant_health/plant_health_stage_bucket.dart';
import 'package:bio_g/models/biog_telemetry.dart';

const List<String> _allStages = <String>[
  NopalStageIds.installationEstablishment,
  NopalStageIds.rootEstablishment,
  NopalStageIds.activeGrowth,
  NopalStageIds.maintenance,
  NopalStageIds.rest,
  NopalStageIds.unknown,
];

const List<String> _allProfiles = <String>[
  kNopal01CompactClumpingContainer,
  kNopal02UprightLargePadWarm,
  kNopal03DesertShrubSpinyLandscape,
  kNopal04LowSpreadingColdHardy,
  kNopalSkip,
];

BioGTelemetry _telemetry({
  double moisture = 30,
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
    deviceId: 'dev-nopal',
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
  String stage = NopalStageIds.maintenance,
  String? profileId,
}) {
  return NopalAgroScoreEngine.evaluate(
    t: t,
    stageId: stage,
    stageLabelEs: nopalStageDisplayName(stage),
    targets: resolveNopalTargets(stage),
    weights: resolveNopalStageWeights(stage, profileId: profileId),
    cropLabel: 'Nopal',
    profileId: profileId,
  );
}

void main() {
  // ── Identidad congelada (Doc A §0.1) ───────────────────────────────────────
  group('Identidad', () {
    test('crop_nopal resuelve CropKey.nopal', () {
      final def = CropRegistry.byKeyName('crop_nopal');
      expect(def, isA<NopalCropDefinition>());
      expect(def!.cropKey, CropKey.nopal);
      expect(def.category, CropCategory.ornamental);
      expect(def.displayName, 'Nopal');
    });

    test('aliases de nopal resuelven a crop_nopal', () {
      const aliases = <String>[
        'nopal',
        'nopales',
        'opuntia',
        'Opuntia spp.',
        'prickly pear',
        'orn_nopal',
        'crop_nopal',
        'Nopal',
      ];
      for (final alias in aliases) {
        expect(
          CropCatalog.canonicalCropKey(alias),
          CropCatalog.nopalCropId,
          reason: '"$alias" debería resolver a crop_nopal',
        );
      }
    });

    test('"penca de nopal" NO cae en maguey y "nopal" NO cae en cactus', () {
      expect(CropCatalog.canonicalCropKey('nopal'), isNot(CropCatalog.cactusCropId));
      expect(CropCatalog.canonicalCropKey('nopal'), isNot(CropCatalog.agaveCropId));
      expect(CropCatalog.canonicalCropKey('opuntia'), CropCatalog.nopalCropId);
    });

    test('lifecycleMode = establishment_maintenance y sin cosecha', () {
      expect(NopalLifecycle.lifecycleMode, 'establishment_maintenance');
      expect(NopalLifecycle.supportsYieldProjection, isFalse);
      expect(NopalLifecycle.supportsHarvest, isFalse);
      expect(NopalLifecycle.supportsRecurringBloom, isFalse);
      expect(NopalLifecycle.supportsHydricCycle, isFalse);
      expect(NopalLifecycle.supportsStressMemory, isFalse);
    });

    test('nopal usa el runtime ornamental de establecimiento', () {
      expect(
        isEstablishmentMaintenanceCrop(cropId: CropCatalog.nopalCropId),
        isTrue,
      );
    });
  });

  // ── El fallback silencioso a Cactus (Doc A §2.9) ───────────────────────────
  group('No hereda de Cactus', () {
    test('el despacho ornamental devuelve identidad de nopal, no de cactus', () {
      final id = CropCatalog.nopalCropId;
      expect(ornamentalCropDisplayName(id), 'Nopal');
      expect(ornamentalDefaultProfileId(id), kNopalSkip);
      expect(ornamentalGeneralShortLabel(id), 'Nopal general');
      expect(ornamentalTypeQuestion(id), contains('nopal'));
    });

    test('los assets son los de nopal, no los de cactus', () {
      final id = CropCatalog.nopalCropId;
      expect(ornamentalCropIcon(id), NopalAssets.cropIcon);
      expect(ornamentalCropIcon(id), isNot(CactusAssets.cropIcon));
      for (final stage in _allStages) {
        expect(
          ornamentalStageImage(id, stage),
          contains('assets/seeds/nopal/'),
          reason: 'la etapa $stage no debe usar arte de otro cultivo',
        );
      }
      expect(
        ornamentalProfileIcon(id, kNopal01CompactClumpingContainer),
        NopalAssets.profileCompactClumpingContainer,
      );
    });

    test('los textos de etapa son los de nopal', () {
      final id = CropCatalog.nopalCropId;
      expect(
        ornamentalStageDisplayName(id, NopalStageIds.maintenance),
        'Estable',
      );
      expect(
        ornamentalStagePriorityText(id, NopalStageIds.maintenance),
        nopalStagePriorityText(NopalStageIds.maintenance),
      );
      expect(
        ornamentalStageCareNoteEs(id, NopalStageIds.activeGrowth),
        nopalStageCareNoteEs(NopalStageIds.activeGrowth),
      );
    });
  });

  // ── Perfiles (Doc A §6) ────────────────────────────────────────────────────
  group('Perfiles', () {
    test('son cinco y el general va al final', () {
      expect(nopalProfileEntries.length, 5);
      expect(nopalProfileEntries.last.id, kNopalSkip);
      expect(nopalProfileEntries.map((e) => e.id).toList(), _allProfiles);
    });

    test('el perfil general nunca muestra la palabra SKIP', () {
      final skip = nopalProfileEntries.last;
      expect(skip.label.toLowerCase(), isNot(contains('skip')));
      expect(skip.subtitle?.toLowerCase() ?? '', isNot(contains('skip')));
    });

    test('un alias ambiguo NO decide un perfil concreto', () {
      final def = NopalCropDefinition();
      for (final alias in <String>[
        'nopal de maceta',
        'nopal morado',
        'nopal criollo',
        'nopal sin espinas',
      ]) {
        expect(
          def.resolveProfile(profileId: alias)?.id,
          kNopalSkip,
          reason: '"$alias" describe contexto o color, no arquitectura',
        );
      }
    });

    test('un alias de forma sí decide perfil', () {
      final def = NopalCropDefinition();
      expect(
        def.resolveProfile(varietyAlias: 'opuntia microdasys')?.id,
        kNopal01CompactClumpingContainer,
      );
      expect(
        def.resolveProfile(varietyAlias: 'nopal de castilla')?.id,
        kNopal02UprightLargePadWarm,
      );
      expect(
        def.resolveProfile(varietyAlias: 'opuntia humifusa')?.id,
        kNopal04LowSpreadingColdHardy,
      );
    });

    test('un perfil desconocido cae en NO-SKIP, nunca en otra ornamental', () {
      final def = NopalCropDefinition();
      expect(def.resolveProfile(profileId: 'xx_99')?.id, kNopalSkip);
      expect(def.resolveProfile()?.id, kNopalSkip);
    });
  });

  // ── Etapas (Doc A §9, §12) ─────────────────────────────────────────────────
  group('Etapas', () {
    test('las seis etapas existen y unknown tiene targets propios', () {
      expect(NopalStageIds.all.length, 6);
      for (final stage in _allStages) {
        final t = resolveNopalTargets(stage);
        expect(t.moistureRaw.optimalMax, greaterThan(t.moistureRaw.optimalMin));
        expect(t.nSoilPpmRange, isNotNull);
      }
      final unknown = resolveNopalTargets(NopalStageIds.unknown);
      final maintenance = resolveNopalTargets(NopalStageIds.maintenance);
      expect(unknown.moistureRaw.highMin, isNot(maintenance.moistureRaw.highMin));
    });

    test('mantenimiento NO cierra el ciclo', () {
      expect(
        isAllowedNopalStageTransition(
          NopalStageIds.maintenance,
          NopalStageIds.installationEstablishment,
        ),
        isFalse,
      );
      expect(
        isAllowedNopalStageTransition(
          NopalStageIds.maintenance,
          NopalStageIds.activeGrowth,
        ),
        isTrue,
      );
    });

    test('ventanas por fecha del Doc A §12.1', () {
      final now = DateTime(2026, 7, 26);
      String at(int days, {String? profileId}) => estimateNopalStageFromDate(
        plantingDate: now.subtract(Duration(days: days)),
        now: now,
        profileId: profileId,
      ).stageId;

      expect(at(10), NopalStageIds.installationEstablishment);
      expect(at(21), NopalStageIds.installationEstablishment);
      expect(at(22), NopalStageIds.rootEstablishment);
      expect(at(120), NopalStageIds.rootEstablishment);
      expect(at(121), NopalStageIds.activeGrowth);
      expect(at(540), NopalStageIds.activeGrowth);
      expect(at(541), NopalStageIds.maintenance);
      expect(at(4000), NopalStageIds.maintenance);
    });

    test('NO-02 usa la ventana larga de instalación (30 días)', () {
      final now = DateTime(2026, 7, 26);
      String at(int days, String profileId) => estimateNopalStageFromDate(
        plantingDate: now.subtract(Duration(days: days)),
        now: now,
        profileId: profileId,
      ).stageId;

      expect(
        at(28, kNopal02UprightLargePadWarm),
        NopalStageIds.installationEstablishment,
      );
      expect(at(28, kNopalSkip), NopalStageIds.rootEstablishment);
    });

    test('"ya está plantado" sin fecha nunca se queda en unknown', () {
      final e = resolveNopalSetupStage(
        intentId: NopalSetupIntentIds.alreadyPlanted,
        plantingDate: null,
        now: DateTime(2026, 7, 26),
      );
      expect(e.stageId, NopalStageIds.maintenance);
    });

    test('reposo NO se infiere por fecha', () {
      for (var d = 0; d < 2000; d += 37) {
        final e = estimateNopalStageFromDate(
          plantingDate: DateTime(2026, 7, 26).subtract(Duration(days: d)),
          now: DateTime(2026, 7, 26),
        );
        expect(e.stageId, isNot(NopalStageIds.rest));
      }
    });
  });

  // ── Pesos y caps (Doc B §10, §14) ──────────────────────────────────────────
  group('Pesos y NPK caps', () {
    test('cada fila de pesos suma 1.00', () {
      for (final stage in _allStages) {
        for (final profile in <String?>[null, ..._allProfiles]) {
          final w = resolveNopalStageWeights(stage, profileId: profile);
          expect(
            w.sum,
            closeTo(1.0, 0.0001),
            reason: 'etapa $stage con perfil $profile',
          );
        }
      }
    });

    test('caps propios: N 90 · P 60 · K 280', () {
      double cap(AgroMetricKey k) =>
          NpkCaps.forCropMetric(cropKey: 'crop_nopal', metricKey: k);
      expect(cap(AgroMetricKey.n), 90.0);
      expect(cap(AgroMetricKey.p), 60.0);
      expect(cap(AgroMetricKey.k), 280.0);
    });

    test('los caps NO se heredan de cactus, suculenta ni sábila', () {
      for (final other in <String>['cactus', 'succulent', 'aloe']) {
        final same =
            NpkCaps.forCropMetric(
                  cropKey: other,
                  metricKey: AgroMetricKey.n,
                ) ==
                90.0 &&
            NpkCaps.forCropMetric(
                  cropKey: other,
                  metricKey: AgroMetricKey.p,
                ) ==
                60.0;
        expect(same, isFalse, reason: 'nopal no debe compartir caps con $other');
      }
      // Maguey comparte N=90 y K=280, así que la diferencia se prueba con P.
      expect(
        NpkCaps.forCropMetric(cropKey: 'maguey', metricKey: AgroMetricKey.p),
        isNot(
          NpkCaps.forCropMetric(cropKey: 'nopal', metricKey: AgroMetricKey.p),
        ),
      );
    });

    test('todos los aliases del cultivo devuelven el mismo cap', () {
      for (final alias in <String>[
        'nopal',
        'crop_nopal',
        'nopales',
        'opuntia',
        'orn_nopal',
        'prickly pear',
        'cactus pear',
      ]) {
        expect(
          NpkCaps.forCropMetric(cropKey: alias, metricKey: AgroMetricKey.k),
          280.0,
          reason: 'alias "$alias"',
        );
      }
    });
  });

  // ── Regresiones obligatorias de humedad (Doc B §5.7) ───────────────────────
  group('Regresiones de humedad', () {
    test('60 % es ÓPTIMO en crecimiento y nunca crítico en el resto', () {
      for (final stage in _allStages) {
        final r = _evaluate(
          t: _telemetry(moisture: 60),
          stage: stage,
        ).eval.metrics[AgroMetricKey.soilMoisture]!;
        if (stage == NopalStageIds.activeGrowth) {
          expect(r.band, AgroBand.optimal, reason: 'crecimiento');
        } else {
          expect(
            r.band,
            isNot(AgroBand.critical),
            reason: '60 % no debe ser rojo en $stage',
          );
        }
      }
    });

    test('82 % es crítico alto en TODAS las etapas', () {
      for (final stage in _allStages) {
        final res = _evaluate(t: _telemetry(moisture: 82), stage: stage);
        expect(
          res.eval.metrics[AgroMetricKey.soilMoisture]!.band,
          AgroBand.critical,
          reason: stage,
        );
        expect(res.eval.suggestedAlertKeys, contains('soilMoisture.critical'));
      }
    });

    test('2 % es crítico bajo y castiga menos que el exceso', () {
      final seco = _evaluate(t: _telemetry(moisture: 2)).eval;
      final mojado = _evaluate(t: _telemetry(moisture: 82)).eval;
      expect(seco.metrics[AgroMetricKey.soilMoisture]!.band, AgroBand.critical);
      expect(
        mojado.soilControlScore01,
        lessThan(seco.soilControlScore01),
        reason: 'el exceso de agua debe pesar más que la sequía',
      );
    });
  });

  // ── Claves de alerta (Doc B §1.4) ──────────────────────────────────────────
  group('Claves de alerta', () {
    test('solo se emiten claves canónicas', () {
      const canonicalPrefixes = <String>[
        'soilMoisture.',
        'soilTemp.',
        'ph.',
        'ec.',
        'resistance.',
        'airTemp.',
        'airHumidity.',
        'npk.',
        'stage.',
      ];
      final combos = <AgroEvalResult>[
        _evaluate(t: _telemetry(moisture: 90, soilTemp: -3, ec: 4.5, ph: 9)).eval,
        _evaluate(t: _telemetry(moisture: 1, airTemp: 48, airHumidity: 95)).eval,
        _evaluate(
          t: _telemetry(airTemp: -2),
          stage: NopalStageIds.rootEstablishment,
        ).eval,
      ];
      for (final eval in combos) {
        for (final key in eval.suggestedAlertKeys) {
          expect(
            canonicalPrefixes.any(key.startsWith),
            isTrue,
            reason: 'clave no canónica: $key',
          );
          expect(key.startsWith('nopal'), isFalse);
          expect(key.startsWith('opuntia'), isFalse);
        }
      }
    });

    test('la helada avisa siempre, también en NO-04 y en reposo', () {
      final res = _evaluate(
        t: _telemetry(airTemp: -1),
        stage: NopalStageIds.rest,
        profileId: kNopal04LowSpreadingColdHardy,
      );
      expect(res.eval.suggestedAlertKeys, contains('airTemp.frost'));
    });

    test('el aviso de frío no dispara en reposo confirmado', () {
      final rest = _evaluate(
        t: _telemetry(airTemp: 3),
        stage: NopalStageIds.rest,
      );
      final growth = _evaluate(
        t: _telemetry(airTemp: 3),
        stage: NopalStageIds.activeGrowth,
      );
      expect(rest.eval.suggestedAlertKeys, isNot(contains('airTemp.cold')));
      expect(growth.eval.suggestedAlertKeys, contains('airTemp.cold'));
    });
  });

  // ── Ajustes por perfil (Doc B §6.5, §8.4, §15) ─────────────────────────────
  group('Ajustes por perfil', () {
    test('NO-01 solo estrecha rangos si el contexto es maceta o vivero', () {
      final base = resolveNopalTargets(NopalStageIds.maintenance);
      final enMaceta = resolveNopalTargetsForProfile(
        NopalStageIds.maintenance,
        profileId: kNopal01CompactClumpingContainer,
        cultivationContextId: 'pot',
      );
      final enSuelo = resolveNopalTargetsForProfile(
        NopalStageIds.maintenance,
        profileId: kNopal01CompactClumpingContainer,
        cultivationContextId: 'open_ground',
      );
      expect(enMaceta.moistureRaw.highMin, base.moistureRaw.highMin - 4);
      expect(enSuelo.moistureRaw.highMin, base.moistureRaw.highMin);
      expect(enMaceta.ec.highMin, closeTo(base.ec.highMin - 0.25, 0.0001));
    });

    test('NO-04 recibe tolerancia al frío solo en estable y reposo', () {
      final base = resolveNopalTargets(NopalStageIds.rest);
      final frio = resolveNopalTargetsForProfile(
        NopalStageIds.rest,
        profileId: kNopal04LowSpreadingColdHardy,
      );
      expect(frio.soilTemp.lowMax, lessThan(base.soilTemp.lowMax));

      final raiz = resolveNopalTargetsForProfile(
        NopalStageIds.rootEstablishment,
        profileId: kNopal04LowSpreadingColdHardy,
      );
      expect(
        raiz.soilTemp.lowMax,
        resolveNopalTargets(NopalStageIds.rootEstablishment).soilTemp.lowMax,
        reason: 'en raíz NO se aplica la tolerancia al frío',
      );
    });

    test('el pH viene del contexto, nunca del perfil', () {
      for (final profile in _allProfiles) {
        final maceta = resolveNopalTargetsForProfile(
          NopalStageIds.maintenance,
          profileId: profile,
          cultivationContextId: 'pot',
        );
        final paisaje = resolveNopalTargetsForProfile(
          NopalStageIds.maintenance,
          profileId: profile,
          cultivationContextId: 'landscape',
        );
        expect(maceta.ph.highMin, NopalUniversalProfile.phPotNursery.highMin);
        expect(
          paisaje.ph.highMin,
          NopalUniversalProfile.phLandscapeGround.highMin,
        );
      }
    });

    test('NO-SKIP limita la prioridad de NPK a revisión', () {
      final adj = nopalProfileAdjustments(kNopalSkip);
      expect(adj.limitNpkPriorityToReview, isTrue);
      expect(adj.sensorLocalCaution, isTrue);
      expect(adj.coldSeverityMultiplier, 1.0);
    });
  });

  // ── Sanidad (Doc C) ────────────────────────────────────────────────────────
  group('Sanidad', () {
    test('el registro devuelve los 18 síndromes de nopal', () {
      final catalog = PlantHealthRegistry.catalogForCrop(
        CropCatalog.nopalCropId,
      );
      expect(catalog.length, 18);
      expect(catalog, same(nopalSyndromes));
      for (final s in catalog) {
        expect(s.cropId, CropCatalog.nopalCropId);
      }
    });

    test('los alias del cultivo también encuentran el catálogo', () {
      expect(PlantHealthRegistry.catalogForCrop('nopal').length, 18);
      expect(PlantHealthRegistry.catalogForCrop('opuntia').length, 18);
    });

    test('el adaptador mapea las seis etapas a los buckets correctos', () {
      PlantHealthStageBucket? bucket(String stage) =>
          PlantHealthStageAdapter.fromCropStage(
            cropId: CropCatalog.nopalCropId,
            stageKey: stage,
            daySinceSowing: null,
          );
      expect(
        bucket(NopalStageIds.installationEstablishment),
        PlantHealthStageBucket.seedling,
      );
      expect(
        bucket(NopalStageIds.rootEstablishment),
        PlantHealthStageBucket.seedling,
      );
      expect(
        bucket(NopalStageIds.activeGrowth),
        PlantHealthStageBucket.vegetativeMid,
      );
      expect(
        bucket(NopalStageIds.maintenance),
        PlantHealthStageBucket.vegetativeLate,
      );
      expect(bucket(NopalStageIds.rest), PlantHealthStageBucket.lateSeason);
      expect(bucket(NopalStageIds.unknown), isNull);
    });

    test('existe el órgano penca y tiene etiqueta humana', () {
      expect(PlantHealthIds.organCladode, 'cladode');
      expect(PlantHealthIds.organLabel(PlantHealthIds.organCladode), 'Penca');
    });

    test('cada síndrome tiene id, síntoma y etiquetas resueltas', () {
      final ids = <String>{};
      for (final s in nopalSyndromes) {
        expect(ids.add(s.id), isTrue, reason: 'id duplicado: ${s.id}');
        expect(s.labelEs, isNotEmpty);
        expect(s.primarySymptomId, isNotEmpty);
        expect(
          PlantHealthIds.symptomLabel(s.primarySymptomId),
          isNot(s.primarySymptomId),
          reason: 'sin etiqueta: ${s.primarySymptomId}',
        );
        for (final signal in <String>{
          ...s.strongSignals,
          ...s.weakSignals,
          ...s.conflictingSignals,
        }) {
          expect(
            PlantHealthIds.signalLabel(signal),
            isNot(signal),
            reason: 'señal sin etiqueta: $signal',
          );
        }
        for (final organ in s.organIds) {
          expect(
            PlantHealthIds.organLabel(organ),
            isNot(organ),
            reason: 'órgano sin etiqueta: $organ',
          );
        }
        expect(s.probableDiagnoses, isNotEmpty);
        expect(s.probableDiagnoses.length, lessThanOrEqualTo(4));
        expect(s.confirmationChecksEs, isNotEmpty);
        expect(s.baseActionsEs, isNotEmpty);
        expect(s.disclaimerEs, isNotEmpty);
      }
    });

    test('ningún texto de sanidad diagnostica ni receta', () {
      const prohibidas = <String>[
        'tu nopal tiene',
        'aplica ',
        'rocía',
        'fumiga',
        'gramos',
        'mililitros',
        'cada siete días',
        'está muerto',
      ];
      for (final s in nopalSyndromes) {
        final texto = <String>[
          s.labelEs,
          s.disclaimerEs,
          ...s.confirmationChecksEs,
          ...s.baseActionsEs,
          ...s.probableDiagnoses.map((d) => '${d.labelEs} ${d.summaryEs}'),
        ].join(' ').toLowerCase();
        for (final frase in prohibidas) {
          expect(
            texto.contains(frase),
            isFalse,
            reason: '${s.id} contiene "$frase"',
          );
        }
      }
    });

    test('los patrones de alta consecuencia piden no mover material', () {
      final altos = nopalSyndromes
          .where((s) => s.severity == PlantHealthSeverity.critical)
          .toList();
      expect(altos, isNotEmpty);
      for (final s in altos) {
        final acciones = s.baseActionsEs.join(' ').toLowerCase();
        expect(acciones, contains('no muevas'));
        expect(s.disclaimerEs.toLowerCase(), contains('autoridad'));
      }
    });
  });
}
