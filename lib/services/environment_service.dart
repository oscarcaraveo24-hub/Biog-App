// lib/services/environment_service.dart
import 'dart:async';
import 'dart:convert';

import 'package:bio_g/models/environment_models.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

enum EnvironmentFailureKind {
  invalidCoordinates,
  timeout,
  network,
  http,
  parse,
}

class EnvironmentServiceException implements Exception {
  final EnvironmentFailureKind kind;
  final String message;
  final int? statusCode;
  final Object? cause;

  const EnvironmentServiceException({
    required this.kind,
    required this.message,
    this.statusCode,
    this.cause,
  });

  @override
  String toString() {
    final status = statusCode == null ? '' : ' status=$statusCode';
    final detail = cause == null ? '' : ' cause=$cause';
    return 'EnvironmentServiceException(kind=${kind.name}$status, '
        'message=$message$detail)';
  }
}

class EnvironmentService {
  const EnvironmentService();

  static const String _apiHost = 'api.open-meteo.com';
  static const String _forecastPath = '/v1/forecast';
  static const Duration _requestTimeout = Duration(seconds: 30);
  static const bool _debugEnvironmentLogs = false;
  static const List<Duration> _timeoutRetryDelays = <Duration>[
    Duration(seconds: 1),
    Duration(seconds: 3),
  ];
  static final Map<String, Future<http.Response>> _inFlightRequests =
      <String, Future<http.Response>>{};

  /// Primera carga ligera: permite pintar la pantalla antes de pedir series.
  Future<EnvironmentPayload> fetchCurrentEnvironment({
    required EnvironmentLocation location,
  }) async {
    final uri = _forecastUri(location, <String, String>{
      'timezone': 'auto',
      'current':
          'temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m,precipitation,is_day',
      'forecast_days': '1',
    });

    final res = await _get(uri, requestName: 'Current weather');
    _ensureSuccess(res, requestName: 'Current weather');

    final data = _decodeObject(res.body);
    final current = _asObject(data['current'], field: 'current');
    final nowModel = _nowFromCurrent(current);

    return EnvironmentPayload(
      location: location.copyWith(updatedAt: DateTime.now()),
      now: nowModel,
      nextDays: const <EnvironmentDaily>[],
      insight: _buildInsight(const <EnvironmentDaily>[], nowModel),
    );
  }

