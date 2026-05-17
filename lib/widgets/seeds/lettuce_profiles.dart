import 'package:bio_g/widgets/seeds/lettuce_models.dart';
import 'package:bio_g/widgets/seeds/maize_models.dart';

const String kLeGen = 'le_gen';
const String kLe01 = 'le_01';
const String kLe02 = 'le_02';
const String kLe03 = 'le_03';
const String kLe04 = 'le_04';
const String kLe05 = 'le_05';

/// Perfiles biológicos de lechuga basados en el Perfil Universal BIO-G
/// `crop_lettuce` v1.1.
///
/// Las ventanas son rangos calendario (no GDD) calibrados desde fuentes
/// de extensión universitaria (Texas A&M, UC ANR, UF/IFAS, U. Arizona,
/// Perennia, INIFAP). Los rangos NO sustituyen análisis local: son base
/// conservadora y migrable. LE-GEN nunca debe sentirse incompleto.
const Map<String, LettuceProfile> lettuceProfiles = {
  // ───────────────────────────────────────────────────────────────────
  // LE-GEN — Lechuga genérica / no sé todavía.
  // Entrada SKIP segura, conservadora y migrable. No asume cabeza ni
  // baby leaf. Si el usuario afina el tipo, se migra a LE-01..LE-05 sin
  // reiniciar historial ni memoria de estrés.
  // ───────────────────────────────────────────────────────────────────
  kLeGen: LettuceProfile(
    id: kLeGen,
    label: 'LE-GEN - Lechuga genérica / no sé todavía',
    useType: 'Hoja genérica - configuración segura',
    marketType: LettuceMarketType.generic,
    lettuceUseType: LettuceUseType.flexible,
    defaultEstablishmentMode: LettuceEstablishmentMode.unknown,
    formsHead: false,
    e2EndDay: 21,
    e3EndDay: 44,
    e4EndDay: 58,
    e5EndDay: 80,
    cycleDays: RangeInt(45, 80),
    plantWeightG: RangeInt(150, 600),
    densityPlantsPerHa: RangeInt(70000, 120000),
    referenceYieldTHa: RangeDouble(15, 45),
    isGenericProfile: true,
  ),

  // LE-01 — Lechuga romana / cos.
  kLe01: LettuceProfile(
    id: kLe01,
    label: 'LE-01 - Lechuga romana / cos',
    useType: 'Cabeza alargada de nervadura marcada - 1 corte',
    marketType: LettuceMarketType.romaine,
    lettuceUseType: LettuceUseType.headLeaf,
    defaultEstablishmentMode: LettuceEstablishmentMode.transplant,
    formsHead: true,
    e2EndDay: 21,
    e3EndDay: 42,
    e4EndDay: 58,
    e5EndDay: 80,
    cycleDays: RangeInt(55, 80),
    plantWeightG: RangeInt(300, 800),
    densityPlantsPerHa: RangeInt(60000, 95000),
    referenceYieldTHa: RangeDouble(20, 50),
  ),

  // LE-02 — Mini romana / corazones / Little Gem.
  kLe02: LettuceProfile(
    id: kLe02,
    label: 'LE-02 - Mini romana / corazones / Little Gem',
    useType: 'Cabeza compacta chica - 1 corte',
    marketType: LettuceMarketType.miniRomaine,
    lettuceUseType: LettuceUseType.headLeaf,
    defaultEstablishmentMode: LettuceEstablishmentMode.transplant,
    formsHead: true,
    e2EndDay: 18,
    e3EndDay: 36,
    e4EndDay: 50,
    e5EndDay: 70,
    cycleDays: RangeInt(45, 70),
    plantWeightG: RangeInt(150, 400),
    densityPlantsPerHa: RangeInt(90000, 140000),
    referenceYieldTHa: RangeDouble(15, 40),
  ),

  // LE-03 — Iceberg / bola / crisphead.
  kLe03: LettuceProfile(
    id: kLe03,
    label: 'LE-03 - Lechuga bola / iceberg',
    useType: 'Cabeza redonda compacta - 1 corte',
    marketType: LettuceMarketType.iceberg,
    lettuceUseType: LettuceUseType.headLeaf,
    defaultEstablishmentMode: LettuceEstablishmentMode.transplant,
    formsHead: true,
    e2EndDay: 21,
    e3EndDay: 46,
    e4EndDay: 64,
    e5EndDay: 90,
    cycleDays: RangeInt(60, 90),
    plantWeightG: RangeInt(400, 1200),
    densityPlantsPerHa: RangeInt(50000, 80000),
    referenceYieldTHa: RangeDouble(25, 60),
  ),

  // LE-04 — Mantequilla / butterhead / Bibb / Boston.
  kLe04: LettuceProfile(
    id: kLe04,
    label: 'LE-04 - Lechuga mantequilla / butterhead',
    useType: 'Cabeza suave de hojas tiernas - 1 corte',
    marketType: LettuceMarketType.butterhead,
    lettuceUseType: LettuceUseType.headLeaf,
    defaultEstablishmentMode: LettuceEstablishmentMode.transplant,
    formsHead: true,
    e2EndDay: 18,
    e3EndDay: 38,
    e4EndDay: 53,
    e5EndDay: 75,
    cycleDays: RangeInt(45, 75),
    plantWeightG: RangeInt(200, 500),
    densityPlantsPerHa: RangeInt(60000, 95000),
    referenceYieldTHa: RangeDouble(15, 35),
  ),

  // LE-05 — Hoja suelta / orejona / baby leaf.
  // No cabecea: E4 se interpreta como madurez comercial de roseta/hoja,
  // nunca como formación de cabeza obligatoria.
  kLe05: LettuceProfile(
    id: kLe05,
    label: 'LE-05 - Lechuga hoja suelta / orejona / baby leaf',
    useType: 'Roseta abierta - 1 corte o multicorte',
    marketType: LettuceMarketType.looseLeaf,
    lettuceUseType: LettuceUseType.looseLeaf,
    defaultEstablishmentMode: LettuceEstablishmentMode.directSeed,
    formsHead: false,
    e2EndDay: 16,
    e3EndDay: 32,
    e4EndDay: 44,
    e5EndDay: 62,
    overMatureDays: 14,
    cycleDays: RangeInt(30, 60),
    plantWeightG: RangeInt(80, 300),
    densityPlantsPerHa: RangeInt(120000, 320000),
    referenceYieldTHa: RangeDouble(10, 30),
    isLooseLeaf: true,
  ),
};

