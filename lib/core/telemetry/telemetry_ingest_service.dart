// lib/core/telemetry/telemetry_ingest_service.dart
//
// El recorrido operativo de una medición, de principio a fin.
//
// Este es el archivo que faltaba. `uploadBatch()` y `TelemetryLocalStorage.
// append()` existían desde hacía tiempo y tenían **cero llamadores**: eran dos
// puertas sin pasillo. Aquí está el pasillo.
//
// Orden deliberado, y es el orden lo que importa:
//
//   1. Validar el sobre contra el contrato.
//   2. Guardar en local. Si esto falla, se aborta: perder el dato no es opción.
//   3. Marcar como pendiente de nube, en almacenamiento persistente.
//   4. Intentar subir.
//   5. Quitar de pendientes SOLO si la nube confirmó.
//
// El paso 5 es el que evita el defecto que ya existe en la cola de contexto de
// cultivo, donde los adaptadores tragan el error con `catch (_) {}` y la
// operación se descarta al primer intento, dejando el backoff como código
// inalcanzable. Aquí la confirmación es explícita: `uploadBatch` devuelve un
// booleano y sin un `true` nada se da por sincronizado.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bio_g/core/telemetry/telemetry_contract.dart';
import 'package:bio_g/core/telemetry/telemetry_transport.dart';
import 'package:bio_g/models/biog_telemetry.dart';
import 'package:bio_g/services/biog/storage/telemetry_local_storage.dart';
import 'package:bio_g/services/biog/storage/telemetry_supabase_sync.dart';

/// Qué pasó con un sobre.
enum TelemetryIngestStatus {
  /// Guardado en local y confirmado en la nube.
  storedAndSynced,

  /// Guardado en local; la nube queda pendiente de reintento.
  storedPendingSync,

  /// Rechazado por el contrato. No se guardó.
  rejected,

  /// Ya se había recibido esta misma lectura.
  duplicate,

  /// Fallo al escribir en local. El dato no se guardó en ningún sitio.
  storageFailure,
}

@immutable
class TelemetryIngestResult {
  const TelemetryIngestResult({
    required this.status,
    this.rejection,
    this.reading,
    this.message,
  });

  final TelemetryIngestStatus status;
  final TelemetryRejectionReason? rejection;
  final BioGTelemetry? reading;
  final String? message;

  bool get isStored =>
      status == TelemetryIngestStatus.storedAndSynced ||
      status == TelemetryIngestStatus.storedPendingSync;

  bool get isSynced => status == TelemetryIngestStatus.storedAndSynced;

  String get labelEs {
    switch (status) {
      case TelemetryIngestStatus.storedAndSynced:
        return 'Lectura guardada y sincronizada';
      case TelemetryIngestStatus.storedPendingSync:
        return 'Lectura guardada; se sincronizará al recuperar señal';
      case TelemetryIngestStatus.rejected:
        return rejection?.labelEs ?? 'Lectura rechazada';
      case TelemetryIngestStatus.duplicate:
        return 'Lectura repetida; se ignoró';
      case TelemetryIngestStatus.storageFailure:
        return 'No se pudo guardar la lectura';
    }
  }
}

class TelemetryIngestService {
  TelemetryIngestService({
    TelemetryLocalStorage? localStorage,
    TelemetrySupabaseSync? cloudSync,
    DateTime Function()? clock,
  }) : _local = localStorage ?? TelemetryLocalStorage(),
       _cloud = cloudSync ?? TelemetrySupabaseSync(),
       _now = clock ?? DateTime.now;

  static const String _pendingPrefsKey = 'biog_telemetry_pending_upload_v1';
  static const String _sequencePrefsKey = 'biog_telemetry_last_sequence_v1';

  /// Cuántas lecturas se suben por lote al vaciar pendientes.
  static const int _flushBatchSize = 100;

  final TelemetryLocalStorage _local;
  final TelemetrySupabaseSync _cloud;
  final DateTime Function() _now;

  StreamSubscription<TelemetryEnvelope>? _transportSub;

  /// Pendientes de subir: deviceId -> conjunto de instantes en epoch ms.
  final Map<String, Set<int>> _pending = <String, Set<int>>{};

  /// Última secuencia vista por dispositivo, para descartar duplicados.
  final Map<String, int> _lastSequence = <String, int>{};

  bool _hydrated = false;

