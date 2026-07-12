import 'package:bio_g/core/crops/apple_tree/apple_tree_catalog.dart';
import 'package:bio_g/core/crops/peach_tree/peach_tree_catalog.dart';
import 'package:bio_g/core/crops/pear_tree/pear_tree_catalog.dart';
import 'package:bio_g/core/crops/walnut_tree/walnut_tree_catalog.dart';
import 'package:bio_g/core/crops/pistachio_tree/pistachio_tree_catalog.dart';
import 'package:bio_g/core/crops/orange_tree/orange_tree_catalog.dart';
import 'package:bio_g/core/crops/lemon_tree/lemon_tree_catalog.dart';
import 'package:bio_g/core/crops/mango_tree/mango_tree_catalog.dart';
import 'package:bio_g/core/crops/avocado_tree/avocado_tree_catalog.dart';
import 'package:bio_g/core/crops/tree_lifecycle.dart';
import 'package:bio_g/core/yield/yield_reference_catalog.dart';

/// Rendimiento de referencia para árboles perennes, expresado en **kg por
/// árbol** (no ton/ha como los anuales en [YieldReferenceCatalog]).
///
/// Decisión #11: sin historial, BIO-G estima con una tabla conservadora por
/// *tier productivo* (joven / primera producción / plena) y por perfil,
/// multiplicable por el número de árboles. La confianza es siempre baja
/// (`modeled`) y la estimación es deliberadamente conservadora (SKIP-style):
/// es una orientación, no una promesa.
///
/// No agrega columnas a Supabase ni persiste densidad (decisión #10): el número
/// de árboles entra como parámetro de cálculo, no como estado del cultivo.

/// Tier productivo del árbol para fines de rendimiento. Es un eje propio del
/// rendimiento; NO reusa ni inventa IDs del ciclo de vida ([TreeStateIds]).
enum TreeProductiveTier {
  /// Árbol joven que recién empieza a producir (baja carga).
  young,

  /// Primeras temporadas productivas (producción parcial).
  firstProduction,

  /// Árbol en plena producción.
  full,
}

class TreeYieldReference {
  final String id;
  final String cropId;
  final String profileId;
  final TreeProductiveTier tier;
  final double kgPerTreeLow;
  final double kgPerTreeHigh;
  final YieldDataConfidence confidence;
  final String sourceMethod;

  const TreeYieldReference({
    required this.id,
    required this.cropId,
    required this.profileId,
    required this.tier,
    required this.kgPerTreeLow,
    required this.kgPerTreeHigh,
    required this.confidence,
    required this.sourceMethod,
  });
}

/// Resultado de una estimación total = kg/árbol × número de árboles.
class TreeYieldEstimate {
  final double kgLow;
  final double kgHigh;
  final int treeCount;
  final TreeProductiveTier tier;
  final YieldDataConfidence confidence;
  final String sourceMethod;

  const TreeYieldEstimate({
    required this.kgLow,
    required this.kgHigh,
    required this.treeCount,
    required this.tier,
    required this.confidence,
    required this.sourceMethod,
  });
}

class TreeYieldReferenceCatalog {
  const TreeYieldReferenceCatalog._();

