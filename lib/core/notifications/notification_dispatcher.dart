// lib/core/notifications/notification_dispatcher.dart
//
// Entrega de avisos, con bandeja persistente.
//
// El problema real: push y notificaciones locales necesitan paquetes nativos
// (`firebase_messaging`, `flutter_local_notifications`) que hoy no están en
// `pubspec.yaml`, más permisos de Android e iOS. Eso pertenece a P2 del plan
// de cierre y no puede cerrarse sin tocar el proyecto nativo.
//
// Lo que sí puede cerrarse hoy, y es la mitad que de verdad importa: decidir
// QUÉ merece avisarse, respetar lo que el usuario configuró, deduplicar, y
// **no perder el aviso** aunque no haya forma de entregarlo todavía.
//
// De eso se encarga la bandeja: cada aviso que supera las preferencias se
// guarda con su estado. Hoy lo consume la propia app cuando el usuario la
// abre. Cuando exista push, su adaptador drena esta misma bandeja y el
// comportamiento configurado se respeta sin reescribir nada de aquí.
//
// Esto es lo que resuelve el objetivo declarado —y hasta ahora incumplido— del
// almacén de eventos: que el aviso de las 3 a.m. exista aunque nadie tuviera
// la app abierta.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bio_g/core/agro/agronomic_event.dart';
import 'package:bio_g/core/notifications/notification_preferences.dart';

enum NotificationDeliveryState {
  /// Aceptado por las preferencias, esperando ser mostrado.
  pending,

  /// Mostrado dentro de la app.
  deliveredInApp,

  /// Entregado por push o notificación local.
  deliveredPush,

  /// El usuario lo vio.
  read,

  /// Descartado por el usuario.
  dismissed,
}

@immutable
class BiogNotification {
  const BiogNotification({
    required this.id,
    required this.category,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.severity,
    this.deviceId,
    this.state = NotificationDeliveryState.pending,
    this.deliveredAt,
    this.readAt,
    this.payload = const <String, Object?>{},
  });

  /// Llave estable del aviso. Se deriva del evento para que recalcularlo no
  /// genere un aviso nuevo.
  final String id;

  final NotificationCategory category;
  final String title;
  final String body;
  final DateTime createdAt;
  final AgronomicEventSeverity severity;
  final String? deviceId;
  final NotificationDeliveryState state;
  final DateTime? deliveredAt;
  final DateTime? readAt;
  final Map<String, Object?> payload;

  bool get isPending => state == NotificationDeliveryState.pending;
  bool get isUnread =>
      state != NotificationDeliveryState.read &&
      state != NotificationDeliveryState.dismissed;

  BiogNotification copyWith({
    NotificationDeliveryState? state,
    DateTime? deliveredAt,
    DateTime? readAt,
  }) {
    return BiogNotification(
      id: id,
      category: category,
      title: title,
      body: body,
      createdAt: createdAt,
      severity: severity,
      deviceId: deviceId,
      state: state ?? this.state,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      readAt: readAt ?? this.readAt,
      payload: payload,
    );
  }

