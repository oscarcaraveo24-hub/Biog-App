// test/core/agro/absent_sensor_scoring_test.dart
//
// LA ENTRADA QUE ESTE TRABAJO EXISTE PARA MANEJAR: EL CANAL QUE NO MIDIÓ.
//
// ─────────────────────────────────────────────────────────────────────────────
// POR QUÉ HACE FALTA UNA PRUEBA ASÍ
// ─────────────────────────────────────────────────────────────────────────────
//
// `BioGTelemetry` rellena con 0.0 el sensor que no reportó y baja su bandera de
// presencia. Los motores del catálogo leían el número y no la bandera, con dos
// consecuencias concretas:
//
//   · `0.0 <= 0` cumple la condición de helada. Un equipo sin sensor de aire
//     —o con un cable flojo en el bus— avisaba de HELADA CRÍTICA en cada
//     lectura, para siempre. Un productor puede encender calefactores o quemar
//     diésel por un canal que nunca existió.
//   · 0.0 cae en CRÍTICO en cuatro de los cinco rangos de humedad. Una sonda
//     averiada se leía como suelo en emergencia, y el anillo del Panel pintaba
//     un diagnóstico catastrófico de un dato que no existe.
//
// Ninguna prueba cubría ese caso: todas las que había construyen telemetría con
// las banderas en verdadero, que es el camino feliz.