  /// Tabla conservadora de manzano por tier. v1 usa el perfil general
  /// (AP-SKIP); el ajuste fino por variedad (decisión #9) se difiere, así que
  /// cualquier perfil cae a esta base mediante [referenceFor].
  static const Map<String, TreeYieldReference> byId = <String, TreeYieldReference>{
    'apple_tree_ap_skip_young': TreeYieldReference(
      id: 'apple_tree_ap_skip_young',
      cropId: kCropAppleTree,
      profileId: kApSkip,
      tier: TreeProductiveTier.young,
      kgPerTreeLow: 5,
      kgPerTreeHigh: 15,
      confidence: YieldDataConfidence.modeled,
      sourceMethod: 'Modelo conservador por tier (sin historial)',
    ),
    'apple_tree_ap_skip_first': TreeYieldReference(
      id: 'apple_tree_ap_skip_first',
      cropId: kCropAppleTree,
      profileId: kApSkip,
      tier: TreeProductiveTier.firstProduction,
      kgPerTreeLow: 15,
      kgPerTreeHigh: 35,
      confidence: YieldDataConfidence.modeled,
      sourceMethod: 'Modelo conservador por tier (sin historial)',
    ),
    'apple_tree_ap_skip_full': TreeYieldReference(
      id: 'apple_tree_ap_skip_full',
      cropId: kCropAppleTree,
      profileId: kApSkip,
      tier: TreeProductiveTier.full,
      kgPerTreeLow: 40,
      kgPerTreeHigh: 90,
      confidence: YieldDataConfidence.modeled,
      sourceMethod: 'Modelo conservador por tier (sin historial)',
    ),
    // Pera (doc 03 §10.4): tabla mínima por tier para la pantalla simple. La
    // referencia agronómica completa vive en pear_tree_yield_reference.dart.
    'pear_tree_pr_skip_young': TreeYieldReference(
      id: 'pear_tree_pr_skip_young',
      cropId: kCropPearTree,
      profileId: kPrSkip,
      tier: TreeProductiveTier.young,
      kgPerTreeLow: 3,
      kgPerTreeHigh: 12,
      confidence: YieldDataConfidence.modeled,
      sourceMethod: 'Modelo conservador por tier (sin historial)',
    ),
    'pear_tree_pr_skip_first': TreeYieldReference(
      id: 'pear_tree_pr_skip_first',
      cropId: kCropPearTree,
      profileId: kPrSkip,
      tier: TreeProductiveTier.firstProduction,
      kgPerTreeLow: 8,
      kgPerTreeHigh: 28,
      confidence: YieldDataConfidence.modeled,
      sourceMethod: 'Modelo conservador por tier (sin historial)',
    ),
    'pear_tree_pr_skip_full': TreeYieldReference(
      id: 'pear_tree_pr_skip_full',
      cropId: kCropPearTree,
      profileId: kPrSkip,
      tier: TreeProductiveTier.full,
      kgPerTreeLow: 25,
      kgPerTreeHigh: 70,
      confidence: YieldDataConfidence.modeled,
      sourceMethod: 'Modelo conservador por tier (sin historial)',
    ),
    // Durazno (doc 03 §10.4): tabla mínima por tier para la pantalla simple. La
    // referencia agronómica completa vive en peach_tree_yield_reference.dart.
    'peach_tree_dz_skip_young': TreeYieldReference(
      id: 'peach_tree_dz_skip_young',
      cropId: kCropPeachTree,
      profileId: kDzSkip,
      tier: TreeProductiveTier.young,
      kgPerTreeLow: 4,
      kgPerTreeHigh: 15,
      confidence: YieldDataConfidence.modeled,
      sourceMethod: 'Modelo conservador por tier (sin historial)',
    ),
    'peach_tree_dz_skip_first': TreeYieldReference(
      id: 'peach_tree_dz_skip_first',
      cropId: kCropPeachTree,
      profileId: kDzSkip,
      tier: TreeProductiveTier.firstProduction,
      kgPerTreeLow: 10,
      kgPerTreeHigh: 28,
      confidence: YieldDataConfidence.modeled,
      sourceMethod: 'Modelo conservador por tier (sin historial)',
    ),
    'peach_tree_dz_skip_full': TreeYieldReference(
      id: 'peach_tree_dz_skip_full',
      cropId: kCropPeachTree,
      profileId: kDzSkip,
      tier: TreeProductiveTier.full,
      kgPerTreeLow: 18,
      kgPerTreeHigh: 45,
      confidence: YieldDataConfidence.modeled,
      sourceMethod: 'Modelo conservador por tier (sin historial)',
    ),
    // Nogal pecanero (doc 03 §11): tabla minima por tier para la pantalla simple
    // (kg de nuez con cascara/arbol). La referencia agronomica completa vive en
    // walnut_tree_yield_reference.dart.
    'walnut_tree_ng_skip_young': TreeYieldReference(
      id: 'walnut_tree_ng_skip_young',
      cropId: kCropWalnutTree,
      profileId: kNgSkip,
      tier: TreeProductiveTier.young,
      kgPerTreeLow: 2,
      kgPerTreeHigh: 10,
      confidence: YieldDataConfidence.modeled,
      sourceMethod: 'Modelo conservador por tier (nogal pecanero, sin historial)',
    ),
    'walnut_tree_ng_skip_first': TreeYieldReference(
      id: 'walnut_tree_ng_skip_first',
      cropId: kCropWalnutTree,
      profileId: kNgSkip,
      tier: TreeProductiveTier.firstProduction,
      kgPerTreeLow: 6,
      kgPerTreeHigh: 22,
      confidence: YieldDataConfidence.modeled,
      sourceMethod: 'Modelo conservador por tier (nogal pecanero, sin historial)',
    ),
    'walnut_tree_ng_skip_full': TreeYieldReference(
      id: 'walnut_tree_ng_skip_full',
      cropId: kCropWalnutTree,
      profileId: kNgSkip,
      tier: TreeProductiveTier.full,
      kgPerTreeLow: 15,
      kgPerTreeHigh: 45,
      confidence: YieldDataConfidence.modeled,
      sourceMethod: 'Modelo conservador por tier (nogal pecanero, sin historial)',
    ),

    // Pistache (doc 03 §12): tabla minima por tier para la pantalla simple
    // (kg de pistache seco con cascara/arbol promedio del huerto; incluye
    // dilucion conservadora por machos cuando el usuario captura arboles
    // totales). La referencia agronomica completa vive en
    // pistachio_tree_yield_reference.dart.
    'pistachio_tree_ps_skip_young': TreeYieldReference(
      id: 'pistachio_tree_ps_skip_young',
      cropId: kCropPistachioTree,
      profileId: kPsSkip,
      tier: TreeProductiveTier.young,
      kgPerTreeLow: 0.5,
      kgPerTreeHigh: 4,
      confidence: YieldDataConfidence.modeled,
      sourceMethod: 'Modelo conservador por tier (pistache, sin historial)',
    ),
    'pistachio_tree_ps_skip_first': TreeYieldReference(
      id: 'pistachio_tree_ps_skip_first',
      cropId: kCropPistachioTree,
      profileId: kPsSkip,
      tier: TreeProductiveTier.firstProduction,
      kgPerTreeLow: 2,
      kgPerTreeHigh: 8,
      confidence: YieldDataConfidence.modeled,
      sourceMethod: 'Modelo conservador por tier (pistache, sin historial)',
    ),
    'pistachio_tree_ps_skip_full': TreeYieldReference(
      id: 'pistachio_tree_ps_skip_full',
      cropId: kCropPistachioTree,
      profileId: kPsSkip,
      tier: TreeProductiveTier.full,
      kgPerTreeLow: 6,
      kgPerTreeHigh: 18,
      confidence: YieldDataConfidence.modeled,
      sourceMethod: 'Modelo conservador por tier (pistache, sin historial)',
    ),

    // Naranjo (doc 03 §11): tabla minima por tier para la pantalla simple (kg de
    // naranja fresca/arbol). La referencia agronomica completa vive en
    // orange_tree_yield_reference.dart.
    'orange_tree_or_skip_young': TreeYieldReference(
      id: 'orange_tree_or_skip_young',
      cropId: kCropOrangeTree,
      profileId: kOrSkip,
      tier: TreeProductiveTier.young,
      kgPerTreeLow: 5,
      kgPerTreeHigh: 20,
      confidence: YieldDataConfidence.modeled,
      sourceMethod: 'Modelo conservador por tier (naranjo, sin historial)',
    ),
    'orange_tree_or_skip_first': TreeYieldReference(
      id: 'orange_tree_or_skip_first',
      cropId: kCropOrangeTree,
      profileId: kOrSkip,
      tier: TreeProductiveTier.firstProduction,
      kgPerTreeLow: 15,
      kgPerTreeHigh: 45,
      confidence: YieldDataConfidence.modeled,
      sourceMethod: 'Modelo conservador por tier (naranjo, sin historial)',
    ),
    'orange_tree_or_skip_full': TreeYieldReference(
      id: 'orange_tree_or_skip_full',
      cropId: kCropOrangeTree,
      profileId: kOrSkip,
      tier: TreeProductiveTier.full,
      kgPerTreeLow: 35,
      kgPerTreeHigh: 85,
      confidence: YieldDataConfidence.modeled,
      sourceMethod: 'Modelo conservador por tier (naranjo, sin historial)',
    ),

    // Limón (doc 03 §15): tabla minima por tier para la pantalla simple (kg de
    // limón fresco/arbol). La referencia agronomica completa vive en
    // lemon_tree_yield_reference.dart. NO hereda kg/arbol del naranjo.
    'lemon_tree_lm_skip_young': TreeYieldReference(
      id: 'lemon_tree_lm_skip_young',
      cropId: kCropLemonTree,
      profileId: kLmSkip,
      tier: TreeProductiveTier.young,
      kgPerTreeLow: 3,
      kgPerTreeHigh: 15,
      confidence: YieldDataConfidence.modeled,
      sourceMethod: 'Modelo conservador por tier (limón, sin historial)',
    ),
    'lemon_tree_lm_skip_first': TreeYieldReference(
      id: 'lemon_tree_lm_skip_first',
      cropId: kCropLemonTree,
      profileId: kLmSkip,
      tier: TreeProductiveTier.firstProduction,
      kgPerTreeLow: 8,
      kgPerTreeHigh: 30,
      confidence: YieldDataConfidence.modeled,
      sourceMethod: 'Modelo conservador por tier (limón, sin historial)',
    ),
    'lemon_tree_lm_skip_full': TreeYieldReference(
      id: 'lemon_tree_lm_skip_full',
      cropId: kCropLemonTree,
      profileId: kLmSkip,
      tier: TreeProductiveTier.full,
      kgPerTreeLow: 20,
      kgPerTreeHigh: 70,
      confidence: YieldDataConfidence.modeled,
      sourceMethod: 'Modelo conservador por tier (limón, sin historial)',
    ),

    // Mango (doc 03 §15): tabla minima por tier para la pantalla simple (kg de
    // mango fresco/arbol). La referencia agronomica completa (perfiles,
    // densidad, alternancia, calidad) vive en mango_tree_yield_reference.dart. NO
    // hereda kg/arbol de limón/naranjo/manzano.
    'mango_tree_mg_skip_first': TreeYieldReference(
      id: 'mango_tree_mg_skip_first',
      cropId: kCropMangoTree,
      profileId: kMgSkip,
      tier: TreeProductiveTier.firstProduction,
      kgPerTreeLow: 2,
      kgPerTreeHigh: 20,
      confidence: YieldDataConfidence.modeled,
      sourceMethod: 'Modelo conservador por tier (mango, sin historial)',
    ),
    'mango_tree_mg_skip_young': TreeYieldReference(
      id: 'mango_tree_mg_skip_young',
      cropId: kCropMangoTree,
      profileId: kMgSkip,
      tier: TreeProductiveTier.young,
      kgPerTreeLow: 10,
      kgPerTreeHigh: 55,
      confidence: YieldDataConfidence.modeled,
      sourceMethod: 'Modelo conservador por tier (mango, sin historial)',
    ),
    'mango_tree_mg_skip_full': TreeYieldReference(
      id: 'mango_tree_mg_skip_full',
      cropId: kCropMangoTree,
      profileId: kMgSkip,
      tier: TreeProductiveTier.full,
      kgPerTreeLow: 18,
      kgPerTreeHigh: 90,
      confidence: YieldDataConfidence.modeled,
      sourceMethod: 'Modelo conservador por tier (mango, sin historial)',
    ),

    // Aguacate (doc 03 §12): tabla minima por tier para la pantalla simple (kg
    // de aguacate fresco/arbol). La referencia agronomica completa (perfiles,
    // densidad, alternancia, floracion A/B, calidad) vive en
    // avocado_tree_yield_reference.dart. NO hereda kg/arbol de mango/limón/
    // naranjo/manzano.
    'avocado_tree_ag_skip_young': TreeYieldReference(
      id: 'avocado_tree_ag_skip_young',
      cropId: kCropAvocadoTree,
      profileId: kAgSkip,
      tier: TreeProductiveTier.young,
      kgPerTreeLow: 2,
      kgPerTreeHigh: 10,
      confidence: YieldDataConfidence.modeled,
      sourceMethod: 'Modelo conservador por tier (aguacate, sin historial)',
    ),
    'avocado_tree_ag_skip_first': TreeYieldReference(
      id: 'avocado_tree_ag_skip_first',
      cropId: kCropAvocadoTree,
      profileId: kAgSkip,
      tier: TreeProductiveTier.firstProduction,
      kgPerTreeLow: 6,
      kgPerTreeHigh: 25,
      confidence: YieldDataConfidence.modeled,
      sourceMethod: 'Modelo conservador por tier (aguacate, sin historial)',
    ),
    'avocado_tree_ag_skip_full': TreeYieldReference(
      id: 'avocado_tree_ag_skip_full',
      cropId: kCropAvocadoTree,
      profileId: kAgSkip,
      tier: TreeProductiveTier.full,
      kgPerTreeLow: 18,
      kgPerTreeHigh: 75,
      confidence: YieldDataConfidence.modeled,
      sourceMethod: 'Modelo conservador por tier (aguacate, sin historial)',
    ),
  };

