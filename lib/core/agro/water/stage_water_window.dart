// lib/core/agro/water/stage_water_window.dart
//
// Qué ventana hídrica es cada etapa fenológica. Declarado, no adivinado.
//
// ─────────────────────────────────────────────────────────────────────────────
// POR QUÉ ESTE ARCHIVO EXISTE
// ─────────────────────────────────────────────────────────────────────────────
//
// Antes, `allowableDepletionForStage` decidía si una etapa era crítica o de
// secado buscando subcadenas: `stageKey.contains('grain_fill')`,
// `stageKey.contains('cosecha')`. Se veía razonable y estaba roto de raíz.
//
// De las claves reales del catálogo, la mayoría no coincidía con NINGUNA
// palabra, y varias coincidían al revés:
//
//   · `grainFill` (trigo, cebada, avena, frijol) nunca coincidió con
//     'grain_fill': el runtime emite el `.name` del enum, sin guion bajo. La
//     lista ya había previsto esto para el fruto —traía `fruit_fill` Y
//     `fruitfill`— y para el grano se olvidó. Cuatro cultivos atravesaban todo
//     el llenado de grano sin apretar el riego.
//   · `tasseling` (maíz) no coincidía porque la lista traía 'espigado', en
//     español, y la clave está en inglés. Su propio texto de ayuda dice
//     "Etapa crítica: estrés hídrico reduce polinización".
//   · `bulbMaturation` (ajo) coincidía con 'bulb' y APRETABA el riego, mientras
//     la guía del propio ajo dice "Detén N fuerte y riegos tardíos".
//   · `cosechaProgresiva` (tomate, chile, pepino, berenjena, calabaza)
//     coincidía con 'cosecha' y AFLOJABA un 40 % durante la etapa más larga
//     del ciclo, que el propio repositorio documenta como de floración y
//     cuajado simultáneos.
//   · `post_harvest` (9 frutales) aflojaba, mientras `isTreeCriticalStage`, en
//     este mismo repositorio, lo declara crítico.
//   · `espigadoSenescencia` (espinaca) contiene 'espigado' Y 'senescencia'.
//     Como el bucle crítico corría primero, una etapa terminal salía apretada.
//
// Y las pruebas no lo detectaban porque probaban el maíz con la cadena
// 'grain_fill', que ningún motor emite jamás. Validaban la lista de palabras
// contra sí misma, nunca contra el catálogo de etapas.
//
// La lección no es "faltaban palabras". Es que **adivinar el significado de una
// etapa a partir de su nombre es el error**. Aquí cada etapa real declara qué
// es, y `stage_water_window_coverage_test.dart` recorre los catálogos y falla
// si alguna quedó sin declarar.
//
// ─────────────────────────────────────────────────────────────────────────────
// NORMALIZACIÓN DE CLAVE
// ─────────────────────────────────────────────────────────────────────────────
//
// El catálogo usa DOS convenciones a la vez, según el adaptador:
//
//   · `.name` de enum, en camelCase — trigo, cebada, avena, frijol, maíz,
//     tomate, chile, pepino, berenjena, calabaza, lechuga, espinaca, cebolla,
//     ajo.  →  "grainFill", "cosechaProgresiva"
//   · constantes `*StageIds`, en snake_case — los 9 frutales, rosal, cactus,
//     nopal, suculenta, sábila, agave, girasol, cempasúchil, tulipán.
//     →  "fruit_fill", "post_harvest"
//
// Esa dualidad es exactamente lo que mató al método anterior. Aquí se
// neutraliza: la clave se normaliza a minúsculas sin guiones bajos, guiones ni
// espacios, así que `grainFill`, `grain_fill` y `GRAIN_FILL` caen en la MISMA
// entrada. Ningún cambio de convención en un adaptador puede volver a apagar
// silenciosamente una clasificación.
//
// ─────────────────────────────────────────────────────────────────────────────
// COLISIONES ENTRE CULTIVOS
// ─────────────────────────────────────────────────────────────────────────────
//
// Algunas cadenas las comparten cultivos donde NO significan lo mismo. Para eso
// está `_byCrop`, que se consulta antes que el mapa global:
//
//   · `stem_elongation` es rutina vegetativa en girasol y cempasúchil, pero en
//     tulipán de corte define el largo de tallo, que ES el producto.
//   · `root_establishment` es crítico en frutales y rosal —una raíz que se está
//     formando no puede ir a buscar agua— y deliberadamente NO lo es en las
//     xerófitas, donde adelantar el riego durante el arraigo es justo lo que
//     las pudre.
//
// Cuando una cadena significa lo mismo en todos lados, vive en `_global`.

