// lib/services/biog/telemetry/ble/biog_ble_config.dart
//
// Todo lo que el firmware y la app tienen que acordar, en un solo lugar.
// Si el ESP32 cambia un UUID, se cambia aqui y en ningun otro sitio.

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BioGBleConfig {
  const BioGBleConfig._();

  /// Servicio propio de BIO-G. No es un UUID de ejemplo de Nordic a proposito:
  /// en el taller va a haber varios aparatos anunciando a la vez.
  static final Guid serviceUuid = Guid(
    '7b8a0001-8c6f-4f2d-a8b5-3b35a12c0001',
  );

  /// Telemetria: READ + NOTIFY. JSON compacto.
  static final Guid telemetryCharacteristicUuid = Guid(
    '7b8a0002-8c6f-4f2d-a8b5-3b35a12c0002',
  );

  /// Identidad: READ. Es de donde sale el `deviceId` real.
  static final Guid identityCharacteristicUuid = Guid(
    '7b8a0003-8c6f-4f2d-a8b5-3b35a12c0003',
  );

  /// Prefijo del nombre anunciado (`BIO-G-DEV-001` en el equipo de desarrollo).
  ///
  /// Se filtra por servicio Y por prefijo de nombre: el filtro por servicio es
  /// el fiable, el de nombre atrapa firmware viejo que todavia no anuncia el
  /// UUID en el paquete de advertising.
  static const String advertisedNamePrefix = 'BIO-G';

  /// MTU objetivo en Android.
  ///
  /// Con el MTU por defecto (23) una notificacion carga 20 bytes utiles y el
  /// JSON de telemetria NO cabe: las notificaciones no se fragmentan solas
  /// como si lo hace una lectura larga. Por eso el MTU se sube ANTES de
  /// suscribirse a Notify, nunca despues.
  ///
  /// 247 y no 512: es lo que negocia de forma fiable un ESP32 y deja 244 bytes
  /// utiles por notificacion, de sobra para el sobre compacto.
  static const int desiredMtu = 247;

  /// Minimo de bytes utiles por notificacion para dar por buena la telemetria.
  ///
  /// El sobre compacto de hoy ronda los 70 bytes; el margen es para cuando el
  /// firmware anada bateria, codigo de error o mas decimales. Con el MTU por
  /// defecto (23) solo hay 20 bytes utiles y no cabe ni el sobre de hoy.
  static const int minUsableNotificationBytes = 100;

  static const Duration defaultScanTimeout = Duration(seconds: 10);
  static const Duration connectTimeout = Duration(seconds: 20);

  /// Licencia declarada de flutter_blue_plus 2.x.
  ///
  /// ATENCION, DECISION PENDIENTE DE OSCAR: la version 2.x obliga a declarar
  /// el tipo de licencia en cada `connect()`. Queda en `nonprofit` porque hoy
  /// esto es una prueba de hardware en desarrollo. **BIO-G es un producto
  /// comercial**, y antes de distribuir la app hay que cambiar esto a
  /// `License.commercial` y contratar la licencia correspondiente con el autor
  /// del paquete. No es una decision que yo pueda tomar por ti.
  static const License license = License.nonprofit;
}
