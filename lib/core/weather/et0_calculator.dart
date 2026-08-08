// lib/core/weather/et0_calculator.dart
//
// Evapotranspiración de referencia (ET0) para cuando el proveedor no la da.
//
// Preferencia de origen, en orden:
//   1. `et0_fao_evapotranspiration` de Open-Meteo — FAO-56 Penman-Monteith
//      completo, con radiación, viento y déficit de presión de vapor reales.
//   2. Hargreaves-Samani local — solo necesita Tmax, Tmin y la latitud.
//
// Por qué existe el paso 2: el paso 1 puede faltar (respuesta parcial, red
// caída, snapshot viejo de caché). Una ET0 aproximada es mejor que ninguna
// para *orientar* el veto de riego, pero NO es suficiente para calcular una
// lámina en milímetros. Por eso el resultado viene siempre etiquetado con su
// origen y el motor de riego solo cuantifica con ET0 precisa (Fundacional 2.1:
// motor de veto primero, balance hídrico después).
//
// Referencia: Allen et al., FAO Irrigation and Drainage Paper 56, ec. 21 y 52.

import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'package:bio_g/core/weather/agronomic_weather_snapshot.dart';

@immutable
class Et0Estimate {
  const Et0Estimate({required this.millimetersPerDay, required this.source});

  final double? millimetersPerDay;
  final Et0Source source;

  static const Et0Estimate unavailable = Et0Estimate(
    millimetersPerDay: null,
    source: Et0Source.unavailable,
  );

  bool get hasValue => millimetersPerDay != null;
}

class Et0Calculator {
  const Et0Calculator._();

  /// Constante solar, MJ·m⁻²·min⁻¹ (FAO-56).
  static const double _solarConstant = 0.0820;

  /// Factor de conversión de MJ·m⁻²·día⁻¹ a mm·día⁻¹ de evaporación
  /// equivalente (FAO-56, ec. 20): dividir entre el calor latente de
  /// vaporización, 2.45 MJ·kg⁻¹.
  ///
  /// Es imprescindible en Hargreaves: la ecuación 52 exige Ra expresada en
  /// las MISMAS unidades que ET0 —milímetros—, no en megajulios. Omitirlo
  /// multiplica el resultado por 1/0.408 = 2.45 y devuelve valores como
  /// 14.5 mm/día donde el real es 5.9.
  static const double _mjToMm = 0.408;

  /// Resuelve la ET0 del día con la mejor fuente disponible.
  ///
  /// [providerEt0Mm] es el valor que Open-Meteo entregó, si llegó. Cuando es
  /// null se intenta Hargreaves con las temperaturas del snapshot.
  static Et0Estimate resolveDaily({
    double? providerEt0Mm,
    double? tMaxC,
    double? tMinC,
    required double latitudeDeg,
    required DateTime date,
  }) {
    if (providerEt0Mm != null &&
        providerEt0Mm.isFinite &&
        providerEt0Mm >= 0 &&
        providerEt0Mm <= 25) {
      return Et0Estimate(
        millimetersPerDay: providerEt0Mm,
        source: Et0Source.openMeteoFao56,
      );
    }

    final hargreaves = hargreavesSamani(
      tMaxC: tMaxC,
      tMinC: tMinC,
      latitudeDeg: latitudeDeg,
      date: date,
    );
    if (hargreaves == null) return Et0Estimate.unavailable;

    return Et0Estimate(
      millimetersPerDay: hargreaves,
      source: Et0Source.hargreavesLocal,
    );
  }

