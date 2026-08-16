// lib/core/hardware/biog_serial.dart
//
// El formato del número de serie y del código QR de un equipo BIO-G.
//
// ─────────────────────────────────────────────────────────────────────────────
// POR QUÉ ESTE ARCHIVO EXISTE, Y POR QUÉ ANTES QUE EL RESTO
// ─────────────────────────────────────────────────────────────────────────────
//
// Este formato lleva restricción de unicidad en la base de datos y va impreso
// en una etiqueta física. **No se puede rehacer sobre equipos ya rotulados.**
// Por eso queda fijado aquí, en código, antes de imprimir la primera etiqueta,
// y no como una convención verbal entre la app y quien fabrica.
//
// ─────────────────────────────────────────────────────────────────────────────
// EL MODELO VA DENTRO DE LA SERIE
// ─────────────────────────────────────────────────────────────────────────────
//
// Es la decisión de diseño que sostiene todo lo demás: el medio de cultivo es
// una consecuencia del aparato, no una opinión del usuario. Si el modelo viaja
// dentro de la serie, un equipo escaneado ya sabe si vive en maceta, en huerto
// o en campo antes de que nadie conteste nada, y el dato sobrevive a un
// reinicio, a un cambio de teléfono y a una reinstalación.
//
// ─────────────────────────────────────────────────────────────────────────────
// FORMATO
// ─────────────────────────────────────────────────────────────────────────────
//
//     BIOG-M-2632-000001-2
//     ─┬── ┬ ──┬─ ──┬─── ┬
//      │   │   │    │    └── dígito de control (base32 Crockford)
//      │   │   │    └─────── secuencia de 6, base32 Crockford
//      │   │   └──────────── año (2 díg.) + semana ISO (2 díg.) de fabricación
//      │   └──────────────── modelo: C campo · H huerto · M maceta
//      └──────────────────── prefijo fijo
//
// **Base32 de Crockford**, no hexadecimal ni base64: quita I, L, O y U del
// alfabeto. La I contra el 1 y la O contra el 0 son el error de transcripción
// clásico cuando alguien lee la etiqueta por teléfono, y la U se quita para no
// formar palabras desafortunadas por accidente. Al decodificar se aceptan
// igualmente: `I`/`L` → 1, `O` → 0. Eso hace la serie **tolerante al dictado**
// sin ser ambigua al imprimirla.
//
// El dígito de control es una suma módulo 32 de todos los caracteres útiles.
// No protege contra un adversario —no es una firma— sino contra el dedo: un
// carácter mal tecleado se detecta antes de salir a la red.
//
// ─────────────────────────────────────────────────────────────────────────────
// EL CÓDIGO QR
// ─────────────────────────────────────────────────────────────────────────────
//
// El QR lleva una URL, no la serie a secas, para que una cámara genérica haga
// algo útil en vez de mostrar una cadena sin sentido:
//
//     https://bio-g.mx/d/BIOG-M-2632-000001-2?k=<uuid del equipo>
//
// El parámetro `k` es el identificador de telemetría (UUID). Es opcional: si el
// firmware todavía no lo tiene grabado, la app crea uno y lo adopta. La app
// acepta además la serie pelada y un JSON legacy, porque el primer lote de
// prototipos se rotuló a mano.

import 'package:flutter/foundation.dart';

import 'package:bio_g/core/agro/cultivation_scale.dart';

/// Alfabeto base32 de Crockford, sin I, L, O ni U.
const String _kAlphabet = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';

const String _kPrefix = 'BIOG';

/// Host canónico del QR. Vive aquí para que cambiarlo sea un solo sitio.
const String kBioGQrHost = 'bio-g.mx';

String _modelLetter(BioGDeviceModel model) => switch (model) {
  BioGDeviceModel.campo => 'C',
  BioGDeviceModel.huerto => 'H',
  BioGDeviceModel.maceta => 'M',
};

BioGDeviceModel? _modelFromLetter(String letter) => switch (letter) {
  'C' => BioGDeviceModel.campo,
  'H' => BioGDeviceModel.huerto,
  'M' => BioGDeviceModel.maceta,
  _ => null,
};

