// lib/core/agro/water/soil_texture_source.dart
//
// De dónde salió el tipo de suelo. Se guarda **aparte del valor**, a propósito.
//
// ─────────────────────────────────────────────────────────────────────────────
// POR QUÉ LA FUENTE ES UN CAMPO Y NO UN DETALLE
// ─────────────────────────────────────────────────────────────────────────────
//
// No es lo mismo que el productor haya declarado su tierra a que la hayamos
// deducido del modelo del equipo. Esa distinción hace falta para dos cosas
// distintas y ninguna es cosmética:
//
//   · el historial auditable, que tiene que poder responder «¿con qué
//     información dijiste esto aquel martes?»;
//   · medir adopción — cuántos productores contestan de verdad la pregunta.
//
// Y hay una tercera, la que más importa para el consejo: solo `declared` y
// `guidedEstimate` son afirmaciones del productor. `unknown` es una respuesta
// de primera clase —«lo declaró y dijo que no sabe»— y NO es lo mismo que
// `null`, que significa «contexto anterior a esta versión».

import 'package:flutter/foundation.dart';

@immutable
class _SoilTextureSourceIds {
  const _SoilTextureSourceIds._();

  static const String declared = 'declared';
  static const String guidedEstimate = 'guided_estimate';
  static const String derivedFromDevice = 'derived_from_device';
  static const String derivedFromScale = 'derived_from_scale';
  static const String unknown = 'unknown';
}

enum SoilTextureSource {
  /// El productor eligió la textura a mano en el carrusel.
  declared(_SoilTextureSourceIds.declared),

  /// Salió de la guía de tres preguntas de 20 segundos. Es una aproximación de
  /// campo, no una clasificación de laboratorio, y así se etiqueta.
  guidedEstimate(_SoilTextureSourceIds.guidedEstimate),

  /// La asignó el modelo del equipo (un BIO-G Maceta vive en sustrato por
  /// construcción). El hardware manda: no es una opinión que pueda cambiar.
  derivedFromDevice(_SoilTextureSourceIds.derivedFromDevice),

  /// La asignó la escala de cultivo declarada, como respaldo mientras no hay
  /// equipo emparejado.
  derivedFromScale(_SoilTextureSourceIds.derivedFromScale),

  /// El productor marcó «No estoy seguro». Es una respuesta, no un hueco.
  unknown(_SoilTextureSourceIds.unknown);

  const SoilTextureSource(this.id);

  final String id;

  /// True cuando el dato es una afirmación del productor y no una deducción
  /// nuestra. Es lo que distingue *tiene suelo franco* de *no sabe qué tiene*.
  bool get isDeclaredByFarmer =>
      this == SoilTextureSource.declared ||
      this == SoilTextureSource.guidedEstimate ||
      this == SoilTextureSource.unknown;

  /// True cuando el medio lo decidió el aparato o la escala, no una pregunta.
  bool get isDerived =>
      this == SoilTextureSource.derivedFromDevice ||
      this == SoilTextureSource.derivedFromScale;

  String get labelEs => switch (this) {
    SoilTextureSource.declared => 'Declarado por ti',
    SoilTextureSource.guidedEstimate => 'Estimación por tacto',
    SoilTextureSource.derivedFromDevice => 'Según tu equipo BIO-G',
    SoilTextureSource.derivedFromScale => 'Según tu tipo de cultivo',
    SoilTextureSource.unknown => 'Sin definir',
  };

  /// Devuelve `null` ante nulo o cadena vacía, y **no** cae a [unknown]: un
  /// contexto anterior a esta versión no declaró nada, y confundir «no había
  /// campo» con «el productor dijo que no sabe» destruiría la métrica de
  /// adopción y ensuciaría el historial.
  static SoilTextureSource? fromId(String? raw) {
    final v = raw?.trim().toLowerCase();
    if (v == null || v.isEmpty) return null;
    for (final s in SoilTextureSource.values) {
      if (s.id == v || s.name.toLowerCase() == v) return s;
    }
    return switch (v) {
      'manual' || 'user' || 'declarado' => SoilTextureSource.declared,
      'guided' || 'guia' || 'guía' || 'estimacion' || 'estimación' =>
        SoilTextureSource.guidedEstimate,
      'device' || 'hardware' || 'equipo' => SoilTextureSource.derivedFromDevice,
      'scale' || 'escala' => SoilTextureSource.derivedFromScale,
      'desconocido' || 'no_se' => SoilTextureSource.unknown,
      _ => null,
    };
  }
}
