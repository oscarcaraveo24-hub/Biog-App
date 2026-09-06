// test/core/agro/nutrition/fertilization_signature_scanner_test.dart
//
// El detector de firmas de fertilización es lo que sustituye al registro
// manual: si se equivoca, el agricultor recibe una ventana «atendida» que no lo
// fue, o una advertencia por una fertilización que sí hizo. Estas pruebas
// congelan los cuatro comportamientos que lo hacen honesto:
//   1. un fertirriego real produce una firma compatible;
//   2. un riego con agua sola NO la produce (la CE bruta sube, la normalizada no);
//   3. una ventana sin lecturas, o con suelo seco, no se puede juzgar;
//   4. varios pulsos en la misma ventana son UNA firma.
import 'dart:math' as math;

import 'package:bio_g/core/agro/nutrition/fertilization_signature_scanner.dart';
import 'package:bio_g/core/agro/nutrition/nutrition_types.dart';
import 'package:bio_g/models/biog_telemetry.dart';
import 'package:flutter_test/flutter_test.dart';

final DateTime _t0 = DateTime(2026, 6, 1, 0);

/// Serie sintética cada 2 h. [ecAt] y [vwcAt] reciben las horas desde [_t0].
List<BioGTelemetry> _series({
  required int hours,
  required double Function(double h) ecAt,
  required double Function(double h) vwcAt,
  bool withMoisture = true,
  double Function(double h)? nAt,
}) {
  final List<BioGTelemetry> out = <BioGTelemetry>[];
  for (int h = 0; h <= hours; h += 2) {
    final double hh = h.toDouble();
    final double ec = ecAt(hh);
    out.add(
      BioGTelemetry(
        deviceId: 'dev',
        timestamp: _t0.add(Duration(hours: h)),
        airTempC: 24,
        airHumidityPct: 50,
        soilMoisturePct: withMoisture ? vwcAt(hh) : 0.0,
        hasSoilMoistureData: withMoisture,
        soilTempC: 22,
        ph: 6.8,
        ec: ec,
        resistance: 0.9,
        // Canales derivados de la CE, como en la sonda 7-en-1.
        n: nAt?.call(hh) ?? ec * 30,
        p: ec * 12,
        k: ec * 50,
        batteryPct: 90,
        signalRssi: -60,
      ),
    );
  }
  return out;
}

/// Ciclo diurno suave para que la referencia tenga una MAD realista.
double _diurnal(double h, double amp) => amp * math.sin(h / 24 * 2 * math.pi);

