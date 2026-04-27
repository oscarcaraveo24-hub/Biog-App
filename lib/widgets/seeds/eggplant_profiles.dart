import 'package:bio_g/widgets/seeds/eggplant_models.dart';
import 'package:bio_g/widgets/seeds/maize_models.dart';

const String kBeGen = 'be_gen';
const String kBe01 = 'be_01';
const String kBe02 = 'be_02';
const String kBe03 = 'be_03';
const String kBe04 = 'be_04';

const Map<String, EggplantProfile> eggplantProfiles = {
  kBeGen: EggplantProfile(
    id: kBeGen,
    label: 'BE-GEN - Berenjena genérica',
    useType: 'Fruto fresco genérico',
    marketType: EggplantMarketType.generic,
    defaultEstablishmentMode: EggplantEstablishmentMode.transplant,
    // PDF Perfil Universal v2: floración 45-65 DAT, cosecha 70-95 DAT.
    floweringDays: RangeInt(45, 65),
    harvestStartDays: RangeInt(70, 95),
    endWindowDays: RangeInt(145, 205),
    endActionLabel: 'Cierre conservador',
    plantHeightM: RangeDouble(0.70, 1.25),
    densityPlantsPerHa: RangeInt(12000, 20000),
    referenceYieldTHa: RangeDouble(18, 32),
    isGenericProfile: true,
  ),
  kBe01: EggplantProfile(
    id: kBe01,
    label: 'BE-01 - Berenjena larga / semilarga morada',
    useType: 'Fruto fresco',
    marketType: EggplantMarketType.longPurple,
    defaultEstablishmentMode: EggplantEstablishmentMode.transplant,
    // PDF Perfil Universal v2: floración 40-60 DAT, cosecha 65-90 DAT.
    floweringDays: RangeInt(40, 60),
    harvestStartDays: RangeInt(65, 90),
    endWindowDays: RangeInt(150, 215),
    endActionLabel: 'Cierre de cosecha progresiva',
    plantHeightM: RangeDouble(0.80, 1.40),
    densityPlantsPerHa: RangeInt(14000, 22000),
    referenceYieldTHa: RangeDouble(25, 45),
  ),
  kBe02: EggplantProfile(
    id: kBe02,
    label: 'BE-02 - Berenjena oval / bola morada',
    useType: 'Fruto fresco',
    marketType: EggplantMarketType.ovalRound,
    defaultEstablishmentMode: EggplantEstablishmentMode.transplant,
    // PDF Perfil Universal v2: floración 45-65 DAT, cosecha 70-95 DAT.
    floweringDays: RangeInt(45, 65),
    harvestStartDays: RangeInt(70, 95),
    endWindowDays: RangeInt(150, 215),
    endActionLabel: 'Cierre de cosecha progresiva',
    plantHeightM: RangeDouble(0.75, 1.35),
    densityPlantsPerHa: RangeInt(12000, 20000),
    referenceYieldTHa: RangeDouble(22, 42),
  ),
  kBe03: EggplantProfile(
    id: kBe03,
    label: 'BE-03 - Berenjena rayada / listada',
    useType: 'Fruto fresco nicho',
    marketType: EggplantMarketType.striped,
    defaultEstablishmentMode: EggplantEstablishmentMode.transplant,
    // PDF Perfil Universal v2: floración 45-70 DAT, cosecha 75-105 DAT.
    floweringDays: RangeInt(45, 70),
    harvestStartDays: RangeInt(75, 105),
    endWindowDays: RangeInt(145, 205),
    endActionLabel: 'Cierre de cosecha de calidad visual',
    plantHeightM: RangeDouble(0.70, 1.25),
    densityPlantsPerHa: RangeInt(12000, 20000),
    referenceYieldTHa: RangeDouble(16, 32),
    visualQualitySensitive: true,
  ),
  kBe04: EggplantProfile(
    id: kBe04,
    label: 'BE-04 - Berenjena blanca',
    useType: 'Fruto fresco nicho',
    marketType: EggplantMarketType.white,
    defaultEstablishmentMode: EggplantEstablishmentMode.transplant,
    // PDF Perfil Universal v2: floración 45-70 DAT, cosecha 75-105 DAT.
    floweringDays: RangeInt(45, 70),
    harvestStartDays: RangeInt(75, 105),
    endWindowDays: RangeInt(145, 205),
    endActionLabel: 'Cierre de cosecha de calidad visual',
    plantHeightM: RangeDouble(0.65, 1.20),
    densityPlantsPerHa: RangeInt(12000, 20000),
    referenceYieldTHa: RangeDouble(14, 30),
    visualQualitySensitive: true,
  ),
};