  final StreamController<TelemetryIngestResult> _results =
      StreamController<TelemetryIngestResult>.broadcast();

  /// Resultados de ingesta, para que la interfaz muestre lo que ocurrió.
  Stream<TelemetryIngestResult> get results => _results.stream;

  /// Cuántas lecturas esperan confirmación de la nube.
  int get pendingCount =>
      _pending.values.fold<int>(0, (sum, set) => sum + set.length);

  // ── Ciclo de vida ────────────────────────────────────────────────────────

  /// Carga el estado persistente. Idempotente.
  Future<void> hydrate() async {
    if (_hydrated) return;
    _hydrated = true;

    try {
      final prefs = await SharedPreferences.getInstance();

      final rawPending = prefs.getString(_pendingPrefsKey);
      if (rawPending != null && rawPending.isNotEmpty) {
        final decoded = jsonDecode(rawPending);
        if (decoded is Map) {
          decoded.forEach((key, value) {
            if (value is! List) return;
            _pending[key.toString()] = value
                .whereType<num>()
                .map((n) => n.toInt())
                .toSet();
          });
        }
      }

      final rawSeq = prefs.getString(_sequencePrefsKey);
      if (rawSeq != null && rawSeq.isNotEmpty) {
        final decoded = jsonDecode(rawSeq);
        if (decoded is Map) {
          decoded.forEach((key, value) {
            if (value is num) _lastSequence[key.toString()] = value.toInt();
          });
        }
      }
    } catch (_) {
      // Un estado persistente ilegible no puede impedir recibir lecturas: se
      // arranca en limpio. Lo peor que pasa es reintentar una subida ya hecha,
      // y el upsert por (device_id, timestamp) la hace idempotente.
      _pending.clear();
      _lastSequence.clear();
    }
  }

  /// Conecta un transporte para que sus sobres entren automáticamente.
  ///
  /// Este es el punto exacto donde se enchufará el BLE real: basta con pasar
  /// una implementación distinta de [TelemetryTransport].
  void bindTransport(TelemetryTransport transport) {
    _transportSub?.cancel();
    _transportSub = transport.envelopes.listen((envelope) {
      unawaited(ingest(envelope));
    });
  }

  Future<void> dispose() async {
    await _transportSub?.cancel();
    _transportSub = null;
    await _results.close();
  }

  // ── Ingesta ──────────────────────────────────────────────────────────────

  /// Procesa un sobre completo.
  Future<TelemetryIngestResult> ingest(TelemetryEnvelope envelope) async {
    await hydrate();

    final now = _now();

    // 1) Contrato.
    final rejection = envelope.validate(now: now);
    if (rejection != null) {
      return _emit(
        TelemetryIngestResult(
          status: TelemetryIngestStatus.rejected,
          rejection: rejection,
          message: rejection.labelEs,
        ),
      );
    }

    final deviceId = envelope.identity.deviceId.trim();

    // 2) Duplicados por número de secuencia.
    final seq = envelope.sequenceNumber;
    if (seq != null) {
      final last = _lastSequence[deviceId];
      if (last != null && seq <= last && !envelope.quality.isRetransmission) {
        return _emit(
          const TelemetryIngestResult(
            status: TelemetryIngestStatus.duplicate,
            rejection: TelemetryRejectionReason.duplicateSequence,
          ),
        );
      }
    }

    final reading = envelope.toReading();

    // 3) Local primero. Si esto falla, no se sigue: la fuente de verdad de la
    //    app es el almacenamiento local, y una lectura que no queda ahí es una
    //    lectura perdida.
    final storedOk = await _storeLocally(deviceId, reading);
    if (!storedOk) {
      return _emit(
        const TelemetryIngestResult(
          status: TelemetryIngestStatus.storageFailure,
        ),
      );
    }

    if (seq != null) {
      _lastSequence[deviceId] = seq;
      unawaited(_persistSequences());
    }

    // 4) Marcar pendiente ANTES de intentar subir. Si la app muere durante la
    //    subida, al reabrir la lectura sigue marcada y se reintenta.
    final stamp = reading.timestamp.toUtc().millisecondsSinceEpoch;
    _pending.putIfAbsent(deviceId, () => <int>{}).add(stamp);
    await _persistPending();

    // 5) Nube, con confirmación explícita.
    final uploaded = await _cloud.uploadBatch(<BioGTelemetry>[reading]);
    if (uploaded) {
      _pending[deviceId]?.remove(stamp);
      if (_pending[deviceId]?.isEmpty ?? false) _pending.remove(deviceId);
      await _persistPending();

      return _emit(
        TelemetryIngestResult(
          status: TelemetryIngestStatus.storedAndSynced,
          reading: reading,
        ),
      );
    }

    return _emit(
      TelemetryIngestResult(
        status: TelemetryIngestStatus.storedPendingSync,
        reading: reading,
      ),
    );
  }

