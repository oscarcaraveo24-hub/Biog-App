// lib/core/crops/generic/generic_guide.dart
//
// MODO GUÍA GENERAL
//
// Para el agricultor que tiene una planta que BIO-G no lleva en el catálogo.
// Elige "Otro" en el wizard y obtiene etiquetas —Óptimo / Bajo / Alto— de las
// cinco condiciones del suelo que casi todas las plantas comparten: humedad,
// pH, temperatura de suelo, conductividad eléctrica y compactación.
//
// Lo que este modo NO hace, y es deliberado: **no interpreta NPK**. El nitrógeno
// que sobra en crecimiento vegetativo falta en llenado de fruto; sin saber qué
// planta es ni en qué etapa va, no hay ventana de demanda que aplicar. Los
// valores de N, P y K se siguen mostrando en crudo, sin etiqueta. Es la línea
// que marca el Fundacional 2.1 §9.2: se puede mostrar lo medido, no se puede
// inventar la interpretación.
//
// ── PARA QUIÉN NO SIRVE ──────────────────────────────────────────────────────
//
// Las plantas que se salen de estos rangos ya tienen su propia entrada en el
// catálogo y hay que elegirlas ahí: nopal, cactus, suculentas, agave, sábila y
// todos los frutales. Este modo está pensado para el resto — las mesófitas, que
// es la enorme mayoría.
//
// ── DE DÓNDE SALEN LOS NÚMEROS ───────────────────────────────────────────────
//
// No son un promedio de los 85 cultivos: promediar nopal con lechuga da una
// banda que no describe a ninguno de los dos. Son la **mediana de los perfiles
// mesófitos que BIO-G ya tiene escritos**, tomando todas sus etapas:
//
//   barley · bean · chili · cucumber · eggplant · garlic · lettuce · maize
//   marigold · oat · onion · rose · spinach · squash · sunflower · tomato
//   tulip · wheat
//
// Con exclusión explícita de xerófitas (agave, aloe, cactus, nopal, suculenta)
// y de los catorce frutales, precisamente porque son los que tiran la mediana.
//
// Muestra por métrica: humedad n=67 rangos de etapa, temperatura n=94, CE n=52,
// resistencia n=52.
//
// El pH es la excepción y conviene decirlo: solo 9 de los perfiles mesófitos lo
// declaran, muestra demasiado pobre para fiarse de su mediana. Para pH se usa la
// referencia general que la app **ya trae en producción** y que el agricultor ya
// ve en la pantalla de pre-siembra (`_preSowingPhStatus`: bajo <5.8, alto >7.2)
// y en el score de suelo (crítico fuera de 4.5–8.8). Usar la mediana de esos 9
// habría hecho que un pH de 7.0 saliera "Alto" aquí y "Apto" allá — dos
// pantallas contradiciéndose sobre la misma lectura.
//
// ── ADVERTENCIA DE ESCALA ────────────────────────────────────────────────────
//
// Estos rangos están en la MISMA escala que el resto del catálogo, con el mismo
// defecto conocido: los perfiles se escribieron contra lecturas de sustrato, no
// contra VWC de suelo mineral (ver `core/agro/water/soil_water_scale.dart`).
// Cuando se cierre ese contrato de escala, **esta tabla se recalibra junto con
// los 85 cultivos, no por separado.** Si se corrige solo aquí, el modo guía
// pasaría a contradecir a todos los demás.

import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/crops/crop_target_models.dart';

/// Identificador del cultivo en modo guía.
///
/// Se persiste en `DeviceCropContext.cropId`, que es `required String`. No
/// resuelve a ninguna `CropDefinition` a propósito: sin definición no hay
/// fenología, y sin fenología no hay etapas que inventar.
const String kGuideCropId = 'crop_generic';

/// Id de la categoría en el wizard.
const String kGuideCategoryId = 'generic';

/// Etiqueta de etapa. Fija: en modo guía no hay calendario fenológico.
const String kGuideStageKey = 'general';

/// Perfil que se persiste en `DeviceCropContext.profileId`.
///
/// Mismo texto que [kGuideStageKey], pero es otra cosa y conviene que tenga su
/// propio nombre: uno responde "¿en qué etapa va?" y el otro "¿qué perfil de
/// cultivo se eligió?". En guía la respuesta a las dos es "ninguna", y al
/// compartir literal se leían como si fueran el mismo concepto.
///
/// El valor no debe cambiarse: hay contextos ya guardados en disco con él.
const String kGuideProfileId = 'general';

