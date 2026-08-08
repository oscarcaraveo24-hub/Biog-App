// test/core/weather/et0_calculator_test.dart

import 'package:flutter_test/flutter_test.dart';

import 'package:bio_g/core/weather/agronomic_weather_snapshot.dart';
import 'package:bio_g/core/weather/et0_calculator.dart';

void main() {
  group('radiación extraterrestre', () {
    test('produce valores en el orden de magnitud correcto', () {
      // FAO-56, tabla 2.6: en el ecuador Ra ronda 35-38 MJ/m²/día.
      final ra = Et0Calculator.extraterrestrialRadiation(
        latitudeDeg: 0,
        dayOfYear: 172,
      );
      expect(ra, isNotNull);
      expect(ra!, inInclusiveRange(30, 40));
    });

    test('el verano del norte supera al invierno del norte', () {
      final julio = Et0Calculator.extraterrestrialRadiation(
        latitudeDeg: 40,
        dayOfYear: 196,
      );
      final enero = Et0Calculator.extraterrestrialRadiation(
        latitudeDeg: 40,
        dayOfYear: 15,
      );
      expect(julio, isNotNull);
      expect(enero, isNotNull);
      expect(julio!, greaterThan(enero!));
    });

    test('no produce NaN en latitudes polares', () {
      final polar = Et0Calculator.extraterrestrialRadiation(
        latitudeDeg: 85,
        dayOfYear: 355,
      );
      expect(polar, isNotNull);
      expect(polar!.isFinite, isTrue);
      expect(polar, greaterThanOrEqualTo(0));
    });

    test('rechaza entradas imposibles', () {
      expect(
        Et0Calculator.extraterrestrialRadiation(
          latitudeDeg: 120,
          dayOfYear: 100,
        ),
        isNull,
      );
      expect(
        Et0Calculator.extraterrestrialRadiation(latitudeDeg: 20, dayOfYear: 0),
        isNull,
      );
    });
  });

  group('Hargreaves-Samani', () {
    test('da un valor plausible para un día cálido de verano', () {
      final et0 = Et0Calculator.hargreavesSamani(
        tMaxC: 32,
        tMinC: 18,
        latitudeDeg: 19.4,
        date: DateTime.utc(2026, 6, 21),
      );
      expect(et0, isNotNull);
      // Un día así en el centro de México ronda 5-8 mm.
      expect(et0!, inInclusiveRange(3.5, 9.0));
    });

    test('un día frío evapora menos que uno cálido', () {
      final frio = Et0Calculator.hargreavesSamani(
        tMaxC: 14,
        tMinC: 4,
        latitudeDeg: 19.4,
        date: DateTime.utc(2026, 1, 15),
      );
      final calido = Et0Calculator.hargreavesSamani(
        tMaxC: 34,
        tMinC: 20,
        latitudeDeg: 19.4,
        date: DateTime.utc(2026, 6, 15),
      );
      expect(frio!, lessThan(calido!));
    });

    test('devuelve null si falta una temperatura', () {
      expect(
        Et0Calculator.hargreavesSamani(
          tMaxC: null,
          tMinC: 10,
          latitudeDeg: 19,
          date: DateTime.utc(2026, 5, 1),
        ),
        isNull,
      );
    });

    test('amplitud térmica cero o negativa devuelve null, no cero', () {
      // Una ET0 de 0 mm sería un dato agronómico falso; lo honesto es no tener
      // dato. Es el mismo principio que la humedad ausente.
      expect(
        Et0Calculator.hargreavesSamani(
          tMaxC: 25,
          tMinC: 25,
          latitudeDeg: 19,
          date: DateTime.utc(2026, 5, 1),
        ),
        isNull,
      );
      expect(
        Et0Calculator.hargreavesSamani(
          tMaxC: 10,
          tMinC: 25,
          latitudeDeg: 19,
          date: DateTime.utc(2026, 5, 1),
        ),
        isNull,
      );
    });
  });

  group('resolución de origen', () {
    test('el valor del proveedor gana sobre la estimación local', () {
      final result = Et0Calculator.resolveDaily(
        providerEt0Mm: 5.1,
        tMaxC: 32,
        tMinC: 18,
        latitudeDeg: 19.4,
        date: DateTime.utc(2026, 6, 21),
      );
      expect(result.millimetersPerDay, 5.1);
      expect(result.source, Et0Source.openMeteoFao56);
      expect(result.source.isPrecise, isTrue);
    });

    test('sin proveedor cae a Hargreaves y lo declara', () {
      final result = Et0Calculator.resolveDaily(
        providerEt0Mm: null,
        tMaxC: 32,
        tMinC: 18,
        latitudeDeg: 19.4,
        date: DateTime.utc(2026, 6, 21),
      );
      expect(result.hasValue, isTrue);
      expect(result.source, Et0Source.hargreavesLocal);
      expect(result.source.isPrecise, isFalse);
    });

    test('un valor del proveedor imposible se descarta', () {
      final result = Et0Calculator.resolveDaily(
        providerEt0Mm: 99,
        tMaxC: 32,
        tMinC: 18,
        latitudeDeg: 19.4,
        date: DateTime.utc(2026, 6, 21),
      );
      expect(result.source, Et0Source.hargreavesLocal);
    });

    test('sin nada utilizable devuelve no disponible', () {
      final result = Et0Calculator.resolveDaily(
        providerEt0Mm: null,
        tMaxC: null,
        tMinC: null,
        latitudeDeg: 19.4,
        date: DateTime.utc(2026, 6, 21),
      );
      expect(result.hasValue, isFalse);
      expect(result.source, Et0Source.unavailable);
    });
  });

  group('regresión de unidades (FAO-56 ec. 52)', () {
    // Este grupo existe por un bug real: la primera versión metía Ra en
    // MJ/m²/día directamente en la fórmula de Hargreaves, que exige Ra como
    // evaporación equivalente en mm/día. El resultado salía 1/0.408 = 2.45
    // veces más alto: 14.5 mm/día donde el real son 5.9.
    test('Ra se convierte de MJ/m2/dia a mm/dia antes de la formula', () {
      const lat = 19.4;
      final fecha = DateTime.utc(2026, 6, 21);

      final raMj = Et0Calculator.extraterrestrialRadiation(
        latitudeDeg: lat,
        dayOfYear: Et0Calculator.dayOfYear(fecha),
      );
      expect(raMj, isNotNull);

      final et0 = Et0Calculator.hargreavesSamani(
        tMaxC: 32,
        tMinC: 18,
        latitudeDeg: lat,
        date: fecha,
      );
      expect(et0, isNotNull);

      // Rehacemos la cuenta a mano con la conversión explícita.
      const tMedia = (32 + 18) / 2;
      final esperado = 0.0023 * (raMj! * 0.408) * (tMedia + 17.8) * 3.7416573;
      expect(et0!, closeTo(esperado, 0.01));

      // Y la comprobación que de verdad caza el error: SIN convertir, el
      // resultado sería 2.45 veces mayor.
      final sinConvertir = 0.0023 * raMj * (tMedia + 17.8) * 3.7416573;
      expect(sinConvertir / et0, closeTo(1 / 0.408, 0.01));
      expect(et0, lessThan(sinConvertir));
    });

    test('ninguna latitud ni fecha produce una ET0 superior a 15 mm/dia', () {
      // Cota física: la ET0 más alta registrada en desierto extremo ronda
      // 15 mm/día. Cualquier valor por encima delata un error de unidades.
      for (final lat in <double>[-45, -20, 0, 19.4, 35, 55]) {
        for (final mes in <int>[1, 4, 7, 10]) {
          final et0 = Et0Calculator.hargreavesSamani(
            tMaxC: 45,
            tMinC: 20,
            latitudeDeg: lat,
            date: DateTime.utc(2026, mes, 15),
          );
          if (et0 == null) continue;
          expect(
            et0,
            lessThan(15.0),
            reason: 'lat $lat mes $mes dio $et0 mm/día',
          );
        }
      }
    });
  });

  test('día juliano', () {
    expect(Et0Calculator.dayOfYear(DateTime.utc(2026, 1, 1)), 1);
    expect(Et0Calculator.dayOfYear(DateTime.utc(2026, 12, 31)), 365);
  });
}
