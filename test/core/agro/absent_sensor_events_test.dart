// test/core/agro/absent_sensor_events_test.dart
//
// Un sensor que no reporta no es un sensor que reporta un problema.
//
// Estas pruebas fijan el comportamiento en la frontera exacta donde nacía el
// consejo falso: `BioGTelemetry` rellena con 0.0 lo que llega ausente, y ese
// cero atravesaba el factory, el motor de score y el motor de eventos hasta
// convertirse en "Riego recomendado" con severidad crítica.

import 'package:flutter_test/flutter_test.dart';

import 'package:bio_g/core/agro/agro_event_input_factory.dart';
import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/agro/agronomic_event.dart';
import 'package:bio_g/core/agro/event_engine.dart';
import 'package:bio_g/models/biog_telemetry.dart';

void main() {
  final DateTime now = DateTime.utc(2026, 8, 3, 12);
  const String deviceId = '3f2504e0-4f89-11d3-9a0c-0305e82c3301';

  /// Telemetría con todas las banderas de presencia apagadas: el aparato no
  /// mandó nada, y todos los valores son el 0.0 sintetizado.
  BioGTelemetry allAbsent() {
    return BioGTelemetry.tryFromJson(<String, dynamic>{
      'device_id': deviceId,
      'timestamp': now.toIso8601String(),
    })!;
  }

  AgroEvalResult evalWithBands(Map<AgroMetricKey, AgroBand> bands) {
    return AgroEvalResult(
      soilControlScore01: 0.0,
      metrics: <AgroMetricKey, AgroMetricEval>{
        for (final entry in bands.entries)
          entry.key: AgroMetricEval(
            band: entry.value,
            score01: 0.0,
            labelEs: entry.value.labelEs,
          ),
      },
      alerts: const <BioGAlert>[],
      suggestedAlertKeys: const <String>[],
    );
  }

  group('safeCurrentBands degrada lo que no se midió', () {
    test('sin telemetría conserva el comportamiento anterior', () {
      final bands = AgroEventInputFactory.safeCurrentBands(
        evalWithBands(<AgroMetricKey, AgroBand>{
          AgroMetricKey.soilMoisture: AgroBand.critical,
        }),
      );
      expect(bands[EventMetricKeys.soilMoisture], AgroBand.critical);
    });

    test('con la bandera apagada, la banda pasa a unknown', () {
      // El motor de score evaluó el 0.0 y dijo "crítico". La bandera de
      // presencia lo desmiente.
      final bands = AgroEventInputFactory.safeCurrentBands(
        evalWithBands(<AgroMetricKey, AgroBand>{
          AgroMetricKey.soilMoisture: AgroBand.critical,
          AgroMetricKey.ph: AgroBand.critical,
          AgroMetricKey.n: AgroBand.critical,
        }),
        live: allAbsent(),
      );

      expect(bands[EventMetricKeys.soilMoisture], AgroBand.unknown);
      expect(bands[EventMetricKeys.ph], AgroBand.unknown);
      expect(bands[EventMetricKeys.n], AgroBand.unknown);
    });

    test('una métrica sí presente conserva su banda', () {
      final live = BioGTelemetry.tryFromJson(<String, dynamic>{
        'device_id': deviceId,
        'timestamp': now.toIso8601String(),
        'soil_moisture_pct': 12.0,
      })!;

      final bands = AgroEventInputFactory.safeCurrentBands(
        evalWithBands(<AgroMetricKey, AgroBand>{
          AgroMetricKey.soilMoisture: AgroBand.critical,
          AgroMetricKey.ph: AgroBand.critical,
        }),
        live: live,
      );

      expect(bands[EventMetricKeys.soilMoisture], AgroBand.critical);
      expect(bands[EventMetricKeys.ph], AgroBand.unknown);
    });
  });

  group('AgroEventInputFactory.build no inventa mediciones', () {
    test('todas las métricas ausentes llegan al motor como null', () {
      final input = AgroEventInputFactory.build(
        timestamp: now,
        deviceId: deviceId,
        seed: null,
        cropContext: null,
        live: allAbsent(),
        effectiveEval: null,
        stageResult: null,
        isGenericMode: false,
      );

      expect(input.soilMoisture, isNull);
      expect(input.ph, isNull);
      expect(input.resistance, isNull);
      expect(input.soilTemp, isNull);
      // El aire también: un 0 °C sintetizado disparaba "Riesgo de helada"
      // crítica, porque el umbral de helada vale entre 0 y 7 °C.
      expect(input.airTemp, isNull);
      expect(input.airHumidity, isNull);
      expect(input.n, isNull);
      expect(input.p, isNull);
      expect(input.k, isNull);
    });
  });

  group('EventEngine con métricas desconocidas', () {
    List<AgronomicEvent> buildWith(Map<String, AgroBand> bands) {
      return EventEngine.build(
        EventEngineInput(
          timestamp: now,
          deviceId: deviceId,
          cropId: 'maize',
          stageKey: 'vegetative',
          stageLabel: 'Crecimiento vegetativo',
          currentBands: bands,
        ),
      );
    }

    test('humedad desconocida NO produce riego recomendado', () {
      final events = buildWith(<String, AgroBand>{
        EventMetricKeys.soilMoisture: AgroBand.unknown,
      });

      expect(
        events.where(
          (e) => e.type == AgronomicEventType.irrigationRecommended,
        ),
        isEmpty,
      );
      expect(
        events.where((e) => e.type == AgronomicEventType.lowMoisture),
        isEmpty,
      );
    });

    test('humedad crítica real SÍ produce riego recomendado', () {
      final events = buildWith(<String, AgroBand>{
        EventMetricKeys.soilMoisture: AgroBand.critical,
      });

      expect(
        events.where(
          (e) => e.type == AgronomicEventType.irrigationRecommended,
        ),
        isNotEmpty,
      );
    });

    test('NPK desconocido NO produce desbalance nutrimental', () {
      // `unknown` no es `optimal`, así que sin filtrarlo dos nutrientes
      // ausentes bastaban para emitir "Desbalance nutrimental".
      final events = buildWith(<String, AgroBand>{
        EventMetricKeys.n: AgroBand.unknown,
        EventMetricKeys.p: AgroBand.unknown,
        EventMetricKeys.k: AgroBand.unknown,
      });

      expect(
        events.where((e) => e.type == AgronomicEventType.nutrientImbalance),
        isEmpty,
      );
    });

    test('dos nutrientes realmente bajos SÍ producen desbalance', () {
      final events = buildWith(<String, AgroBand>{
        EventMetricKeys.n: AgroBand.low,
        EventMetricKeys.p: AgroBand.low,
        EventMetricKeys.k: AgroBand.optimal,
      });

      expect(
        events.where((e) => e.type == AgronomicEventType.nutrientImbalance),
        isNotEmpty,
      );
    });

    test('un nutriente ausente no arrastra a los presentes', () {
      final events = buildWith(<String, AgroBand>{
        EventMetricKeys.n: AgroBand.unknown,
        EventMetricKeys.p: AgroBand.optimal,
        EventMetricKeys.k: AgroBand.optimal,
      });

      expect(
        events.where((e) => e.type == AgronomicEventType.nutrientImbalance),
        isEmpty,
      );
    });
  });
}
