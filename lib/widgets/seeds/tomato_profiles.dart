import 'package:bio_g/widgets/seeds/maize_models.dart';
import 'package:bio_g/widgets/seeds/tomato_models.dart';

const String kTm01 = 'tm_01';
const String kTm02 = 'tm_02';
const String kTm03 = 'tm_03';
const String kTm04 = 'tm_04';
const String kTm05 = 'tm_05';
const String kTmGen = 'tm_gen';

/// Perfiles oficiales TM-01..TM-05 + TM-GEN.
///
/// Datos derivados del Perfil Universal Tomate v2, Perfil Genérico
/// Tomate TM-GEN v2 y Guía Universal de Fertilización de Tomate v2.
/// Los días (flowering/harvest/end) están anclados a DDT
/// (Días Después de Trasplante) salvo que el usuario elija siembra directa
/// en onboarding, en cuyo caso el engine aplica un offset automático.
const Map<String, TomatoProfile> tomatoProfiles = {
  // ───────────────────────────────────────────────────────────────────
  // TM-01 · Saladette campo abierto
  // Determinado; ciclo corto-medio; procesamiento o fresco.
  // ───────────────────────────────────────────────────────────────────
  kTm01: TomatoProfile(
    id: kTm01,
    label: 'TM-01 · Saladette campo abierto',
    useType: 'Fresco / proceso',
    marketType: TomatoMarketType.saladette,
    tomatoUseType: TomatoUseType.fresh,
    defaultEstablishmentMode: TomatoEstablishmentMode.transplant,
    floweringDays: RangeInt(28, 38),
    harvestStartDays: RangeInt(65, 80),
    endWindowDays: RangeInt(115, 140),
    endActionLabel: 'Cierre de cosecha',
    plantHeightM: RangeDouble(0.80, 1.20),
    densityPlantsPerHa: RangeInt(20000, 30000),
    referenceYieldTHa: RangeDouble(45, 80),
  ),

  // ───────────────────────────────────────────────────────────────────
  // TM-02 · Saladette protegido (malla/invernadero básico, en suelo)
  // Determinado/semideterminado; ciclo medio-largo.
  // ───────────────────────────────────────────────────────────────────
  kTm02: TomatoProfile(
    id: kTm02,
    label: 'TM-02 · Saladette protegido',
    useType: 'Fresco',
    marketType: TomatoMarketType.saladette,
    tomatoUseType: TomatoUseType.fresh,
    defaultEstablishmentMode: TomatoEstablishmentMode.transplant,
    floweringDays: RangeInt(30, 42),
    harvestStartDays: RangeInt(70, 90),
    endWindowDays: RangeInt(160, 210),
    endActionLabel: 'Cierre de ciclo',
    plantHeightM: RangeDouble(1.40, 2.20),
    densityPlantsPerHa: RangeInt(22000, 28000),
    referenceYieldTHa: RangeDouble(90, 160),
  ),

  // ───────────────────────────────────────────────────────────────────
  // TM-03 · Bola (redondo grande), protegido en suelo o campo abierto alto
  // Indeterminado; ciclo largo.
  // ───────────────────────────────────────────────────────────────────
  kTm03: TomatoProfile(
    id: kTm03,
    label: 'TM-03 · Bola',
    useType: 'Fresco',
    marketType: TomatoMarketType.bola,
    tomatoUseType: TomatoUseType.fresh,
    defaultEstablishmentMode: TomatoEstablishmentMode.transplant,
    floweringDays: RangeInt(32, 45),
    harvestStartDays: RangeInt(75, 95),
    endWindowDays: RangeInt(180, 230),
    endActionLabel: 'Cierre de ciclo',
    plantHeightM: RangeDouble(1.60, 2.40),
    densityPlantsPerHa: RangeInt(18000, 24000),
    referenceYieldTHa: RangeDouble(100, 180),
  ),

  // ───────────────────────────────────────────────────────────────────
  // TM-04 · Cherry / uva (protegido en suelo)
  // Indeterminado; ciclo largo; racimos pequeños.
  // ───────────────────────────────────────────────────────────────────
  kTm04: TomatoProfile(
    id: kTm04,
    label: 'TM-04 · Cherry / uva',
    useType: 'Fresco',
    marketType: TomatoMarketType.cherry,
    tomatoUseType: TomatoUseType.fresh,
    defaultEstablishmentMode: TomatoEstablishmentMode.transplant,
    floweringDays: RangeInt(28, 40),
    harvestStartDays: RangeInt(65, 85),
    endWindowDays: RangeInt(170, 220),
    endActionLabel: 'Cierre de ciclo',
    plantHeightM: RangeDouble(1.80, 2.60),
    densityPlantsPerHa: RangeInt(20000, 28000),
    referenceYieldTHa: RangeDouble(60, 110),
  ),

  // ───────────────────────────────────────────────────────────────────
  // TM-05 · TOV (racimo comercial), protegido en suelo
  // Indeterminado; ciclo largo; racimos uniformes.
  // ───────────────────────────────────────────────────────────────────
  kTm05: TomatoProfile(
    id: kTm05,
    label: 'TM-05 · TOV (racimo)',
    useType: 'Fresco',
    marketType: TomatoMarketType.tov,
    tomatoUseType: TomatoUseType.fresh,
    defaultEstablishmentMode: TomatoEstablishmentMode.transplant,
    floweringDays: RangeInt(30, 42),
    harvestStartDays: RangeInt(70, 90),
    endWindowDays: RangeInt(175, 225),
    endActionLabel: 'Cierre de ciclo',
    plantHeightM: RangeDouble(1.80, 2.60),
    densityPlantsPerHa: RangeInt(20000, 26000),
    referenceYieldTHa: RangeDouble(95, 160),
  ),

  // ───────────────────────────────────────────────────────────────────
  // TM-GEN · Genérico (skip obligatorio, migrable a TM-01..TM-05)
  // ───────────────────────────────────────────────────────────────────
  kTmGen: TomatoProfile(
    id: kTmGen,
    label: 'TM-GEN · Genérico',
    useType: 'Fresco (genérico)',
    marketType: TomatoMarketType.generic,
    tomatoUseType: TomatoUseType.fresh,
    defaultEstablishmentMode: TomatoEstablishmentMode.transplant,
    floweringDays: RangeInt(30, 42),
    harvestStartDays: RangeInt(70, 90),
    endWindowDays: RangeInt(150, 190),
    endActionLabel: 'Cierre de ciclo',
    plantHeightM: RangeDouble(1.20, 1.80),
    densityPlantsPerHa: RangeInt(20000, 26000),
    referenceYieldTHa: RangeDouble(60, 110),
    isGenericProfile: true,
  ),
};

