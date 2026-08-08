// lib/core/weather/weather_repository.dart
//
// Fuente única de clima para toda la aplicación.
//
// El problema que resuelve: antes cada pantalla instanciaba su propio
// `EnvironmentService`, cada una con su caché (o sin ninguna), y el motor
// agronómico no consultaba ninguno. El resultado era que Ambiente podía
// anunciar lluvia mientras el Panel recomendaba regar, porque literalmente
// miraban datos distintos.
//
// A partir de aquí hay un solo objeto que sabe qué clima está vigente. Quien
// decida riego y quien pinte el pronóstico leen del mismo lugar, así que la
// contradicción deja de ser posible por construcción y no por disciplina.
//
// Contrato de honestidad:
//  - `fetchedAt` es siempre el momento REAL de la descarga. Reutilizar la
//    caché nunca lo rejuvenece.
//  - Si no hay red y hay caché, se devuelve la caché marcada como tal.
//  - Si no hay red ni caché, se devuelve un snapshot `unavailable`, jamás
//    datos inventados ni ceros.

import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:bio_g/core/weather/agronomic_weather_snapshot.dart';
import 'package:bio_g/core/weather/weather_snapshot_storage.dart';
import 'package:bio_g/models/environment_models.dart';
import 'package:bio_g/services/environment_service.dart';

/// Resultado de pedir clima, con el motivo cuando no se pudo refrescar.
@immutable
class WeatherFetchOutcome {
  const WeatherFetchOutcome({
    required this.snapshot,
    required this.refreshed,
    this.failureKind,
    this.failureMessage,
  });

  final AgronomicWeatherSnapshot snapshot;

  /// True si este resultado viene de una descarga nueva.
  final bool refreshed;

  /// Motivo del fallo cuando [refreshed] es false y había intención de
  /// refrescar. Null si se sirvió de caché por política de TTL.
  final EnvironmentFailureKind? failureKind;
  final String? failureMessage;

  bool get servedFromCache =>
      snapshot.source == WeatherSnapshotSource.cache && !refreshed;

  bool get failed => failureKind != null;
}

class WeatherRepository extends ChangeNotifier {
  WeatherRepository({
    EnvironmentService service = const EnvironmentService(),
    WeatherSnapshotStorage? storage,
    Duration refreshInterval = const Duration(minutes: 30),
    DateTime Function()? clock,
  }) : _service = service,
       _storage = storage ?? SharedPrefsWeatherSnapshotStorage(),
       _refreshInterval = refreshInterval,
       _now = clock ?? DateTime.now;

  final EnvironmentService _service;
  final WeatherSnapshotStorage _storage;
  final Duration _refreshInterval;
  final DateTime Function() _now;

  /// Snapshots vigentes por clave de ubicación.
  final Map<String, AgronomicWeatherSnapshot> _byLocation =
      <String, AgronomicWeatherSnapshot>{};

  /// Descargas en vuelo. Dos pantallas que piden lo mismo al mismo tiempo
  /// comparten una sola petición de red.
  final Map<String, Future<WeatherFetchOutcome>> _inFlight =
      <String, Future<WeatherFetchOutcome>>{};

  /// Última ubicación consultada. Permite que la UI lea el clima vigente sin
  /// tener que conocer las coordenadas.
  String? _lastKey;

  /// Snapshot de la última ubicación consultada, o null si nunca se pidió.
  AgronomicWeatherSnapshot? get current {
    final key = _lastKey;
    if (key == null) return null;
    return _byLocation[key];
  }

  /// Snapshot vigente para unas coordenadas concretas, sin disparar red.
  AgronomicWeatherSnapshot? snapshotFor(double lat, double lon) {
    return _byLocation[SharedPrefsWeatherSnapshotStorage.locationKey(lat, lon)];
  }

  /// Clima listo para decidir, o `unavailable` si no hay nada utilizable.
  ///
  /// El motor de riego llama a esto, nunca a la red. Así una decisión jamás
  /// depende de que una petición HTTP termine a tiempo.
  AgronomicWeatherSnapshot snapshotForDecision({
    required double? lat,
    required double? lon,
  }) {
    final now = _now();
    if (lat == null || lon == null) {
      return AgronomicWeatherSnapshot.unavailable(at: now);
    }

    final snapshot = snapshotFor(lat, lon);
    if (snapshot == null) {
      return AgronomicWeatherSnapshot.unavailable(at: now, lat: lat, lon: lon);
    }

    // Vencido es tan inservible como ausente, y decirlo explícitamente evita
    // que el motor tenga que acordarse de mirar la antigüedad.
    if (!snapshot.isUsableForDecisionAt(now)) {
      return AgronomicWeatherSnapshot.unavailable(at: now, lat: lat, lon: lon);
    }

    return snapshot;
  }

  /// Carga desde disco lo último que se sabía de una ubicación.
  ///
  /// Pensado para el arranque: la app puede mostrar y decidir con el último
  /// pronóstico conocido antes de que la red responda, o incluso sin red.
  Future<AgronomicWeatherSnapshot?> hydrate({
    required double lat,
    required double lon,
  }) async {
    final key = SharedPrefsWeatherSnapshotStorage.locationKey(lat, lon);
    final cached = await _storage.load(key);
    if (cached == null) return null;

    _byLocation[key] = cached;
    _lastKey = key;
    notifyListeners();
    return cached;
  }

