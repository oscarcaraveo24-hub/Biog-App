import 'package:bio_g/core/crops/apple_tree/apple_tree_catalog.dart';
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
  };

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

    TreeYieldReference? match;
    TreeYieldReference? skipFallback;

    for (final ref in byId.values) {
      if (ref.cropId != normalizedCrop || ref.tier != tier) continue;
      if (ref.profileId == normalizedProfile) {
        match = ref;
      }
      if (ref.profileId == kApSkip) {
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