  factory BiogNotification.fromEvent(AgronomicEvent event) {
    return BiogNotification(
      id: '${event.deviceId ?? '-'}|${event.dedupKey}',
      category: NotificationCategoryX.fromEventType(event.type),
      title: event.title,
      body: event.message,
      createdAt: event.timestamp,
      severity: event.severity,
      deviceId: event.deviceId,
      payload: <String, Object?>{
        'eventType': event.type.name,
        'metricKey': event.metricKey,
        'stageKey': event.stageKey,
      },
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'category': category.name,
    'title': title,
    'body': body,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'severity': severity.name,
    'deviceId': deviceId,
    'state': state.name,
    'deliveredAt': deliveredAt?.toUtc().toIso8601String(),
    'readAt': readAt?.toUtc().toIso8601String(),
    'payload': payload,
  };

  static BiogNotification? fromJson(Map<String, dynamic> json) {
    try {
      return BiogNotification(
        id: json['id'] as String,
        category: NotificationCategory.values.firstWhere(
          (c) => c.name == json['category'],
          orElse: () => NotificationCategory.cropCycle,
        ),
        title: json['title'] as String,
        body: json['body'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        severity: AgronomicEventSeverity.values.firstWhere(
          (s) => s.name == json['severity'],
          orElse: () => AgronomicEventSeverity.info,
        ),
        deviceId: json['deviceId'] as String?,
        state: NotificationDeliveryState.values.firstWhere(
          (s) => s.name == json['state'],
          orElse: () => NotificationDeliveryState.pending,
        ),
        deliveredAt: json['deliveredAt'] == null
            ? null
            : DateTime.tryParse(json['deliveredAt'] as String),
        readAt: json['readAt'] == null
            ? null
            : DateTime.tryParse(json['readAt'] as String),
        payload:
            (json['payload'] as Map?)?.cast<String, Object?>() ??
            const <String, Object?>{},
      );
    } catch (_) {
      return null;
    }
  }
}

/// Capa física de entrega. Implementar esto es lo único que hará falta para
/// enchufar push o notificaciones locales.
abstract class NotificationChannel {
  String get name;

  /// True si el canal puede entregar ahora mismo.
  Future<bool> get isAvailable;

  /// Intenta entregar. Devuelve `true` solo si lo consiguió.
  Future<bool> deliver(BiogNotification notification);
}

/// Canal dentro de la app: no requiere ningún paquete nativo.
///
/// No "entrega" en el sentido de sonar el teléfono; marca el aviso como
/// disponible para que la pantalla de Notificaciones lo muestre. Es lo máximo
/// honesto que se puede hacer sin plugin, y funciona hoy.
class InAppNotificationChannel implements NotificationChannel {
  const InAppNotificationChannel();

  @override
  String get name => 'in_app';

  @override
  Future<bool> get isAvailable async => true;

  @override
  Future<bool> deliver(BiogNotification notification) async => true;
}

/// Bandeja persistente + política de entrega.
class NotificationDispatcher extends ChangeNotifier {
  NotificationDispatcher({
    NotificationPreferencesStore? preferencesStore,
    List<NotificationChannel>? channels,
    DateTime Function()? clock,
    int maxStored = 200,
  }) : _preferencesStore = preferencesStore ?? NotificationPreferencesStore(),
       _channels = channels ?? const <NotificationChannel>[
         InAppNotificationChannel(),
       ],
       _now = clock ?? DateTime.now,
       _maxStored = maxStored;

  static const String _outboxKey = 'biog_notification_outbox_v1';

  final NotificationPreferencesStore _preferencesStore;
  final List<NotificationChannel> _channels;
  final DateTime Function() _now;
  final int _maxStored;

  final List<BiogNotification> _outbox = <BiogNotification>[];
  NotificationPreferences _preferences = NotificationPreferences.defaults;
  bool _hydrated = false;

  NotificationPreferences get preferences => _preferences;

  /// Avisos vivos, del más reciente al más antiguo.
  List<BiogNotification> get notifications =>
      List<BiogNotification>.unmodifiable(_outbox);

  List<BiogNotification> get unread =>
      _outbox.where((n) => n.isUnread).toList(growable: false);

  int get unreadCount => unread.length;

  /// Lee la bandeja de disco. Idempotente y **esperable**.
  ///
  /// Antes bastaba con `if (_hydrated) return;` y una bandera puesta antes del
  /// primer `await`. Eso hacía que el segundo llamante volviera de inmediato
  /// con la bandeja todavía vacía: era idempotente en efecto, pero no servía
  /// como barrera de sincronización. Quien quisiera esperar a tener los datos
  /// —la pantalla de la campana, por ejemplo— seguía adelante sin ellos.
  ///
  /// Cacheando el futuro, todos los llamantes esperan la misma carga.
  Future<void> hydrate() => _hydration ??= _hydrateOnce();
  Future<void>? _hydration;

  Future<void> _hydrateOnce() async {
    if (_hydrated) return;
    _hydrated = true;

    _preferences = await _preferencesStore.load();

    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_outboxKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          for (final item in decoded) {
            if (item is! Map) continue;
            final n = BiogNotification.fromJson(item.cast<String, dynamic>());
            if (n != null) _outbox.add(n);
          }
        }
      }
    } catch (_) {
      _outbox.clear();
    }