  /// ✅ Fetch principal (mantiene arquitectura/modelos actuales)
  /// - EnvironmentScreen: usa default (3 días)
  /// - EnvironmentForecastScreen: pide 7 días con dailyLimit: 7
  Future<EnvironmentPayload> fetchEnvironment({
    required EnvironmentLocation location,
    int dailyLimit = 3,
  }) async {
    // Open-Meteo: current + daily + hourly
    final uri = _forecastUri(location, <String, String>{
      'timezone': 'auto',
      'current':
          'temperature_2m,relative_humidity_2m,wind_speed_10m,weather_code,precipitation,is_day',
      'hourly': 'precipitation_probability,shortwave_radiation',
      'daily':
          'temperature_2m_max,temperature_2m_min,precipitation_probability_max,precipitation_sum,weather_code,wind_speed_10m_max',
      'forecast_days': '7',
    });

    final res = await _get(uri, requestName: 'Weather');
    _ensureSuccess(res, requestName: 'Weather');

    final data = _decodeObject(res.body);

    // ---------- current ----------
    final current = _asObject(data['current'], field: 'current');

    // ---------- radiation (pick nearest hour) ----------
    double? shortwave;
    final hourly = _asObject(
      data['hourly'],
      field: 'hourly',
      isRequired: false,
    );
    final times = _asList(
      hourly['time'],
      field: 'hourly.time',
      isRequired: false,
    ).map((e) => e.toString()).toList();
    final radiation = _asList(
      hourly['shortwave_radiation'],
      field: 'hourly.shortwave_radiation',
      isRequired: false,
    );

    final nowIso = (current['time'] ?? '').toString();
    final idx = times.indexOf(nowIso);
    if (idx >= 0) {
      shortwave = _nullableNumD(_valueAt(radiation, idx));
    } else if (radiation.isNotEmpty) {
      shortwave = _nullableNumD(radiation.first);
    }

    final nowModel = _nowFromCurrent(current, shortwaveWm2: shortwave);

    // ---------- daily (FULL 7 from API) ----------
    final daily = _asObject(data['daily'], field: 'daily');
    final dailyTimes = _asList(
      daily['time'],
      field: 'daily.time',
    ).map((e) => e.toString()).toList();

    if (dailyTimes.isEmpty) {
      throw _parseError('Missing daily forecast rows');
    }

    final tMax = _asList(
      daily['temperature_2m_max'],
      field: 'daily.temperature_2m_max',
      isRequired: false,
    );
    final tMin = _asList(
      daily['temperature_2m_min'],
      field: 'daily.temperature_2m_min',
      isRequired: false,
    );
    final pMax = _asList(
      daily['precipitation_probability_max'],
      field: 'daily.precipitation_probability_max',
      isRequired: false,
    );
    final precipitationSum = _asList(
      daily['precipitation_sum'],
      field: 'daily.precipitation_sum',
      isRequired: false,
    );
    final wCode = _asList(
      daily['weather_code'],
      field: 'daily.weather_code',
      isRequired: false,
    );
    final wMax = _asList(
      daily['wind_speed_10m_max'],
      field: 'daily.wind_speed_10m_max',
      isRequired: false,
    );

    final fullDays = <EnvironmentDaily>[];
    for (int i = 0; i < dailyTimes.length; i++) {
      final weatherCode = _numI(_valueAt(wCode, i));
      final dCond = _mapWeatherCode(weatherCode);
      final label = _dayLabelFromIso(dailyTimes[i], i);

      final windKmh = _numD(_valueAt(wMax, i));
      final windLabel = _windLabel(windKmh);
      fullDays.add(
        EnvironmentDaily(
          dayLabel: label,
          condition: dCond,
          weatherCode: weatherCode,
          precipitationMm: _nullableNumD(_valueAt(precipitationSum, i)),
          forecastDate: DateTime.tryParse(dailyTimes[i]),
          maxC: _numD(_valueAt(tMax, i)).round(),
          minC: _numD(_valueAt(tMin, i)).round(),
          rainProbPct: _numI(_valueAt(pMax, i)).clamp(0, 100),
          windLabel: windLabel,
          windKmh: windKmh,
        ),
      );
    }

    // ✅ Aquí está el fix:
    // - Service ya tiene 7 reales (fullDays)
    // - PERO puedes pedir 3 o 7 según la pantalla con dailyLimit
    final limitedDays = fullDays
        .take(dailyLimit.clamp(1, fullDays.length))
        .toList();

    // ---------- insight ----------
    final insight = _buildInsight(limitedDays, nowModel);

    return EnvironmentPayload(
      location: location.copyWith(updatedAt: DateTime.now()),
      now: nowModel,
      nextDays: limitedDays,
      insight: insight,
    );
  }

