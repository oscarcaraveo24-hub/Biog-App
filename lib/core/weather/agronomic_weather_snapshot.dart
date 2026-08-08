// lib/core/weather/agronomic_weather_snapshot.dart
//
// Fotografía inmutable del clima tal como el motor agronómico lo usó.
//
// Por qué existe: hasta ahora el clima vivía dentro de las pantallas de
// Ambiente y desaparecía en cuanto el widget se destruía. Ninguna decisión
// podía citar el pronóstico que la produjo, así que era imposible responder
// "¿por qué me dijo que regara si iba a llover?".
//
// Este snapshot es el contrato: todo lo que el motor necesita saber del clima
// cabe aquí, se serializa, se persiste y se guarda junto a la recomendación.
// Fundacional 2.1 §9.1 (dato válido -> contexto climático -> decisión).
//
// Regla de diseño: TODOS los campos meteorológicos son nullable. Un dato que
// no llegó vale `null`, nunca `0`. Un cero en lluvia significa "no va a
// llover"; un null significa "no sé si va a llover", y son decisiones
// distintas. Esta es la lección del bug de humedad ausente = 0.

import 'package:flutter/foundation.dart';

/// De dónde salió el snapshot.
enum WeatherSnapshotSource {
  /// Descarga completa (current + horario + diario) desde Open-Meteo.
  forecast,

  /// Solo condiciones actuales; el pronóstico no pudo descargarse.
  currentOnly,

  /// Reconstruido desde la caché persistida: la app está sin red.
  cache,

  /// No hay clima disponible en absoluto.
  unavailable,
}

extension WeatherSnapshotSourceX on WeatherSnapshotSource {
  String get labelEs {
    switch (this) {
      case WeatherSnapshotSource.forecast:
        return 'Pronóstico en línea';
      case WeatherSnapshotSource.currentOnly:
        return 'Solo condiciones actuales';
      case WeatherSnapshotSource.cache:
        return 'Último pronóstico guardado';
      case WeatherSnapshotSource.unavailable:
        return 'Sin datos de clima';
    }
  }

  /// True si el snapshot puede usarse para decidir riego.
  ///
  /// `currentOnly` no basta: sin pronóstico no se puede aplicar el veto por
  /// lluvia, que es la mitad del valor del motor.
  bool get supportsIrrigationDecision =>
      this == WeatherSnapshotSource.forecast ||
      this == WeatherSnapshotSource.cache;
}

/// Cómo se obtuvo la evapotranspiración de referencia.
enum Et0Source {
  /// Open-Meteo la entregó calculada (FAO-56 Penman-Monteith).
  openMeteoFao56,

  /// Estimada localmente por Hargreaves-Samani a partir de temperaturas.
  hargreavesLocal,

  /// No hay ET0 disponible.
  unavailable,
}

extension Et0SourceX on Et0Source {
  String get labelEs {
    switch (this) {
      case Et0Source.openMeteoFao56:
        return 'FAO-56 (Open-Meteo)';
      case Et0Source.hargreavesLocal:
        return 'Estimada (Hargreaves)';
      case Et0Source.unavailable:
        return 'No disponible';
    }
  }

  /// La estimación local sirve para orientar, no para calcular una lámina.
  bool get isPrecise => this == Et0Source.openMeteoFao56;
}

/// Qué tan viejo es el snapshot respecto al momento de la decisión.
enum WeatherFreshness {
  /// Menos de 1 h. Se puede decidir con confianza plena.
  fresh,

  /// Entre 1 h y 6 h. Se puede decidir, con confianza reducida.
  aging,

  /// Entre 6 h y 24 h. Solo veto conservador: no autoriza regar por sí solo.
  stale,

  /// Más de 24 h. Inservible para decidir.
  expired,
}

