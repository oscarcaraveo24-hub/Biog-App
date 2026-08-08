// lib/core/agro/traceability/recommendation_recorder.dart
//
// Convierte una decisión efímera en memoria auditable, y la lee de vuelta.
//
// Esta clase es el consumidor que le faltaba al almacén: existe justamente
// para que guardar y leer sean el mismo camino y no puedan separarse con el
// tiempo, que es como el registro anterior acabó siendo de escritura pura.

import 'package:bio_g/core/agro/irrigation/irrigation_types.dart';
import 'package:bio_g/core/agro/traceability/recommendation_record.dart';
import 'package:bio_g/core/agro/traceability/recommendation_store.dart';
import 'package:bio_g/core/crops/crop_runtime_snapshot.dart';

class RecommendationRecorder {
  RecommendationRecorder({
    RecommendationStore? store,
    DateTime Function()? clock,
  }) : _store = store ?? RecommendationStore(),
       _now = clock ?? DateTime.now;

  final RecommendationStore _store;
  final DateTime Function() _now;

  RecommendationStore get store => _store;

  /// Evita reescribir la misma decisión si el store notifica varias veces.
  String? _lastRecordedId;

  /// Registra una decisión de riego.
  ///
  /// Devuelve el registro guardado, o `null` si no había nada que guardar.
  ///
  /// Regla deliberada: **`datosInsuficientes` NO se registra como
  /// recomendación**. No es un consejo, es la ausencia de uno. Guardarlo
  /// ensuciaría el historial con filas que dirían "BIO-G recomendó" algo que
  /// nunca recomendó.
  Future<RecommendationRecord?> recordIrrigation({
    required IrrigationDecision decision,
    required CropRuntimeSnapshot runtime,
    String? userId,
  }) async {
    if (!decision.action.isRecommendation) return null;

    final deviceId = runtime.device?.id;
    final reading = runtime.live;
    if (deviceId == null || reading == null) return null;

    final context = runtime.cropContext;

    final ageMinutes = decision.evidence['moistureAgeMinutes'];
    final isPresent = decision.evidence['moisturePresent'];
    final isCalibrated = decision.evidence['moistureCalibrated'];

    final record = RecommendationRecord.fromIrrigationDecision(
      decision: decision,
      deviceId: deviceId,
      readingTimestamp: reading.timestamp,
      userId: userId,
      cropId: context?.cropId ?? runtime.cropKeyName,
      cropLabel: runtime.cropLabel,
      varietyId: context?.varietyId,
      varietyAlias: context?.varietyAlias,
      catalogVersion: context?.catalogVersion,
      parcelLabel: context?.locationLabel,
      parcelLat: context?.geoLat,
      parcelLon: context?.geoLng,
      moistureIsPresent: isPresent is bool ? isPresent : null,
      moistureIsCalibrated: isCalibrated is bool ? isCalibrated : null,
      moistureAgeMinutes: ageMinutes is int ? ageMinutes : null,
    );

    if (record.id == _lastRecordedId) return record;

    await _store.save(record);
    _lastRecordedId = record.id;
    return record;
  }

  /// Historial auditable de un dispositivo.
  Future<List<RecommendationRecord>> history({
    required String deviceId,
    String? userId,
    RecommendationKind? kind,
    int limit = 200,
  }) {
    return _store.load(
      deviceId: deviceId,
      userId: userId,
      kind: kind,
      limit: limit,
    );
  }

  /// Recomendaciones que esperan respuesta del agricultor.
  Future<List<RecommendationRecord>> pending({
    required String deviceId,
    String? userId,
  }) async {
    // Se vencen primero las caducadas para que "pendiente" no incluya cosas
    // que ya no valen.
    await _store.expirePending(now: _now());
    return _store.loadPending(deviceId: deviceId, userId: userId);
  }

  /// Registra la acción del agricultor sobre una recomendación.
  Future<bool> respond({
    required String recordId,
    required UserResponse response,
  }) {
    return _store.respond(
      recordId: recordId,
      response: response,
      at: _now(),
    );
  }

  /// Limpia la marca de deduplicación al cambiar de usuario o dispositivo.
  void reset() {
    _lastRecordedId = null;
  }
}