  /// Perfil SKIP/general de cada árbol, para el fallback por cultivo. Evita que
  /// la pera caiga al fallback del manzano (doc 03 §0.1, §13).
  static String? _skipProfileForCrop(String cropId) {
    switch (cropId) {
      case kCropAppleTree:
        return kApSkip;
      case kCropPearTree:
        return kPrSkip;
      case kCropPeachTree:
        return kDzSkip;
      case kCropWalnutTree:
        return kNgSkip;
      case kCropPistachioTree:
        return kPsSkip;
      case kCropOrangeTree:
        return kOrSkip;
      case kCropLemonTree:
        return kLmSkip;
      case kCropMangoTree:
        return kMgSkip;
      case kCropAvocadoTree:
        return kAgSkip;
      default:
        return null;
    }
  }

  /// Devuelve la referencia para `(cropId, profileId, tier)`. Si no hay una
  /// entrada específica del perfil, cae al perfil general conservador (AP-SKIP).
  /// Devuelve `null` si el cultivo no tiene tabla de árbol.
  static TreeYieldReference? referenceFor({
    required String cropId,
    String? profileId,
    required TreeProductiveTier tier,
  }) {
    final normalizedCrop = cropId.trim().toLowerCase();
    final normalizedProfile = profileId?.trim().toLowerCase();
    // Fallback al SKIP del MISMO cultivo (la pera nunca cae al de manzano).
    final skipProfile = _skipProfileForCrop(normalizedCrop);

    TreeYieldReference? match;
    TreeYieldReference? skipFallback;

    for (final ref in byId.values) {
      if (ref.cropId != normalizedCrop || ref.tier != tier) continue;
      if (ref.profileId == normalizedProfile) {
        match = ref;
      }
      if (ref.profileId == skipProfile) {
        skipFallback = ref;
      }
    }

    return match ?? skipFallback;
  }

