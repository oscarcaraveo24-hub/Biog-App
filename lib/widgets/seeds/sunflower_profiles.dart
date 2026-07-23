// lib/widgets/seeds/sunflower_profiles.dart
//
// Perfiles oficiales del Girasol (Documento A §5, §6, §11). Cuatro tipos
// funcionales + el perfil general `gi_skip`, que SIEMPRE va al final de la lista
// y NUNCA muestra su id interno al usuario (Documento A §6.5, §13.1).
//
// Cada perfil guarda su CALENDARIO como límites de FIN de etapa (día absoluto
// desde la fecha ancla / siembra). Las bandas son las ventanas nominales del
// Documento A §11: son defaults operativos de ingeniería, NO una promesa
// biológica exacta (§11.1, §11.8). Un perfil existe solo si cambia porte,
// ramificación, contenedor, duración floral o forma de terminar (§5.1); nunca
// por color de flor.

import 'package:bio_g/widgets/seeds/maize_models.dart';
import 'package:bio_g/widgets/seeds/sunflower_models.dart';

// ─── IDs canónicos (Documento A §0.2, §4.1) ──────────────────────────────────

const String kGi01TallGarden = 'gi_01_tall_garden';
const String kGi02CompactContainer = 'gi_02_compact_container';
const String kGi03BranchingOrnamental = 'gi_03_branching_ornamental';
const String kGi04CutFlowerSingleStem = 'gi_04_cut_flower_single_stem';
const String kGiSkip = 'gi_skip';

const String kSunflowerProfilePrefix = 'GI';

// ─── Perfiles ─────────────────────────────────────────────────────────────────

const Map<String, SunflowerProfile> sunflowerProfiles =
    <String, SunflowerProfile>{
      // ── Girasol alto de jardín (Documento A §6.1, §11.2) ──────────────────
      // Porte alto, flor dominante, tallo largo y posible soporte. Ventana
      // completa ~120 d.
      kGi01TallGarden: SunflowerProfile(
        id: kGi01TallGarden,
        label: 'Girasol alto de jardín',
        useType: 'ornamental',
        sunflowerUseType: SunflowerUseType.tallGarden,
        defaultEstablishmentMode: SunflowerEstablishmentMode.directSowing,
        sowingEndDay: 0,
        germinationEndDay: 8,
        emergenceEndDay: 14,
        earlyVegetativeEndDay: 27,
        activeVegetativeEndDay: 44,
        stemElongationEndDay: 57,
        budFormationEndDay: 69,
        floweringEndDay: 82,
        postBloomEndDay: 100,
        senescenceEndDay: 119,
        floweringWindowDays: RangeInt(70, 82),
        transplantAgeOffsetDays: 21,
      ),

      // ── Girasol compacto para maceta (Documento A §6.2, §11.3) ────────────
      // Porte bajo, raíz restringida por contenedor, ciclo más corto ~95 d.
      kGi02CompactContainer: SunflowerProfile(
        id: kGi02CompactContainer,
        label: 'Girasol compacto para maceta',
        useType: 'ornamental',
        sunflowerUseType: SunflowerUseType.compactContainer,
        defaultEstablishmentMode: SunflowerEstablishmentMode.directSowing,
        sowingEndDay: 0,
        germinationEndDay: 7,
        emergenceEndDay: 12,
        earlyVegetativeEndDay: 22,
        activeVegetativeEndDay: 34,
        stemElongationEndDay: 42,
        budFormationEndDay: 51,
        floweringEndDay: 66,
        postBloomEndDay: 80,
        senescenceEndDay: 94,
        floweringWindowDays: RangeInt(52, 66),
        transplantAgeOffsetDays: 18,
      ),

      // ── Girasol ramificado ornamental (Documento A §6.3, §11.4) ───────────
      // Varias flores, apertura escalonada, floración prolongada (70–99). No
      // reinicia por cada rama ni cierra por una cabeza envejecida.
      kGi03BranchingOrnamental: SunflowerProfile(
        id: kGi03BranchingOrnamental,
        label: 'Girasol ramificado ornamental',
        useType: 'ornamental',
        sunflowerUseType: SunflowerUseType.branchingOrnamental,
        defaultEstablishmentMode: SunflowerEstablishmentMode.directSowing,
        sowingEndDay: 0,
        germinationEndDay: 8,
        emergenceEndDay: 14,
        earlyVegetativeEndDay: 28,
        activeVegetativeEndDay: 46,
        stemElongationEndDay: 58,
        budFormationEndDay: 69,
        floweringEndDay: 99,
        postBloomEndDay: 114,
        senescenceEndDay: 134,
        floweringWindowDays: RangeInt(70, 99),
        transplantAgeOffsetDays: 21,
      ),

      // ── Girasol de corte de tallo único (Documento A §6.4, §11.5) ─────────
      // Una flor por tallo, ciclo corto ~91 d, terminación por corte explícito.
      kGi04CutFlowerSingleStem: SunflowerProfile(
        id: kGi04CutFlowerSingleStem,
        label: 'Girasol de corte de tallo único',
        useType: 'ornamental',
        sunflowerUseType: SunflowerUseType.cutFlowerSingleStem,
        defaultEstablishmentMode: SunflowerEstablishmentMode.directSowing,
        sowingEndDay: 0,
        germinationEndDay: 7,
        emergenceEndDay: 12,
        earlyVegetativeEndDay: 22,
        activeVegetativeEndDay: 34,
        stemElongationEndDay: 43,
        budFormationEndDay: 52,
        floweringEndDay: 65,
        postBloomEndDay: 76,
        senescenceEndDay: 90,
        floweringWindowDays: RangeInt(53, 65),
        transplantAgeOffsetDays: 21,
        supportsCutTermination: true,
      ),

      // ── No sé / Girasol general ───────────────────────────────────────────
      // SIEMPRE al final (Documento A §6.5, §13.1). Calendario medio y
      // conservador (~113 d). El usuario puede precisar el tipo después sin
      // perder historial.
      kGiSkip: SunflowerProfile(
        id: kGiSkip,
        label: 'No sé / Girasol general',
        useType: 'ornamental',
        sunflowerUseType: SunflowerUseType.generic,
        defaultEstablishmentMode: SunflowerEstablishmentMode.unknown,
        sowingEndDay: 0,
        germinationEndDay: 8,
        emergenceEndDay: 14,
        earlyVegetativeEndDay: 27,
        activeVegetativeEndDay: 42,
        stemElongationEndDay: 52,
        budFormationEndDay: 63,
        floweringEndDay: 78,
        postBloomEndDay: 94,
        senescenceEndDay: 112,
        floweringWindowDays: RangeInt(64, 78),
        transplantAgeOffsetDays: 21,
      ),
    };