  /// Devuelve clima utilizable, descargándolo si hace falta.
  ///
  /// [force] salta el intervalo de refresco (tirar para refrescar).
  Future<WeatherFetchOutcome> ensureFresh({
    required double lat,
    required double lon,
    String locationLabel = 'Parcela',
    String zoneLabel = '',
    bool force = false,
  }) async {
    final key = SharedPrefsWeatherSnapshotStorage.locationKey(lat, lon);
    _lastKey = key;

    // Coordenadas imposibles: se responde sin tocar la red.
    if (!_areUsableCoordinates(lat, lon)) {
      final snapshot = AgronomicWeatherSnapshot.unavailable(at: _now());
      return WeatherFetchOutcome(
        snapshot: snapshot,
        refreshed: false,
        failureKind: EnvironmentFailureKind.invalidCoordinates,
        failureMessage: 'Coordenadas no utilizables ($lat, $lon)',
      );
    }

    // Caché en memoria todavía dentro del intervalo.
    final existing = _byLocation[key];
    if (!force && existing != null && _isWithinRefreshInterval(existing)) {
      return WeatherFetchOutcome(snapshot: existing, refreshed: false);
    }

    // Caché en disco, por si es un arranque en frío.
    if (existing == null) {
      final fromDisk = await _storage.load(key);
      if (fromDisk != null) {
        _byLocation[key] = fromDisk;
        notifyListeners();
        if (!force && _isWithinRefreshInterval(fromDisk)) {
          return WeatherFetchOutcome(snapshot: fromDisk, refreshed: false);
        }
      }
    }

    final inFlight = _inFlight[key];
    if (inFlight != null) return inFlight;

    final future = _download(
      key: key,
      lat: lat,
      lon: lon,
      locationLabel: locationLabel,
      zoneLabel: zoneLabel,
    );
    _inFlight[key] = future;

    try {
      return await future;
    } finally {
      _inFlight.remove(key);
    }
  }

  Future<WeatherFetchOutcome> _download({
    required String key,
    required double lat,
    required double lon,
    required String locationLabel,
    required String zoneLabel,
  }) async {
    final location = EnvironmentLocation(
      fieldName: locationLabel,
      zoneLabel: zoneLabel,
      updatedAt: _now(),
      lat: lat,
      lon: lon,
    );

    try {
      final snapshot = await _service.fetchAgronomicSnapshot(
        location: location,
      );

      _byLocation[key] = snapshot;
      unawaited(_storage.save(key, snapshot));
      notifyListeners();

      return WeatherFetchOutcome(snapshot: snapshot, refreshed: true);
    } on EnvironmentServiceException catch (e) {
      return _fallbackAfterFailure(
        key: key,
        lat: lat,
        lon: lon,
        kind: e.kind,
        message: e.message,
      );
    } catch (e) {
      return _fallbackAfterFailure(
        key: key,
        lat: lat,
        lon: lon,
        kind: EnvironmentFailureKind.network,
        message: e.toString(),
      );
    }
  }

  /// Ante un fallo de red, se sirve lo último que se sabía — marcado como
  /// caché y con su antigüedad real — en lugar de dejar a la app sin clima.
  WeatherFetchOutcome _fallbackAfterFailure({
    required String key,
    required double lat,
    required double lon,
    required EnvironmentFailureKind kind,
    required String message,
  }) {
    final existing = _byLocation[key];
    if (existing != null) {
      final cached = existing.asCached();
      _byLocation[key] = cached;
      notifyListeners();
      return WeatherFetchOutcome(
        snapshot: cached,
        refreshed: false,
        failureKind: kind,
        failureMessage: message,
      );
    }

    return WeatherFetchOutcome(
      snapshot: AgronomicWeatherSnapshot.unavailable(
        at: _now(),
        lat: lat,
        lon: lon,
      ),
      refreshed: false,
      failureKind: kind,
      failureMessage: message,
    );
  }

  bool _isWithinRefreshInterval(AgronomicWeatherSnapshot snapshot) {
    return snapshot.ageAt(_now()) < _refreshInterval;
  }

  static bool _areUsableCoordinates(double lat, double lon) {
    if (!lat.isFinite || !lon.isFinite) return false;
    if (lat < -90 || lat > 90) return false;
    if (lon < -180 || lon > 180) return false;
    // (0, 0) es el marcador habitual de "sin ubicación" en este proyecto.
    if (lat == 0 && lon == 0) return false;
    return true;
  }

  /// Olvida todo lo cacheado. Se llama al cerrar sesión: el pronóstico de la
  /// parcela de un usuario no debe sobrevivir al cambio de cuenta.
  Future<void> clearAll() async {
    _byLocation.clear();
    _inFlight.clear();
    _lastKey = null;
    await _storage.clearAll();
    notifyListeners();
  }
}
