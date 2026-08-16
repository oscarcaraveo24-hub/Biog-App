// lib/core/agro/water/soil_profile_resolver.dart
//
// Quién decide en qué medio vive la planta. Una sola jerarquía, un solo sitio.
//
// ─────────────────────────────────────────────────────────────────────────────
// EL PRINCIPIO RECTOR: EL HARDWARE MANDA
// ─────────────────────────────────────────────────────────────────────────────
//
// BIO-G Mood, Huerto y Campo son productos distintos, identificados por el
// propio equipo. El medio de cultivo **no es una opinión del usuario**: es una
// consecuencia del aparato que compró. Un BIO-G Mood vive en sustrato de maceta
// por construcción.
//
// Frente a eso, la escala de cultivo es una clasificación agronómica que el
// usuario declara, que puede cambiar y que —verificado— otro código nulificaba
// para ornamentales. Un plan que hiciera depender el sustrato de
// `cultivationScaleId == 'pot'` invertiría el consejo exactamente en el grupo
// que pretendía blindar: cactus, suculentas, tulipán y rosal son ornamentales,
// el campo les llegaba nulo, el resolver no detectaba maceta, y les aplicaba
// constantes de suelo mineral.
//
// (Esa nulificación se retiró; ver `biog_store._normalizeContextForStorage`.
// La jerarquía de aquí abajo no depende de ello igualmente, que es el punto.)
//
// ─────────────────────────────────────────────────────────────────────────────
// LA JERARQUÍA
// ─────────────────────────────────────────────────────────────────────────────
//
//   1. deviceModelId == maceta / Mood   -> perfil de SUSTRATO
//   2. deviceModelId == huerto / campo  -> suelo MINERAL, usa soilTextureId
//   3. sin equipo emparejado todavía:
//          cultivationScaleId == 'pot'  -> perfil de SUSTRATO   (respaldo)
//          en otro caso                 -> suelo MINERAL
//   4. soilTextureId ausente o unknown  -> Media, marcada como respaldo,
//                                          menos 0,15 de confianza
//
// Y dentro del perfil de sustrato, la variante drenante o general se deriva del
// grupo hídrico del cultivo, **sin preguntar**: cactus, nopal, agave y
// suculentas ya están clasificados como xerófitos en la política hídrica.

import 'package:flutter/foundation.dart';

import 'package:bio_g/core/agro/cultivation_scale.dart';
import 'package:bio_g/core/agro/water/crop_water_policy.dart';
import 'package:bio_g/core/agro/water/soil_texture_source.dart';
import 'package:bio_g/core/agro/water/soil_water_scale.dart';
import 'package:bio_g/core/crops/crop_types.dart';

/// El medio resuelto, con su procedencia y lo que hay que declarar por él.
@immutable
class ResolvedSoilProfile {
  const ResolvedSoilProfile({
    required this.texture,
    required this.source,
    required this.isFallback,
    required this.limitationsEs,
  });

  final SoilTexture texture;
  final SoilTextureSource source;

  /// True cuando la textura NO se conoce y se está usando la media como
  /// respaldo. Quien la use debe declararlo y bajar la confianza.
  final bool isFallback;

  /// Qué no sabemos, en lenguaje humano. Va a la decisión, no a la basura.
  final List<String> limitationsEs;

  /// Cuánta confianza hay que restar por lo que se asumió.
  double get confidencePenalty => isFallback ? 0.15 : 0.0;
}

abstract final class SoilProfileResolver {
  static const String version = 'soil-profile-resolver-1.0';

  static const String _fallbackLimitation =
      'No sabemos qué tierra tienes, así que usamos la más común (media). '
      'Si es muy arenosa o muy pesada, los umbrales cambian bastante.';

  /// Resuelve el medio de cultivo. Ninguno de los parámetros es obligatorio:
  /// la función tiene que dar una respuesta útil incluso con todo en nulo, que
  /// es el estado de cualquier instalación anterior a esta versión.
  static ResolvedSoilProfile resolve({
    String? deviceModelId,
    String? cultivationScaleId,
    String? soilTextureId,
    String? soilTextureSourceId,
    CropKey? cropKey,
  }) {
    final BioGDeviceModel? model = deviceModelFromId(deviceModelId);
    final CultivationScale? scale = cultivationScaleFromId(cultivationScaleId);

    // ── 1 · El equipo lo dice ────────────────────────────────────────────────
    if (model == BioGDeviceModel.maceta) {
      return ResolvedSoilProfile(
        texture: _substrateFor(cropKey),
        source: SoilTextureSource.derivedFromDevice,
        isFallback: false,
        limitationsEs: const <String>[],
      );
    }

    // ── 2 y 3 · Suelo mineral, o sustrato por escala si aún no hay equipo ────
    //
    // La escala solo se consulta cuando NO hay equipo emparejado. Con un BIO-G
    // Huerto o Campo conectado, decir «maceta» en la escala no puede convertir
    // el medio en sustrato: el aparato ya contestó esa pregunta.
    if (model == null && scale == CultivationScale.pot) {
      return ResolvedSoilProfile(
        texture: _substrateFor(cropKey),
        source: SoilTextureSource.derivedFromScale,
        isFallback: false,
        limitationsEs: const <String>[],
      );
    }

    // ── 4 · Textura mineral declarada, o respaldo ────────────────────────────
    final SoilTexture declared = SoilTexture.fromId(soilTextureId);

    // Un sustrato guardado en el campo de textura mineral es un dato imposible:
    // el sustrato jamás se pregunta. Si aparece, se trata como no declarado.
    final bool hasUsableTexture =
        !declared.isSubstrate && declared != SoilTexture.unknown;

    if (!hasUsableTexture) {
      return ResolvedSoilProfile(
        texture: SoilTexture.loam,
        // `unknown` como respaldo del respaldo: en runtime la fuente no puede
        // ser nula. La distinción entre «no había campo» y «dijo que no sabe»
        // se conserva en la persistencia, que sí admite nulo.
        source:
            SoilTextureSource.fromId(soilTextureSourceId) ??
            SoilTextureSource.unknown,
        isFallback: true,
        limitationsEs: const <String>[_fallbackLimitation],
      );
    }

    return ResolvedSoilProfile(
      texture: declared,
      source:
          SoilTextureSource.fromId(soilTextureSourceId) ??
          SoilTextureSource.declared,
      isFallback: false,
      limitationsEs: const <String>[],
    );
  }

  /// Sustrato general o drenante. **No se pregunta: lo dice el cultivo.**
  ///
  /// Un sustrato de cactus lleva perlita, arena o pómez; drena rápido, retiene
  /// poco y se seca parejo. Uno de turba para ornamental convencional retiene
  /// mucho más y libera el agua de otra forma. Meterlos en la misma fila porque
  /// ambos están en maceta es el mismo error de escala que se corrigió un nivel
  /// más abajo, en suelo.
  static SoilTexture _substrateFor(CropKey? cropKey) {
    final policy = CropWaterPolicies.forCrop(cropKey);
    return policy.group == CropWaterGroup.xeric
        ? SoilTexture.pottingMixDraining
        : SoilTexture.pottingMix;
  }
}