extension WeatherFreshnessX on WeatherFreshness {
  String get labelEs {
    switch (this) {
      case WeatherFreshness.fresh:
        return 'Actualizado';
      case WeatherFreshness.aging:
        return 'Reciente';
      case WeatherFreshness.stale:
        return 'Desactualizado';
      case WeatherFreshness.expired:
        return 'Vencido';
    }
  }

  /// Penalización de confianza que este nivel de frescura impone.
  double get confidencePenalty {
    switch (this) {
      case WeatherFreshness.fresh:
        return 0.0;
      case WeatherFreshness.aging:
        return 0.10;
      case WeatherFreshness.stale:
        return 0.30;
      case WeatherFreshness.expired:
        return 1.0;
    }
  }

  bool get isUsableForDecision => this != WeatherFreshness.expired;
}

/// Umbrales de vigencia del clima. Centralizados para que la política sea
/// una sola y esté documentada, no repartida en constantes sueltas.
class WeatherValidityPolicy {
  const WeatherValidityPolicy({
    this.freshLimit = const Duration(hours: 1),
    this.agingLimit = const Duration(hours: 6),
    this.staleLimit = const Duration(hours: 24),
  });

  final Duration freshLimit;
  final Duration agingLimit;
  final Duration staleLimit;

  static const WeatherValidityPolicy standard = WeatherValidityPolicy();

  WeatherFreshness freshnessFor(Duration age) {
    if (age < freshLimit) return WeatherFreshness.fresh;
    if (age < agingLimit) return WeatherFreshness.aging;
    if (age < staleLimit) return WeatherFreshness.stale;
    return WeatherFreshness.expired;
  }
}

/// Probabilidad de lluvia en ventanas cortas, en porcentaje 0-100.
///
/// Cada ventana es nullable por separado: el pronóstico horario puede cubrir
/// las próximas 24 h y no las 48 h.
@immutable
class RainOutlook {
  const RainOutlook({
    this.probNext6hPct,
    this.probNext12hPct,
    this.probNext24hPct,
    this.probNext48hPct,
    this.expectedNext24hMm,
    this.expectedNext48hMm,
    this.observedLast24hMm,
    this.observedLast72hMm,
  });

  final int? probNext6hPct;
  final int? probNext12hPct;
  final int? probNext24hPct;
  final int? probNext48hPct;

  /// Acumulado previsto, en milímetros.
  final double? expectedNext24hMm;
  final double? expectedNext48hMm;

  /// Lluvia ya caída. Open-Meteo la entrega en el bloque `past_days`.
  final double? observedLast24hMm;
  final double? observedLast72hMm;

  static const RainOutlook empty = RainOutlook();

  bool get hasAnyForecast =>
      probNext6hPct != null ||
      probNext12hPct != null ||
      probNext24hPct != null ||
      expectedNext24hMm != null;

  bool get hasAnyObservation =>
      observedLast24hMm != null || observedLast72hMm != null;

  /// Probabilidad más alta dentro de la ventana operativa de riego (24 h).
  int? get maxProbNext24hPct {
    final candidates = <int>[
      ?probNext6hPct,
      ?probNext12hPct,
      ?probNext24hPct,
    ];
    if (candidates.isEmpty) return null;
    return candidates.reduce((a, b) => a > b ? a : b);
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'probNext6hPct': probNext6hPct,
    'probNext12hPct': probNext12hPct,
    'probNext24hPct': probNext24hPct,
    'probNext48hPct': probNext48hPct,
    'expectedNext24hMm': expectedNext24hMm,
    'expectedNext48hMm': expectedNext48hMm,
    'observedLast24hMm': observedLast24hMm,
    'observedLast72hMm': observedLast72hMm,
  };

