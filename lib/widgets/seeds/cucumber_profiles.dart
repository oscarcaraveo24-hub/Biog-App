import 'package:bio_g/widgets/seeds/cucumber_models.dart';
import 'package:bio_g/widgets/seeds/maize_models.dart';

const String kPe01 = 'pe_01';
const String kPe02 = 'pe_02';
const String kPe03 = 'pe_03';
const String kPe04 = 'pe_04';
const String kPeGen = 'pe_gen';

/// Perfiles oficiales PE-01..PE-04 + PE-GEN.
///
/// Datos derivados del Perfil Universal Pepino v1, Perfil Genérico Pepino
/// PE-GEN v1, Guía Universal de Fertilización del Pepino v1 y documento de
/// rendimiento aproximado v1. Los días se interpretan desde el inicio real del
/// ciclo (siembra o trasplante, según el sistema), sin offset artificial.
/// Todos los perfiles asumen suelo (campo abierto o invernadero/malla en
/// suelo), sin hidroponía.
const Map<String, CucumberProfile> cucumberProfiles = {
  // ───────────────────────────────────────────────────────────────────
  // PE-01 · Slicer campo abierto (americano / criollo de rebanada)
  // Determinado–semideterminado; ciclo corto-medio; consumo en fresco.
  // ───────────────────────────────────────────────────────────────────
  kPe01: CucumberProfile(
    id: kPe01,
    label: 'PE-01 · Slicer campo abierto',
    useType: 'Fresco',
    marketType: CucumberMarketType.slicer,
    cucumberUseType: CucumberUseType.fresh,
    defaultEstablishmentMode: CucumberEstablishmentMode.directSeed,
    floweringDays: RangeInt(35, 50),
    harvestStartDays: RangeInt(50, 70),
    endWindowDays: RangeInt(80, 105),
    endActionLabel: 'Cierre de cosecha',
    plantHeightM: RangeDouble(0.40, 0.80),
    densityPlantsPerHa: RangeInt(25000, 40000),
    referenceYieldTHa: RangeDouble(25, 40),
  ),

  // ───────────────────────────────────────────────────────────────────
  // PE-02 · Europeo / inglés protegido
  // Largo, uniforme, normalmente guiado; protegido en suelo.
  // ───────────────────────────────────────────────────────────────────
  kPe02: CucumberProfile(
    id: kPe02,
    label: 'PE-02 · Europeo / inglés protegido',
    useType: 'Fresco',
    marketType: CucumberMarketType.european,
    cucumberUseType: CucumberUseType.fresh,
    defaultEstablishmentMode: CucumberEstablishmentMode.transplant,
    floweringDays: RangeInt(35, 55),
    harvestStartDays: RangeInt(55, 80),
    endWindowDays: RangeInt(110, 145),
    endActionLabel: 'Cierre de ciclo',
    plantHeightM: RangeDouble(1.80, 2.60),
    densityPlantsPerHa: RangeInt(18000, 28000),
    referenceYieldTHa: RangeDouble(75, 100),
  ),

  // ───────────────────────────────────────────────────────────────────
  // PE-03 · Persa / mini / Beit-Alfa
  // Protegido en suelo; partenocárpico; ciclo productivo prolongado.
  // ───────────────────────────────────────────────────────────────────
  kPe03: CucumberProfile(
    id: kPe03,
    label: 'PE-03 · Persa / mini / Beit-Alfa',
    useType: 'Fresco',
    marketType: CucumberMarketType.persianMini,
    cucumberUseType: CucumberUseType.fresh,
    defaultEstablishmentMode: CucumberEstablishmentMode.transplant,
    floweringDays: RangeInt(35, 55),
    harvestStartDays: RangeInt(55, 85),
    endWindowDays: RangeInt(110, 155),
    endActionLabel: 'Cierre de ciclo',
    plantHeightM: RangeDouble(2.00, 2.80),
    densityPlantsPerHa: RangeInt(18000, 30000),
    referenceYieldTHa: RangeDouble(40, 70),
  ),

  // ───────────────────────────────────────────────────────────────────
  // PE-04 · Pickler (encurtido / cornichón), campo abierto
  // Determinado; ciclo corto; cosecha de fruto pequeño y firme.
  // ───────────────────────────────────────────────────────────────────
  kPe04: CucumberProfile(
    id: kPe04,
    label: 'PE-04 · Pickler campo abierto',
    useType: 'Proceso (encurtido)',
    marketType: CucumberMarketType.pickler,
    cucumberUseType: CucumberUseType.process,
    defaultEstablishmentMode: CucumberEstablishmentMode.directSeed,
    floweringDays: RangeInt(30, 50),
    harvestStartDays: RangeInt(45, 70),
    endWindowDays: RangeInt(70, 95),
    endActionLabel: 'Cierre de cosecha',
    plantHeightM: RangeDouble(0.35, 0.70),
    densityPlantsPerHa: RangeInt(60000, 120000),
    referenceYieldTHa: RangeDouble(18, 35),
  ),

  // ───────────────────────────────────────────────────────────────────
  // PE-GEN · Genérico (skip obligatorio, migrable a PE-01..PE-04)
  // ───────────────────────────────────────────────────────────────────
  kPeGen: CucumberProfile(
    id: kPeGen,
    label: 'PE-GEN · Genérico',
    useType: 'Fresco (genérico)',
    marketType: CucumberMarketType.generic,
    cucumberUseType: CucumberUseType.fresh,
    defaultEstablishmentMode: CucumberEstablishmentMode.transplant,
    floweringDays: RangeInt(35, 50),
    harvestStartDays: RangeInt(55, 75),
    endWindowDays: RangeInt(95, 130),
    endActionLabel: 'Cierre de ciclo',
    plantHeightM: RangeDouble(1.00, 1.80),
    densityPlantsPerHa: RangeInt(25000, 35000),
    referenceYieldTHa: RangeDouble(30, 70),
    isGenericProfile: true,
  ),
};

