// test/core/telemetry/soil_sensor_spec_test.dart
//
// El contrato del sensor es la única fuente de unidades y plausibilidad para
// la sonda 7-en-1 (Guía v0.4, fase 3).
import 'package:bio_g/core/telemetry/soil_sensor_spec.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SoilSensorSpec · SN-3002-TR-ECTHNPKPH-N01', () {
    const SoilSensorSpec spec = SoilSensorSpec.sn3002;

    test('declara los siete canales y marca N/P/K como derivados', () {
      expect(spec.channels.length, 7);
      expect(spec.derivedChannels, <SoilChannel>{
        SoilChannel.nitrogen,
        SoilChannel.phosphorus,
        SoilChannel.potassium,
      });
      expect(spec.channelFor(SoilChannel.ec)!.isDerived, isFalse);
    });

    test('la CE se convierte de µS/cm a mS/cm y respeta el rango plausible', () {
      expect(spec.ecFromMicroSiemens(1400), closeTo(1.4, 1e-9));
      expect(spec.ecFromMicroSiemens(0), 0.0);
      expect(spec.ecFromMicroSiemens(25000), isNull);
      expect(spec.ecFromMicroSiemens(null), isNull);
    });

    test('humedad y temperatura escalan ×0.1 desde el registro', () {
      expect(spec.channelFor(SoilChannel.moisture)!.fromRaw(345), closeTo(34.5, 1e-9));
      expect(spec.channelFor(SoilChannel.temperature)!.fromRaw(-52), closeTo(-5.2, 1e-9));
      expect(spec.channelFor(SoilChannel.moisture)!.fromRaw(1200), isNull);
    });

    test('los topes nativos de N/P/K coinciden con los del modelo interno', () {
      expect(
        spec.channelFor(SoilChannel.nitrogen)!.plausibleMax,
        SoilSensorSpec.kNitrogenMaxNative,
      );
      expect(
        spec.channelFor(SoilChannel.phosphorus)!.plausibleMax,
        SoilSensorSpec.kPhosphorusMaxNative,
      );
      expect(
        spec.channelFor(SoilChannel.potassium)!.plausibleMax,
        SoilSensorSpec.kPotassiumMaxNative,
      );
    });

    test('se resuelve por id sin importar mayúsculas y cae a la de referencia', () {
      expect(SoilSensorSpec.byId('sn-3002-tr-ecthnpkph-n01'), same(spec));
      expect(SoilSensorSpec.byId('otra-sonda'), isNull);
      expect(SoilSensorSpec.byId(null), isNull);
      expect(SoilSensorSpec.defaultSpec, same(spec));
    });
  });
}
