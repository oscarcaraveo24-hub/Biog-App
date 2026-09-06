// lib/services/biog/telemetry/ble/biog_ble_codec.dart
//
// Traductor entre el JSON compacto que emite el ESP32 y el contrato interno.
//
// Vive en la capa de transporte a proposito: `sm`, `st`, `n`, `p`, `k` son
// abreviaciones del cable, no vocabulario del dominio. El core de BIO-G no
// debe enterarse nunca de que existen. Si manana el aparato habla por Wi-Fi
// con nombres completos, se cambia este archivo y nada mas.
//
// No importa flutter_blue_plus: es Dart puro y por eso se puede probar sin
// radio ni telefono.

import 'dart:convert';

import 'package:bio_g/core/telemetry/soil_sensor_spec.dart';
import 'package:bio_g/core/telemetry/telemetry_contract.dart';
import 'package:bio_g/models/biog_telemetry.dart';

class BioGBleCodec {
  const BioGBleCodec._();

  // ── Identidad ──────────────────────────────────────────────────────────────

  /// Decodifica la caracteristica de Identidad.
  ///
  /// Devuelve `null` si el JSON no trae un `deviceId` usable. Eso es
  /// deliberado: **sin identidad declarada por el aparato no hay
  /// emparejamiento**, y preferimos fallar visiblemente antes que inventar un
  /// UUID en el telefono, que es justo el defecto que este contrato existe
  /// para cerrar.
  static TelemetryDeviceIdentity? decodeIdentity(List<int> bytes) {
    final json = _decodeJsonObject(bytes);
    if (json == null) return null;
    final identity = TelemetryDeviceIdentity.fromJson(json);
    if (identity == null) return null;
    // Un deviceId mal formado es peor que ninguno: contamina la nube.
    if (!identity.hasValidId) return null;
    return identity;
  }

  // ── Telemetria ─────────────────────────────────────────────────────────────

