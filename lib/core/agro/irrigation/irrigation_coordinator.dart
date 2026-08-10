// lib/core/agro/irrigation/irrigation_coordinator.dart
//
// Une las cinco piezas: clima → decisión → registro → aviso.
//
// Existe para que la pantalla no tenga que orquestar nada. El Panel pide la
// decisión de forma síncrona (segura dentro de `build`) y, por separado, pide
// una sincronización que refresca el clima, recalcula y deja constancia.
//
// Separación deliberada entre [decisionFor] y [sync]:
//  - [decisionFor] es puro y no toca red ni disco. Se puede llamar en cada
//    reconstrucción sin coste ni riesgo de bucles.
//  - [sync] hace el trabajo asíncrono y solo notifica si el resultado cambió,
//    lo que evita que un `notifyListeners` dispare otra reconstrucción que
//    vuelva a llamar a `sync`.

import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:bio_g/core/agro/irrigation/irrigation_advisor.dart';
import 'package:bio_g/core/agro/irrigation/irrigation_types.dart';
import 'package:bio_g/core/agro/irrigation/parcel_location.dart';
import 'package:bio_g/core/agro/traceability/recommendation_recorder.dart';
import 'package:bio_g/core/crops/crop_runtime_snapshot.dart';
import 'package:bio_g/core/weather/agronomic_weather_snapshot.dart';
import 'package:bio_g/core/weather/weather_repository.dart';
import 'package:bio_g/models/device_crop_context.dart';

class IrrigationCoordinator extends ChangeNotifier {
  IrrigationCoordinator({
    WeatherRepository? weatherRepository,
    IrrigationAdvisor advisor = const IrrigationAdvisor(),
    RecommendationRecorder? recorder,
    DateTime Function()? clock,
    Future<void> Function(DeviceCropContext healed)? onParcelLocationRecovered,
  }) : _onParcelLocationRecovered = onParcelLocationRecovered,
       _weather = weatherRepository ?? WeatherRepository(),
       _ownsWeatherRepository = weatherRepository == null,
       _advisor = advisor,
       _recorder = recorder ?? RecommendationRecorder(),
       _now = clock ?? DateTime.now;

  final WeatherRepository _weather;
  final IrrigationAdvisor _advisor;

  /// Se invoca cuando la ubicación efectiva de la parcela no coincide con la
  /// que tiene guardada el contexto de cultivo. Quien lo reciba debe
  /// persistirlo; aquí no se conoce el store a propósito.
  final Future<void> Function(DeviceCropContext healed)?
  _onParcelLocationRecovered;
  final RecommendationRecorder _recorder;
  final DateTime Function() _now;

  /// Cada cuánto se vuelve a comprobar el clima aunque no haya lectura nueva.
  ///
  /// El repositorio decide si de verdad hace red (tiene su propio intervalo);
  /// esto solo evita que el coordinador deje de preguntar.
  static const Duration _weatherRecheckInterval = Duration(minutes: 15);

  /// True si este coordinador creó el repositorio de clima y por tanto debe
  /// liberarlo. Si se lo inyectaron, el dueño es quien lo inyectó.
  final bool _ownsWeatherRepository;

  WeatherRepository get weather => _weather;
  RecommendationRecorder get recorder => _recorder;

  IrrigationDecision? _decision;
  IrrigationDecision? get decision => _decision;

  /// Firma de la última decisión publicada, para no notificar en balde.
  String? _lastSignature;

  /// Evita solapar sincronizaciones.
  bool _syncing = false;

  /// Última clave de estado sincronizada.
  String? _lastSyncKey;

  /// Ubicación efectiva de la parcela, resuelta en el último [sync].
  ///
  /// Se guarda porque [decisionFor] es síncrono —corre dentro de `build`— y
  /// leer preferencias no lo es. En el primer fotograma vale null y la
  /// decisión sale sin clima; en cuanto [sync] resuelve, notifica y la
  /// siguiente reconstrucción ya la trae.
  ParcelLocation? _parcel;

  /// Coordenadas del último intento de curado, para no repetirlo mientras el
  /// guardado está en vuelo.
  String? _lastHealKey;

  /// La ubicación que se está usando para pedir clima y decidir. Null si la
  /// app todavía no sabe dónde está la parcela.
  ParcelLocation? get parcelLocation => _parcel;

  /// Calcula la decisión con el clima que YA está en memoria.
  ///
  /// Nunca dispara red: si el clima no está disponible todavía, el motor
  /// recibe un snapshot `unavailable` y decide en consecuencia —que es
  /// exactamente lo que debe hacer— en vez de bloquear la interfaz.
  IrrigationDecision? decisionFor(
    CropRuntimeSnapshot runtime, {
    DateTime? now,
  }) {
    if (runtime.device == null) return null;

    final at = now ?? _now();

    // La resuelta en el último `sync` manda; el contexto es el respaldo para
    // el primer fotograma, antes de que `sync` haya podido leer preferencias.
    final parcel =
        _parcel ?? ParcelLocationResolver.fromCropContext(runtime.cropContext);

    final snapshot = parcel == null
        ? AgronomicWeatherSnapshot.unavailable(at: at)
        : _weather.snapshotForDecision(lat: parcel.lat, lon: parcel.lon);

    return _advisor.adviseFromRuntime(
      runtime: runtime,
      weather: snapshot,
      now: at,
    );
  }