/// Cómo se nombra a la planta dentro de los textos de alerta.
///
/// El motor de alertas interpola el nombre del cultivo en el cuerpo del aviso.
/// En guía no hay nombre que interpolar: el `cropId` es un centinela y el
/// catálogo devolvería para él una etiqueta de respaldo. Se fija aquí un texto
/// explícito para que ninguna alerta imprima `crop_generic` ni afirme un
/// cultivo que el sistema no conoce.
///
/// Se dice "planta" y no "cultivo" a propósito: quien entra por "Otro" tiene
/// tanto derecho a un rosal como a una hortaliza.
const String kGuideCropLabel = 'tu planta';

/// True si este contexto corre en modo guía general.
///
/// Predicado único a propósito. Es la misma lección de `isGenericMode`, que hoy
/// significa tres cosas distintas repartidas por media docena de archivos: si
/// cada pantalla decide por su cuenta qué es "guía", vuelven las dos verdades.
bool isGuideCropId(String? cropId) {
  final String value = (cropId ?? '').trim().toLowerCase();
  return value == kGuideCropId || value == kGuideCategoryId;
}

/// Rango que nunca produce banda útil.
///
/// Ocupa los tres campos de NPK que `StageTargets` exige. No se usa: el modo
/// guía deja `targets` en null aguas arriba y su motor no evalúa nutrientes.
/// Existe solo para satisfacer al constructor.
const AgroRange _kUnusedNutrientRange = AgroRange(
  lowMax: 0,
  optimalMin: 0,
  optimalMax: 100,
  highMin: 100,
);

/// Bandas de la guía general.
///
/// Semántica de [AgroRange], para leer la tabla:
///   valor < lowMax                    → Crítico (por debajo)
///   lowMax ≤ valor < optimalMin       → Bajo
///   optimalMin ≤ valor ≤ optimalMax   → Óptimo
///   optimalMax < valor ≤ highMin      → Alto
///   valor > highMin                   → Crítico (por encima)
const StageTargets kGuideTargets = StageTargets(
  // Mediana de 67 rangos de etapa mesófitos.
  moistureRaw: AgroRange(
    lowMax: 18,
    optimalMin: 35,
    optimalMax: 70,
    highMin: 85,
  ),

  // Mediana de 94 rangos de etapa mesófitos.
  soilTemp: AgroRange(lowMax: 8, optimalMin: 15, optimalMax: 26, highMin: 32),

  // Referencia general ya vigente en la app (pre-siembra + score de suelo).
  // Ver la nota de cabecera: la mediana de los perfiles tenía n=9.
  ph: AgroRange(lowMax: 4.5, optimalMin: 5.8, optimalMax: 7.2, highMin: 8.8),

  // Mediana de 52 rangos de etapa mesófitos.
  ec: AgroRange(lowMax: 0.2, optimalMin: 0.5, optimalMax: 1.5, highMin: 2.2),

  // Mediana de 52 rangos mesófitos. El `lowMax` negativo es intencional y viene
  // de los propios perfiles: un suelo no puede estar peligrosamente suelto, así
  // que la resistencia nunca debe leer "crítico por debajo". Solo la
  // compactación es un problema.
  resistance: AgroRange(
    lowMax: -1.0,
    optimalMin: 0.0,
    optimalMax: 1.4,
    highMin: 2.0,
  ),

  // Sin uso. Ver [_kUnusedNutrientRange].
  nIndex: _kUnusedNutrientRange,
  pIndex: _kUnusedNutrientRange,
  kIndex: _kUnusedNutrientRange,
);

/// Pesos del score de suelo en modo guía.
///
/// `npk: 0` es la pieza clave: los nutrientes no entran en el score compuesto.
/// Sin eso el anillo de salud del suelo estaría promediando una interpretación
/// nutrimental que este modo, por definición, no tiene.
///
/// Los cinco pesos de suelo replican el reparto que usan los perfiles mesófitos
/// en etapa vegetativa, que es el punto medio del ciclo.
const StageWeights kGuideWeights = StageWeights(
  moisture: 0.40,
  soilTemp: 0.15,
  resistance: 0.15,
  ph: 0.20,
  ec: 0.10,
  npk: 0.0,
);