const Map<String, String> _cucumberProfileAliasToCanonical = {
  'pe-01': kPe01,
  'pe01': kPe01,
  'slicer': kPe01,
  'slicer campo abierto': kPe01,
  'americano': kPe01,
  'pepino criollo': kPe01,
  'criollo': kPe01,
  'rebanada': kPe01,

  'pe-02': kPe02,
  'pe02': kPe02,
  'europeo': kPe02,
  'europeo protegido': kPe02,
  'ingles': kPe02,
  'inglés': kPe02,
  'ingles protegido': kPe02,
  'inglés protegido': kPe02,
  'pepino ingles': kPe02,
  'pepino inglés': kPe02,

  'pe-03': kPe03,
  'pe03': kPe03,
  'persian': kPe03,
  'persa': kPe03,
  'beit alpha': kPe03,
  'beit-alpha': kPe03,
  'beitalpha': kPe03,
  'pepino persa': kPe03,
  'mini': kPe03,
  'partenocarpico': kPe03,
  'partenocárpico': kPe03,
  'sin semilla': kPe03,
  'snack': kPe03,

  'pe-04': kPe04,
  'pe04': kPe04,
  'pickler': kPe04,
  'cornichon': kPe04,
  'cornichón': kPe04,
  'encurtido': kPe04,
  'pepinillo': kPe04,
  'pepino encurtido': kPe04,

  'pe-gen': kPeGen,
  'pegen': kPeGen,
  'pe_gen': kPeGen,
  'generico': kPeGen,
  'genérico': kPeGen,
  'generic': kPeGen,
  'pepino generico': kPeGen,
  'pepino genérico': kPeGen,
};

String? resolveCanonicalCucumberProfileId(String raw) {
  final normalized = raw.trim().toLowerCase();
  if (normalized.isEmpty) return null;
  if (cucumberProfiles.containsKey(normalized)) return normalized;
  return _cucumberProfileAliasToCanonical[normalized];
}