/// Orden de presentación en el wizard (Documento A §13.1): tipos concretos
/// primero, `gi_skip` SIEMPRE al final.
const List<String> sunflowerProfileOrder = <String>[
  kGi01TallGarden,
  kGi02CompactContainer,
  kGi03BranchingOrnamental,
  kGi04CutFlowerSingleStem,
  kGiSkip,
];

// ─── Alias → ID canónico (Documento A §6, §7.4) ──────────────────────────────
//
// Incluye la migración de los perfiles legacy GS-* (§7.4). GS-05 (semilla/
// aceite) NO se migra: exige nueva selección explícita (§7.4, §18.2).

const Map<String, String> _sunflowerProfileAliasToCanonical =
    <String, String>{
      // Legacy GI-0x / gi0x.
      'gi-01': kGi01TallGarden,
      'gi01': kGi01TallGarden,
      'gi-02': kGi02CompactContainer,
      'gi02': kGi02CompactContainer,
      'gi-03': kGi03BranchingOrnamental,
      'gi03': kGi03BranchingOrnamental,
      'gi-04': kGi04CutFlowerSingleStem,
      'gi04': kGi04CutFlowerSingleStem,
      'gi-skip': kGiSkip,
      'giskip': kGiSkip,
      'gi-gen': kGiSkip,
      'gi_gen': kGiSkip,

      // Migración de fichas anteriores GS-* (Documento A §7.4).
      'gs-skip': kGiSkip,
      'gs_skip': kGiSkip,
      'gs-01': kGi04CutFlowerSingleStem,
      'gs_01': kGi04CutFlowerSingleStem,
      'gs-02': kGi03BranchingOrnamental,
      'gs_02': kGi03BranchingOrnamental,
      'gs-03': kGi02CompactContainer,
      'gs_03': kGi02CompactContainer,
      'gs-04': kGi01TallGarden,
      'gs_04': kGi01TallGarden,

      // gi_01 alto de jardín (Documento A §6.1).
      'girasol alto de jardin': kGi01TallGarden,
      'girasol alto de jardín': kGi01TallGarden,
      'girasol alto': kGi01TallGarden,
      'girasol gigante': kGi01TallGarden,
      'girasol de jardin': kGi01TallGarden,
      'girasol mammoth': kGi01TallGarden,
      'mammoth': kGi01TallGarden,
      'russian mammoth': kGi01TallGarden,
      'american giant': kGi01TallGarden,
      'kong': kGi01TallGarden,
      'skyscraper': kGi01TallGarden,
      'titan': kGi01TallGarden,
      'girasol cabeza grande': kGi01TallGarden,

      // gi_02 compacto para maceta (Documento A §6.2).
      'girasol compacto para maceta': kGi02CompactContainer,
      'girasol enano': kGi02CompactContainer,
      'girasol compacto': kGi02CompactContainer,
      'girasol mini': kGi02CompactContainer,
      'girasol para maceta': kGi02CompactContainer,
      'dwarf sunflower': kGi02CompactContainer,
      'sunspot': kGi02CompactContainer,
      'teddy bear': kGi02CompactContainer,
      'big smile': kGi02CompactContainer,
      'pacino': kGi02CompactContainer,
      'ballad': kGi02CompactContainer,
      'miss sunshine': kGi02CompactContainer,
      'little becka': kGi02CompactContainer,

      // gi_03 ramificado ornamental (Documento A §6.3).
      'girasol ramificado ornamental': kGi03BranchingOrnamental,
      'girasol ramificado': kGi03BranchingOrnamental,
      'girasol multirama': kGi03BranchingOrnamental,
      'girasol multiflor': kGi03BranchingOrnamental,
      'girasol bouquet': kGi03BranchingOrnamental,
      'branching sunflower': kGi03BranchingOrnamental,
      'cut and come again': kGi03BranchingOrnamental,
      'autumn beauty': kGi03BranchingOrnamental,
      'belleza de otoño': kGi03BranchingOrnamental,
      'belleza de otono': kGi03BranchingOrnamental,
      'soraya': kGi03BranchingOrnamental,
      'moulin rouge': kGi03BranchingOrnamental,
      'florenza': kGi03BranchingOrnamental,
      'lemon queen': kGi03BranchingOrnamental,
      'velvet queen': kGi03BranchingOrnamental,
      'ruby eclipse': kGi03BranchingOrnamental,
      'sonja': kGi03BranchingOrnamental,

      // gi_04 corte de tallo único (Documento A §6.4).
      'girasol de corte de tallo unico': kGi04CutFlowerSingleStem,
      'girasol de corte de tallo único': kGi04CutFlowerSingleStem,
      'girasol de corte': kGi04CutFlowerSingleStem,
      'flor de corte': kGi04CutFlowerSingleStem,
      'girasol unifloral': kGi04CutFlowerSingleStem,
      'girasol de tallo unico': kGi04CutFlowerSingleStem,
      'girasol de tallo único': kGi04CutFlowerSingleStem,
      'single stem sunflower': kGi04CutFlowerSingleStem,
      'pollenless': kGi04CutFlowerSingleStem,
      'sin polen': kGi04CutFlowerSingleStem,
      'procut': kGi04CutFlowerSingleStem,
      'sunrich': kGi04CutFlowerSingleStem,
      'vincent': kGi04CutFlowerSingleStem,
      'sunbright': kGi04CutFlowerSingleStem,
      'premier': kGi04CutFlowerSingleStem,
      'helios': kGi04CutFlowerSingleStem,

      // gi_skip general (Documento A §6.5).
      'girasol': kGiSkip,
      'girasol comun': kGiSkip,
      'girasol común': kGiSkip,
      'girasol general': kGiSkip,
      'semilla de girasol generica': kGiSkip,
      'semilla de girasol genérica': kGiSkip,
      'no se que girasol es': kGiSkip,
      'no sé qué girasol es': kGiSkip,
      'mirasol': kGiSkip,
      'flor de sol': kGiSkip,
    };

/// Resuelve el ID canónico del perfil de Girasol a partir de texto libre.
String? resolveCanonicalSunflowerProfileId(String raw) {
  final normalized = raw.trim().toLowerCase();
  if (normalized.isEmpty) return null;
  if (sunflowerProfiles.containsKey(normalized)) return normalized;
  return _sunflowerProfileAliasToCanonical[normalized];
}