  /// Mapea el estado perenne visible a un tier productivo. Los estados que aún
  /// no producen devuelven `null`: BIO-G SKIPea la proyección (conservador).
  static TreeProductiveTier? tierForPerennialState(String? perennialStateId) {
    switch (normalizeTreeStateId(perennialStateId)) {
      case TreeStateIds.established:
        return TreeProductiveTier.firstProduction;
      case TreeStateIds.productiveSeason:
        return TreeProductiveTier.full;
      // newly_planted / juvenile_non_productive / unknown: aún no produce.
      default:
        return null;
    }
  }

  /// Estima el rendimiento total = kg/árbol × número de árboles. Devuelve `null`
  /// si no hay tabla aplicable o si el número de árboles no es positivo. La
  /// confianza heredada es siempre baja (`modeled`).
  static TreeYieldEstimate? estimateTotalKg({
    required String cropId,
    String? profileId,
    required TreeProductiveTier tier,
    required int treeCount,
  }) {
    if (treeCount <= 0) return null;

    final ref = referenceFor(cropId: cropId, profileId: profileId, tier: tier);
    if (ref == null) return null;

    return TreeYieldEstimate(
      kgLow: ref.kgPerTreeLow * treeCount,
      kgHigh: ref.kgPerTreeHigh * treeCount,
      treeCount: treeCount,
      tier: tier,
      confidence: ref.confidence,
      sourceMethod: ref.sourceMethod,
    );
  }
}
