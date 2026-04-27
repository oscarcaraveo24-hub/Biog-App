import 'package:bio_g/widgets/seeds/chili_models.dart';
import 'package:bio_g/widgets/seeds/maize_models.dart';

const String kChGen = 'ch_gen';
const String kCh01 = 'ch_01';
const String kCh02 = 'ch_02';
const String kCh03 = 'ch_03';
const String kCh04 = 'ch_04';
const String kCh05 = 'ch_05';
const String kCh06 = 'ch_06';
const String kCh07 = 'ch_07';
const String kCh08 = 'ch_08';

/// Perfiles oficiales CH-GEN + CH-01..CH-08.
///
/// Chile es el cultivo madre BIO-G. Los tipos comerciales viven como perfiles
/// internos y las variedades comerciales solo funcionan como alias del perfil.
/// CH-GEN es conservador, migrable y no busca maximizar rendimiento.
const Map<String, ChiliProfile> chiliProfiles = {
  kChGen: ChiliProfile(
    id: kChGen,
    label: 'CH-GEN - Chile generico',
    useType: 'Fresco / seco (generico)',
    marketType: ChiliMarketType.generic,
    defaultEstablishmentMode: ChiliEstablishmentMode.transplant,
    floweringDays: RangeInt(50, 65),
    harvestStartDays: RangeInt(95, 115),
    endWindowDays: RangeInt(165, 215),
    endActionLabel: 'Cierre conservador',
    plantHeightM: RangeDouble(0.75, 1.45),
    densityPlantsPerHa: RangeInt(30000, 45000),
    referenceYieldTHa: RangeDouble(16, 30),
    isGenericProfile: true,
  ),
  kCh01: ChiliProfile(
    id: kCh01,
    label: 'CH-01 - Jalapeno',
    useType: 'Fresco / proceso / chipotle',
    marketType: ChiliMarketType.jalapeno,
    chiliUseType: ChiliUseType.process,
    defaultEstablishmentMode: ChiliEstablishmentMode.transplant,
    floweringDays: RangeInt(45, 65),
    harvestStartDays: RangeInt(90, 110),
    endWindowDays: RangeInt(150, 190),
    endActionLabel: 'Cierre de cosecha',
    plantHeightM: RangeDouble(0.80, 1.40),
    densityPlantsPerHa: RangeInt(30000, 45000),
    referenceYieldTHa: RangeDouble(20, 45),
  ),
  kCh02: ChiliProfile(
    id: kCh02,
    label: 'CH-02 - Serrano',
    useType: 'Fresco / proceso',
    marketType: ChiliMarketType.serrano,
    defaultEstablishmentMode: ChiliEstablishmentMode.transplant,
    floweringDays: RangeInt(45, 60),
    harvestStartDays: RangeInt(85, 105),
    endWindowDays: RangeInt(145, 185),
    endActionLabel: 'Cierre de cosecha continua',
    plantHeightM: RangeDouble(0.80, 1.50),
    densityPlantsPerHa: RangeInt(35000, 55000),
    referenceYieldTHa: RangeDouble(22, 45),
  ),
  kCh03: ChiliProfile(
    id: kCh03,
    label: 'CH-03 - Poblano / Ancho',
    useType: 'Fresco / seco',
    marketType: ChiliMarketType.poblanoAncho,
    chiliUseType: ChiliUseType.process,
    defaultEstablishmentMode: ChiliEstablishmentMode.transplant,
    floweringDays: RangeInt(50, 68),
    harvestStartDays: RangeInt(95, 125),
    endWindowDays: RangeInt(170, 220),
    endActionLabel: 'Cierre de cosecha fresco/seco',
    plantHeightM: RangeDouble(0.90, 1.60),
    densityPlantsPerHa: RangeInt(25000, 40000),
    referenceYieldTHa: RangeDouble(18, 35),
  ),
  kCh04: ChiliProfile(
    id: kCh04,
    label: 'CH-04 - Chilaca / Pasilla',
    useType: 'Seco principalmente',
    marketType: ChiliMarketType.chilacaPasilla,
    chiliUseType: ChiliUseType.dry,
    defaultEstablishmentMode: ChiliEstablishmentMode.transplant,
    floweringDays: RangeInt(55, 75),
    harvestStartDays: RangeInt(105, 135),
    endWindowDays: RangeInt(180, 230),
    endActionLabel: 'Cierre orientado a secado',
    plantHeightM: RangeDouble(0.90, 1.60),
    densityPlantsPerHa: RangeInt(20000, 35000),
    referenceYieldTHa: RangeDouble(1.2, 2.8),
    isDryDestination: true,
  ),
  kCh05: ChiliProfile(
    id: kCh05,
    label: 'CH-05 - Mirasol / Guajillo',
    useType: 'Seco principalmente',
    marketType: ChiliMarketType.guajilloMirasol,
    chiliUseType: ChiliUseType.dry,
    defaultEstablishmentMode: ChiliEstablishmentMode.transplant,
    floweringDays: RangeInt(55, 75),
    harvestStartDays: RangeInt(105, 145),
    endWindowDays: RangeInt(180, 230),
    endActionLabel: 'Cierre orientado a secado',
    plantHeightM: RangeDouble(0.80, 1.50),
    densityPlantsPerHa: RangeInt(20000, 35000),
    referenceYieldTHa: RangeDouble(1.5, 3.5),
    isDryDestination: true,
  ),
  kCh06: ChiliProfile(
    id: kCh06,
    label: 'CH-06 - De arbol / Puya',
    useType: 'Seco principalmente',
    marketType: ChiliMarketType.arbolPuya,
    chiliUseType: ChiliUseType.dry,
    defaultEstablishmentMode: ChiliEstablishmentMode.transplant,
    floweringDays: RangeInt(48, 63),
    harvestStartDays: RangeInt(95, 120),
    endWindowDays: RangeInt(160, 210),
    endActionLabel: 'Cierre de cosecha seca',
    plantHeightM: RangeDouble(0.80, 1.40),
    densityPlantsPerHa: RangeInt(40000, 70000),
    referenceYieldTHa: RangeDouble(1.0, 2.8),
    isDryDestination: true,
  ),
  kCh07: ChiliProfile(
    id: kCh07,
    label: 'CH-07 - Habanero',
    useType: 'Fresco / proceso',
    marketType: ChiliMarketType.habanero,
    defaultEstablishmentMode: ChiliEstablishmentMode.transplant,
    floweringDays: RangeInt(55, 80),
    harvestStartDays: RangeInt(110, 150),
    endWindowDays: RangeInt(180, 240),
    endActionLabel: 'Cierre de ciclo largo',
    plantHeightM: RangeDouble(0.80, 1.40),
    densityPlantsPerHa: RangeInt(20000, 40000),
    referenceYieldTHa: RangeDouble(15, 40),
    isCapsicumChinense: true,
  ),
  kCh08: ChiliProfile(
    id: kCh08,
    label: 'CH-08 - Pimiento morron / Chile gordo',
    useType: 'Fresco',
    marketType: ChiliMarketType.bellPepper,
    defaultEstablishmentMode: ChiliEstablishmentMode.transplant,
    floweringDays: RangeInt(50, 75),
    harvestStartDays: RangeInt(95, 130),
    endWindowDays: RangeInt(170, 230),
    endActionLabel: 'Cierre de cosecha',
    plantHeightM: RangeDouble(0.80, 1.50),
    densityPlantsPerHa: RangeInt(25000, 40000),
    referenceYieldTHa: RangeDouble(25, 45),
  ),
};