  /// Refresca clima, recalcula y registra.
  ///
  /// Seguro de llamar en cada reconstrucción: sale de inmediato si el estado
  /// relevante no cambió.
  Future<void> sync({
    required CropRuntimeSnapshot runtime,
    String? userId,
    bool force = false,
  }) async {
    if (_syncing) return;

    final device = runtime.device;
    if (device == null) return;

    // La bandera se levanta ANTES del primer `await`. Resolver la ubicación
    // toca preferencias, o sea que cede el hilo, y sin esto dos fotogramas
    // seguidos entrarían a la vez.
    _syncing = true;
    try {
      final reading = runtime.live;
      final now = _now();

      // Ubicación efectiva de la parcela. Manda la del perfil —lo último que
      // el usuario eligió— y el contexto de cultivo queda de respaldo.
      // `parcel_location.dart` explica por qué había dos.
      final ParcelLocation? parcel = await ParcelLocationResolver.resolve(
        runtime.cropContext,
      );
      _parcel = parcel;

      // La clave incluye un "cubo" de 15 minutos además del estado.
      //
      // Sin él, si no llega telemetría nueva la sincronización salía por la
      // primera comprobación para siempre y el clima quedaba congelado con el
      // de la primera vez, por mucho que venciera el intervalo de refresco del
      // repositorio.
      final int timeBucket =
          now.millisecondsSinceEpoch ~/ _weatherRecheckInterval.inMilliseconds;

      final key = <Object?>[
        device.id,
        reading?.timestamp.millisecondsSinceEpoch,
        runtime.cropContext?.cropId,
        runtime.stageResult?.stageKey,
        // Las coordenadas efectivas, no las del contexto: si el usuario mueve
        // la parcela desde Cuenta → Ubicación, esto lo nota en el acto.
        parcel?.lat,
        parcel?.lon,
        timeBucket,
      ].join('|');

      if (!force && key == _lastSyncKey) return;

      if (parcel != null) {
        // Sin ubicación no hay clima que pedir, y el motor ya sabe tratar la
        // ausencia. Pedirlo igual solo generaría errores de coordenadas.
        await _weather.ensureFresh(
          lat: parcel.lat,
          lon: parcel.lon,
          locationLabel:
              parcel.label ?? runtime.cropContext?.locationLabel ?? 'Parcela',
          force: force,
        );

        // Y si el contexto de cultivo no sabía dónde está la parcela, se le
        // dice. No es cosmético: el registro auditable y el panel web leen
        // `geo_lat` de ahí, no de las preferencias del teléfono.
        _healContextLocation(runtime.cropContext, parcel);
      }

      final next = decisionFor(runtime, now: now);
      _lastSyncKey = key;

      if (next == null) return;

      final signature = _signatureOf(next);
      final changed = signature != _lastSignature;

      _decision = next;
      _lastSignature = signature;

      // Solo lo que es una recomendación de verdad llega al registro
      // auditable; el recorder descarta `datosInsuficientes` por su cuenta.
      unawaited(
        _recorder.recordIrrigation(
          decision: next,
          runtime: runtime,
          userId: userId,
        ),
      );

      if (changed) notifyListeners();
    } catch (_) {
      // Ni el clima ni la trazabilidad pueden tumbar el Panel. Si algo falla,
      // la decisión anterior sigue siendo válida hasta su vencimiento.
    } finally {
      _syncing = false;
    }
  }

  /// Fuerza un refresco (tirar para refrescar).
  Future<void> refresh({
    required CropRuntimeSnapshot runtime,
    String? userId,
  }) {
    return sync(runtime: runtime, userId: userId, force: true);
  }

  /// Limpia el estado al cambiar de usuario o de dispositivo activo.
  void reset() {
    _decision = null;
    _lastSignature = null;
    _lastSyncKey = null;
    _parcel = null;
    _lastHealKey = null;
    _recorder.reset();
    notifyListeners();
  }

  @override
  void dispose() {
    if (_ownsWeatherRepository) _weather.dispose();
    super.dispose();
  }

  /// Escribe en el contexto de cultivo la ubicación que de verdad se está
  /// usando.
  ///
  /// No espera al guardado ni deja que un fallo afecte a la decisión: si no se
  /// pudo persistir, la próxima sincronización lo vuelve a intentar. El
  /// guardado dispara una reconstrucción, así que el guardián de coordenadas
  /// es lo que impide que eso se convierta en un bucle.
  void _healContextLocation(DeviceCropContext? context, ParcelLocation parcel) {
    final callback = _onParcelLocationRecovered;
    if (callback == null) return;
    if (!parcel.needsContextSync) return;

    final String healKey = '${parcel.lat}|${parcel.lon}';
    if (healKey == _lastHealKey) return;

    final DeviceCropContext? healed = ParcelLocationResolver.contextHealedWith(
      context,
      parcel,
    );
    if (healed == null) return;

    _lastHealKey = healKey;
    unawaited(callback(healed).catchError((Object _) {}));
  }

  /// Dos decisiones con la misma firma se consideran la misma para efectos de
  /// repintado. Incluye la confianza porque una caída de confianza cambia lo
  /// que la tarjeta debe mostrar aunque la acción sea la misma.
  static String _signatureOf(IrrigationDecision d) {
    return <Object?>[
      d.action.name,
      d.urgency.name,
      d.headlineEs,
      d.confidence01.toStringAsFixed(2),
      d.requiresConfirmation,
      d.weather?.source.name,
    ].join('|');
  }
}
