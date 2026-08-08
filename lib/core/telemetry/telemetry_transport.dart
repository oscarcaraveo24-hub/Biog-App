// lib/core/telemetry/telemetry_transport.dart
//
// Costura por donde entra el hardware.
//
// El motivo de que esto sea una interfaz y no una implementación BLE: el BLE
// exige un paquete nativo, permisos de Android e iOS y un firmware que todavía
// no existe. Todo eso pertenece a P2 del plan de cierre. Lo que sí puede —y
// debe— cerrarse antes es el *camino operativo*: validar, guardar, sincronizar
// y reintentar. Con esta interfaz, ese camino queda completo y probado hoy, y
// enchufar BLE mañana consiste en escribir una clase que la implemente, sin
// tocar el resto del sistema.
//
// Hay dos implementaciones aquí:
//  - [ManualTelemetryTransport], que acepta sobres empujados a mano. Es la que
//    usan las pruebas y la que permitirá una importación manual o un endpoint
//    HTTP sin esperar al firmware.
//  - [NullTelemetryTransport], que no entrega nada. Es el estado actual, y
//    existe para que la app declare explícitamente que no hay radio en vez de
//    fingir que la hay.

import 'dart:async';

import 'package:bio_g/core/telemetry/telemetry_contract.dart';

/// Estado del enlace con el hardware.
enum TelemetryLinkState {
  /// No hay transporte capaz de recibir del hardware.
  unavailable,

  /// Hay transporte pero no está conectado.
  disconnected,

  /// Buscando dispositivos.
  scanning,

  /// Conectado y recibiendo.
  connected,
}

extension TelemetryLinkStateX on TelemetryLinkState {
  String get labelEs {
    switch (this) {
      case TelemetryLinkState.unavailable:
        return 'Sin enlace disponible';
      case TelemetryLinkState.disconnected:
        return 'Desconectado';
      case TelemetryLinkState.scanning:
        return 'Buscando';
      case TelemetryLinkState.connected:
        return 'Conectado';
    }
  }

  bool get canReceive => this == TelemetryLinkState.connected;
}

/// Un dispositivo detectado por el transporte.
class DiscoveredDevice {
  const DiscoveredDevice({
    required this.transportAddress,
    required this.displayName,
    this.hardwareSerial,
    this.declaredDeviceId,
    this.rssi,
  });

  /// Dirección propia del transporte (MAC BLE, host, ruta de archivo…).
  final String transportAddress;

  final String displayName;

  /// Serie de fábrica anunciada, si el dispositivo la publica.
  final String? hardwareSerial;

  /// UUID que el dispositivo declara como su `telemetry.device_id`.
  ///
  /// Es el dato que hoy se descarta al escanear y se sustituye por un UUID
  /// aleatorio generado en el teléfono. Sin esto no hay emparejamiento real
  /// posible por muchas radios que se enciendan.
  final String? declaredDeviceId;

  final int? rssi;

  bool get hasUsableIdentity =>
      declaredDeviceId != null &&
      TelemetryDeviceIdentity.isValidDeviceId(declaredDeviceId!);
}

/// Contrato del transporte. Cualquier medio físico que implemente esto queda
/// conectado al camino operativo completo.
abstract class TelemetryTransport {
  /// Nombre legible del transporte, para diagnóstico.
  String get name;

  TelemetryLinkState get state;

  /// Cambios de estado del enlace.
  Stream<TelemetryLinkState> get stateChanges;

  /// Sobres recibidos del hardware.
  Stream<TelemetryEnvelope> get envelopes;

  /// Busca dispositivos disponibles.
  Future<List<DiscoveredDevice>> scan({
    Duration timeout = const Duration(seconds: 10),
  });

  /// Se conecta a un dispositivo concreto.
  Future<bool> connect(DiscoveredDevice device);

  Future<void> disconnect();