/// Normaliza un bloque de datos para lectura tolerante al dictado.
///
/// **Solo se aplica a los bloques de datos, nunca al prefijo**: `BIOG` lleva
/// una I y una O, y normalizarlo lo convertiría en `B10G`. Es exactamente la
/// clase de detalle que solo se ve cuando alguien lee una serie por teléfono.
String _normalizeBlock(String raw) {
  final b = StringBuffer();
  for (final c in raw.toUpperCase().replaceAll(' ', '').split('')) {
    b.write(switch (c) {
      'I' || 'L' => '1',
      'O' => '0',
      _ => c,
    });
  }
  return b.toString();
}

int _checksumValue(String modelLetter, String dateBlock, String sequence) {
  var sum = 0;
  for (final c in '$modelLetter$dateBlock$sequence'.split('')) {
    final idx = _kAlphabet.indexOf(c);
    // Un carácter fuera del alfabeto suma 0 a propósito: no puede lanzar aquí,
    // porque este mismo cálculo se usa para VALIDAR entrada del usuario.
    sum += idx < 0 ? 0 : idx;
  }
  return sum % 32;
}

/// Una serie BIO-G ya interpretada.
@immutable
class BioGSerial {
  const BioGSerial({
    required this.raw,
    required this.model,
    required this.dateBlock,
    required this.sequence,
    required this.checksum,
  });

  /// La serie tal cual, ya normalizada y en mayúsculas.
  final String raw;

  final BioGDeviceModel model;

  /// `YYWW`: año de dos dígitos y semana ISO de fabricación.
  final String dateBlock;

  final String sequence;
  final String checksum;

  /// Id del modelo tal como lo espera `BioGDevice.deviceModelId`.
  String get deviceModelId => model.name;

  @override
  String toString() => raw;

  /// Construye una serie válida. Pensado para la herramienta de rotulado y
  /// para pruebas: la app normalmente **lee** series, no las genera.
  static BioGSerial build({
    required BioGDeviceModel model,
    required int year,
    required int isoWeek,
    required int sequenceNumber,
  }) {
    final letter = _modelLetter(model);
    final yy = (year % 100).toString().padLeft(2, '0');
    final ww = isoWeek.clamp(1, 53).toString().padLeft(2, '0');
    final dateBlock = '$yy$ww';

    var n = sequenceNumber;
    final seq = StringBuffer();
    for (var i = 0; i < 6; i++) {
      seq.write(_kAlphabet[n % 32]);
      n = n ~/ 32;
    }
    final sequence = String.fromCharCodes(seq.toString().codeUnits.reversed);

    final chk = _kAlphabet[_checksumValue(letter, dateBlock, sequence)];
    return BioGSerial(
      raw: '$_kPrefix-$letter-$dateBlock-$sequence-$chk',
      model: model,
      dateBlock: dateBlock,
      sequence: sequence,
      checksum: chk,
    );
  }

  /// Interpreta una serie. Devuelve `null` si no cumple el formato o si el
  /// dígito de control no cuadra.
  ///
  /// Rechazar por checksum es deliberado: una serie mal tecleada que llegue a
  /// la base de datos ocupa un identificador único que después no se puede
  /// liberar sobre un equipo ya rotulado.
  static BioGSerial? tryParse(String? raw) {
    if (raw == null) return null;
    final parts = raw.trim().toUpperCase().replaceAll(' ', '').split('-');
    if (parts.length != 5) return null;
    if (parts[0] != _kPrefix) return null;

    // El prefijo queda fuera de la normalización tolerante, a propósito.
    final modelLetter = parts[1].toUpperCase();
    final model = _modelFromLetter(modelLetter);
    if (model == null) return null;

    final dateBlock = _normalizeBlock(parts[2]);
    if (dateBlock.length != 4 || int.tryParse(dateBlock) == null) return null;

    final sequence = _normalizeBlock(parts[3]);
    if (sequence.length != 6) return null;
    for (final c in sequence.split('')) {
      if (!_kAlphabet.contains(c)) return null;
    }

    final checksum = _normalizeBlock(parts[4]);
    if (checksum.length != 1) return null;
    if (_kAlphabet[_checksumValue(modelLetter, dateBlock, sequence)] !=
        checksum) {
      return null;
    }

    return BioGSerial(
      raw: '$_kPrefix-$modelLetter-$dateBlock-$sequence-$checksum',
      model: model,
      dateBlock: dateBlock,
      sequence: sequence,
      checksum: checksum,
    );
  }

  static bool isValid(String? raw) => tryParse(raw) != null;
}