import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/crops/crop_runtime_resolver.dart';
import 'package:bio_g/models/biog_telemetry.dart';
import 'package:bio_g/models/device_crop_context.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const AlertsState emptyAlerts = AlertsState();
  final DateTime now = DateTime.utc(2026, 8, 10, 12);
  const String deviceId = '3f2504e0-4f89-11d3-9a0c-0305e82c3301';

  /// Telemetría por claves crudas: omitir una clave es exactamente lo que hace
  /// un equipo cuyo canal no reportó, y es la única forma de que `tryFromJson`
  /// baje la bandera de presencia.
  BioGTelemetry telemetry({
    bool withMoisture = true,
    bool withAirTemp = true,
    double moisture = 22,
    double airTemp = 22,
  }) {
    return BioGTelemetry.tryFromJson(<String, dynamic>{
      'device_id': deviceId,
      'timestamp': now.toIso8601String(),
      if (withMoisture) 'soil_moisture_pct': moisture,
      'ph': 6.5,
      'soil_temp_c': 20,
      'resistance': 0.8,
      'ec': 1.0,
      'n': 40,
      'p': 25,
      'k': 60,
      if (withAirTemp) 'air_temp_c': airTemp,
      'air_humidity_pct': 55,
    })!;
  }

  DeviceCropContext maizeContext() => DeviceCropContext(
    deviceId: deviceId,
    cropCategoryId: 'grain',
    cropId: 'maize',
    profileId: 'maize_generic',
    lifecycleStatus: CropLifecycleStatus.planted,
    sowingDate: now.subtract(const Duration(days: 55)),
    sowingDateConfidence: DateConfidence.exact,
    cultivationScaleId: 'field',
    soilTextureId: 'loam',
    soilTextureSource: 'declared',
    catalogVersion: 'test',
    source: CropConfigSource.wizard,
    configuredAt: now,
    updatedAt: now,
  );

  AgroEvalResult evalWith(BioGTelemetry t) {
    final snapshot = CropRuntimeResolver.resolve(
      device: null,
      seed: null,
      cropContext: maizeContext(),
      live: t,
      alertsState: emptyAlerts,
      now: now,
    );
    expect(
      snapshot.eval,
      isNotNull,
      reason: 'el maíz sembrado con telemetría debe producir evaluación',
    );
    return snapshot.eval!;
  }

  group('Bandera de presencia · humedad', () {
    test('sin sonda, la humedad sale «sin dato», no crítica', () {
      final eval = evalWith(telemetry(withMoisture: false));
      final metric = eval.metrics[AgroMetricKey.soilMoisture];

      expect(metric, isNotNull);
      expect(
        metric!.band,
        AgroBand.unknown,
        reason:
            'El 0.0 sintetizado caía en crítico: suelo en emergencia salido de '
            'un canal que no existe.',
      );
      expect(
        eval.suggestedAlertKeys.any((k) => k.startsWith('soilMoisture')),
        isFalse,
        reason: 'no se notifica sobre un dato que no llegó',
      );
    });

    test('con sonda, la banda sí se calcula', () {
      // 22 % en franco, maíz en vegetativo: dentro del rango de reposición.
      final metric = evalWith(
        telemetry(moisture: 22),
      ).metrics[AgroMetricKey.soilMoisture];

      expect(metric, isNotNull);
      expect(metric!.band, isNot(AgroBand.unknown));
    });

    test('una lectura seca real SÍ dispara', () {
      // 8 % en franco está por debajo del punto de marchitez (13 %).
      final eval = evalWith(telemetry(moisture: 8));
      expect(
        eval.metrics[AgroMetricKey.soilMoisture]!.band,
        AgroBand.critical,
      );
    });
  });

  group('Bandera de presencia · temperatura del aire', () {
    test('sin sensor de aire NO se avisa de helada', () {
      final eval = evalWith(telemetry(withAirTemp: false));

      expect(
        eval.suggestedAlertKeys,
        isNot(contains('airTemp.frost')),
        reason:
            'Es el defecto que motivó todo esto: 0.0 <= 0 cumple la condición '
            'de helada, y la alerta se emitía como CRÍTICA en cada lectura.',
      );
      expect(eval.suggestedAlertKeys, isNot(contains('airTemp.cold')));
    });

    test('con sensor de aire, una helada real SÍ se avisa', () {
      final eval = evalWith(telemetry(airTemp: -1));
      expect(eval.suggestedAlertKeys, contains('airTemp.frost'));
    });

    test('sin sensor de aire tampoco se avisa de calor extremo', () {
      final eval = evalWith(telemetry(withAirTemp: false));
      expect(eval.suggestedAlertKeys, isNot(contains('airTemp.extreme_heat')));
      expect(eval.suggestedAlertKeys, isNot(contains('airTemp.heat')));
    });
  });

  group('El objetivo de humedad llega derivado de la textura', () {
    test('la banda del catálogo se sustituye por la del suelo declarado', () {
      final snapshot = CropRuntimeResolver.resolve(
        device: null,
        seed: null,
        cropContext: maizeContext(),
        live: telemetry(),
        alertsState: emptyAlerts,
        now: now,
      );

      expect(snapshot.resolvedMoisture, isNotNull);
      expect(snapshot.targets, isNotNull);

      // Suelo franco: capacidad de campo 28 %, encharcamiento 43,2 %. Lo que el
      // catálogo traía escrito a mano era otra escala por completo.
      final range = snapshot.targets!.moistureRaw;
      expect(range.optimalMax, closeTo(28, 0.1));
      expect(range.highMin, closeTo(43.2, 0.1));
      expect(range, snapshot.resolvedMoisture!.range);

      // Y el contexto de suelo queda listo para el balance hídrico, que era la
      // condición que `supportsWaterBalance` no podía cumplir nunca.
      expect(snapshot.resolvedMoisture!.soilContext.supportsWaterBalance, isTrue);
      expect(snapshot.resolvedMoisture!.isFallbackTexture, isFalse);
    });

    test('sin textura declarada se usa media, marcada como respaldo', () {
      final snapshot = CropRuntimeResolver.resolve(
        device: null,
        seed: null,
        cropContext: maizeContext().copyWith(
          soilTextureId: null,
          soilTextureSource: null,
        ),
        live: telemetry(),
        alertsState: emptyAlerts,
        now: now,
      );

      final resolved = snapshot.resolvedMoisture!;
      expect(resolved.isFallbackTexture, isTrue);
      expect(resolved.confidencePenalty, greaterThanOrEqualTo(0.15));
      expect(resolved.soilContext.isFallbackTexture, isTrue);
      expect(resolved.textureLimitationEs, isNotNull);
    });
  });
}