import 'package:bio_g/core/crops/crop_types.dart';

/// Qué papel juega el agua en una etapa fenológica.
enum WaterWindow {
  /// Sin ajuste: se usa el agotamiento permisible base del cultivo.
  normal,

  /// Ventana donde el estrés hídrico no baja el rendimiento, lo destruye, y el
  /// daño no se recupera regando después. Aprieta el agotamiento permisible.
  critical,

  /// Ventana donde el cultivo QUIERE secarse: madurez, curado, reposo. Aflojar
  /// aquí no es descuido, es la práctica correcta.
  drying,
}

abstract final class StageWaterWindows {
  const StageWaterWindows._();

  /// Neutraliza camelCase contra snake_case. Ver la nota de arriba.
  static String normalizeKey(String raw) =>
      raw.trim().toLowerCase().replaceAll(RegExp(r'[_\-\s]+'), '');

  /// La ventana hídrica de una etapa, o `null` si no está declarada.
  ///
  /// `null` NO es un error en runtime: el llamador usa el agotamiento base, que
  /// es el comportamiento conservador. Es la prueba de cobertura la que
  /// convierte un `null` en fallo, y lo hace antes de que llegue a producción.
  static WaterWindow? lookup(String? stageKey, {CropKey? cropKey}) {
    if (stageKey == null) return null;
    final key = normalizeKey(stageKey);
    if (key.isEmpty) return null;
    final scoped = cropKey == null ? null : _byCrop[cropKey]?[key];
    return scoped ?? _global[key];
  }

