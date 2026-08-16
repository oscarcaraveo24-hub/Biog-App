// lib/core/agro/water/crop_water_policy.dart
//
// Cuánta agua puede agotar cada cultivo antes de que le duela.
//
// ─────────────────────────────────────────────────────────────────────────────
// POR QUÉ ESTO ES UNA TABLA CORTA Y NO 85 CURVAS
// ─────────────────────────────────────────────────────────────────────────────
//
// El objetivo de humedad de un cultivo NO es un número de VWC. Un tomate no
// quiere "28 %": quiere que no se le agote más de la mitad del agua que su
// suelo puede darle. En arena eso son 8 % VWC y en arcilla 32 % — el mismo
// criterio agronómico, dos números completamente distintos.
//
// La variable en la que sí está escrita la literatura de riego es el
// **agotamiento permisible (MAD, *management allowed depletion*)**: la fracción
// del agua disponible que se deja consumir antes de volver a regar. Y en esa
// variable los cultivos se agrupan en un puñado de clases, no en 85 curvas.
//
// Por eso este archivo cabe en una pantalla mientras cubre todo el catálogo, y
// por eso arreglar la escala de humedad resultó ser MENOS trabajo que mantener
// los rangos escritos a mano que había antes.
//
// Fuentes: FAO-56 (tabla 22, fracción de agotamiento sin estrés `p`),
// extensión universitaria de EE. UU. para hortalizas y frutales, y —para
// cactáceas, agaves y nopal— el documento interno de recalibración de
// ornamentales, que ya había hecho este trabajo bien para maceta.

import 'package:flutter/foundation.dart';

import 'package:bio_g/core/agro/water/stage_water_window.dart';
import 'package:bio_g/core/crops/crop_types.dart';

/// Clases de tolerancia al agotamiento. El número es la fracción del agua
/// disponible que se puede consumir antes de regar.
enum CropWaterGroup {
  /// Raíz somera y sin capacidad de recuperación: lechuga, espinaca, cebolla.
  /// Un solo episodio de estrés ya cuesta calidad, no solo rendimiento.
  sensitive(0.30, 'Muy sensible a la sequía'),

  /// Hortaliza de fruto en etapa reproductiva, y frutales jóvenes.
  moderate(0.40, 'Sensible'),

  /// El grueso del catálogo: hortaliza de fruto establecida, frutal adulto.
  standard(0.50, 'Tolerancia normal'),

  /// Grano de temporal y frutal de raíz profunda: llegan más abajo y toleran
  /// más agotamiento sin perder cosecha.
  tolerant(0.60, 'Tolerante'),

  /// Xerófitas. No es que "aguanten" la sequía: es que el exceso de agua las
  /// mata más rápido que la falta. Aquí el riesgo real es el otro extremo.
  xeric(0.80, 'Xerófita — más riesgo por exceso que por falta');

  const CropWaterGroup(this.allowableDepletion, this.labelEs);

  /// MAD: fracción de agua disponible consumible antes de regar.
  final double allowableDepletion;
  final String labelEs;
}

/// Política hídrica de un cultivo: su grupo y su profundidad radicular
/// efectiva, que es la otra mitad de la ecuación de la lámina.
@immutable
class CropWaterPolicy {
  const CropWaterPolicy({
    required this.group,
    required this.rootDepthCm,
    this.wettedAreaM2PerPlant,
  });

  final CropWaterGroup group;

  /// Profundidad radicular efectiva, en cm: de dónde extrae realmente el agua
  /// la mayoría de la raíz. No es la profundidad máxima que alcanza —esa es
  /// mucho mayor y sobrestimaría la lámina—.
  final double rootDepthCm;

  /// Superficie que moja cada planta. Solo para cultivos donde "milímetros"
  /// no significa nada al productor: árboles y maceta, donde la pregunta real
  /// es "¿cuántos litros por planta?".
  final double? wettedAreaM2PerPlant;

  double get allowableDepletion => group.allowableDepletion;
}

abstract final class CropWaterPolicies {
  /// Versión de la tabla. Viaja en el registro de trazabilidad: si estos
  /// valores cambian, las recomendaciones ya emitidas no se reescriben.
  static const String version = 'crop-water-policy-1.0';