/// Mapa de alias (lowercase) hacia perfil canónico LE-XX / LE-GEN.
///
/// Cubre tipos comerciales, variedades regionales y términos en
/// español/inglés del Perfil Universal §2 y la Matriz §4. Mantener
/// siempre la opción "otra variedad" abierta: el mercado local cambia.
const Map<String, String> _lettuceProfileAliasToCanonical = {
  // LE-GEN — genérico / no sabe.
  'le-gen': kLeGen,
  'legen': kLeGen,
  'le_gen': kLeGen,
  'lechuga': kLeGen,
  'lechuga generica': kLeGen,
  'lechuga genérica': kLeGen,
  'lechuga generico': kLeGen,
  'lechuga genérico': kLeGen,
  'generica lechuga': kLeGen,
  'generic lettuce': kLeGen,
  'lettuce': kLeGen,
  'lettuce generic': kLeGen,
  'lettuce_generic': kLeGen,
  'otra lechuga': kLeGen,
  'otra variedad': kLeGen,
  'no se': kLeGen,
  'no sé': kLeGen,
  'no se todavia': kLeGen,
  'no sé todavía': kLeGen,
  'skip': kLeGen,

  // LE-01 — Romana / cos.
  'le-01': kLe01,
  'le01': kLe01,
  'le_01': kLe01,
  'romana': kLe01,
  'lechuga romana': kLe01,
  'cos': kLe01,
  'oreja larga': kLe01,
  'orejalarga': kLe01,
  'romaine': kLe01,
  'valmaine': kLe01,
  'parris island': kLe01,
  'little caesar': kLe01,
  'otra variedad romana': kLe01,
  'lettuce_romaine_field': kLe01,

  // LE-02 — Mini romana / corazones / Little Gem.
  'le-02': kLe02,
  'le02': kLe02,
  'le_02': kLe02,
  'mini romana': kLe02,
  'miniromana': kLe02,
  'corazones': kLe02,
  'corazon': kLe02,
  'corazón': kLe02,
  'little gem': kLe02,
  'gem': kLe02,
  'mini cos': kLe02,
  'mini gem': kLe02,
  'otra variedad mini romana': kLe02,

  // LE-03 — Iceberg / bola / crisphead.
  'le-03': kLe03,
  'le03': kLe03,
  'le_03': kLe03,
  'bola': kLe03,
  'lechuga bola': kLe03,
  'iceberg': kLe03,
  'crisphead': kLe03,
  'great lakes': kLe03,
  'salinas': kLe03,
  'sure shot': kLe03,
  'otra variedad iceberg': kLe03,

  // LE-04 — Mantequilla / butterhead.
  'le-04': kLe04,
  'le04': kLe04,
  'le_04': kLe04,
  'mantequilla': kLe04,
  'lechuga mantequilla': kLe04,
  'butterhead': kLe04,
  'bibb': kLe04,
  'boston': kLe04,
  'fairly': kLe04,
  'cuervo': kLe04,
  'otra variedad mantequilla': kLe04,

  // LE-05 — Hoja suelta / orejona / baby leaf.
  'le-05': kLe05,
  'le05': kLe05,
  'le_05': kLe05,
  'hoja suelta': kLe05,
  'hojasuelta': kLe05,
  'orejona': kLe05,
  'looseleaf': kLe05,
  'loose leaf': kLe05,
  'leaf lettuce': kLe05,
  'baby leaf': kLe05,
  'babyleaf': kLe05,
  'green leaf': kLe05,
  'red leaf': kLe05,
  'lolla': kLe05,
  'lollo': kLe05,
  'oak leaf': kLe05,
  'sangria': kLe05,
  'otra variedad hoja suelta': kLe05,
};

/// Devuelve el perfil canónico (kLeGen..kLe05) si el alias se reconoce.
///
/// Si la entrada coincide directo con un id de perfil válido lo devuelve
/// tal cual; si no, busca en el mapa de alias normalizado.
String? resolveCanonicalLettuceProfileId(String raw) {
  final normalized = raw.trim().toLowerCase();
  if (normalized.isEmpty) return null;
  if (lettuceProfiles.containsKey(normalized)) return normalized;
  return _lettuceProfileAliasToCanonical[normalized];
}