  /// Pide al dispositivo que reenvíe lo que tenga pendiente en su memoria.
  ///
  /// Es lo que permite que una medición tomada sin el teléfono cerca no se
  /// pierda: el aparato la guarda y la entrega al reconectar.
  Future<int> requestBacklog();

  Future<void> dispose();
}

/// Transporte manual: los sobres se empujan desde fuera.
///
/// Sirve para pruebas, para importación manual y como base de un transporte
/// HTTP. No simula datos: solo entrega lo que alguien le entregue.
class ManualTelemetryTransport implements TelemetryTransport {
  ManualTelemetryTransport({String? label}) : _label = label ?? 'manual';

  final String _label;

  final StreamController<TelemetryEnvelope> _envelopes =
      StreamController<TelemetryEnvelope>.broadcast();
  final StreamController<TelemetryLinkState> _states =
      StreamController<TelemetryLinkState>.broadcast();

  TelemetryLinkState _state = TelemetryLinkState.disconnected;
  final List<DiscoveredDevice> _devices = <DiscoveredDevice>[];

  @override
  String get name => _label;

  @override
  TelemetryLinkState get state => _state;

  @override
  Stream<TelemetryLinkState> get stateChanges => _states.stream;

  @override
  Stream<TelemetryEnvelope> get envelopes => _envelopes.stream;

  /// Registra dispositivos que [scan] debe devolver.
  void seedDevices(List<DiscoveredDevice> devices) {
    _devices
      ..clear()
      ..addAll(devices);
  }

  /// Entrega un sobre como si viniera del hardware.
  void push(TelemetryEnvelope envelope) {
    if (_envelopes.isClosed) return;
    _envelopes.add(envelope);
  }

  @override
  Future<List<DiscoveredDevice>> scan({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    _setState(TelemetryLinkState.scanning);
    final result = List<DiscoveredDevice>.unmodifiable(_devices);
    _setState(
      _state == TelemetryLinkState.scanning
          ? TelemetryLinkState.disconnected
          : _state,
    );
    return result;
  }

  @override
  Future<bool> connect(DiscoveredDevice device) async {
    _setState(TelemetryLinkState.connected);
    return true;
  }

  @override
  Future<void> disconnect() async {
    _setState(TelemetryLinkState.disconnected);
  }

  @override
  Future<int> requestBacklog() async => 0;

  @override
  Future<void> dispose() async {
    await _envelopes.close();
    await _states.close();
  }

  void _setState(TelemetryLinkState next) {
    if (_state == next) return;
    _state = next;
    if (!_states.isClosed) _states.add(next);
  }
}

/// Transporte nulo: el estado real de hoy.
///
/// Declara honestamente que no hay forma de recibir del hardware, en vez de
/// dejar la app aparentando una conexión que no existe. Cuando llegue el BLE,
/// se sustituye esta instancia por la real y nada más cambia.
class NullTelemetryTransport implements TelemetryTransport {
  const NullTelemetryTransport();

  @override
  String get name => 'ninguno';

  @override
  TelemetryLinkState get state => TelemetryLinkState.unavailable;

  // `Stream.empty()` sin `const` a propósito: su constructor const depende de
  // la versión del SDK y aquí no aporta nada. La clase sigue siendo const.
  @override
  // ignore: prefer_const_constructors
  Stream<TelemetryLinkState> get stateChanges =>
      Stream<TelemetryLinkState>.empty();

  @override
  // ignore: prefer_const_constructors
  Stream<TelemetryEnvelope> get envelopes => Stream<TelemetryEnvelope>.empty();

  @override
  Future<List<DiscoveredDevice>> scan({
    Duration timeout = const Duration(seconds: 10),
  }) async => const <DiscoveredDevice>[];

  @override
  Future<bool> connect(DiscoveredDevice device) async => false;

  @override
  Future<void> disconnect() async {}

  @override
  Future<int> requestBacklog() async => 0;

  @override
  Future<void> dispose() async {}
}