  static const Map<CropKey, CropWaterPolicy> _table = {
    // ── Granos ──────────────────────────────────────────────────────────────
    // Raíz profunda y tolerancia alta al agotamiento en vegetativo. El
    // agotamiento se aprieta por etapa (ver [forStage]): en floración y
    // llenado de grano el maíz no perdona.
    CropKey.maize: CropWaterPolicy(
      group: CropWaterGroup.tolerant,
      rootDepthCm: 60,
    ),
    CropKey.wheat: CropWaterPolicy(
      group: CropWaterGroup.tolerant,
      rootDepthCm: 55,
    ),
    CropKey.barley: CropWaterPolicy(
      group: CropWaterGroup.tolerant,
      rootDepthCm: 55,
    ),
    CropKey.oat: CropWaterPolicy(
      group: CropWaterGroup.tolerant,
      rootDepthCm: 50,
    ),
    // El frijol es la excepción entre los de grano: raíz somera y de los
    // cultivos más sensibles al estrés hídrico y salino del catálogo.
    CropKey.bean: CropWaterPolicy(
      group: CropWaterGroup.moderate,
      rootDepthCm: 40,
    ),

    // ── Hortalizas de fruto ─────────────────────────────────────────────────
    CropKey.tomato: CropWaterPolicy(
      group: CropWaterGroup.standard,
      rootDepthCm: 45,
      wettedAreaM2PerPlant: 0.25,
    ),
    CropKey.chili: CropWaterPolicy(
      group: CropWaterGroup.moderate,
      rootDepthCm: 35,
      wettedAreaM2PerPlant: 0.20,
    ),
    CropKey.cucumber: CropWaterPolicy(
      group: CropWaterGroup.moderate,
      rootDepthCm: 35,
      wettedAreaM2PerPlant: 0.25,
    ),
    CropKey.eggplant: CropWaterPolicy(
      group: CropWaterGroup.standard,
      rootDepthCm: 45,
      wettedAreaM2PerPlant: 0.25,
    ),
    CropKey.squash: CropWaterPolicy(
      group: CropWaterGroup.standard,
      rootDepthCm: 45,
      wettedAreaM2PerPlant: 0.40,
    ),

    // ── Hoja y bulbo ────────────────────────────────────────────────────────
    // Raíz somera, sin margen. Aquí el MAD de 0.30 no es conservadurismo:
    // la lechuga con estrés hídrico se amarga y no se recupera.
    CropKey.lettuce: CropWaterPolicy(
      group: CropWaterGroup.sensitive,
      rootDepthCm: 25,
    ),
    CropKey.spinach: CropWaterPolicy(
      group: CropWaterGroup.sensitive,
      rootDepthCm: 25,
    ),
    CropKey.onion: CropWaterPolicy(
      group: CropWaterGroup.sensitive,
      rootDepthCm: 30,
    ),
    CropKey.garlic: CropWaterPolicy(
      group: CropWaterGroup.sensitive,
      rootDepthCm: 30,
    ),

    // ── Frutales ────────────────────────────────────────────────────────────
    // Raíz profunda; la lámina se expresa en litros por árbol, no en mm.
    CropKey.appleTree: CropWaterPolicy(
      group: CropWaterGroup.standard,
      rootDepthCm: 80,
      wettedAreaM2PerPlant: 4.0,
    ),
    CropKey.pearTree: CropWaterPolicy(
      group: CropWaterGroup.standard,
      rootDepthCm: 80,
      wettedAreaM2PerPlant: 4.0,
    ),
    CropKey.peachTree: CropWaterPolicy(
      group: CropWaterGroup.standard,
      rootDepthCm: 70,
      wettedAreaM2PerPlant: 3.5,
    ),
    CropKey.walnutTree: CropWaterPolicy(
      group: CropWaterGroup.tolerant,
      rootDepthCm: 100,
      wettedAreaM2PerPlant: 8.0,
    ),
    CropKey.pistachioTree: CropWaterPolicy(
      group: CropWaterGroup.tolerant,
      rootDepthCm: 100,
      wettedAreaM2PerPlant: 6.0,
    ),
    // Cítricos: raíz relativamente somera para su porte y sensibles tanto a
    // sal como a asfixia. No suben a `tolerant` aunque sean árboles.
    CropKey.orangeTree: CropWaterPolicy(
      group: CropWaterGroup.moderate,
      rootDepthCm: 60,
      wettedAreaM2PerPlant: 4.0,
    ),
    CropKey.lemonTree: CropWaterPolicy(
      group: CropWaterGroup.moderate,
      rootDepthCm: 60,
      wettedAreaM2PerPlant: 4.0,
    ),
    CropKey.mangoTree: CropWaterPolicy(
      group: CropWaterGroup.standard,
      rootDepthCm: 80,
      wettedAreaM2PerPlant: 6.0,
    ),
    // Aguacate: el más intolerante a la asfixia radicular de todo el catálogo.
    // Su MAD moderado protege del déficit; la alarma de encharcamiento —que
    // ahora es alcanzable— protege de lo que de verdad lo mata.
    CropKey.avocadoTree: CropWaterPolicy(
      group: CropWaterGroup.moderate,
      rootDepthCm: 50,
      wettedAreaM2PerPlant: 5.0,
    ),

    // ── Xerófitas y ornamentales ────────────────────────────────────────────
    CropKey.cactus: CropWaterPolicy(
      group: CropWaterGroup.xeric,
      rootDepthCm: 20,
      wettedAreaM2PerPlant: 0.05,
    ),
    CropKey.succulent: CropWaterPolicy(
      group: CropWaterGroup.xeric,
      rootDepthCm: 15,
      wettedAreaM2PerPlant: 0.05,
    ),
    // La sábila es la menos extrema de las xerófitas: el estudio de 2026 que
    // cita el doc de ornamentales la encuentra creciendo mejor cerca de
    // capacidad de campo. Por eso baja a `tolerant` y no se queda en `xeric`.
    CropKey.aloe: CropWaterPolicy(
      group: CropWaterGroup.tolerant,
      rootDepthCm: 25,
      wettedAreaM2PerPlant: 0.10,
    ),
    CropKey.agave: CropWaterPolicy(
      group: CropWaterGroup.xeric,
      rootDepthCm: 40,
      wettedAreaM2PerPlant: 0.50,
    ),
    CropKey.nopal: CropWaterPolicy(
      group: CropWaterGroup.xeric,
      rootDepthCm: 30,
      wettedAreaM2PerPlant: 0.40,
    ),
    CropKey.rose: CropWaterPolicy(
      group: CropWaterGroup.moderate,
      rootDepthCm: 40,
      wettedAreaM2PerPlant: 0.30,
    ),
    CropKey.tulip: CropWaterPolicy(
      group: CropWaterGroup.sensitive,
      rootDepthCm: 25,
      wettedAreaM2PerPlant: 0.05,
    ),
    CropKey.sunflower: CropWaterPolicy(
      group: CropWaterGroup.tolerant,
      rootDepthCm: 70,
    ),
    CropKey.marigold: CropWaterPolicy(
      group: CropWaterGroup.standard,
      rootDepthCm: 30,
      wettedAreaM2PerPlant: 0.10,
    ),
  };