  static RainOutlook fromJson(Map<String, dynamic> json) {
    return RainOutlook(
      probNext6hPct: _asInt(json['probNext6hPct']),
      probNext12hPct: _asInt(json['probNext12hPct']),
      probNext24hPct: _asInt(json['probNext24hPct']),
      probNext48hPct: _asInt(json['probNext48hPct']),
      expectedNext24hMm: _asDouble(json['expectedNext24hMm']),
      expectedNext48hMm: _asDouble(json['expectedNext48hMm']),
      observedLast24hMm: _asDouble(json['observedLast24hMm']),
      observedLast72hMm: _asDouble(json['observedLast72hMm']),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RainOutlook &&
        other.probNext6hPct == probNext6hPct &&
        other.probNext12hPct == probNext12hPct &&
        other.probNext24hPct == probNext24hPct &&
        other.probNext48hPct == probNext48hPct &&
        other.expectedNext24hMm == expectedNext24hMm &&
        other.expectedNext48hMm == expectedNext48hMm &&
        other.observedLast24hMm == observedLast24hMm &&
        other.observedLast72hMm == observedLast72hMm;
  }

  @override
  int get hashCode => Object.hash(
    probNext6hPct,
    probNext12hPct,
    probNext24hPct,
    probNext48hPct,
    expectedNext24hMm,
    expectedNext48hMm,
    observedLast24hMm,
    observedLast72hMm,
  );
}

/// El snapshot completo.
@immutable
class AgronomicWeatherSnapshot {
  const AgronomicWeatherSnapshot({
    required this.lat,
    required this.lon,
    required this.fetchedAt,
    required this.source,
    this.timezone,
    this.observedAt,
    this.airTempC,
    this.airTempMaxC,
    this.airTempMinC,
    this.airHumidityPct,
    this.windKmh,
    this.shortwaveWm2,
    this.weatherCode,
    this.rain = RainOutlook.empty,
    this.et0TodayMm,
    this.et0Next24hMm,
    this.et0Source = Et0Source.unavailable,
    this.policy = WeatherValidityPolicy.standard,
  });

  /// Coordenadas de la parcela para las que se pidió el clima.
  final double lat;
  final double lon;

  /// Zona horaria resuelta por el proveedor (`America/Mexico_City`).
  final String? timezone;

  /// Cuándo se descargó este snapshot. Es la referencia de frescura: nunca se
  /// reescribe al reutilizar la caché, para que la antigüedad sea la real.
  final DateTime fetchedAt;

  /// Momento de la observación "actual" según el proveedor.
  final DateTime? observedAt;

  final double? airTempC;
  final double? airTempMaxC;
  final double? airTempMinC;
  final double? airHumidityPct;
  final double? windKmh;
  final double? shortwaveWm2;
  final int? weatherCode;

  final RainOutlook rain;

  /// Evapotranspiración de referencia, en mm.
  final double? et0TodayMm;
  final double? et0Next24hMm;
  final Et0Source et0Source;

  final WeatherSnapshotSource source;
  final WeatherValidityPolicy policy;

  /// Snapshot vacío: se usa cuando no hay ubicación o no hay red ni caché.
  /// Deliberadamente NO es `null` para que el motor siempre reciba un objeto
  /// y tenga que decidir explícitamente qué hacer sin clima.
  static AgronomicWeatherSnapshot unavailable({
    required DateTime at,
    double lat = 0,
    double lon = 0,
  }) {
    return AgronomicWeatherSnapshot(
      lat: lat,
      lon: lon,
      fetchedAt: at,
      source: WeatherSnapshotSource.unavailable,
    );
  }

  bool get isUnavailable => source == WeatherSnapshotSource.unavailable;

  Duration ageAt(DateTime now) {
    final diff = now.toUtc().difference(fetchedAt.toUtc());
    return diff.isNegative ? Duration.zero : diff;
  }

  WeatherFreshness freshnessAt(DateTime now) {
    if (isUnavailable) return WeatherFreshness.expired;
    return policy.freshnessFor(ageAt(now));
  }

  /// True si este snapshot puede fundamentar una decisión de riego.
  bool isUsableForDecisionAt(DateTime now) {
    if (isUnavailable) return false;
    if (!source.supportsIrrigationDecision) return false;
    return freshnessAt(now).isUsableForDecision;
  }