const Map<String, String> _chiliProfileAliasToCanonical = {
  'ch-gen': kChGen,
  'chgen': kChGen,
  'ch_gen': kChGen,
  'generico': kChGen,
  'generic': kChGen,
  'chile generico': kChGen,
  'otro chile': kChGen,
  'no se': kChGen,
  'skip': kChGen,

  'ch-01': kCh01,
  'ch01': kCh01,
  'ch_01': kCh01,
  'jalapeno': kCh01,
  'chipotle': kCh01,

  'ch-02': kCh02,
  'ch02': kCh02,
  'ch_02': kCh02,
  'serrano': kCh02,

  'ch-03': kCh03,
  'ch03': kCh03,
  'ch_03': kCh03,
  'poblano': kCh03,
  'ancho': kCh03,
  'mulato': kCh03,

  'ch-04': kCh04,
  'ch04': kCh04,
  'ch_04': kCh04,
  'chilaca': kCh04,
  'pasilla': kCh04,

  'ch-05': kCh05,
  'ch05': kCh05,
  'ch_05': kCh05,
  'mirasol': kCh05,
  'guajillo': kCh05,

  'ch-06': kCh06,
  'ch06': kCh06,
  'ch_06': kCh06,
  'chili_arbol_fresh': kCh06,
  'chili_arbol_puya': kCh06,
  'chili_arbol_puya_dry': kCh06,
  'de arbol': kCh06,
  'de arbol fresco': kCh06,
  'arbol': kCh06,
  'arbol fresco': kCh06,
  'chile de arbol fresco': kCh06,
  'puya': kCh06,
  'puya seco': kCh06,

  'ch-07': kCh07,
  'ch07': kCh07,
  'ch_07': kCh07,
  'habanero': kCh07,
  'capsicum chinense': kCh07,

  'ch-08': kCh08,
  'ch08': kCh08,
  'ch_08': kCh08,
  'pimiento': kCh08,
  'pimiento morron': kCh08,
  'morron': kCh08,
  'chile gordo': kCh08,
  'bell pepper': kCh08,
};

String? resolveCanonicalChiliProfileId(String raw) {
  final normalized = raw.trim().toLowerCase();
  if (normalized.isEmpty) return null;
  if (chiliProfiles.containsKey(normalized)) return normalized;
  return _chiliProfileAliasToCanonical[normalized];
}