  /// Política por defecto para modo genérico o cultivo no catalogado.
  ///
  /// Es deliberadamente conservadora (MAD 0.40, raíz somera): si BIO-G no sabe
  /// qué hay sembrado, más vale sugerir riego un poco antes que dejar secar un
  /// cultivo sensible. Quien la use debe declararlo como limitación.
  static const CropWaterPolicy generic = CropWaterPolicy(
    group: CropWaterGroup.moderate,
    rootDepthCm: 35,
  );

  static CropWaterPolicy forCrop(CropKey? key) {
    if (key == null || key == CropKey.generic) return generic;
    return _table[key] ?? generic;
  }

  static bool isGenericFallback(CropKey? key) =>
      key == null || key == CropKey.generic || !_table.containsKey(key);

  /// Ajusta el agotamiento permisible según la etapa.
  ///
  /// La regla agronómica es vieja y sólida: **en floración, cuajado y llenado
  /// no se deja agotar**. Es la ventana donde el estrés hídrico no baja el
  /// rendimiento, lo destruye, y donde el daño no se recupera regando después.
  ///
  /// En el otro extremo, cerca de cosecha y en reposo muchos cultivos QUIEREN
  /// secarse: la cebolla y el ajo necesitan el cuello seco para almacenarse, y
  /// un frutal en dormancia no debe regarse como si estuviera creciendo.
  ///
  /// Qué etapa es cuál NO se adivina a partir del nombre. Antes se hacía con
  /// `stageKey.contains('grain_fill')` y compañía, y estaba roto: `grainFill`
  /// nunca coincidió con `'grain_fill'` porque el runtime emite el `.name` del
  /// enum, sin guion bajo; el ajo APRETABA el riego en `bulbMaturation` por
  /// contener 'bulb', justo donde su propia guía dice que lo detengas; y
  /// `cosechaProgresiva` aflojaba un 40 % durante la etapa que el propio
  /// repositorio documenta como de floración y cuajado simultáneos.
  ///
  /// Hoy cada etapa declara su ventana en [StageWaterWindows], y
  /// `stage_water_window_coverage_test.dart` recorre los catálogos y falla si
  /// alguna clave real queda sin declarar.
  ///
  /// [cropKey] solo hace falta para las etapas cuya cadena significa cosas
  /// distintas según el cultivo. Sin él se resuelve por el mapa global, que es
  /// correcto para la inmensa mayoría.
  static double allowableDepletionForStage(
    CropWaterPolicy policy,
    String? stageKey, {
    CropKey? cropKey,
  }) {
    final base = policy.allowableDepletion;
    final window = StageWaterWindows.lookup(stageKey, cropKey: cropKey);

    switch (window) {
      // Ventana crítica: se aprieta un 30 %, con piso de 0.20 para no volver el
      // riego imposible de satisfacer en suelos arenosos.
      case WaterWindow.critical:
        return (base * 0.70).clamp(0.20, 0.85);
      // Ventana seca deliberada: se afloja un 40 %, con techo de 0.85.
      case WaterWindow.drying:
        return (base * 1.40).clamp(0.20, 0.85);
      case WaterWindow.normal:
        return base;
      // Etapa nula, vacía o sin declarar. En runtime se usa el agotamiento base,
      // que es lo conservador; es la prueba de cobertura la que convierte esto
      // en fallo, y lo hace antes de llegar a producción.
      case null:
        return base;
    }
  }
}