const Map<String, String> _tomatoProfileAliasToCanonical = {
  'tm-01': kTm01,
  'tm01': kTm01,
  'saladette campo abierto': kTm01,
  'saladette ca': kTm01,
  'roma': kTm01,
  'pera': kTm01,

  'tm-02': kTm02,
  'tm02': kTm02,
  'saladette protegido': kTm02,
  'saladette invernadero': kTm02,
  'saladette malla': kTm02,

  'tm-03': kTm03,
  'tm03': kTm03,
  'bola': kTm03,
  'tomate bola': kTm03,
  'redondo': kTm03,
  'beef': kTm03,

  'tm-04': kTm04,
  'tm04': kTm04,
  'cherry': kTm04,
  'tomate cherry': kTm04,
  'uva': kTm04,
  'grape': kTm04,

  'tm-05': kTm05,
  'tm05': kTm05,
  'tov': kTm05,
  'racimo': kTm05,
  'truss on the vine': kTm05,

  'tm-gen': kTmGen,
  'tmgen': kTmGen,
  'tm_gen': kTmGen,
  'generico': kTmGen,
  'genérico': kTmGen,
  'generic': kTmGen,
  'tomate generico': kTmGen,
  'tomate genérico': kTmGen,
};

String? resolveCanonicalTomatoProfileId(String raw) {
  final normalized = raw.trim().toLowerCase();
  if (normalized.isEmpty) return null;
  if (tomatoProfiles.containsKey(normalized)) return normalized;
  return _tomatoProfileAliasToCanonical[normalized];
}
