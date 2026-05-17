import 'package:bio_g/widgets/seeds/maize_models.dart';
import 'package:bio_g/widgets/seeds/squash_models.dart';

const String kCaGen = 'ca_gen';
const String kCa01 = 'ca_01';
const String kCa02 = 'ca_02';
const String kCa03 = 'ca_03';
const String kCa04 = 'ca_04';
const String kCa05 = 'ca_05';
const String kCa06 = 'ca_06';
const String kCa07 = 'ca_07';

/// Perfiles biológicos de calabaza basados en el Perfil Universal v2.
///
/// Las ventanas son rangos calendario (no GDD) calibrados desde fuentes
/// universitarias y guías comerciales (Mid-Atlantic, OSU, MSU, UPR,
/// INIFAP). Los rangos NO sustituyen análisis local; son base segura.
const Map<String, SquashProfile> squashProfiles = {
  // ───────────────────────────────────────────────────────────────────
  // CA-GEN — Calabaza genérica (entrada SKIP, conservadora y migrable).
  // No decide tierno/maduro/pepita. Si el usuario afina, se migra sin
  // reiniciar historial.
  // ───────────────────────────────────────────────────────────────────
  kCaGen: SquashProfile(
    id: kCaGen,
    label: 'CA-GEN - Calabaza genérica',
    useType: 'Fruto genérico flexible',
    marketType: SquashMarketType.generic,
    squashUseType: SquashUseType.flexible,
    defaultEstablishmentMode: SquashEstablishmentMode.seed,
    // Perfil Universal v2: floración 40-60 d, cosecha 60-95 d con
    // extensión a 90-130 d si se permite ruta de fruto maduro.
    floweringDays: RangeInt(40, 60),
    harvestStartDays: RangeInt(60, 95),
    endWindowDays: RangeInt(110, 160),
    endActionLabel: 'Cierre conservador',
    plantHeightM: RangeDouble(0.45, 1.10),
    densityPlantsPerHa: RangeInt(8000, 18000),
    referenceYieldTHa: RangeDouble(15, 28),
    isGenericProfile: true,
  ),

  // CA-01 — Calabacita italiana / zucchini.
  kCa01: SquashProfile(
    id: kCa01,
    label: 'CA-01 - Calabacita italiana / zucchini',
    useType: 'Fruto tierno - cosecha progresiva',
    marketType: SquashMarketType.italianZucchini,
    squashUseType: SquashUseType.fruitTender,
    defaultEstablishmentMode: SquashEstablishmentMode.seed,
    floweringDays: RangeInt(30, 45),
    harvestStartDays: RangeInt(45, 65),
    endWindowDays: RangeInt(85, 130),
    endActionLabel: 'Cierre de cosecha progresiva',
    plantHeightM: RangeDouble(0.40, 0.90),
    densityPlantsPerHa: RangeInt(12000, 25000),
    referenceYieldTHa: RangeDouble(20, 40),
    isContinuousHarvest: true,
  ),

  // CA-02 — Calabacita criolla / huicha / milpa.
  kCa02: SquashProfile(
    id: kCa02,
    label: 'CA-02 - Calabacita criolla / huicha / milpa',
    useType: 'Fruto tierno - sistema mixto',
    marketType: SquashMarketType.criollaMilpa,
    squashUseType: SquashUseType.fruitTender,
    defaultEstablishmentMode: SquashEstablishmentMode.seed,
    floweringDays: RangeInt(35, 55),
    harvestStartDays: RangeInt(55, 80),
    endWindowDays: RangeInt(100, 150),
    endActionLabel: 'Cierre de temporal',
    plantHeightM: RangeDouble(0.40, 1.10),
    densityPlantsPerHa: RangeInt(5000, 15000),
    referenceYieldTHa: RangeDouble(10, 25),
    isContinuousHarvest: true,
    isLongVining: true,
  ),

  // CA-03 — Calabacita de bola / redonda.
  kCa03: SquashProfile(
    id: kCa03,
    label: 'CA-03 - Calabacita de bola / redonda',
    useType: 'Fruto tierno - cosecha progresiva',
    marketType: SquashMarketType.ballRound,
    squashUseType: SquashUseType.fruitTender,
    defaultEstablishmentMode: SquashEstablishmentMode.seed,
    floweringDays: RangeInt(30, 45),
    harvestStartDays: RangeInt(45, 65),
    endWindowDays: RangeInt(85, 130),
    endActionLabel: 'Cierre de cosecha progresiva',
    plantHeightM: RangeDouble(0.40, 0.90),
    densityPlantsPerHa: RangeInt(12000, 25000),
    referenceYieldTHa: RangeDouble(18, 36),
    isContinuousHarvest: true,
  ),

  // CA-04 — Calabaza de Castilla / pumpkin mexicano.
  kCa04: SquashProfile(
    id: kCa04,
    label: 'CA-04 - Calabaza de Castilla',
    useType: 'Fruto maduro - cosecha única',
    marketType: SquashMarketType.castillaPumpkin,
    squashUseType: SquashUseType.fruitMature,
    defaultEstablishmentMode: SquashEstablishmentMode.seed,
    floweringDays: RangeInt(45, 70),
    harvestStartDays: RangeInt(90, 120),
    endWindowDays: RangeInt(120, 165),
    endActionLabel: 'Cierre tras cosecha de fruto maduro',
    plantHeightM: RangeDouble(0.40, 0.95),
    densityPlantsPerHa: RangeInt(4000, 10000),
    referenceYieldTHa: RangeDouble(18, 35),
    isLongVining: true,
  ),

  // CA-05 — Butternut / buchona / mantequilla.
  kCa05: SquashProfile(
    id: kCa05,
    label: 'CA-05 - Butternut / buchona / mantequilla',
    useType: 'Fruto maduro - cosecha única',
    marketType: SquashMarketType.butternut,
    squashUseType: SquashUseType.fruitMature,
    defaultEstablishmentMode: SquashEstablishmentMode.seed,
    floweringDays: RangeInt(45, 70),
    harvestStartDays: RangeInt(90, 130),
    endWindowDays: RangeInt(125, 175),
    endActionLabel: 'Cierre tras cosecha y curado',
    plantHeightM: RangeDouble(0.40, 0.95),
    densityPlantsPerHa: RangeInt(4000, 10000),
    referenceYieldTHa: RangeDouble(20, 45),
    isLongVining: true,
  ),

  // CA-06 — Chilacayote.
  kCa06: SquashProfile(
    id: kCa06,
    label: 'CA-06 - Chilacayote',
    useType: 'Fruto maduro - ciclo muy largo',
    marketType: SquashMarketType.chilacayote,
    squashUseType: SquashUseType.fruitMature,
    defaultEstablishmentMode: SquashEstablishmentMode.seed,
    floweringDays: RangeInt(70, 90),
    harvestStartDays: RangeInt(180, 210),
    endWindowDays: RangeInt(200, 260),
    endActionLabel: 'Cierre extendido',
    plantHeightM: RangeDouble(0.40, 1.20),
    densityPlantsPerHa: RangeInt(1000, 4000),
    referenceYieldTHa: RangeDouble(8, 25),
    isLongVining: true,
  ),

  // CA-07 — Pipián / pipiana / pepita (semilla seca por defecto).
  kCa07: SquashProfile(
    id: kCa07,
    label: 'CA-07 - Pipián / pipiana / pepita',
    useType: 'Semilla seca / pepita',
    marketType: SquashMarketType.pipianSeed,
    squashUseType: SquashUseType.seedDry,
    defaultEstablishmentMode: SquashEstablishmentMode.seed,
    floweringDays: RangeInt(45, 70),
    harvestStartDays: RangeInt(110, 160),
    endWindowDays: RangeInt(150, 200),
    endActionLabel: 'Cierre tras secado de semilla',
    plantHeightM: RangeDouble(0.40, 1.10),
    densityPlantsPerHa: RangeInt(3000, 8000),
    referenceYieldTHa: RangeDouble(0.4, 1.2),
    isLongVining: true,
    isSeedFocused: true,
  ),
};