const Map<String, String> _eggplantProfileAliasToCanonical = {
  // ---------------------------------------------------------------------------
  // BE-GEN - Genérico / no sabe / otra
  // ---------------------------------------------------------------------------
  'be-gen': kBeGen,
  'begen': kBeGen,
  'be_gen': kBeGen,
  'generica': kBeGen,
  'genérica': kBeGen,
  'generico': kBeGen,
  'genérico': kBeGen,
  'generic': kBeGen,
  'berenjena generica': kBeGen,
  'berenjena genérica': kBeGen,
  'otra berenjena': kBeGen,
  'no se': kBeGen,
  'no sé': kBeGen,
  'skip': kBeGen,

  // ---------------------------------------------------------------------------
  // BE-01 - Larga / semilarga morada
  // ---------------------------------------------------------------------------
  'be-01': kBe01,
  'be01': kBe01,
  'be_01': kBe01,
  'larga': kBe01,
  'semilarga': kBe01,
  'morada larga': kBe01,
  'larga morada': kBe01,
  'berenjena larga': kBe01,
  'berenjena semilarga': kBe01,
  'semilarga morada': kBe01,
  'oriental': kBe01,
  'china': kBe01,
  'berenjena china': kBe01,
  'barcelona': kBe01,
  'dark night': kBe01,
  'orestia': kBe01,
  'napoli': kBe01,
  'nápoli': kBe01,
  'eggplant_long_purple': kBe01,
  'long purple': kBe01,

  // ---------------------------------------------------------------------------
  // BE-02 - Oval / bola morada / italiana clásica
  // ---------------------------------------------------------------------------
  'be-02': kBe02,
  'be02': kBe02,
  'be_02': kBe02,
  'oval': kBe02,
  'bola': kBe02,
  'bola morada': kBe02,
  'oval morada': kBe02,
  'berenjena bola': kBe02,
  'berenjena oval': kBe02,
  'americana': kBe02,
  'morada grande': kBe02,
  'italiana': kBe02,
  'berenjena italiana': kBe02,
  'berenjena italiana / clasica morada': kBe02,
  'berenjena italiana / clásica morada': kBe02,
  'italiana clasica morada': kBe02,
  'italiana clásica morada': kBe02,
  'italian': kBe02,
  'clasica': kBe02,
  'clásica': kBe02,
  'clasica morada': kBe02,
  'clásica morada': kBe02,
  'morada clasica': kBe02,
  'morada clásica': kBe02,
  'black beauty': kBe02,
  'night shadow': kBe02,
  'emma f1': kBe02,
  'eggplant_italian_purple': kBe02,
  'eggplant_italian_black': kBe02,
  'eggplant_oval_round': kBe02,
  'oval round': kBe02,

  // ---------------------------------------------------------------------------
  // BE-03 - Rayada / listada
  // ---------------------------------------------------------------------------
  'be-03': kBe03,
  'be03': kBe03,
  'be_03': kBe03,
  'rayada': kBe03,
  'listada': kBe03,
  'jaspeada': kBe03,
  'berenjena rayada': kBe03,
  'berenjena listada': kBe03,
  'graffiti': kBe03,
  'grafiti': kBe03,
  'eggplant_striped': kBe03,
  'striped': kBe03,

  // ---------------------------------------------------------------------------
  // BE-04 - Blanca
  // ---------------------------------------------------------------------------
  'be-04': kBe04,
  'be04': kBe04,
  'be_04': kBe04,
  'blanca': kBe04,
  'berenjena blanca': kBe04,
  'white egg': kBe04,
  'blanca f1': kBe04,
  'otra blanca': kBe04,
  'eggplant_white': kBe04,
  'white': kBe04,
};

String? resolveCanonicalEggplantProfileId(String raw) {
  final normalized = raw.trim().toLowerCase();

  if (normalized.isEmpty) return null;
  if (eggplantProfiles.containsKey(normalized)) return normalized;

  return _eggplantProfileAliasToCanonical[normalized];
}