  /// Etiqueta de antigüedad para la interfaz. Nunca miente: si el snapshot
  /// viene de caché lo dice, aunque la app se acabe de abrir.
  String freshnessLabelEs(DateTime now) {
    if (isUnavailable) return 'Sin datos de clima';

    final age = ageAt(now);
    final String rel;
    if (age.inMinutes < 2) {
      rel = 'hace un momento';
    } else if (age.inMinutes < 60) {
      rel = 'hace ${age.inMinutes} min';
    } else if (age.inHours < 24) {
      rel = 'hace ${age.inHours} h';
    } else {
      rel = 'hace ${age.inDays} d';
    }

    if (source == WeatherSnapshotSource.cache) {
      return 'Último pronóstico guardado $rel';
    }
    return 'Clima actualizado $rel';
  }

  /// Copia marcada como proveniente de caché, conservando el `fetchedAt`
  /// original. Es el punto exacto donde se evitaba antes mentir sobre la
  /// antigüedad: reutilizar el dato NO lo vuelve nuevo.
  AgronomicWeatherSnapshot asCached() {
    if (source == WeatherSnapshotSource.cache) return this;
    return copyWith(source: WeatherSnapshotSource.cache);
  }

  AgronomicWeatherSnapshot copyWith({
    double? lat,
    double? lon,
    String? timezone,
    DateTime? fetchedAt,
    DateTime? observedAt,
    double? airTempC,
    double? airTempMaxC,
    double? airTempMinC,
    double? airHumidityPct,
    double? windKmh,
    double? shortwaveWm2,
    int? weatherCode,
    RainOutlook? rain,
    double? et0TodayMm,
    double? et0Next24hMm,
    Et0Source? et0Source,
    WeatherSnapshotSource? source,
    WeatherValidityPolicy? policy,
  }) {
    return AgronomicWeatherSnapshot(
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
      timezone: timezone ?? this.timezone,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      observedAt: observedAt ?? this.observedAt,
      airTempC: airTempC ?? this.airTempC,
      airTempMaxC: airTempMaxC ?? this.airTempMaxC,
      airTempMinC: airTempMinC ?? this.airTempMinC,
      airHumidityPct: airHumidityPct ?? this.airHumidityPct,
      windKmh: windKmh ?? this.windKmh,
      shortwaveWm2: shortwaveWm2 ?? this.shortwaveWm2,
      weatherCode: weatherCode ?? this.weatherCode,
      rain: rain ?? this.rain,
      et0TodayMm: et0TodayMm ?? this.et0TodayMm,
      et0Next24hMm: et0Next24hMm ?? this.et0Next24hMm,
      et0Source: et0Source ?? this.et0Source,
      source: source ?? this.source,
      policy: policy ?? this.policy,
    );
  }

  /// Serialización estable. Va a la caché en disco y al RecommendationRecord,
  /// así que el formato es parte del contrato de trazabilidad: agregar campos
  /// está permitido, cambiar el significado de uno existente no.
  Map<String, dynamic> toJson() => <String, dynamic>{
    'v': 1,
    'lat': lat,
    'lon': lon,
    'timezone': timezone,
    'fetchedAt': fetchedAt.toUtc().toIso8601String(),
    'observedAt': observedAt?.toUtc().toIso8601String(),
    'airTempC': airTempC,
    'airTempMaxC': airTempMaxC,
    'airTempMinC': airTempMinC,
    'airHumidityPct': airHumidityPct,
    'windKmh': windKmh,
    'shortwaveWm2': shortwaveWm2,
    'weatherCode': weatherCode,
    'rain': rain.toJson(),
    'et0TodayMm': et0TodayMm,
    'et0Next24hMm': et0Next24hMm,
    'et0Source': et0Source.name,
    'source': source.name,
  };

