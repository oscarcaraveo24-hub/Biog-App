// test/core/crops/generic_guide_test.dart
//
// Fija el contrato del MODO GUÍA GENERAL: bandas para las cinco condiciones
// del suelo, y NADA de nutrición.
//
// Lo que estas pruebas protegen no es una cifra, es una línea doctrinal. Si
// alguien "arregla" el motor de guía para que también emita N, P y K —porque
// parece incompleto— la app empezaría a recomendar fertilización para una
// planta que no sabe cuál es. Las pruebas de NPK de abajo están para que ese
// cambio no pase en silencio.

import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/agro/guide_agro_score_engine.dart';
import 'package:bio_g/core/crops/crop_runtime_resolver.dart';
import 'package:bio_g/core/crops/crop_runtime_snapshot.dart';
import 'package:bio_g/core/crops/generic/generic_guide.dart';
import 'package:bio_g/models/biog_telemetry.dart';
import 'package:bio_g/models/device_crop_context.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const AlertsState emptyAlerts = AlertsState();
  final DateTime now = DateTime.utc(2026, 8, 10, 12);
  const String deviceId = '3f2504e0-4f89-11d3-9a0c-0305e82c3301';

  BioGTelemetry telemetry({
    double moisture = 45,
    double ph = 6.5,
    double soilTemp = 20,
    double resistance = 0.8,
    double ec = 1.0,
    int n = 40,
    int p = 25,
    int k = 60,
    double airTemp = 22,
    double airHumidity = 55,
  }) {
    return BioGTelemetry.tryFromJson(<String, dynamic>{
      'device_id': deviceId,
      'timestamp': now.toIso8601String(),
      'soil_moisture_pct': moisture,
      'ph': ph,
      'soil_temp_c': soilTemp,
      'resistance': resistance,
      'ec': ec,
      'n': n,
      'p': p,
      'k': k,
      'air_temp_c': airTemp,
      'air_humidity_pct': airHumidity,
    })!;
  }

  DeviceCropContext guideContext() {
    return DeviceCropContext(
      deviceId: deviceId,
      cropCategoryId: kGuideCategoryId,
      cropId: kGuideCropId,
      profileId: kGuideProfileId,
      lifecycleStatus: CropLifecycleStatus.planted,
      sowingDateConfidence: DateConfidence.unknown,
      catalogVersion: 'test',
      source: CropConfigSource.wizard,
      configuredAt: now,
      updatedAt: now,
    );
  }

  CropRuntimeSnapshot resolveGuide({BioGTelemetry? live}) {
    return CropRuntimeResolver.resolve(
      device: null,
      seed: null,
      cropContext: guideContext(),
      live: live ?? telemetry(),
      alertsState: emptyAlerts,
      now: now,
    );
  }

  group('isGuideCropId', () {
    test('reconoce el centinela y la categoría', () {
      expect(isGuideCropId(kGuideCropId), isTrue);
      expect(isGuideCropId(kGuideCategoryId), isTrue);
      expect(isGuideCropId('  CROP_GENERIC '), isTrue);
    });

    test('no se traga cultivos reales ni nulos', () {
      expect(isGuideCropId(null), isFalse);
      expect(isGuideCropId(''), isFalse);
      expect(isGuideCropId('maize'), isFalse);
      // Ojo: "maíz genérico" es una VARIEDAD genérica de un cultivo real.
      // Ese es el modo genérico de siempre y no debe confundirse con la guía.
      expect(isGuideCropId('generic_maize'), isFalse);
    });
  });

  group('el motor de guía no toca la nutrición', () {
    test('emite exactamente las cinco métricas de suelo', () {
      final build = GuideAgroScoreEngine.evaluate(t: telemetry());

      expect(build.eval.metrics.keys.toSet(), <AgroMetricKey>{
        AgroMetricKey.soilMoisture,
        AgroMetricKey.soilTemp,
        AgroMetricKey.ph,
        AgroMetricKey.ec,
        AgroMetricKey.resistance,
      });
    });

    test('N, P y K NO aparecen en el mapa, ni siquiera como desconocidos', () {
      // La diferencia importa: una clave con banda `unknown` la pintaría
      // igualmente cualquier pantalla que la lea sin comprobar el modo. Una
      // clave ausente no se puede pintar por accidente.
      final build = GuideAgroScoreEngine.evaluate(t: telemetry(n: 90, p: 5));

      expect(build.eval.metrics.containsKey(AgroMetricKey.n), isFalse);
      expect(build.eval.metrics.containsKey(AgroMetricKey.p), isFalse);
      expect(build.eval.metrics.containsKey(AgroMetricKey.k), isFalse);
    });

    test('el nitrógeno no mueve el score de suelo', () {
      // Si `npk` dejara de valer 0 en los pesos, este test lo caza.
      final pobre = GuideAgroScoreEngine.evaluate(t: telemetry(n: 0, p: 0, k: 0));
      final rico = GuideAgroScoreEngine.evaluate(
        t: telemetry(n: 200, p: 200, k: 200),
      );

      expect(
        pobre.eval.soilControlScore01,
        closeTo(rico.eval.soilControlScore01, 1e-9),
      );
    });

    test('ninguna alerta sugerida habla de nutrientes', () {
      final build = GuideAgroScoreEngine.evaluate(t: telemetry(n: 0, k: 400));

      expect(
        build.eval.suggestedAlertKeys.where((String k) => k.startsWith('npk')),
        isEmpty,
      );
    });
  });

  group('política de alertas de la guía', () {
    test('la helada llega igual que en cualquier otro cultivo', () {
      // Lo que más importa de este grupo. Una helada no pregunta si la planta
      // está en el catálogo; si este test se cae, el usuario de guía es el
      // único de la app que se entera del frío cuando ya se le quemó.
      final build = GuideAgroScoreEngine.evaluate(
        t: telemetry(airTemp: -1),
      );

      expect(build.eval.suggestedAlertKeys, contains('airTemp.frost'));
      expect(build.eval.alerts, isNotEmpty);
      expect(build.eval.alerts.first.severity, BioGAlertSeverity.critical);
    });

    test('el calor extremo también', () {
      final build = GuideAgroScoreEngine.evaluate(t: telemetry(airTemp: 42));

      expect(build.eval.suggestedAlertKeys, contains('airTemp.extreme_heat'));
    });

    test('con clima normal no inventa alertas ambientales', () {
      final build = GuideAgroScoreEngine.evaluate(t: telemetry());

      expect(
        build.eval.suggestedAlertKeys.where(
          (String k) => k.startsWith('airTemp') || k.startsWith('airHumidity'),
        ),
        isEmpty,
      );
    });

    test('solo notifica lo crítico del suelo, nunca bajo ni alto', () {
      // "Bajo" y "Alto" se pintan en las bandas del Panel; no suenan el
      // teléfono. Sin esta regla la guía sería el modo más ruidoso de la app,
      // y encima sobre una planta que no sabemos cuál es.
      // Bandas contra la escala corregida (franco, agotamiento genérico):
      // 19 / 22 – 28 / 43,2 % de contenido volumétrico.
      final bajo = GuideAgroScoreEngine.evaluate(t: telemetry(moisture: 20));
      final alto = GuideAgroScoreEngine.evaluate(t: telemetry(moisture: 35));
      final critico = GuideAgroScoreEngine.evaluate(t: telemetry(moisture: 10));

      expect(bajo.eval.suggestedAlertKeys, isEmpty);
      expect(alto.eval.suggestedAlertKeys, isEmpty);
      expect(
        critico.eval.suggestedAlertKeys,
        contains('soilMoisture.critical'),
      );

      // Pero la banda sí se calcula: la información está, solo no notifica.
      expect(
        bajo.eval.metrics[AgroMetricKey.soilMoisture]!.band,
        AgroBand.low,
      );
    });

    test('el encharcamiento no se anuncia como sequía', () {
      // 92 % y 10 % son los dos extremos de la MISMA banda crítica. Con una
      // sola clave, la maceta inundada recibía "muy por debajo del rango".
      final seco = GuideAgroScoreEngine.evaluate(t: telemetry(moisture: 10));
      // 46 % en suelo franco SÍ es encharcamiento: está por encima del 43,2 %
      // que es el 90 % de la saturación. Con la escala vieja hacía falta un
      // 92 % que ningún suelo mineral alcanza — la alarma era inalcanzable.
      final inundado = GuideAgroScoreEngine.evaluate(
        t: telemetry(moisture: 46),
      );

      expect(seco.eval.suggestedAlertKeys, contains('soilMoisture.critical'));
      expect(
        inundado.eval.suggestedAlertKeys,
        contains('soilMoisture.saturated'),
      );
      expect(inundado.eval.alerts.single.body, contains('por encima'));
    });

    test('los textos no nombran etapa ni cultivo inventado', () {
      final build = GuideAgroScoreEngine.evaluate(
        t: telemetry(airTemp: -1, moisture: 10),
      );

      for (final BioGAlert a in build.eval.alerts) {
        final String texto = '${a.title} ${a.body}';
        expect(
          texto,
          isNot(contains('etapa actual')),
          reason: 'la guía no tiene etapa; "en etapa etapa actual" es ruido',
        );
        expect(
          texto,
          isNot(contains('tu cultivo')),
          reason: 'quien entra por "Otro" puede tener un rosal',
        );
        expect(texto, isNot(contains(kGuideCropId)));
      }
    });
  });

  group('bandas de la guía', () {
    AgroBand bandFor(double moisture) {
      final build = GuideAgroScoreEngine.evaluate(
        t: telemetry(moisture: moisture),
      );
      return build.eval.metrics[AgroMetricKey.soilMoisture]!.band;
    }

    test('humedad: crítico / bajo / óptimo / alto / crítico', () {
      // Contra kGuideTargets.moistureRaw = 19 / 22 – 28 / 43,2, que es lo que
      // produce el resolver para suelo franco con agotamiento genérico. Los
      // valores de antes —45 como «óptimo», 92 como único crítico alto— vivían
      // en una escala de sustrato de maceta.
      expect(bandFor(10), AgroBand.critical);
      expect(bandFor(20), AgroBand.low);
      expect(bandFor(25), AgroBand.optimal);
      expect(bandFor(35), AgroBand.high);
      expect(bandFor(46), AgroBand.critical);
    });

    test('la resistencia nunca sale crítica por estar suelta', () {
      // `lowMax` negativo a propósito: un suelo no puede estar
      // peligrosamente suelto. Solo la compactación es problema.
      final suelto = GuideAgroScoreEngine.evaluate(t: telemetry(resistance: 0));
      final compacto = GuideAgroScoreEngine.evaluate(
        t: telemetry(resistance: 2.6),
      );

      expect(
        suelto.eval.metrics[AgroMetricKey.resistance]!.band,
        AgroBand.optimal,
      );
      expect(
        compacto.eval.metrics[AgroMetricKey.resistance]!.band,
        AgroBand.critical,
      );
    });

    test('el pH coincide con lo que ya dice la pantalla de pre-siembra', () {
      // 5.8–7.2 es la ventana que la app ya le muestra al agricultor. Si la
      // guía usara otra, dos pantallas se contradirían sobre la misma lectura.
      AgroBand ph(double v) => GuideAgroScoreEngine.evaluate(
        t: telemetry(ph: v),
      ).eval.metrics[AgroMetricKey.ph]!.band;

      expect(ph(5.7), AgroBand.low);
      expect(ph(5.9), AgroBand.optimal);
      expect(ph(7.1), AgroBand.optimal);
      expect(ph(7.4), AgroBand.high);
    });
  });

  group('sensores ausentes', () {
    BioGTelemetry sinSensores() {
      return telemetry().copyWith(
        hasSoilMoistureData: false,
        hasSoilTempData: false,
        hasPhData: false,
        hasEcData: false,
        hasResistanceData: false,
        hasAirTempData: false,
        hasAirHumidityData: false,
      );
    }

    test('un sensor de aire ausente no inventa una helada', () {
      // `BioGTelemetry` rellena con 0.0 lo que falta, y 0.0 <= 0 cumple la
      // condición de helada. Sin la bandera, un equipo sin sensor de aire
      // avisaría de helada crítica en cada lectura, para siempre.
      final build = GuideAgroScoreEngine.evaluate(t: sinSensores());

      expect(build.eval.suggestedAlertKeys, isEmpty);
      expect(build.eval.alerts, isEmpty);
    });

    test('un sensor de suelo ausente sale sin banda, no en crítico', () {
      final build = GuideAgroScoreEngine.evaluate(t: sinSensores());

      expect(
        build.eval.metrics[AgroMetricKey.ph]!.band,
        AgroBand.unknown,
      );
      expect(build.eval.metrics[AgroMetricKey.ph]!.labelEs, '—');
    });

    test('el peso del sensor ausente se reparte, no hunde el score', () {
      // Con todo óptimo y el pH averiado, el suelo sigue siendo óptimo. Si el
      // pH entrara con score 0, el anillo caería un 20% por un cable suelto.
      final completo = GuideAgroScoreEngine.evaluate(t: telemetry());
      final sinPh = GuideAgroScoreEngine.evaluate(
        t: telemetry().copyWith(hasPhData: false),
      );

      expect(
        sinPh.eval.soilControlScore01,
        closeTo(completo.eval.soilControlScore01, 1e-9),
      );
    });
  });

  group('CropRuntimeResolver en modo guía', () {
    test('enciende isGuideMode y apaga isGenericMode', () {
      final snapshot = resolveGuide();

      expect(snapshot.isGuideMode, isTrue);
      // Excluyentes. Si isGenericMode se colara, el Panel volvería a
      // "Lectura actual" y se perderían las cinco bandas.
      expect(snapshot.isGenericMode, isFalse);
    });

    test('cuenta como plantado aunque no haya fecha de siembra', () {
      // Sin esto las métricas caerían a los textos de pre-siembra.
      expect(resolveGuide().isPlanted, isTrue);
    });

    test('no inventa etapa ni objetivos', () {
      final snapshot = resolveGuide();

      expect(snapshot.stageResult, isNull);
      // `targets` en null es lo que hace que NPK salga sin interpretar en
      // toda la app sin tocar un solo consumidor.
      expect(snapshot.targets, isNull);
      expect(snapshot.definition, isNull);
    });

    test('produce evaluación de suelo, sin claves de nutrientes', () {
      // 25 % de contenido volumétrico en suelo franco: dentro del óptimo. El
      // ayudante trae 45 por omisión, que en la escala corregida es
      // encharcamiento.
      final snapshot = resolveGuide(live: telemetry(moisture: 25));

      expect(snapshot.eval, isNotNull);
      expect(
        snapshot.eval!.metrics[AgroMetricKey.soilMoisture]?.band,
        AgroBand.optimal,
      );
      expect(snapshot.eval!.metrics.containsKey(AgroMetricKey.n), isFalse);
    });

    test('sin telemetría no inventa una evaluación', () {
      final snapshot = CropRuntimeResolver.resolve(
        device: null,
        seed: null,
        cropContext: guideContext(),
        live: null,
        alertsState: emptyAlerts,
        now: now,
      );

      expect(snapshot.isGuideMode, isTrue);
      expect(snapshot.eval, isNull);
    });
  });

  group('un cultivo real no se ve afectado', () {
    test('maíz sigue sin ser guía y conserva su etapa', () {
      final snapshot = CropRuntimeResolver.resolve(
        device: null,
        seed: null,
        cropContext: DeviceCropContext(
          deviceId: deviceId,
          cropCategoryId: 'grain',
          cropId: 'maize',
          profileId: 'maize_universal',
          lifecycleStatus: CropLifecycleStatus.planted,
          sowingDate: now.subtract(const Duration(days: 40)),
          sowingDateConfidence: DateConfidence.exact,
          catalogVersion: 'test',
          source: CropConfigSource.wizard,
          configuredAt: now,
          updatedAt: now,
        ),
        live: telemetry(),
        alertsState: emptyAlerts,
        now: now,
      );

      expect(snapshot.isGuideMode, isFalse);
      expect(snapshot.stageResult, isNotNull);
      expect(snapshot.targets, isNotNull);
    });
  });
}
