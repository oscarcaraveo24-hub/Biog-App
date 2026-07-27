import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Entidad que se sincroniza con Supabase.
enum SyncEntity { cropContext, yieldProjection }

/// Operación pendiente sobre esa entidad.
enum SyncOp { upsert, delete }

/// Una operación esperando su turno para subir a la nube.
///
/// El payload es el objeto de dominio ya serializado. Se guarda tal cual para
/// que la operación sobreviva a que la app se cierre: al reabrir se reconstruye
/// desde JSON sin depender de que el objeto siga en memoria.
@immutable
class PendingSyncOp {
  const PendingSyncOp({
    required this.entity,
    required this.op,
    required this.entityId,
    this.payload,
    this.attempts = 0,
    this.nextAttemptAtMs = 0,
  });

  final SyncEntity entity;
  final SyncOp op;

  /// Identificador de la fila. Hoy siempre es el `deviceId`.
  final String entityId;

  /// Objeto serializado. Null para las operaciones de borrado.
  final Map<String, dynamic>? payload;

  final int attempts;
  final int nextAttemptAtMs;

  /// Clave de colapso: una operación nueva sobre la misma entidad y el mismo
  /// id reemplaza a la anterior. Sin esto, editar el cultivo cinco veces sin
  /// señal encolaría cinco subidas de las que sólo la última importa.
  String get collapseKey => '${entity.name}:$entityId';

  PendingSyncOp reschedule({required int attempts, required int nextAttemptAtMs}) {
    return PendingSyncOp(
      entity: entity,
      op: op,
      entityId: entityId,
      payload: payload,
      attempts: attempts,
      nextAttemptAtMs: nextAttemptAtMs,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'entity': entity.name,
    'op': op.name,
    'entityId': entityId,
    'payload': payload,
    'attempts': attempts,
    'nextAttemptAtMs': nextAttemptAtMs,
  };

  static PendingSyncOp? fromJson(Map<String, dynamic> json) {
    try {
      return PendingSyncOp(
        entity: SyncEntity.values.byName(json['entity'] as String),
        op: SyncOp.values.byName(json['op'] as String),
        entityId: json['entityId'] as String,
        payload: (json['payload'] as Map?)?.cast<String, dynamic>(),
        attempts: (json['attempts'] as num?)?.toInt() ?? 0,
        nextAttemptAtMs: (json['nextAttemptAtMs'] as num?)?.toInt() ?? 0,
      );
    } catch (_) {
      // Una entrada corrupta no puede envenenar toda la cola.
      return null;
    }
  }
}

/// Bandeja de salida persistente hacia Supabase.
///
/// Antes, cada escritura remota era un `unawaited(sync.upload(...))` con un
/// `catch` vacío: si el agricultor editaba su perfil o su cultivo sin señal,
/// ese cambio no llegaba nunca a la nube. Ni al recuperar señal, ni al abrir la
/// app de nuevo — nunca, salvo que lo volviera a capturar a mano sin saber que
/// hacía falta. Eso vaciaba de contenido la promesa de "funciona sin internet".
///
/// Ahora todo lo que hay que subir se apunta primero en el teléfono y se
/// reintenta con esperas crecientes hasta que entra. Nada se pierde en silencio.
///
/// El guardado local NO pasa por aquí: sigue siendo directo y síncrono. Esta
/// cola sólo gobierna el viaje a la nube.
class PendingSyncQueue {
  PendingSyncQueue({
    required Future<void> Function(PendingSyncOp op) handler,
    List<Duration>? backoff,
  }) : _handler = handler,
       _backoff = backoff ?? _defaultBackoff;

  static const String _prefix = 'biog_pending_sync_v1_';
  static const String _guestKey = 'biog_pending_sync_v1__guest';

  /// Espera antes de cada reintento. El último valor se repite indefinidamente:
  /// una operación nunca se descarta, sólo se reintenta cada vez más despacio.
  static const List<Duration> _defaultBackoff = <Duration>[
    Duration(seconds: 30),
    Duration(minutes: 2),
    Duration(minutes: 10),
    Duration(hours: 1),
    Duration(hours: 6),
  ];

  final Future<void> Function(PendingSyncOp op) _handler;
  final List<Duration> _backoff;

  String? _userId;
  bool _draining = false;

  String get _key {
    final String? id = _userId;
    if (id == null || id.isEmpty) return _guestKey;
    return '$_prefix$id';
  }

  /// Cambia de usuario. Cada cuenta tiene su propia bandeja.
  void bindUser(String? userId) {
    _userId = userId;
  }

  Future<List<PendingSyncOp>> load() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return <PendingSyncOp>[];
    try {
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((dynamic e) => PendingSyncOp.fromJson(e as Map<String, dynamic>))
          .whereType<PendingSyncOp>()
          .toList();
    } catch (_) {
      return <PendingSyncOp>[];
    }
  }

  Future<void> _write(List<PendingSyncOp> ops) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (ops.isEmpty) {
      await prefs.remove(_key);
      return;
    }
    await prefs.setString(
      _key,
      jsonEncode(ops.map((PendingSyncOp o) => o.toJson()).toList()),
    );
  }

  /// Apunta una operación y trata de vaciarla de inmediato.
  ///
  /// Si no hay señal, el intento falla sin ruido y la operación se queda
  /// esperando: es exactamente el comportamiento que se busca.
  Future<void> enqueue(PendingSyncOp op) async {
    final List<PendingSyncOp> ops = await load();
    ops.removeWhere((PendingSyncOp o) => o.collapseKey == op.collapseKey);
    ops.add(op);
    await _write(ops);
    unawaited(drain());
  }

  /// Vacía la bandeja. Seguro de llamar en cualquier momento: si ya hay un
  /// vaciado en curso, esta llamada no hace nada.
  Future<void> drain() async {
    if (_draining) return;
    _draining = true;
    try {
      final List<PendingSyncOp> ops = await load();
      if (ops.isEmpty) return;

      final int now = DateTime.now().millisecondsSinceEpoch;
      final List<PendingSyncOp> remaining = <PendingSyncOp>[];

      for (final PendingSyncOp op in ops) {
        if (op.nextAttemptAtMs > now) {
          // Todavía no le toca su reintento.
          remaining.add(op);
          continue;
        }
        try {
          await _handler(op);
          // Éxito: la operación sale de la bandeja.
        } catch (e) {
          final int attempts = op.attempts + 1;
          final Duration wait =
              _backoff[attempts - 1 < _backoff.length
                  ? attempts - 1
                  : _backoff.length - 1];
          remaining.add(
            op.reschedule(
              attempts: attempts,
              nextAttemptAtMs: now + wait.inMilliseconds,
            ),
          );
          debugPrint(
            '[sync] pendiente ${op.collapseKey} (${op.op.name}) '
            'intento $attempts, reintenta en ${wait.inMinutes} min: $e',
          );
        }
      }

      await _write(remaining);
    } finally {
      _draining = false;
    }
  }

  /// Descarta la bandeja de un usuario. Se usa al borrar la cuenta.
  Future<void> clear() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