  // ---------------------------------------------------------------------------
  // ✅ PREPARADO PARA LA SIGUIENTE PANTALLA (24 horas por día)
  //
  // No toca tus modelos actuales. Regresa una lista simple para que luego
  // decidas si creas un EnvironmentHourly model (en environment_models.dart).
  // ---------------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> fetchHourly24h({
    required EnvironmentLocation location,
    required DateTime day,
  }) async {
    final start = _yyyyMmDd(day);
    final end = _yyyyMmDd(day.add(const Duration(days: 1)));

    // Pedimos 1 día exacto (24h) y variables útiles para UI
    final uri = _forecastUri(location, <String, String>{
      'timezone': 'auto',
      'hourly':
          'temperature_2m,relative_humidity_2m,wind_speed_10m,precipitation_probability,precipitation,weather_code,is_day',
      'start_date': start,
      'end_date': end,
    });

    final res = await _get(uri, requestName: 'Hourly weather');
    _ensureSuccess(res, requestName: 'Hourly weather');

    final data = _decodeObject(res.body);
    final hourly = _asObject(data['hourly'], field: 'hourly');

    final times = _asList(
      hourly['time'],
      field: 'hourly.time',
    ).map((e) => e.toString()).toList();
    final temps = _asList(
      hourly['temperature_2m'],
      field: 'hourly.temperature_2m',
      isRequired: false,
    );
    final hums = _asList(
      hourly['relative_humidity_2m'],
      field: 'hourly.relative_humidity_2m',
      isRequired: false,
    );
    final winds = _asList(
      hourly['wind_speed_10m'],
      field: 'hourly.wind_speed_10m',
      isRequired: false,
    );
    final pops = _asList(
      hourly['precipitation_probability'],
      field: 'hourly.precipitation_probability',
      isRequired: false,
    );
    final precipitation = _asList(
      hourly['precipitation'],
      field: 'hourly.precipitation',
      isRequired: false,
    );
    final codes = _asList(
      hourly['weather_code'],
      field: 'hourly.weather_code',
      isRequired: false,
    );
    final dayFlags = _asList(
      hourly['is_day'],
      field: 'hourly.is_day',
      isRequired: false,
    );

    final out = <Map<String, dynamic>>[];
    final n = times.length;

    for (int i = 0; i < n; i++) {
      final weatherCode = _numI(_valueAt(codes, i));
      final condition = _mapWeatherCode(weatherCode);
      out.add({
        'timeIso': times[i],
        'tempC': _numD(_valueAt(temps, i)),
        'humidityPct': _numI(_valueAt(hums, i)),
        'windKmh': _numD(_valueAt(winds, i)),
        'rainProbPct': _numI(_valueAt(pops, i)).clamp(0, 100),
        'precipitationMm': _nullableNumD(_valueAt(precipitation, i)),
        'weatherCode': weatherCode,
        'isDay': _nullableIsDay(_valueAt(dayFlags, i)),
        'condition': condition,
        'conditionLabel': _labelForCondition(condition),
      });
    }

    return out;
  }

  String _yyyyMmDd(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  EnvironmentNow _nowFromCurrent(
    Map<String, dynamic> current, {
    double? shortwaveWm2,
  }) {
    final temp = _numD(current['temperature_2m']);
    final hum = _numI(current['relative_humidity_2m']);
    final wind = _numD(current['wind_speed_10m']);
    final weatherCode = _numI(current['weather_code']);
    final condition = _mapWeatherCode(weatherCode);

    return EnvironmentNow(
      condition: condition,
      conditionLabel: _labelForCondition(condition),
      agroNote: _agroNoteForNow(condition, temp, hum, wind),
      weatherCode: weatherCode,
      observedAt: DateTime.tryParse((current['time'] ?? '').toString()),
      isDay: _nullableIsDay(current['is_day']),
      precipitationMm: _nullableNumD(current['precipitation']),
      tempC: temp,
      humidityPct: hum,
      windKmh: wind,
      shortwaveWm2: shortwaveWm2,
    );
  }

  Uri _forecastUri(EnvironmentLocation location, Map<String, String> query) {
    _validateCoordinates(location);
    return Uri.https(_apiHost, _forecastPath, <String, String>{
      'latitude': location.lat.toString(),
      'longitude': location.lon.toString(),
      ...query,
    });
  }

  void _validateCoordinates(EnvironmentLocation location) {
    final lat = location.lat;
    final lon = location.lon;
    final invalidRange =
        !lat.isFinite ||
        !lon.isFinite ||
        lat < -90 ||
        lat > 90 ||
        lon < -180 ||
        lon > 180;

    if (invalidRange || (lat == 0 && lon == 0)) {
      throw EnvironmentServiceException(
        kind: EnvironmentFailureKind.invalidCoordinates,
        message: 'Invalid coordinates latitude=$lat longitude=$lon',
      );
    }
  }

  Map<String, dynamic> _decodeObject(String body) {
    try {
      final decoded = jsonDecode(body);
      return _asObject(decoded, field: 'response');
    } on EnvironmentServiceException {
      rethrow;
    } catch (error) {
      _logError('parse failed response error=$error');
      throw _parseError('Invalid JSON response: $error');
    }
  }

  Map<String, dynamic> _asObject(
    dynamic value, {
    required String field,
    bool isRequired = true,
  }) {
    if (value is Map) {
      return value.map<String, dynamic>(
        (key, nestedValue) =>
            MapEntry<String, dynamic>(key.toString(), nestedValue),
      );
    }
    if (!isRequired) return <String, dynamic>{};
    throw _parseError('Missing or invalid object: $field');
  }

  List<dynamic> _asList(
    dynamic value, {
    required String field,
    bool isRequired = true,
  }) {
    if (value is List) return List<dynamic>.from(value);
    if (!isRequired) return <dynamic>[];
    throw _parseError('Missing or invalid list: $field');
  }

  dynamic _valueAt(List<dynamic> values, int index) {
    if (index < 0 || index >= values.length) return null;
    return values[index];
  }

  double? _nullableNumD(dynamic value) =>
      value is num ? value.toDouble() : null;
  bool? _nullableIsDay(dynamic value) => value is num ? value != 0 : null;

  EnvironmentServiceException _parseError(String message) {
    _logError('parse failed error=$message');
    return EnvironmentServiceException(
      kind: EnvironmentFailureKind.parse,
      message: message,
    );
  }

  void _ensureSuccess(http.Response response, {required String requestName}) {
    if (response.statusCode == 200) return;

    final excerpt = _responseExcerpt(response.body);
    throw EnvironmentServiceException(
      kind: EnvironmentFailureKind.http,
      statusCode: response.statusCode,
      message:
          '$requestName HTTP ${response.statusCode}'
          '${excerpt.isEmpty ? '' : ' body=$excerpt'}',
    );
  }

  Future<http.Response> _get(Uri uri, {required String requestName}) {
    final key = uri.toString();
    final existing = _inFlightRequests[key];
    if (existing != null) {
      _logOpenMeteo('deduplicated request=$requestName url=$uri');
      return existing;
    }

    late final Future<http.Response> tracked;
    tracked = _getWithTimeoutRetry(uri, requestName: requestName).whenComplete(
      () {
        if (identical(_inFlightRequests[key], tracked)) {
          _inFlightRequests.remove(key);
        }
      },
    );
    _inFlightRequests[key] = tracked;
    return tracked;
  }

  Future<http.Response> _getWithTimeoutRetry(
    Uri uri, {
    required String requestName,
  }) async {
    final totalStopwatch = Stopwatch()..start();
    final maxAttempts = _timeoutRetryDelays.length + 1;

    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      final attemptStopwatch = Stopwatch()..start();
      final startedAt = DateTime.now().toUtc().toIso8601String();
      _logOpenMeteo(
        'GET $uri request=$requestName attempt=$attempt/$maxAttempts '
        'started_at=$startedAt timeout_s=${_requestTimeout.inSeconds}',
      );

      try {
        final response = await http.get(uri).timeout(_requestTimeout);
        _logOpenMeteo(
          'response status=${response.statusCode} '
          'elapsed_ms=${attemptStopwatch.elapsedMilliseconds} '
          'total_elapsed_ms=${totalStopwatch.elapsedMilliseconds} '
          'request=$requestName attempt=$attempt/$maxAttempts',
        );
        if (response.statusCode != 200) {
          _logOpenMeteoError(
            'response status=${response.statusCode} '
            'elapsed_ms=${attemptStopwatch.elapsedMilliseconds} '
            'body=${_responseExcerpt(response.body)}',
          );
        }
        return response;
      } on TimeoutException catch (error) {
        _logOpenMeteoError(
          'timeout elapsed_ms=${attemptStopwatch.elapsedMilliseconds} '
          'total_elapsed_ms=${totalStopwatch.elapsedMilliseconds} '
          'timeout_s=${_requestTimeout.inSeconds} '
          'request=$requestName attempt=$attempt/$maxAttempts',
        );
        if (attempt == maxAttempts) {
          throw EnvironmentServiceException(
            kind: EnvironmentFailureKind.timeout,
            message:
                '$requestName timeout after $maxAttempts attempts '
                'of ${_requestTimeout.inSeconds} seconds',
            cause: error,
          );
        }

        final retryDelay = _timeoutRetryDelays[attempt - 1];
        _logOpenMeteo(
          'retry scheduled request=$requestName '
          'delay_s=${retryDelay.inSeconds} next_attempt=${attempt + 1}',
        );
        await Future<void>.delayed(retryDelay);
      } on EnvironmentServiceException {
        rethrow;
      } catch (error) {
        _logOpenMeteoError(
          'network error type=${error.runtimeType} message=$error '
          'elapsed_ms=${attemptStopwatch.elapsedMilliseconds} '
          'request=$requestName attempt=$attempt/$maxAttempts',
        );
        throw EnvironmentServiceException(
          kind: EnvironmentFailureKind.network,
          message: '$requestName request failed',
          cause: error,
        );
      }
    }

    throw StateError('Unreachable Open-Meteo retry state');
  }

  String _responseExcerpt(String body) {
    final normalizedBody = body.replaceAll(RegExp(r'\s+'), ' ').trim();
    return normalizedBody.length > 180
        ? '${normalizedBody.substring(0, 180)}...'
        : normalizedBody;
  }

  void _log(String message) {
    if (!kDebugMode || !_debugEnvironmentLogs) return;
    debugPrint('[BioG/Environment] $message');
  }

  void _logOpenMeteo(String message) {
    if (!kDebugMode || !_debugEnvironmentLogs) return;
    debugPrint('[BioG/OpenMeteo] $message');
  }

  void _logError(String message) {
    if (!kDebugMode) return;
    debugPrint('[BioG/Environment] $message');
  }

  void _logOpenMeteoError(String message) {
    if (!kDebugMode) return;
    debugPrint('[BioG/OpenMeteo] $message');
  }

  // Casts numericos tolerantes a null. Open-Meteo puede devolver null en
  // algunos campos (radiacion nocturna, prob. de lluvia en los bordes del
  // pronostico); un solo null no debe tumbar toda la pantalla del clima.
  double _numD(dynamic e, [double fallback = 0]) =>
      e is num ? e.toDouble() : fallback;
  int _numI(dynamic e, [int fallback = 0]) => e is num ? e.round() : fallback;

  // ---------------- helpers ----------------

  EnvCondition _mapWeatherCode(int code) {
    return EnvironmentIconMapper.conditionFromWmoCode(code);
  }

  String _labelForCondition(EnvCondition c) {
    switch (c) {
      case EnvCondition.sunny:
        return 'Soleado';
      case EnvCondition.night:
        return 'Despejado';
      case EnvCondition.partlyCloudy:
        return 'Parcialmente nublado';
      case EnvCondition.cloudy:
        return 'Nublado';
      case EnvCondition.fog:
        return 'Neblina';
      case EnvCondition.drizzle:
        return 'Llovizna';
      case EnvCondition.rain:
        return 'Lluvia';
      case EnvCondition.thunder:
        return 'Tormenta';
      case EnvCondition.stormStrong:
        return 'Tormenta fuerte';
      case EnvCondition.snow:
        return 'Nieve';
      case EnvCondition.frost:
        return 'Helada';
      case EnvCondition.heatwave:
        return 'Calor extremo';
      case EnvCondition.unknown:
      default:
        return 'Clima';
    }
  }

  String _agroNoteForNow(EnvCondition c, double t, int h, double wind) {
    if (c == EnvCondition.stormStrong || c == EnvCondition.thunder) {
      return 'Tormenta: protege labores y revisa drenaje';
    }
    if (c == EnvCondition.frost || c == EnvCondition.snow) {
      return 'Frio intenso: vigila helada y protege el cultivo';
    }
    if (c == EnvCondition.rain || c == EnvCondition.drizzle) {
      return 'Humedad elevada: vigila riego y hongos';
    }
    if (t >= 34) return 'Calor alto: riesgo de estrés térmico';
    if (t <= 6) return 'Frío: vigila helada';
    if (wind >= 28) return 'Viento fuerte: posible estrés mecánico';
    if (h <= 25) return 'Aire seco: mayor transpiración';
    return 'Sensación estable para el cultivo';
  }

  String _dayLabelFromIso(String iso, int i) {
    if (i == 0) return 'Hoy';

    final dt = DateTime.tryParse(iso);
    if (dt == null) return 'Día';

    const names = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo',
    ];
    return names[(dt.weekday - 1).clamp(0, 6)];
  }

  String _windLabel(double kmh) {
    if (kmh < 12) return 'Viento bajo';
    if (kmh < 24) return 'Viento moderado';
    return 'Viento fuerte';
  }

  EnvironmentInsight _buildInsight(
    List<EnvironmentDaily> nextDays,
    EnvironmentNow now,
  ) {
    if (now.condition == EnvCondition.stormStrong ||
        now.condition == EnvCondition.thunder) {
      return const EnvironmentInsight(
        level: EnvInsightLevel.critical,
        text: 'Tormenta activa: protege labores y revisa drenaje.',
      );
    }

    if (now.condition == EnvCondition.frost ||
        now.condition == EnvCondition.snow) {
      return const EnvironmentInsight(
        level: EnvInsightLevel.critical,
        text: 'Frio intenso: vigila helada y protege el cultivo.',
      );
    }

    for (final d in nextDays) {
      if (d.condition == EnvCondition.stormStrong ||
          d.condition == EnvCondition.thunder) {
        return EnvironmentInsight(
          level: EnvInsightLevel.critical,
          text:
              'Riesgo de tormenta el ${d.dayLabel.toLowerCase()}, protege labores y revisa drenaje.',
        );
      }
      if (d.condition == EnvCondition.frost ||
          d.condition == EnvCondition.snow) {
        return EnvironmentInsight(
          level: EnvInsightLevel.warn,
          text:
              'Riesgo de helada el ${d.dayLabel.toLowerCase()}, protege el cultivo.',
        );
      }
      if (d.rainProbPct >= 60) {
        return EnvironmentInsight(
          level: EnvInsightLevel.warn,
          text:
              'Se espera lluvia el ${d.dayLabel.toLowerCase()}, considera ajustar riego.',
        );
      }
    }

    if (now.tempC >= 34 || (now.shortwaveWm2 ?? 0) >= 950) {
      return const EnvironmentInsight(
        level: EnvInsightLevel.warn,
        text: 'Temperatura alta: monitorea estrés térmico y riego.',
      );
    }

    return const EnvironmentInsight(
      level: EnvInsightLevel.ok,
      text: 'Condiciones estables. Mantén monitoreo y riego programado.',
    );
  }
}
