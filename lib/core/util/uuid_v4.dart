import 'dart:math';

/// Generador mínimo de UUID v4 (RFC 4122), sin dependencias externas.
///
/// Por qué existe: la columna `devices.id` de Supabase es de tipo `uuid` y
/// rechaza cualquier otro formato. La app generaba ids de texto del estilo
/// `biog-a1b2c3d4-kx9f2`, el `upsert` fallaba con `22P02 invalid input syntax
/// for type uuid`, y ese error se perdía en un `catch` vacío. Resultado: el
/// dispositivo existía sólo dentro del teléfono, nunca llegaba a la nube y
/// jamás podía leer telemetría, porque `BioGDevice.telemetryDeviceId` devuelve
/// `null` para cualquier id que no sea un UUID.
///
/// Se implementa a mano en lugar de añadir el paquete `uuid` para no meter una
/// dependencia nueva por 15 líneas.
String generateUuidV4([Random? random]) {
  final Random rnd = random ?? _defaultRandom();
  final List<int> bytes = List<int>.generate(16, (_) => rnd.nextInt(256));

  // Versión 4: nibble alto del byte 6.
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  // Variante RFC 4122 (10xx): nibble alto del byte 8.
  bytes[8] = (bytes[8] & 0x3f) | 0x80;

  String hex(int start, int end) => bytes
      .sublist(start, end)
      .map((int b) => b.toRadixString(16).padLeft(2, '0'))
      .join();

  return '${hex(0, 4)}-${hex(4, 6)}-${hex(6, 8)}-${hex(8, 10)}-${hex(10, 16)}';
}

/// `Random.secure()` puede no estar disponible en algunas plataformas de
/// escritorio o entornos de prueba; en ese caso se degrada a `Random()`.
/// Para un id de dispositivo la aleatoriedad criptográfica no es un requisito
/// de seguridad, sólo de unicidad.
Random _defaultRandom() {
  try {
    return Random.secure();
  } catch (_) {
    return Random();
  }
}