void main() {
  group('FertilizationSignatureScanner', () {
    test('un fertirriego real produce una firma compatible', () {
      // 3 días de referencia (EC 1.0 / VWC 30) y al día 3 entra agua con sales:
      // VWC 30 → 36, EC 1.0 → 1.6 sostenidos dos días.
      final history = _series(
        hours: 24 * 6,
        ecAt: (h) => (h < 72 ? 1.0 : 1.6) + _diurnal(h, 0.03),
        vwcAt: (h) => (h < 72 ? 30.0 : 36.0) + _diurnal(h, 0.6),
      );
      final scan = FertilizationSignatureScanner.scan(
        SignatureScanRequest(
          history: history,
          windowStart: _t0.add(const Duration(hours: 48)),
          now: _t0.add(const Duration(hours: 24 * 6)),
        ),
      );

      expect(scan.observability, ScanObservability.ok);
      expect(scan.usedMoistureNormalization, isTrue);
      expect(scan.hasCompatibleSignature, isTrue, reason: scan.summaryEs);
      final FertilizationSignature s = scan.best!;
      expect(s.kind, SignatureKind.ionicImmediate);
      expect(s.vwcContext, VwcContext.fertigationLike);
      expect(s.startedAt.isAfter(_t0.add(const Duration(hours: 70))), isTrue);
      expect(s.startedAt.isBefore(_t0.add(const Duration(hours: 76))), isTrue);
      expect(s.nFollowMad, isNotNull);
      expect(s.nFollowMad!, greaterThan(1.0), reason: 'el canal N acompaña');
      expect(scan.canJudgeAbsence, isTrue);
    });

    test('un riego con agua sola NO es fertilización', () {
      // La CE bruta sube con el agua (1.0 → 1.25) pero la carga iónica
      // normalizada por humedad se queda igual: 1.0/0.30 ≈ 1.25/0.375.
      final history = _series(
        hours: 24 * 6,
        ecAt: (h) => (h < 72 ? 1.0 : 1.25) + _diurnal(h, 0.03),
        vwcAt: (h) => (h < 72 ? 30.0 : 37.5) + _diurnal(h, 0.6),
      );
      final scan = FertilizationSignatureScanner.scan(
        SignatureScanRequest(
          history: history,
          windowStart: _t0.add(const Duration(hours: 48)),
          now: _t0.add(const Duration(hours: 24 * 6)),
        ),
      );

      expect(scan.observability, ScanObservability.ok);
      expect(scan.hasCompatibleSignature, isFalse, reason: scan.summaryEs);
    });

    test('sin lecturas la ventana no se puede juzgar', () {
      final scan = FertilizationSignatureScanner.scan(
        SignatureScanRequest(
          history: const <BioGTelemetry>[],
          windowStart: _t0,
          now: _t0.add(const Duration(days: 5)),
        ),
      );
      expect(scan.observability, ScanObservability.noReadings);
      expect(scan.canJudgeAbsence, isFalse);
      expect(scan.signatures, isEmpty);
    });

    test('con suelo seco la CE no sirve y el barrido lo declara', () {
      final history = _series(
        hours: 24 * 5,
        ecAt: (h) => 0.4 + _diurnal(h, 0.02),
        vwcAt: (h) => 12.0 + _diurnal(h, 0.5), // por debajo de la puerta dura
      );
      final scan = FertilizationSignatureScanner.scan(
        SignatureScanRequest(
          history: history,
          windowStart: _t0,
          now: _t0.add(const Duration(days: 5)),
        ),
      );
      expect(scan.observability, ScanObservability.tooDry);
      expect(scan.canJudgeAbsence, isFalse);
    });

    test('varios pulsos en la misma ventana son UNA firma', () {
      // Dos pulsos de fertirriego separados 3 días (dosis partida).
      double ecAt(double h) {
        if (h < 72) return 1.0 + _diurnal(h, 0.03);
        if (h < 144) return 1.5 + _diurnal(h, 0.03);
        return 2.0 + _diurnal(h, 0.03);
      }

      double vwcAt(double h) {
        if (h < 72) return 30.0 + _diurnal(h, 0.6);
        if (h < 144) return 35.0 + _diurnal(h, 0.6);
        return 35.5 + _diurnal(h, 0.6);
      }

      final history = _series(hours: 24 * 9, ecAt: ecAt, vwcAt: vwcAt);
      final scan = FertilizationSignatureScanner.scan(
        SignatureScanRequest(
          history: history,
          windowStart: _t0.add(const Duration(hours: 48)),
          now: _t0.add(const Duration(hours: 24 * 9)),
        ),
      );

      expect(scan.hasCompatibleSignature, isTrue, reason: scan.summaryEs);
      expect(scan.signatures.length, 1, reason: 'no se cuentan como eventos separados');
      final FertilizationSignature s = scan.best!;
      expect(s.jumpCount, greaterThanOrEqualTo(2));
      expect(s.kind, SignatureKind.mixed);
      expect(s.lastJumpAt.isAfter(s.startedAt), isTrue);
    });

    test('un pico aislado de una lectura no es una firma', () {
      final history = _series(
        hours: 24 * 6,
        ecAt: (h) => (h == 80 ? 3.0 : 1.0) + _diurnal(h, 0.03),
        vwcAt: (h) => 30.0 + _diurnal(h, 0.6),
      );
      final scan = FertilizationSignatureScanner.scan(
        SignatureScanRequest(
          history: history,
          windowStart: _t0.add(const Duration(hours: 48)),
          now: _t0.add(const Duration(hours: 24 * 6)),
        ),
      );
      expect(scan.hasCompatibleSignature, isFalse, reason: scan.summaryEs);
    });

    test('sin sensor de humedad la confianza queda acotada a «posible»', () {
      // Mismo salto moderado de CE que un fertirriego, pero sin humedad no se
      // puede separar de un riego: nunca «compatible» salvo salto enorme.
      final history = _series(
        hours: 24 * 6,
        withMoisture: false,
        ecAt: (h) => (h < 72 ? 1.0 : 1.4) + _diurnal(h, 0.03),
        vwcAt: (h) => 30.0,
      );
      final scan = FertilizationSignatureScanner.scan(
        SignatureScanRequest(
          history: history,
          windowStart: _t0.add(const Duration(hours: 48)),
          now: _t0.add(const Duration(hours: 24 * 6)),
        ),
      );
      expect(scan.usedMoistureNormalization, isFalse);
      expect(scan.hasCompatibleSignature, isFalse, reason: scan.summaryEs);
      expect(scan.hasPossibleSignature, isTrue, reason: scan.summaryEs);
    });

    test('una subida gradual de días se lee como patrón de urea', () {
      // Sin escalón: la carga iónica normalizada sube 0.4 % por hora durante
      // ocho días, con humedad estable.
      final history = _series(
        hours: 24 * 10,
        ecAt: (h) => (h < 48 ? 1.0 : 1.0 + (h - 48) * 0.004) + _diurnal(h, 0.02),
        vwcAt: (h) => 30.0 + _diurnal(h, 0.5),
      );
      final scan = FertilizationSignatureScanner.scan(
        SignatureScanRequest(
          history: history,
          windowStart: _t0,
          now: _t0.add(const Duration(days: 10)),
        ),
      );
      expect(scan.signatures, isNotEmpty, reason: scan.summaryEs);
      final FertilizationSignature s = scan.best!;
      expect(s.kind, SignatureKind.delayedGradual);
      expect(
        s.confidence01,
        lessThanOrEqualTo(FertilizationSignatureScanner.gradualMaxConfidence),
      );
    });
  });
}