  /// Convierte una notificacion de telemetria en un [TelemetryEnvelope].
  ///
  /// Formato de entrada (JSON compacto del firmware):
  ///   `{"seq":12,"sm":34.5,"st":21.2,"ph":6.8,"ec":1.4,"n":40,"p":18,"k":95}`
  ///
  /// `ec` viene en mS/cm; si el firmware prefiere reenviar el registro crudo
  /// de la sonda, manda `ec_us` en µS/cm y la conversion la hace el contrato
  /// del sensor (`SoilSensorSpec`), una sola vez. `probe` (opcional) declara
  /// el modelo de sonda.
  ///
  /// Reglas que NO se pueden relajar:
  ///
  ///  - **Metrica ausente NO es cero.** Lo que el sobre no trae se marca con su
  ///    bandera `has...Data = false`. Un `0.0` sintetizado subido a la nube es
  ///    irreversible y es el bug que el proyecto ya arrastro una vez.
  ///  - **El `deviceId` sale de [identity], nunca del transporte.** La MAC del
  ///    BLE es `transportAddress` y se queda en la capa BLE.
  ///  - **El reloj es del telefono.** El sobre compacto no trae hora de
  ///    medicion, asi que `measuredAt == receivedAt` y se declara
  ///    `clockTrusted: false`. Es mentira barata decir que el aparato fecho la
  ///    medicion cuando no lo hizo.
  static TelemetryEnvelope? decodeTelemetry(
    List<int> bytes, {
    required TelemetryDeviceIdentity identity,
    required DateTime receivedAt,
    int? signalRssi,
  }) {
    final json = _decodeJsonObject(bytes);
    if (json == null) return null;

    // Contrato de la sonda (Guia v0.4, fase 3): unidades, conversion unica de
    // CE y plausibilidad viven en `SoilSensorSpec`. Si el firmware declara el
    // modelo (`probe`), se usa su contrato; si no, el de la sonda de referencia.
    final SoilSensorSpec spec =
        SoilSensorSpec.byId((json['probe'] ?? json['probe_id'])?.toString()) ??
        SoilSensorSpec.defaultSpec;

    // Se aceptan tanto la forma compacta como la larga: asi el mismo codec
    // sirve si el firmware crece y empieza a mandar nombres completos.
    //
    // Fuera del rango plausible del contrato, el canal se marca AUSENTE (null):
    // una sonda descalibrada o un payload corrupto no se interpreta.
    final double? soilMoisture = spec
        .channelFor(SoilChannel.moisture)
        ?.accept(_double(json['sm'] ?? json['soil_moisture_pct']));
    final double? soilTemp = spec
        .channelFor(SoilChannel.temperature)
        ?.accept(_double(json['st'] ?? json['soil_temp_c']));
    final double? ph = spec.channelFor(SoilChannel.ph)?.accept(_double(json['ph']));

    // CE: el firmware puede mandarla ya en mS/cm (`ec`) o cruda del registro
    // en µS/cm (`ec_us`). La conversion ocurre aqui, una sola vez.
    final double? ecRawMicro = _double(json['ec_us'] ?? json['ec_uscm']);
    final double? ec = ecRawMicro != null
        ? spec.ecFromMicroSiemens(ecRawMicro)
        : spec.channelFor(SoilChannel.ec)?.accept(_double(json['ec']));

    // N/P/K: senales derivadas de la CE por la propia sonda. Se transportan
    // tal cual, con su plausibilidad; la app nunca las interpreta como analisis.
    final double? n = spec.channelFor(SoilChannel.nitrogen)?.accept(_double(json['n']));
    final double? p = spec.channelFor(SoilChannel.phosphorus)?.accept(_double(json['p']));
    final double? k = spec.channelFor(SoilChannel.potassium)?.accept(_double(json['k']));

    // Presentes solo si el firmware los manda; hoy no los manda. Misma
    // plausibilidad que `BioGTelemetry.tryFromJson`: lo implausible es
    // ausente, por BLE igual que por HTTP.
    final double? airTemp = BioGTelemetry.plausibleOrAbsent(
      _double(json['at'] ?? json['air_temp_c']),
      BioGTelemetry.kAirTempMinC,
      BioGTelemetry.kAirTempMaxC,
    );
    final double? airHumidity = BioGTelemetry.plausibleOrAbsent(
      _double(json['ah'] ?? json['air_humidity_pct']),
      BioGTelemetry.kAirHumidityMinPct,
      BioGTelemetry.kAirHumidityMaxPct,
    );
    final double? resistance = BioGTelemetry.plausibleOrAbsent(
      _double(json['r'] ?? json['resistance']),
      BioGTelemetry.kResistanceMin,
      BioGTelemetry.kResistanceMax,
    );
    final double? batteryPct = BioGTelemetry.plausibleOrAbsent(
      _double(json['bat'] ?? json['battery_pct']),
      BioGTelemetry.kBatteryMinPct,
      BioGTelemetry.kBatteryMaxPct,
    );

    final int? sequence = _int(json['seq'] ?? json['sequenceNumber']);
    final String? errorCode = (json['err'] ?? json['error'])?.toString().trim();

    final bool anyMetric =
        soilMoisture != null ||
        soilTemp != null ||
        ph != null ||
        ec != null ||
        n != null ||
        p != null ||
        k != null ||
        airTemp != null ||
        airHumidity != null ||
        resistance != null;

    final reading = BioGTelemetry(
      deviceId: identity.deviceId,
      timestamp: receivedAt,
      airTempC: airTemp ?? 0.0,
      hasAirTempData: airTemp != null,
      airHumidityPct: airHumidity ?? 0.0,
      hasAirHumidityData: airHumidity != null,
      soilMoisturePct: soilMoisture ?? 0.0,
      hasSoilMoistureData: soilMoisture != null,
      soilTempC: soilTemp ?? 0.0,
      hasSoilTempData: soilTemp != null,
      ph: ph ?? 0.0,
      hasPhData: ph != null,
      ec: ec ?? 0.0,
      hasEcData: ec != null,
      resistance: resistance ?? 0.0,
      hasResistanceData: resistance != null,
      n: n ?? 0.0,
      hasNitrogenData: n != null,
      p: p ?? 0.0,
      hasPhosphorusData: p != null,
      k: k ?? 0.0,
      hasPotassiumData: k != null,
      batteryPct: batteryPct,
      signalRssi: signalRssi,
      hasSensorData: anyMetric,
    );

    return TelemetryEnvelope(
      identity: identity,
      // Ver la nota de arriba: el aparato no fecha, fecha el telefono.
      measuredAt: receivedAt,
      receivedAt: receivedAt,
      reading: reading,
      sequenceNumber: sequence,
      transport: TelemetryTransportKind.ble,
      quality: TelemetryQuality(
        batteryPct: batteryPct,
        signalRssi: signalRssi,
        sensorErrorCode: (errorCode == null || errorCode.isEmpty)
            ? null
            : errorCode,
        clockTrusted: false,
      ),
    );
  }

  // ── Utilidades ─────────────────────────────────────────────────────────────

  static Map<String, dynamic>? _decodeJsonObject(List<int> bytes) {
    if (bytes.isEmpty) return null;
    try {
      final text = utf8.decode(bytes, allowMalformed: true).trim();
      if (text.isEmpty) return null;
      final decoded = jsonDecode(text);
      if (decoded is! Map) return null;
      return Map<String, dynamic>.from(decoded);
    } on FormatException {
      return null;
    } catch (_) {
      return null;
    }
  }

  static double? _double(Object? value) {
    if (value == null) return null;
    if (value is num) {
      final d = value.toDouble();
      return d.isFinite ? d : null;
    }
    if (value is String) {
      final d = double.tryParse(value.trim());
      return (d != null && d.isFinite) ? d : null;
    }
    return null;
  }

  static int? _int(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) {
      final d = value.toDouble();
      return d.isFinite ? d.round() : null;
    }
    if (value is String) return int.tryParse(value.trim());
    return null;
  }
}