  /// Devuelve `null` si la fila es ilegible. Un snapshot viejo con un formato
  /// que ya no se entiende jamás debe tumbar la app: se descarta y se vuelve
  /// a pedir el clima.
  static AgronomicWeatherSnapshot? fromJson(Map<String, dynamic> json) {
    try {
      final fetchedRaw = json['fetchedAt'];
      if (fetchedRaw is! String) return null;
      final fetchedAt = DateTime.tryParse(fetchedRaw);
      if (fetchedAt == null) return null;

      final lat = _asDouble(json['lat']);
      final lon = _asDouble(json['lon']);
      if (lat == null || lon == null) return null;

      final observedRaw = json['observedAt'];
      final observedAt = observedRaw is String
          ? DateTime.tryParse(observedRaw)
          : null;

      return AgronomicWeatherSnapshot(
        lat: lat,
        lon: lon,
        timezone: json['timezone'] as String?,
        fetchedAt: fetchedAt,
        observedAt: observedAt,
        airTempC: _asDouble(json['airTempC']),
        airTempMaxC: _asDouble(json['airTempMaxC']),
        airTempMinC: _asDouble(json['airTempMinC']),
        airHumidityPct: _asDouble(json['airHumidityPct']),
        windKmh: _asDouble(json['windKmh']),
        shortwaveWm2: _asDouble(json['shortwaveWm2']),
        weatherCode: _asInt(json['weatherCode']),
        rain: RainOutlook.fromJson(
          (json['rain'] as Map?)?.cast<String, dynamic>() ??
              const <String, dynamic>{},
        ),
        et0TodayMm: _asDouble(json['et0TodayMm']),
        et0Next24hMm: _asDouble(json['et0Next24hMm']),
        et0Source: _enumByName(
          Et0Source.values,
          json['et0Source'],
          Et0Source.unavailable,
        ),
        source: _enumByName(
          WeatherSnapshotSource.values,
          json['source'],
          WeatherSnapshotSource.cache,
        ),
      );
    } catch (_) {
      return null;
    }
  }

  /// Resumen compacto para incrustar en la evidencia de una recomendación.
  /// Deliberadamente más corto que [toJson]: el registro guarda lo que la
  /// decisión usó, no el pronóstico entero.
  Map<String, Object?> toEvidenceJson() => <String, Object?>{
    'source': source.name,
    'fetchedAt': fetchedAt.toUtc().toIso8601String(),
    'airTempC': airTempC,
    'airHumidityPct': airHumidityPct,
    'rainProb24hPct': rain.probNext24hPct,
    'rainProb12hPct': rain.probNext12hPct,
    'rainNext24hMm': rain.expectedNext24hMm,
    'rainLast24hMm': rain.observedLast24hMm,
    'et0TodayMm': et0TodayMm,
    'et0Source': et0Source.name,
  };

  @override
  String toString() =>
      'AgronomicWeatherSnapshot(source: ${source.name}, fetchedAt: $fetchedAt, '
      'rainProb24h: ${rain.probNext24hPct}, et0: $et0TodayMm)';
}

// ── Helpers de parseo tolerante ─────────────────────────────────────────────

double? _asDouble(Object? value) {
  if (value == null) return null;
  if (value is double) return value.isFinite ? value : null;
  if (value is int) return value.toDouble();
  if (value is String) {
    final parsed = double.tryParse(value);
    return (parsed != null && parsed.isFinite) ? parsed : null;
  }
  if (value is num) {
    final d = value.toDouble();
    return d.isFinite ? d : null;
  }
  return null;
}

int? _asInt(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is double) return value.isFinite ? value.round() : null;
  if (value is String) return int.tryParse(value);
  if (value is num) return value.toInt();
  return null;
}

T _enumByName<T extends Enum>(List<T> values, Object? raw, T fallback) {
  if (raw is! String) return fallback;
  for (final v in values) {
    if (v.name == raw) return v;
  }
  return fallback;
}
