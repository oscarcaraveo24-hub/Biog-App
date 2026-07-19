// test/core/cactus/cactus_integration_test.dart
//
// Contratos de la integración de Cactus (primera ornamental de BIO-G).
//
// Regla que estas pruebas blindan: EL CACTUS SE COMPORTA COMO FRIJOL.
// Mismas unidades, mismas bandas, mismas claves de alerta, mismo motor de
// nutrición. Lo único distinto es que NO es cíclico (establecimiento →
// mantenimiento, sin cosecha ni rendimiento), igual que el árbol.
//
// La integración anterior fallaba justo aquí: usaba "índices comparables" en
// vez de MPa / mS/cm, emitía claves de alerta propias que el AlertsEngine
// compartido no reconoce (→ cero alertas) y mostraba etiquetas ilegibles.

import 'package:flutter_test/flutter_test.dart';

import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/agro/npk_caps.dart';
import 'package:bio_g/core/crops/cactus/cactus_agro_score_engine.dart';
import 'package:bio_g/core/crops/cactus/cactus_catalog.dart';
import 'package:bio_g/core/crops/cactus/cactus_crop_definition.dart';
import 'package:bio_g/core/crops/cactus/cactus_lifecycle.dart';
import 'package:bio_g/core/crops/cactus/cactus_stage_resolver.dart';
import 'package:bio_g/core/crops/cactus/cactus_universal_profile.dart';
import 'package:bio_g/core/crops/catalog/crop_catalog.dart';
import 'package:bio_g/core/crops/crop_registry.dart';
import 'package:bio_g/core/crops/crop_types.dart';
import 'package:bio_g/models/biog_telemetry.dart';
import 'package:bio_g/models/device_crop_context.dart';

const List<String> _allStages = <String>[
  CactusStageIds.installationEstablishment,
  CactusStageIds.rootEstablishment,
  CactusStageIds.activeGrowth,
  CactusStageIds.maintenance,
  CactusStageIds.rest,
  CactusStageIds.unknown,
];

BioGTelemetry _telemetry({
  double moisture = 20,
  double soilTemp = 24,
  double ph = 6.4,
  double ec = 0.7,
  double resistance = 0.6,
  double n = 20,
  double p = 18,
  double k = 100,
  double airTemp = 26,
  double airHumidity = 45,
}) {
  return BioGTelemetry(
    deviceId: 'dev-cactus',
    timestamp: DateTime(2026, 7, 12, 9),
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
  String stage = CactusStageIds.maintenance,
}) {
  return CactusAgroScoreEngine.evaluate(
    t: t,
    stageId: stage,
    stageLabelEs: cactusStageDisplayName(stage),
    targets: resolveCactusTargets(stage),
    weights: resolveCactusStageWeights(stage),
    cropLabel: 'Cactus',
  );
}