/// Mapa de alias (en lowercase) hacia perfil canónico.
///
/// Cubre la lista completa del Perfil Universal v2 sección 13 más
/// variantes de búsqueda en español/inglés sin acentos. Las claves
/// deben estar en lowercase y el resolver normaliza la entrada.
const Map<String, String> _squashProfileAliasToCanonical = {
  // ───────────────────────────────────────────────────────────────────
  // CA-GEN — Genérico / no sabe / otra calabaza
  // ───────────────────────────────────────────────────────────────────
  'ca-gen': kCaGen,
  'cagen': kCaGen,
  'ca_gen': kCaGen,
  'calabaza': kCaGen,
  'calabaza generica': kCaGen,
  'calabaza genérica': kCaGen,
  'calabaza generico': kCaGen,
  'calabaza genérico': kCaGen,
  'generica calabaza': kCaGen,
  'generic squash': kCaGen,
  'squash': kCaGen,
  'squash generic': kCaGen,
  'squash_generic': kCaGen,
  'pumpkin': kCaGen,
  'zapallo': kCaGen,
  'ayote': kCaGen,
  'auyama': kCaGen,
  'otra calabaza': kCaGen,
  'no se': kCaGen,
  'no sé': kCaGen,
  'skip': kCaGen,
  // En el código v1 NO existe CropKey.pumpkin: el alias 'pumpkin' debe
  // resolverse al cultivo madre y quedar en CA-GEN si no hay tipo.

  // ───────────────────────────────────────────────────────────────────
  // CA-01 — Calabacita italiana / zucchini
  // ───────────────────────────────────────────────────────────────────
  'ca-01': kCa01,
  'ca01': kCa01,
  'ca_01': kCa01,
  'calabacita': kCa01,
  'calabacita italiana': kCa01,
  'italiana': kCa01,
  'zucchini': kCa01,
  'zuccini': kCa01,
  'zucchino': kCa01,
  'calabacin': kCa01,
  'calabacín': kCa01,
  'italiana larga': kCa01,
  'grey zucchini': kCa01,
  'gray zucchini': kCa01,
  'squash italiano': kCa01,
  'summer squash': kCa01,
  'squash_zucchini_field': kCa01,
  'squash_zucchini_protected': kCa01,

  // ───────────────────────────────────────────────────────────────────
  // CA-02 — Criolla / huicha / milpa
  // ───────────────────────────────────────────────────────────────────
  'ca-02': kCa02,
  'ca02': kCa02,
  'ca_02': kCa02,
  'calabacita criolla': kCa02,
  'calabaza criolla': kCa02,
  'criolla': kCa02,
  'huicha': kCa02,
  'güicha': kCa02,
  'guicha': kCa02,
  'milpa': kCa02,
  'calabaza de milpa': kCa02,
  'calabaza de temporal': kCa02,
  'temporal': kCa02,
  'squash_criolla_field': kCa02,

  // ───────────────────────────────────────────────────────────────────
  // CA-03 — Bola / redonda
  // ───────────────────────────────────────────────────────────────────
  'ca-03': kCa03,
  'ca03': kCa03,
  'ca_03': kCa03,
  'calabacita de bola': kCa03,
  'calabacita redonda': kCa03,
  'bola': kCa03,
  'redonda': kCa03,
  'eight ball': kCa03,
  'round zucchini': kCa03,
  'squash_round_field': kCa03,

  // ───────────────────────────────────────────────────────────────────
  // CA-04 — Castilla / pumpkin mexicano
  // ───────────────────────────────────────────────────────────────────
  'ca-04': kCa04,
  'ca04': kCa04,
  'ca_04': kCa04,
  'castilla': kCa04,
  'calabaza de castilla': kCa04,
  'calabaza castilla': kCa04,
  'calabaza para dulce': kCa04,
  'calabaza de altar': kCa04,
  'calabaza madura': kCa04,
  'pumpkin mexicano': kCa04,
  'squash_castilla_mature': kCa04,
  'winter squash': kCa04,

  // ───────────────────────────────────────────────────────────────────
  // CA-05 — Butternut / buchona / mantequilla
  // ───────────────────────────────────────────────────────────────────
  'ca-05': kCa05,
  'ca05': kCa05,
  'ca_05': kCa05,
  'butternut': kCa05,
  'buchona': kCa05,
  'mantequilla': kCa05,
  'cacahuate': kCa05,
  'violin': kCa05,
  'violín': kCa05,
  'squash mantequilla': kCa05,
  'squash_butternut_field': kCa05,
  'squash_butternut_intensive': kCa05,

  // ───────────────────────────────────────────────────────────────────
  // CA-06 — Chilacayote
  // ───────────────────────────────────────────────────────────────────
  'ca-06': kCa06,
  'ca06': kCa06,
  'ca_06': kCa06,
  'chilacayote': kCa06,
  'chilacayota': kCa06,
  'alcayota': kCa06,
  'squash_chilacayote_mature': kCa06,

  // ───────────────────────────────────────────────────────────────────
  // CA-07 — Pipián / pipiana / pepita
  // ───────────────────────────────────────────────────────────────────
  'ca-07': kCa07,
  'ca07': kCa07,
  'ca_07': kCa07,
  'pipian': kCa07,
  'pipián': kCa07,
  'pipiana': kCa07,
  'pepita': kCa07,
  'calabaza pipiana': kCa07,
  'calabaza para semilla': kCa07,
  'calabaza chihua': kCa07,
  'chihua': kCa07,
  'cushaw': kCa07,
  'arota': kCa07,
  'squash_pipian_seed_dry': kCa07,
  'squash_pipian_fruit_mature': kCa07,
};

/// Devuelve el perfil canónico (kCaGen..kCa07) si el alias se reconoce.
///
/// Si la entrada coincide directo con un id de perfil válido, lo devuelve
/// tal cual. Si no, busca en el mapa de alias normalizado.
String? resolveCanonicalSquashProfileId(String raw) {
  final normalized = raw.trim().toLowerCase();
  if (normalized.isEmpty) return null;
  if (squashProfiles.containsKey(normalized)) return normalized;
  return _squashProfileAliasToCanonical[normalized];
}