/// Lo que la app obtiene al leer una etiqueta.
@immutable
class BioGQrPayload {
  const BioGQrPayload({
    required this.raw,
    this.serial,
    this.telemetryDeviceId,
    this.displayName,
  });

  /// El contenido crudo del QR, para diagnóstico.
  final String raw;

  final BioGSerial? serial;

  /// UUID de telemetría grabado de fábrica, si la etiqueta lo trae.
  final String? telemetryDeviceId;

  /// Nombre sugerido para el equipo. Si no viene, se deriva del modelo.
  final String? displayName;

  BioGDeviceModel? get model => serial?.model;

  String? get deviceModelId => serial?.deviceModelId;

  bool get isValid => serial != null;

  /// Nombre por defecto: legible, con el modelo dentro y sin depender del
  /// idioma del firmware.
  String get resolvedName {
    final n = displayName?.trim();
    if (n != null && n.isNotEmpty) return n;
    final m = model;
    if (m == null) return 'Bio-G';
    final suffix = serial?.sequence ?? '';
    return switch (m) {
      BioGDeviceModel.campo => 'Bio-G Campo $suffix'.trim(),
      BioGDeviceModel.huerto => 'Bio-G Huerto $suffix'.trim(),
      BioGDeviceModel.maceta => 'Bio-G Maceta $suffix'.trim(),
    };
  }

  /// El mapa que viaja por `Navigator.pop` entre las pantallas de escaneo y
  /// quien crea el equipo. Las claves son las que ya espera `AddBioGScreen`.
  Map<String, dynamic> toScanResult({required String source}) =>
      <String, dynamic>{
        'id': telemetryDeviceId ?? serial?.raw ?? raw,
        'name': resolvedName,
        'model': deviceModelId,
        'serial': serial?.raw,
        'source': source,
      };

  /// Construye la URL que va impresa en la etiqueta.
  static String encodeUrl({
    required BioGSerial serial,
    String? telemetryDeviceId,
  }) {
    final q = telemetryDeviceId == null || telemetryDeviceId.trim().isEmpty
        ? ''
        : '?k=${Uri.encodeComponent(telemetryDeviceId.trim())}';
    return 'https://$kBioGQrHost/d/${serial.raw}$q';
  }

  /// Lee cualquiera de las tres formas admitidas: URL, serie pelada o JSON
  /// legacy del primer lote de prototipos.
  static BioGQrPayload parse(String raw) {
    final trimmed = raw.trim();

    // 1 · URL canónica.
    final uri = Uri.tryParse(trimmed);
    if (uri != null && uri.hasScheme && uri.pathSegments.isNotEmpty) {
      final last = uri.pathSegments.last;
      final serial = BioGSerial.tryParse(last);
      if (serial != null) {
        return BioGQrPayload(
          raw: trimmed,
          serial: serial,
          telemetryDeviceId: _nonEmpty(uri.queryParameters['k']),
          displayName: _nonEmpty(uri.queryParameters['n']),
        );
      }
    }

    // 2 · Serie pelada, tecleada o escaneada de una etiqueta antigua.
    final bare = BioGSerial.tryParse(trimmed);
    if (bare != null) return BioGQrPayload(raw: trimmed, serial: bare);

    // 3 · JSON legacy. No se intenta decodificar con `jsonDecode` para no
    // arrastrar la dependencia ni tragar basura: se buscan las dos claves.
    if (trimmed.startsWith('{')) {
      final serialMatch = RegExp(
        r'"(?:serial|sn)"\s*:\s*"([^"]+)"',
      ).firstMatch(trimmed);
      final idMatch = RegExp(
        r'"(?:id|uuid|deviceId)"\s*:\s*"([^"]+)"',
      ).firstMatch(trimmed);
      final nameMatch = RegExp(r'"name"\s*:\s*"([^"]+)"').firstMatch(trimmed);
      return BioGQrPayload(
        raw: trimmed,
        serial: BioGSerial.tryParse(serialMatch?.group(1)),
        telemetryDeviceId: _nonEmpty(idMatch?.group(1)),
        displayName: _nonEmpty(nameMatch?.group(1)),
      );
    }

    return BioGQrPayload(raw: trimmed);
  }

  static String? _nonEmpty(String? v) {
    final t = v?.trim();
    return (t == null || t.isEmpty) ? null : t;
  }
}