  /// Procesa un lote. Devuelve cuántos quedaron guardados.
  Future<int> ingestBatch(List<TelemetryEnvelope> envelopes) async {
    var stored = 0;
    for (final envelope in envelopes) {
      final result = await ingest(envelope);
      if (result.isStored) stored++;
    }
    return stored;
  }

  // ── Reintento de pendientes ──────────────────────────────────────────────

  /// Reintenta subir lo que quedó pendiente. Devuelve cuántas se confirmaron.
  ///
  /// Pensado para llamarse al recuperar conectividad y al arrancar la app.
  Future<int> flushPending() async {
    await hydrate();
    if (_pending.isEmpty) return 0;

    var confirmed = 0;

    // Copia de las claves: el mapa se modifica dentro del bucle.
    for (final deviceId in _pending.keys.toList(growable: false)) {
      final stamps = _pending[deviceId];
      if (stamps == null || stamps.isEmpty) {
        _pending.remove(deviceId);
        continue;
      }

      final List<BioGTelemetry> local = await _local.load(deviceId);
      if (local.isEmpty) {
        // La lectura ya no está en local (purga por tope de tamaño). No tiene
        // sentido mantenerla pendiente para siempre.
        _pending.remove(deviceId);
        continue;
      }

      final byStamp = <int, BioGTelemetry>{
        for (final r in local) r.timestamp.toUtc().millisecondsSinceEpoch: r,
      };

      final toUpload = <BioGTelemetry>[];
      final orphaned = <int>[];
      for (final stamp in stamps) {
        final reading = byStamp[stamp];
        if (reading != null) {
          toUpload.add(reading);
        } else {
          orphaned.add(stamp);
        }
      }

      // Pendientes cuya lectura ya no existe en local: se sueltan.
      stamps.removeAll(orphaned);

      for (var i = 0; i < toUpload.length; i += _flushBatchSize) {
        final end = (i + _flushBatchSize).clamp(0, toUpload.length);
        final chunk = toUpload.sublist(i, end);

        final ok = await _cloud.uploadBatch(chunk);
        if (!ok) break; // sin red: el resto sigue pendiente

        for (final r in chunk) {
          stamps.remove(r.timestamp.toUtc().millisecondsSinceEpoch);
          confirmed++;
        }
      }

      if (stamps.isEmpty) _pending.remove(deviceId);
    }

    await _persistPending();
    return confirmed;
  }

  /// Olvida los pendientes de un dispositivo. Se llama al desvincularlo.
  Future<void> forgetDevice(String deviceId) async {
    await hydrate();
    _pending.remove(deviceId);
    _lastSequence.remove(deviceId);
    await _persistPending();
    await _persistSequences();
  }

  /// Olvida todo. Se llama al cerrar sesión.
  Future<void> clear() async {
    _pending.clear();
    _lastSequence.clear();
    await _persistPending();
    await _persistSequences();
  }

  // ── Internos ─────────────────────────────────────────────────────────────

  Future<bool> _storeLocally(String deviceId, BioGTelemetry reading) async {
    try {
      await _local.append(deviceId, reading);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _persistPending() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_pending.isEmpty) {
        await prefs.remove(_pendingPrefsKey);
        return;
      }
      await prefs.setString(
        _pendingPrefsKey,
        jsonEncode(
          _pending.map((k, v) => MapEntry(k, v.toList(growable: false))),
        ),
      );
    } catch (_) {
      // Persistir el pendiente es una mejora de robustez, no un requisito
      // para que la lectura actual funcione.
    }
  }

  Future<void> _persistSequences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_lastSequence.isEmpty) {
        await prefs.remove(_sequencePrefsKey);
        return;
      }
      await prefs.setString(_sequencePrefsKey, jsonEncode(_lastSequence));
    } catch (_) {
      // Ídem.
    }
  }

  TelemetryIngestResult _emit(TelemetryIngestResult result) {
    if (!_results.isClosed) _results.add(result);
    return result;
  }
}