void main() {
  group('Unidades reales (el bug de raíz)', () {
    test('EC en mS/cm, no un índice 40-160', () {
      for (final stage in _allStages) {
        final ec = resolveCactusTargets(stage).ec;
        expect(
          ec.highMin,
          lessThan(5),
          reason: 'EC de $stage debe ser mS/cm (frijol: 0.4-1.8), no un índice',
        );
        expect(ec.optimalMin, greaterThan(0));
      }
    });

    test('Resistencia en MPa, no un índice 40-190', () {
      for (final stage in _allStages) {
        final r = resolveCactusTargets(stage).resistance;
        expect(
          r.highMin,
          lessThan(3),
          reason: 'Resistencia de $stage debe ser MPa (frijol: 0-2.0)',
        );
      }
    });

    test('NPK expone rangos comparables en mg/kg', () {
      for (final stage in _allStages) {
        final t = resolveCactusTargets(stage);
        expect(t.nSoilPpmRange, isNotNull);
        expect(t.pSoilPpmRange, isNotNull);
        expect(t.kSoilPpmRange, isNotNull);
        // Cactus = baja demanda: nunca los targets de un cultivo de grano.
        expect(t.nSoilPpmRange!.optimalMax, lessThanOrEqualTo(45));
        // En cactus el K manda sobre el N.
        expect(
          t.kSoilPpmRange!.optimalMax,
          greaterThan(t.nSoilPpmRange!.optimalMax),
        );
      }
    });

    test('los pesos de cada etapa suman 1.0', () {
      for (final stage in _allStages) {
        expect(
          resolveCactusStageWeights(stage).sum,
          closeTo(1.0, 0.001),
          reason: 'Los pesos de $stage deben sumar 1.0, como frijol y árbol',
        );
      }
    });
  });

  group('El motor se comporta como el de frijol', () {
    test('clasifica las 5 métricas de suelo con bandas reales', () {
      final out = _evaluate(t: _telemetry());
      for (final key in <AgroMetricKey>[
        AgroMetricKey.soilMoisture,
        AgroMetricKey.soilTemp,
        AgroMetricKey.ph,
        AgroMetricKey.ec,
        AgroMetricKey.resistance,
      ]) {
        expect(
          out.eval.metrics[key]?.band,
          isNot(AgroBand.unknown),
          reason: '$key debe clasificarse, no quedar "sin baseline"',
        );
      }
    });

    test('una lectura sana da banda Óptimo y score alto', () {
      final out = _evaluate(t: _telemetry());
      expect(
        out.eval.metrics[AgroMetricKey.soilMoisture]?.band,
        AgroBand.optimal,
      );
      expect(out.eval.soilControlScore01, greaterThan(0.7));
    });

    test('interpreta NPK de verdad (no lo anula)', () {
      final out = _evaluate(t: _telemetry());
      for (final key in <AgroMetricKey>[
        AgroMetricKey.n,
        AgroMetricKey.p,
        AgroMetricKey.k,
      ]) {
        final m = out.eval.metrics[key];
        expect(
          m?.priorityLabel,
          isNotNull,
          reason: '$key debe recibir interpretación, no "No accionable"',
        );
        expect(m!.priorityLabel, isNot(NutrientPriorityLabel.unknown));
      }
    });

    test('usa claves CANÓNICAS del AlertsEngine, no claves "cactus.*"', () {
      final out = _evaluate(
        t: _telemetry(moisture: 95, soilTemp: 3, ec: 3.5, resistance: 2.6),
      );

      for (final key in out.eval.suggestedAlertKeys) {
        expect(
          key.startsWith('cactus.'),
          isFalse,
          reason:
              'La clave "$key" no existe en el AlertsEngine compartido; '
              'el cactus quedaría mudo (ese era el bug).',
        );
      }
      expect(out.eval.suggestedAlertKeys, contains('soilMoisture.critical'));
    });

    test('SÍ emite alertas reales al agricultor', () {
      final out = _evaluate(t: _telemetry(moisture: 95, soilTemp: 3, ec: 3.5));
      expect(
        out.eval.alerts,
        isNotEmpty,
        reason: 'Antes el cactus no generaba ninguna alerta',
      );
      for (final a in out.eval.alerts) {
        expect(a.title.trim(), isNotEmpty);
        expect(a.body.trim(), isNotEmpty);
      }
    });
  });

  group('Agronomía del cactus', () {
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
        reason: 'Encharcado debe puntuar peor que seco: así se pudre la raíz',
      );
    });

    test('frío + humedad castiga más que el frío solo', () {
      final coldWet = _evaluate(t: _telemetry(moisture: 90, soilTemp: 2));
      final coldDry = _evaluate(t: _telemetry(moisture: 15, soilTemp: 2));
      expect(
        coldWet.eval.soilControlScore01,
        lessThan(coldDry.eval.soilControlScore01),
      );
    });

    test('el sustrato compactado se detecta', () {
      final out = _evaluate(t: _telemetry(resistance: 2.8));
      expect(
        out.eval.metrics[AgroMetricKey.resistance]?.band,
        AgroBand.critical,
      );
      expect(out.eval.suggestedAlertKeys, contains('resistance.critical'));
    });

    test('los caps NPK son bajos y K > N', () {
      final capN = NpkCaps.forCropMetric(
        cropKey: 'cactus',
        metricKey: AgroMetricKey.n,
      );
      final capK = NpkCaps.forCropMetric(
        cropKey: 'cactus',
        metricKey: AgroMetricKey.k,
      );
      expect(capN, lessThan(100), reason: 'Cactus no es un cultivo de grano');
      expect(capK, greaterThan(capN), reason: 'En cactus el K manda');
    });
  });

  // La planta ornamental de maceta: se planta, arraiga, crece, y se ESTABILIZA
  // para siempre. No es un ciclo. No se reinicia. No tiene día terminal.
  group('Progresión de vida (una sola pasada, sin reinicio)', () {
    final now = DateTime(2026, 7, 13);

    CactusStageEstimate at(int days, {String? profileId}) {
      return estimateCactusStageFromDate(
        plantingDate: now.subtract(Duration(days: days)),
        now: now,
        profileId: profileId,
      );
    }

    test('la progresión completa: plantada → raíz → creciendo → estable', () {
      expect(at(1).stageId, CactusStageIds.installationEstablishment);
      expect(at(14).stageId, CactusStageIds.installationEstablishment);
      expect(at(15).stageId, CactusStageIds.rootEstablishment);
      expect(at(84).stageId, CactusStageIds.rootEstablishment);
      expect(at(85).stageId, CactusStageIds.activeGrowth);
      expect(at(365).stageId, CactusStageIds.activeGrowth);
      expect(at(366).stageId, CactusStageIds.maintenance);
    });

    test('"Creciendo" es ALCANZABLE (era una etapa muerta)', () {
      expect(
        at(180).stageId,
        CactusStageIds.activeGrowth,
        reason: 'Antes la progresión saltaba de raíz directo a estable',
      );
    });

    test('el columnar grande establece más lento', () {
      expect(
        at(20, profileId: kCa03ColumnarLandscape).stageId,
        CactusStageIds.installationEstablishment,
      );
      expect(at(20).stageId, CactusStageIds.rootEstablishment);
    });

    test('ESTABLE ES PARA SIEMPRE: a 1, 5 y 20 años sigue estable', () {
      for (final years in <int>[1, 5, 20]) {
        expect(
          at(365 * years + 1).stageId,
          CactusStageIds.maintenance,
          reason: 'A los $years años NO puede reiniciarse ni terminar',
        );
      }
    });

    test('NINGUNA etapa puede regresar a "Recién plantada" (sin reinicio)', () {
      for (final from in <String>[
        CactusStageIds.rootEstablishment,
        CactusStageIds.activeGrowth,
        CactusStageIds.maintenance,
        CactusStageIds.rest,
      ]) {
        expect(
          isAllowedCactusStageTransition(
            from,
            CactusStageIds.installationEstablishment,
          ),
          isFalse,
          reason: '$from NO puede volver al principio: eso sería un ciclo',
        );
      }
    });

    test('estable puede volver a crecer o descansar, pero nunca reiniciar', () {
      // Una planta estable puede retomar crecimiento en su temporada. Eso NO es
      // un reinicio de ciclo: es la misma planta, más vieja.
      expect(
        isAllowedCactusStageTransition(
          CactusStageIds.maintenance,
          CactusStageIds.activeGrowth,
        ),
        isTrue,
      );
      expect(
        isAllowedCactusStageTransition(
          CactusStageIds.maintenance,
          CactusStageIds.rest,
        ),
        isTrue,
      );
    });
  });

  group('No cíclico (como el árbol)', () {
    test('no proyecta rendimiento ni cosecha', () {
      expect(CactusLifecycle.supportsYieldProjection, isFalse);
      expect(CactusLifecycle.supportsHarvest, isFalse);
      expect(CactusLifecycle.lifecycleMode, 'establishment_maintenance');
    });

    // Decisión congelada en docs/ornamentales/00_Estandar_BIOG_Ornamentales_v1.md §8.
    // El microciclo hídrico y la memoria de estrés se descartaron: exigían un
    // baseline por dispositivo que no existe, y se persistían sin calcularse
    // nunca ("Patrón por aprender" eterno). No se declara lo que no se computa.
    test('microciclo hídrico y memoria de estrés siguen descartados', () {
      expect(
        CactusLifecycle.supportsHydricCycle,
        isFalse,
        reason: 'Si esto vuelve a true, alguien debe HABER construido el motor '
            'de baseline hídrico primero. Ver Doc 00 §8.',
      );
      expect(CactusLifecycle.supportsStressMemory, isFalse);
    });

    test('mantenimiento NUNCA cierra el ciclo', () {
      expect(
        isAllowedCactusStageTransition(
          CactusStageIds.maintenance,
          CactusStageIds.activeGrowth,
        ),
        isTrue,
      );
      expect(
        isAllowedCactusStageTransition(
          CactusStageIds.maintenance,
          CactusStageIds.maintenance,
        ),
        isTrue,
      );
    });

    test('una planta vieja está estable, no "por confirmar"', () {
      final estimate = estimateCactusStageFromDate(
        plantingDate: DateTime(2020, 1, 1),
        now: DateTime(2026, 7, 12),
      );
      expect(estimate.stageId, CactusStageIds.maintenance);
    });
  });

  // El bug: el wizard resolvía la etapa a mano y para "ya está plantado" hacía
  // normalizeCactusStageId(null), que devuelve el STRING 'unknown'. Ese
  // 'unknown' pisaba la estimación por fecha y el usuario veía siempre
  // "Etapa por confirmar" aunque hubiera dicho que la planta ya estaba plantada.
  group('La etapa corresponde con lo que eligió el usuario', () {
    final now = DateTime(2026, 7, 13);

    test('"lo voy a plantar" → Recién plantada', () {
      final e = resolveCactusSetupStage(
        intentId: CactusSetupIntentIds.plannedPlant,
        plantingDate: now.add(const Duration(days: 5)),
        now: now,
      );
      expect(e.stageId, CactusStageIds.installationEstablishment);
    });

    test('"ya está plantado" hace años → Estable (NO "por confirmar")', () {
      final e = resolveCactusSetupStage(
        intentId: CactusSetupIntentIds.alreadyPlanted,
        plantingDate: DateTime(2021, 3, 1),
        now: now,
      );
      expect(e.stageId, CactusStageIds.maintenance);
      expect(e.stageId, isNot(CactusStageIds.unknown));
    });

    test('"ya está plantado" sin fecha → Estable, no "por confirmar"', () {
      final e = resolveCactusSetupStage(
        intentId: CactusSetupIntentIds.alreadyPlanted,
        plantingDate: null,
        now: now,
      );
      expect(
        e.stageId,
        CactusStageIds.maintenance,
        reason: 'El usuario acaba de decir que la planta ya existe',
      );
    });

    test('"ya está plantado" hace 3 semanas → Echando raíz', () {
      final e = resolveCactusSetupStage(
        intentId: CactusSetupIntentIds.alreadyPlanted,
        plantingDate: now.subtract(const Duration(days: 21)),
        now: now,
      );
      expect(e.stageId, CactusStageIds.rootEstablishment);
    });

    test('"ya está plantado" hace 3 días → Recién plantada', () {
      final e = resolveCactusSetupStage(
        intentId: CactusSetupIntentIds.alreadyPlanted,
        plantingDate: now.subtract(const Duration(days: 3)),
        now: now,
      );
      expect(e.stageId, CactusStageIds.installationEstablishment);
    });

    test('una etapa ya confirmada por el usuario se respeta', () {
      final e = resolveCactusSetupStage(
        intentId: CactusSetupIntentIds.alreadyPlanted,
        plantingDate: DateTime(2021, 3, 1),
        now: now,
        previousStageId: CactusStageIds.rest,
      );
      expect(e.stageId, CactusStageIds.rest);
    });
  });

  // El bug de la SeedsScreen: leía `cropContext.ornamentalStageId` CRUDO. Si el
  // contexto se había guardado con 'unknown', la pantalla se quedaba clavada en
  // "Etapa por confirmar" aunque el usuario hubiera dado la fecha. La fuente
  // correcta es el runtime resuelto (CactusStageResolver), que además se
  // auto-repara.
  group('CactusStageResolver alimenta las pantallas', () {
    DeviceCropContext context({
      DateTime? anchor,
      String? storedStage,
      CropLifecycleStatus status = CropLifecycleStatus.planted,
    }) {
      return DeviceCropContext(
        deviceId: 'dev-1',
        cropCategoryId: CropCatalog.ornamentalCategoryId,
        cropId: CropCatalog.cactusCropId,
        profileId: kCa01DesertContainer,
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

    // El caso reportado: maceta, "ya está plantado", plantado el 2 de mayo.
    // 72 días → Echando raíz. Antes salía "Etapa por confirmar".
    test('maceta plantada el 2 de mayo → Echando raíz, con día real', () {
      final result = CactusStageResolver.resolve(
        context: context(anchor: DateTime(2026, 5, 2)),
        today: DateTime(2026, 7, 13),
      );

      expect(result.stageKey, CactusStageIds.rootEstablishment);
      expect(result.stageLabelEs, 'Echando raíz');
      expect(
        result.stageLabelEs,
        isNot('Etapa por confirmar'),
        reason: 'Este era el bug reportado',
      );
      expect(
        result.daySinceSowing,
        72,
        reason: 'La SeedsScreen debe poder mostrar "Día: 72", como en frijol',
      );
    });

    test('un contexto guardado con "unknown" se AUTO-REPARA', () {
      final result = CactusStageResolver.resolve(
        // Así quedaron guardados los contextos creados con el bug.
        context: context(
          anchor: DateTime(2026, 5, 2),
          storedStage: CactusStageIds.unknown,
        ),
        today: DateTime(2026, 7, 13),
      );

      expect(
        result.stageKey,
        CactusStageIds.rootEstablishment,
        reason: 'Un "unknown" guardado no debe congelar la etapa para siempre',
      );
    });

    test('una etapa real guardada se respeta', () {
      final result = CactusStageResolver.resolve(
        context: context(
          anchor: DateTime(2026, 5, 2),
          storedStage: CactusStageIds.rest,
        ),
        today: DateTime(2026, 7, 13),
      );
      expect(result.stageKey, CactusStageIds.rest);
    });

    test('el cactus no tiene día terminal de ciclo', () {
      final result = CactusStageResolver.resolve(
        context: context(anchor: DateTime(2024, 1, 1)),
        today: DateTime(2026, 7, 13),
      );
      expect(result.stageKey, CactusStageIds.maintenance);
      expect(result.expectedDaysToEnd, 0);
      expect(result.windowsNow, isEmpty);
    });

    test('planeado (aún no la planta) → Recién plantada, sin día', () {
      final result = CactusStageResolver.resolve(
        context: context(
          anchor: DateTime(2026, 8, 1),
          status: CropLifecycleStatus.planned,
        ),
        today: DateTime(2026, 7, 13),
      );
      expect(result.stageKey, CactusStageIds.installationEstablishment);
      expect(result.daySinceSowing, isNull);
    });
  });

  group('Wizard: solo dos opciones de alta', () {
    test('las intenciones son exactamente plantar y ya plantado', () {
      expect(CactusSetupIntentIds.all, hasLength(2));
      expect(
        CactusSetupIntentIds.all,
        containsAll(<String>[
          CactusSetupIntentIds.plannedPlant,
          CactusSetupIntentIds.alreadyPlanted,
        ]),
      );
    });

    test('el "repot" retirado se lee como "ya está plantado"', () {
      expect(
        normalizeCactusSetupIntentId('repot'),
        CactusSetupIntentIds.alreadyPlanted,
      );
      expect(
        normalizeCactusSetupIntentId('transplant'),
        CactusSetupIntentIds.alreadyPlanted,
      );
    });

    test('solo "lo voy a plantar" pide fecha futura', () {
      expect(
        cactusSetupIntentRequiresFutureDate(CactusSetupIntentIds.plannedPlant),
        isTrue,
      );
      expect(
        cactusSetupIntentRequiresFutureDate(
          CactusSetupIntentIds.alreadyPlanted,
        ),
        isFalse,
      );
    });
  });

  group('Wizard: orden de los perfiles', () {
    test('"No sé / cactus general" va HASTA ABAJO', () {
      final profiles = CropCatalog.profilesForCrop(
        CropCatalog.cactusCropId,
        enabledOnly: false,
      );
      expect(profiles, isNotEmpty);
      expect(
        profiles.last.id,
        kCaSkip,
        reason: 'La salida "no sé" es la red de seguridad, no la primera opción',
      );
      expect(
        profiles.first.id,
        isNot(kCaSkip),
        reason: 'El menú no debe abrir con "No sé"',
      );
    });
  });

  group('Lenguaje de agricultor (UI/UX)', () {
    test('las etapas se llaman en cristiano', () {
      expect(
        cactusStageDisplayName(CactusStageIds.installationEstablishment),
        'Recién plantada',
      );
      expect(cactusStageDisplayName(CactusStageIds.maintenance), 'Estable');
      expect(cactusStageDisplayName(CactusStageIds.rest), 'En reposo');
    });

    test('ningún texto usa jerga prohibida', () {
      const forbidden = <String>[
        'baseline',
        'objetivo',
        'no accionable',
        'electroconductividad',
        'microciclo',
        'orientativa',
        'ornamental',
      ];

      final texts = <String>[
        for (final s in _allStages) ...<String>[
          cactusStageDisplayName(s),
          cactusStageCareNoteEs(s),
          cactusStagePriorityText(s),
          cactusCriticalWindowLabel(s) ?? '',
        ],
      ];

      for (final text in texts) {
        for (final word in forbidden) {
          expect(
            text.toLowerCase().contains(word),
            isFalse,
            reason: '"$text" no debería decirle "$word" a un agricultor',
          );
        }
      }
    });
  });

  group('Identidad del cultivo', () {
    test('está en el catálogo y en el registry', () {
      final entry = CropCatalog.cropById(CropCatalog.cactusCropId);
      expect(entry, isNotNull);
      expect(entry!.categoryId, CropCatalog.ornamentalCategoryId);
      expect(entry.enabled, isTrue);

      final definition = CropRegistry.byKey(CropKey.cactus);
      expect(definition, isA<CactusCropDefinition>());
      expect(definition!.displayName, 'Cactus');
    });

    test('los alias humanos resuelven a cactus', () {
      for (final alias in <String>['cactus', 'cacto', 'crop_cactus']) {
        expect(CropCatalog.canonicalCropKey(alias), CropCatalog.cactusCropId);
      }
    });

    test('el perfil general nunca muestra "SKIP" al usuario', () {
      final profile = CropCatalog.profileByAny(
        CropCatalog.cactusCropId,
        kCaSkip,
      );
      expect(profile, isNotNull);
      expect(profile!.label.toLowerCase(), isNot(contains('skip')));
    });
  });
}
