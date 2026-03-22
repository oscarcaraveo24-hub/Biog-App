// lib/services/biog/biog_repository.dart
import 'package:bio_g/models/biog_telemetry.dart';

abstract class BioGRepository {
  /// Lista de dispositivos disponibles (incluye demo/fake).
  Stream<List<BioGDevice>> watchDevices();

  /// Dispositivo activo en la app.
  Stream<BioGDevice?> watchActiveDevice();

  /// Telemetría en vivo del dispositivo activo.
  Stream<BioGTelemetry?> watchLiveTelemetry();

  /// Historial del dispositivo activo.
  /// window: cuánto tiempo hacia atrás quieres (ej. 24h, 7d)
  Stream<List<BioGTelemetry>> watchHistory({required Duration window});

  /// Alertas del dispositivo activo (o filtradas internamente).
  Stream<List<BioGAlert>> watchAlerts({int limit = 50});

  Future<void> setActiveDevice(String deviceId);

  /// Crea un dispositivo fake (para simular Add BioG).
  Future<BioGDevice> addFakeDevice({
    String? seedId,
    String? profileId,
    String? locationName,
    String? name,
  });

  Future<void> removeDevice(String deviceId);

  void dispose();
}