  /// Todas las claves normalizadas con clasificación, para la prueba.
  static Set<String> get classifiedKeys => <String>{
    ..._global.keys,
    for (final m in _byCrop.values) ...m.keys,
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // ESPECÍFICO POR CULTIVO — se consulta primero
  // ═══════════════════════════════════════════════════════════════════════════

  //
  // Sobre `root_establishment`: la lleva el mapa por cultivo y NO el global, a
  // propósito. Es crítica en frutales y rosal —una raíz que se está formando no
  // puede ir a buscar agua—, y NO lo es en las xerófitas, donde adelantar el
  // riego durante el arraigo es exactamente lo que las pudre.
  //
  // Podría haberse escrito al revés: global `critical` y excepción `normal` para
  // las cinco xerófitas. Se eligió esta dirección porque si algún día una ruta
  // resuelve sin `cropKey`, el valor que hereda el cactus es el conservador. El
  // costo de equivocarse hacia `normal` en un frutal es un riego menos apretado;
  // hacia `critical` en un cactus, es pudrición de raíz.
  static const Map<CropKey, Map<String, WaterWindow>> _byCrop = {
    // El largo de tallo ES el producto en tulipán de corte; en girasol y
    // cempasúchil la misma clave es rutina vegetativa.
    CropKey.tulip: {'stemelongation': WaterWindow.critical},

    // Arraigo crítico: frutales y rosal.
    CropKey.appleTree: _rootEstablishmentCritical,
    CropKey.pearTree: _rootEstablishmentCritical,
    CropKey.peachTree: _rootEstablishmentCritical,
    CropKey.walnutTree: _rootEstablishmentCritical,
    CropKey.pistachioTree: _rootEstablishmentCritical,
    CropKey.orangeTree: _rootEstablishmentCritical,
    CropKey.lemonTree: _rootEstablishmentCritical,
    CropKey.mangoTree: _rootEstablishmentCritical,
    CropKey.avocadoTree: _rootEstablishmentCritical,
    CropKey.rose: _rootEstablishmentCritical,

    // La sábila comparte `maintenance` con cactus, nopal, suculenta y agave,
    // pero NO comparte su régimen: está en `tolerant` (0,60) y no en `xeric`
    // a propósito —ver la nota de `crop_water_policy.dart`— y por eso vive en
    // sustrato de turba, no en drenante. Dejarla caer en el `drying` global le
    // movería el punto de riego de 38,0 a 28,4 % VWC, y `maintenance` es su
    // estado permanente: no es una ventana, es donde se queda para siempre.
    // Sería el mismo error que estamos corrigiendo, cometido de nuevo.
    CropKey.aloe: {'maintenance': WaterWindow.normal},
  };

  static const Map<String, WaterWindow> _rootEstablishmentCritical = {
    'rootestablishment': WaterWindow.critical,
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // GLOBAL — la cadena significa lo mismo en todo el catálogo
  // ═══════════════════════════════════════════════════════════════════════════

  static const Map<String, WaterWindow> _global = {
    // ── Cereales de grano pequeño: trigo, cebada, avena ──────────────────────
    'germination': WaterWindow.normal,
    'emergence': WaterWindow.normal,
    'vegearly': WaterWindow.normal,
    'tillering': WaterWindow.normal,
    'elongation': WaterWindow.normal,
    // Embuche y espigado: la literatura de riego es unánime, aquí se define el
    // número de granos y el daño no se recupera.
    'booting': WaterWindow.critical,
    'heading': WaterWindow.critical,
    'flowering': WaterWindow.critical,
    // La razón de ser de este archivo: nunca coincidía con 'grain_fill'.
    'grainfill': WaterWindow.critical,
    'physiologicalmaturity': WaterWindow.drying,
    'harvest': WaterWindow.drying,

    // ── Frijol ──────────────────────────────────────────────────────────────
    'vegadvanced': WaterWindow.normal,
    // Amarre de vaina. La lista vieja traía 'fruit_set', no 'podset'.
    'podset': WaterWindow.critical,

    // ── Maíz ────────────────────────────────────────────────────────────────
    'vegmid': WaterWindow.normal,
    // Su propio texto: "Etapa crítica: estrés hídrico reduce polinización".
    'tasseling': WaterWindow.critical,
    'flowerset': WaterWindow.critical,
    // OJO — decisión consciente, y es un empate técnico.
    //
    // Esta etapa del maíz mete DOS cosas en un solo cajón: el llenado de grano
    // y la senescencia. Su propio texto lo dice: "Llenado de grano activo"
    // (grano), "Llenado comercial de mazorca" (elote), "Acumulación final de
    // biomasa, mantén humedad funcional" (forraje).
    //
    // Hoy aflojaba un 40 % por contener 'maturity', que para elote y forraje es
    // claramente incorrecto. Apretarla sería igual de incorrecto para la cola de
    // senescencia. `normal` es el único valor honesto mientras la etapa siga sin
    // partirse, y es estrictamente mejor que lo de antes en los tres usos.
    //
    // La corrección de fondo NO es este renglón: es partir la etapa en
    // `grainFill` + `maturitySenescence` en `maize_engine.dart`. Anotado.
    'maturitysenescence': WaterWindow.normal,

    // ── Fruto-hortalizas: tomate, chile, pepino, berenjena, calabaza ─────────
    'germinacion': WaterWindow.normal,
    'establecimiento': WaterWindow.normal,
    'vegetativo': WaterWindow.normal,
    'floracion': WaterWindow.critical,
    'cuajado': WaterWindow.critical,
    'llenado': WaterWindow.critical,
    // Aflojaba un 40 % por contener 'cosecha'. En indeterminadas esta etapa ES
    // reproducción continua: el propio repositorio documenta floración y
    // cuajado simultáneos durante ella.
    'cosechaprogresiva': WaterWindow.critical,
    'finciclo': WaterWindow.drying,

    // ── Lechuga ─────────────────────────────────────────────────────────────
    'desarrollovegetativo': WaterWindow.normal,
    // Es `heading`, en español. Nunca coincidía.
    'formacioncabeza': WaterWindow.critical,
    // Aflojaba por contener 'cosecha'. En una hoja, la turgencia ES el producto:
    // no es una ventana de secado. Tampoco crítica —encharcar antes de cortar
    // trae pudrición y quemadura de punta—. Normal es el valor correcto.
    'ventanacosecha': WaterWindow.normal,
    'sobremadurez': WaterWindow.drying,

    // ── Espinaca ────────────────────────────────────────────────────────────
    'vegetativotemprano': WaterWindow.normal,
    // La expansión foliar ES el rendimiento.
    'expansionfoliar': WaterWindow.critical,
    'madurezcomercial': WaterWindow.normal,
    'perdidacalidad': WaterWindow.drying,
    // Contenía 'espigado' Y 'senescencia'; como el bucle crítico corría primero,
    // una etapa terminal salía APRETADA. Es secado.
    'espigadosenescencia': WaterWindow.drying,

    // ── Cebolla ─────────────────────────────────────────────────────────────
    'emergencia': WaterWindow.normal,
    // Apretaba por accidente, por contener 'bulb' dentro de "bulbificación".
    'induccionbulbificacion': WaterWindow.normal,
    'iniciobulbo': WaterWindow.critical,
    'llenadobulbo': WaterWindow.critical,
    // La cebolla necesita el cuello seco para almacenarse. Esto ya estaba bien.
    'maduracioncosecha': WaterWindow.drying,
    'maduracion': WaterWindow.drying,
    // En cebolla `espigado` NO es espigado de cereal: es subida a flor, un
    // defecto de calidad. Ni crítica ni de secado.
    'espigado': WaterWindow.normal,

    // ── Ajo ─────────────────────────────────────────────────────────────────
    'cloveplanting': WaterWindow.normal,
    'emergenceestablishment': WaterWindow.normal,
    'vegetativeleafdevelopment': WaterWindow.normal,
    'coldinductionvernalization': WaterWindow.normal,
    'bulbdifferentiation': WaterWindow.critical,
    'bulbfilling': WaterWindow.critical,
    // El caso más claro de todos: APRETABA por contener 'bulb', mientras la guía
    // del propio ajo dice "Detén N fuerte y riegos tardíos: maduración y curado
    // pesan más que seguir verde". Y 'maturity' no coincide con "maturation",
    // así que la salida de secado tampoco disparaba.
    'bulbmaturation': WaterWindow.drying,
    'curingrest': WaterWindow.drying,
    'scapebrooming': WaterWindow.normal,

    // ── Frutales (9) ────────────────────────────────────────────────────────
    'plantingtransplant': WaterWindow.normal,
    // Valor conservador por defecto; frutales y rosal lo elevan a crítico en
    // `_byCrop` (ver la nota de arriba). `isTreeCriticalStage` ya lo declara
    // crítico en este mismo repositorio.
    'rootestablishment': WaterWindow.normal,
    'juvenilevegetative': WaterWindow.normal,
    'dormancy': WaterWindow.drying,
    'budbreak': WaterWindow.normal,
    'vegetativegrowth': WaterWindow.normal,
    'fruitset': WaterWindow.critical,
    'fruitfill': WaterWindow.critical,
    // Aflojaba por contener 'maturity'. En cítrico, mango y aguacate el estrés
    // en maduración cuesta calibre y jugo. El secado controlado de hueso es
    // práctica real pero específica de cultivo y de decisión del productor: no
    // se codifica como norma.
    'harvestmaturity': WaterWindow.normal,
    // Aflojaba un 40 % mientras `isTreeCriticalStage` lo declara crítico. Las
    // reservas de poscosecha definen la floración del año siguiente.
    'postharvest': WaterWindow.critical,
    'unknown': WaterWindow.normal,

    // ── Rosal ───────────────────────────────────────────────────────────────
    'installationestablishment': WaterWindow.normal,
    'vegetativeflush': WaterWindow.normal,
    'budformation': WaterWindow.critical,
    // Apretaba por contener 'bloom', cuando el prefijo `post_` lo niega.
    'postbloomrecovery': WaterWindow.normal,
    'rest': WaterWindow.drying,

    // ── Xerófitas: cactus, nopal, suculenta, sábila, agave ───────────────────
    'activegrowth': WaterWindow.normal,
    // El mantenimiento de una xerófita es deliberadamente seco.
    'maintenance': WaterWindow.drying,

    // ── Girasol y cempasúchil ───────────────────────────────────────────────
    'sowing': WaterWindow.normal,
    'earlyvegetativegrowth': WaterWindow.normal,
    'activevegetativegrowth': WaterWindow.normal,
    'stemelongation': WaterWindow.normal,
    // En girasol es llenado de aquenio; en cempasúchil, floración sostenida que
    // ES el producto. Crítica en ambos, por razones distintas.
    'postbloom': WaterWindow.critical,
    'senescence': WaterWindow.drying,
    'cyclecomplete': WaterWindow.drying,

    // ── Tulipán ─────────────────────────────────────────────────────────────
    // Apretaba por contener 'bulb', y es la etapa de plantación: no engorda nada.
    'bulbplanting': WaterWindow.normal,
    'rootingchilling': WaterWindow.normal,
    'shootemergence': WaterWindow.normal,
    // La recarga del bulbo tras la flor define el bulbo del año siguiente.
    'bulbrecharge': WaterWindow.critical,
    'foliagesenescence': WaterWindow.drying,
    'fallback': WaterWindow.normal,
  };
}