    notifyListeners();
  }

  Future<void> updatePreferences(NotificationPreferences next) async {
    _preferences = next;
    await _preferencesStore.save(next);
    notifyListeners();
  }

  /// Procesa eventos agronómicos y guarda los que merecen aviso.
  ///
  /// Devuelve cuántos avisos nuevos se aceptaron. Deduplicar por `id` es lo
  /// que impide que recalcular la misma lectura genere el mismo aviso una y
  /// otra vez.
  Future<int> ingestEvents(List<AgronomicEvent> events) async {
    await hydrate();
    if (events.isEmpty) return 0;

    final now = _now();
    final existing = _outbox.map((n) => n.id).toSet();
    var accepted = 0;

    for (final event in events) {
      if (!_preferences.shouldDeliver(event, localTime: now)) continue;

      final notification = BiogNotification.fromEvent(event);
      if (existing.contains(notification.id)) continue;

      _outbox.insert(0, notification);
      existing.add(notification.id);
      accepted++;
    }

    if (accepted == 0) return 0;

    _trim();
    await _persist();
    notifyListeners();

    unawaited(deliverPending());
    return accepted;
  }

  /// Intenta entregar lo pendiente por los canales disponibles.
  Future<int> deliverPending() async {
    await hydrate();

    var delivered = 0;
    for (var i = 0; i < _outbox.length; i++) {
      final n = _outbox[i];
      if (!n.isPending) continue;

      for (final channel in _channels) {
        if (!await channel.isAvailable) continue;
        final ok = await channel.deliver(n);
        if (!ok) continue;

        _outbox[i] = n.copyWith(
          state: channel.name == 'in_app'
              ? NotificationDeliveryState.deliveredInApp
              : NotificationDeliveryState.deliveredPush,
          deliveredAt: _now(),
        );
        delivered++;
        break;
      }
    }

    if (delivered > 0) {
      await _persist();
      notifyListeners();
    }
    return delivered;
  }

  Future<void> markRead(String id) async {
    final i = _outbox.indexWhere((n) => n.id == id);
    if (i < 0) return;
    _outbox[i] = _outbox[i].copyWith(
      state: NotificationDeliveryState.read,
      readAt: _now(),
    );
    await _persist();
    notifyListeners();
  }

  Future<void> markAllRead() async {
    // Salvaguarda contra el borrado silencioso de la bandeja.
    //
    // `hydrate()` marca `_hydrated` antes de su primer `await`, así que durante
    // el arranque en frío hay una ventana en la que la bandeja de disco aún no
    // se ha leído y `_outbox` está vacía. Si en esa ventana alguien llamaba a
    // este método —abrir la campana en el primer segundo—, el bucle no hacía
    // nada pero `_persist()` escribía `[]` encima del archivo, y la hidratación
    // en vuelo ya no encontraba nada que leer. Se perdía la bandeja entera, en
    // silencio y para siempre.
    //
    // Sin nada que marcar no hay nada que persistir: es la corrección correcta
    // aunque nadie llame en esa ventana.
    if (!_outbox.any((BiogNotification n) => n.isUnread)) return;

    final now = _now();
    for (var i = 0; i < _outbox.length; i++) {
      if (!_outbox[i].isUnread) continue;
      _outbox[i] = _outbox[i].copyWith(
        state: NotificationDeliveryState.read,
        readAt: now,
      );
    }
    await _persist();
    notifyListeners();
  }

  Future<void> dismiss(String id) async {
    final i = _outbox.indexWhere((n) => n.id == id);
    if (i < 0) return;
    _outbox[i] = _outbox[i].copyWith(
      state: NotificationDeliveryState.dismissed,
    );
    await _persist();
    notifyListeners();
  }

  /// Olvida todo. Se llama al cerrar sesión y al borrar la cuenta: los avisos
  /// de un usuario no pueden quedar visibles para el siguiente.
  Future<void> clear() async {
    _outbox.clear();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_outboxKey);
    } catch (_) {
      // Ídem.
    }
    notifyListeners();
  }

  void _trim() {
    if (_outbox.length <= _maxStored) return;
    _outbox.removeRange(_maxStored, _outbox.length);
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _outboxKey,
        jsonEncode(_outbox.map((n) => n.toJson()).toList(growable: false)),
      );
    } catch (_) {
      // La bandeja en memoria sigue funcionando aunque no se pueda persistir.
    }
  }
}