  /// ET0 diaria por Hargreaves-Samani (FAO-56 ec. 52), en mm/día.
  ///
  ///   ET0 = 0.0023 · Ra[mm/día] · (Tmedia + 17.8) · √(Tmax − Tmin)
  ///
  /// **Ra va en mm/día, no en MJ/m²/día.** [extraterrestrialRadiation]
  /// devuelve megajulios porque es la unidad estándar de esa magnitud, así
  /// que aquí se convierte con [_mjToMm] antes de usarla.
  ///
  /// Devuelve `null` si falta cualquier entrada o si el resultado cae fuera
  /// del rango físicamente plausible. Igual que en telemetría: un valor
  /// imposible se trata como dato ausente, no se recorta al límite.
  static double? hargreavesSamani({
    required double? tMaxC,
    required double? tMinC,
    required double latitudeDeg,
    required DateTime date,
  }) {
    if (tMaxC == null || tMinC == null) return null;
    if (!tMaxC.isFinite || !tMinC.isFinite) return null;
    if (!latitudeDeg.isFinite || latitudeDeg.abs() > 90) return null;

    // Una amplitud térmica negativa significa datos cruzados: es más honesto
    // devolver null que asumir que el orden estaba invertido.
    final range = tMaxC - tMinC;
    if (range < 0) return null;

    // Amplitud cero produce √0 = 0 y una ET0 de cero que no es real; suele
    // indicar que solo llegó una temperatura repetida en ambos campos.
    if (range == 0) return null;

    final tMean = (tMaxC + tMinC) / 2.0;
    if (tMean < -60 || tMean > 60) return null;

    final raMj = extraterrestrialRadiation(
      latitudeDeg: latitudeDeg,
      dayOfYear: dayOfYear(date),
    );
    if (raMj == null) return null;

    // Ra convertida a mm/día antes de entrar en la fórmula. Ver [_mjToMm].
    final raMm = raMj * _mjToMm;

    final et0 = 0.0023 * raMm * (tMean + 17.8) * math.sqrt(range);
    if (!et0.isFinite || et0 < 0 || et0 > 25) return null;

    return et0;
  }

  /// Radiación extraterrestre Ra en MJ·m⁻²·día⁻¹ (FAO-56 ec. 21).
  static double? extraterrestrialRadiation({
    required double latitudeDeg,
    required int dayOfYear,
  }) {
    if (!latitudeDeg.isFinite || latitudeDeg.abs() > 90) return null;
    if (dayOfYear < 1 || dayOfYear > 366) return null;

    final phi = latitudeDeg * math.pi / 180.0;

    // Distancia relativa inversa Tierra-Sol (ec. 23).
    final dr = 1.0 + 0.033 * math.cos(2 * math.pi * dayOfYear / 365.0);

    // Declinación solar (ec. 24).
    final delta = 0.409 * math.sin(2 * math.pi * dayOfYear / 365.0 - 1.39);

    // Ángulo horario de puesta de sol (ec. 25). En latitudes polares el
    // argumento del arccos se sale de [-1, 1]: se satura al día o noche
    // completos en vez de producir NaN.
    final cosOmega = -math.tan(phi) * math.tan(delta);
    final double omegaS;
    if (cosOmega >= 1.0) {
      omegaS = 0.0; // noche polar
    } else if (cosOmega <= -1.0) {
      omegaS = math.pi; // día polar
    } else {
      omegaS = math.acos(cosOmega);
    }

    final ra =
        (24 * 60 / math.pi) *
        _solarConstant *
        dr *
        (omegaS * math.sin(phi) * math.sin(delta) +
            math.cos(phi) * math.cos(delta) * math.sin(omegaS));

    if (!ra.isFinite || ra < 0) return null;
    return ra;
  }

  /// Día juliano 1..366.
  static int dayOfYear(DateTime date) {
    final utc = DateTime.utc(date.year, date.month, date.day);
    final start = DateTime.utc(date.year, 1, 1);
    return utc.difference(start).inDays + 1;
  }

  /// Convierte radiación media en W·m⁻² a MJ·m⁻²·día⁻¹.
  ///
  /// Útil para contrastar la Ra teórica contra la radiación medida y detectar
  /// un pronóstico incoherente. 1 W/m² sostenido un día = 0.0864 MJ/m².
  static double? shortwaveToMjPerDay(double? wattsPerM2) {
    if (wattsPerM2 == null || !wattsPerM2.isFinite || wattsPerM2 < 0) {
      return null;
    }
    return wattsPerM2 * 0.0864;
  }
}
