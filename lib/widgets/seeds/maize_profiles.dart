import 'package:bio_g/widgets/seeds/maize_models.dart';

const String kMzf00 = 'mzf_00';
const String kMzf01 = 'mzf_01';
const String kMzf02 = 'mzf_02';
const String kMzf03 = 'mzf_03';
const String kMzf04 = 'mzf_04';
const String kMzf05 = 'mzf_05';
const String kMzf06 = 'mzf_06';

const String kMzg00 = 'mzg_00';
const String kMzg01 = 'mzg_01';
const String kMzg02 = 'mzg_02';
const String kMzg03 = 'mzg_03';
const String kMzg04 = 'mzg_04';
const String kMzg05 = 'mzg_05';
const String kMzg06 = 'mzg_06';
const String kMzg07 = 'mzg_07';
const String kMzg08 = 'mzg_08';
const String kMzg09 = 'mzg_09';

const String kMze00 = 'mze_00';

const String kMzgGenB = 'mzg_gen_b';
const String kMzgGenA = 'mzg_gen_a';
const String kMzfGen = 'mzf_gen';
const String kMzeGen = 'mze_gen';
const String kMaizeGenericProfileId = 'maize_generic';

const Map<String, MaizeProfile> maizeProfiles = {
  // ── Forrajeros ───────────────────────────────────────────────────────────
  kMzf00: MaizeProfile(
    id: kMzf00,
    label: 'MZF-00 · Forrajero precoz',
    useType: 'Forraje',
    maizeUseType: MaizeUseType.forage,
    r1Days: RangeInt(55, 62),
    endWindowDays: RangeInt(85, 95),
    endActionLabel: 'Corte',
    plantHeightM: RangeDouble(1.90, 2.40),
    earHeightM: RangeDouble(0.75, 1.05),
    germinationDays: RangeInt(4, 7),
    emergenceDays: RangeInt(7, 10),
    vegEarlyDays: RangeInt(10, 24),
  ),
  kMzf01: MaizeProfile(
    id: kMzf01,
    label: 'MZF-01 · Forrajero intermedio temprano',
    useType: 'Forraje',
    maizeUseType: MaizeUseType.forage,
    r1Days: RangeInt(60, 68),
    endWindowDays: RangeInt(95, 110),
    endActionLabel: 'Corte',
    plantHeightM: RangeDouble(2.05, 2.65),
    earHeightM: RangeDouble(0.85, 1.20),
    germinationDays: RangeInt(4, 7),
    emergenceDays: RangeInt(7, 11),
    vegEarlyDays: RangeInt(11, 26),
  ),
  kMzf02: MaizeProfile(
    id: kMzf02,
    label: 'MZF-02 · Forrajero intermedio',
    useType: 'Forraje',
    maizeUseType: MaizeUseType.forage,
    r1Days: RangeInt(68, 76),
    endWindowDays: RangeInt(105, 120),
    endActionLabel: 'Corte',
    plantHeightM: RangeDouble(2.20, 2.90),
    earHeightM: RangeDouble(0.95, 1.30),
    germinationDays: RangeInt(4, 7),
    emergenceDays: RangeInt(7, 11),
    vegEarlyDays: RangeInt(11, 28),
  ),
  kMzf03: MaizeProfile(
    id: kMzf03,
    label: 'MZF-03 · Forrajero intermedio tardío',
    useType: 'Forraje',
    maizeUseType: MaizeUseType.forage,
    r1Days: RangeInt(75, 85),
    endWindowDays: RangeInt(115, 130),
    endActionLabel: 'Corte',
    plantHeightM: RangeDouble(2.40, 3.05),
    earHeightM: RangeDouble(1.05, 1.40),
    germinationDays: RangeInt(4, 7),
    emergenceDays: RangeInt(7, 12),
    vegEarlyDays: RangeInt(12, 30),
  ),
  kMzf04: MaizeProfile(
    id: kMzf04,
    label: 'MZF-04 · Forrajero tardío',
    useType: 'Forraje',
    maizeUseType: MaizeUseType.forage,
    r1Days: RangeInt(85, 95),
    endWindowDays: RangeInt(125, 145),
    endActionLabel: 'Corte',
    plantHeightM: RangeDouble(2.55, 3.25),
    earHeightM: RangeDouble(1.10, 1.50),
    germinationDays: RangeInt(4, 7),
    emergenceDays: RangeInt(7, 12),
    vegEarlyDays: RangeInt(12, 32),
  ),
  kMzf05: MaizeProfile(
    id: kMzf05,
    label: 'MZF-05 · Forrajero intermedio cálido',
    useType: 'Forraje',
    maizeUseType: MaizeUseType.forage,
    r1Days: RangeInt(70, 80),
    endWindowDays: RangeInt(100, 115),
    endActionLabel: 'Corte',
    plantHeightM: RangeDouble(2.10, 2.80),
    earHeightM: RangeDouble(0.90, 1.25),
    germinationDays: RangeInt(4, 7),
    emergenceDays: RangeInt(7, 11),
    vegEarlyDays: RangeInt(11, 27),
  ),
  kMzf06: MaizeProfile(
    id: kMzf06,
    label: 'MZF-06 · Forrajero súper precoz',
    useType: 'Forraje',
    maizeUseType: MaizeUseType.forage,
    r1Days: RangeInt(50, 58),
    endWindowDays: RangeInt(78, 88),
    endActionLabel: 'Corte',
    plantHeightM: RangeDouble(1.70, 2.20),
    earHeightM: RangeDouble(0.65, 0.95),
    germinationDays: RangeInt(4, 6),
    emergenceDays: RangeInt(6, 9),
    vegEarlyDays: RangeInt(9, 22),
  ),

  // ── Grano ────────────────────────────────────────────────────────────────
  kMzg00: MaizeProfile(
    id: kMzg00,
    label: 'MZG-00 · Grano precoz extremo',
    useType: 'Grano',
    maizeUseType: MaizeUseType.grain,
    r1Days: RangeInt(52, 58),
    endWindowDays: RangeInt(95, 105),
    endActionLabel: 'Cosecha',
    plantHeightM: RangeDouble(1.60, 2.10),
    earHeightM: RangeDouble(0.60, 0.90),
    germinationDays: RangeInt(4, 6),
    emergenceDays: RangeInt(6, 9),
    vegEarlyDays: RangeInt(9, 22),
  ),
  kMzg01: MaizeProfile(
    id: kMzg01,
    label: 'MZG-01 · Grano precoz',
    useType: 'Grano',
    maizeUseType: MaizeUseType.grain,
    r1Days: RangeInt(58, 65),
    endWindowDays: RangeInt(105, 115),
    endActionLabel: 'Cosecha',
    plantHeightM: RangeDouble(1.75, 2.25),
    earHeightM: RangeDouble(0.68, 0.98),
    germinationDays: RangeInt(4, 7),
    emergenceDays: RangeInt(7, 10),
    vegEarlyDays: RangeInt(10, 24),
  ),
  kMzg02: MaizeProfile(
    id: kMzg02,
    label: 'MZG-02 · Grano intermedio precoz',
    useType: 'Grano',
    maizeUseType: MaizeUseType.grain,
    r1Days: RangeInt(65, 72),
    endWindowDays: RangeInt(115, 125),
    endActionLabel: 'Cosecha',
    plantHeightM: RangeDouble(1.95, 2.45),
    earHeightM: RangeDouble(0.78, 1.08),
    germinationDays: RangeInt(4, 7),
    emergenceDays: RangeInt(7, 10),
    vegEarlyDays: RangeInt(10, 26),
  ),
  kMzg03: MaizeProfile(
    id: kMzg03,
    label: 'MZG-03 · Grano intermedio estándar',
    useType: 'Grano',
    maizeUseType: MaizeUseType.grain,
    r1Days: RangeInt(72, 80),
    endWindowDays: RangeInt(125, 135),
    endActionLabel: 'Cosecha',
    plantHeightM: RangeDouble(2.05, 2.65),
    earHeightM: RangeDouble(0.85, 1.18),
    germinationDays: RangeInt(4, 7),
    emergenceDays: RangeInt(7, 11),
    vegEarlyDays: RangeInt(11, 28),
  ),
  kMzg04: MaizeProfile(
    id: kMzg04,
    label: 'MZG-04 · Grano intermedio tardío',
    useType: 'Grano',
    maizeUseType: MaizeUseType.grain,
    r1Days: RangeInt(78, 86),
    endWindowDays: RangeInt(135, 145),
    endActionLabel: 'Cosecha',
    plantHeightM: RangeDouble(2.15, 2.80),
    earHeightM: RangeDouble(0.90, 1.25),
    germinationDays: RangeInt(4, 7),
    emergenceDays: RangeInt(7, 11),
    vegEarlyDays: RangeInt(11, 29),
  ),
  kMzg05: MaizeProfile(
    id: kMzg05,
    label: 'MZG-05 · Grano intermedio tardío cálido',
    useType: 'Grano',
    maizeUseType: MaizeUseType.grain,
    r1Days: RangeInt(75, 83),
    endWindowDays: RangeInt(120, 132),
    endActionLabel: 'Cosecha',
    plantHeightM: RangeDouble(2.00, 2.70),
    earHeightM: RangeDouble(0.85, 1.20),
    germinationDays: RangeInt(4, 7),
    emergenceDays: RangeInt(7, 10),
    vegEarlyDays: RangeInt(10, 27),
  ),
  kMzg06: MaizeProfile(
    id: kMzg06,
    label: 'MZG-06 · Grano intermedio corto tropical',
    useType: 'Grano',
    maizeUseType: MaizeUseType.grain,
    r1Days: RangeInt(68, 76),
    endWindowDays: RangeInt(112, 124),
    endActionLabel: 'Cosecha',
    plantHeightM: RangeDouble(1.90, 2.55),
    earHeightM: RangeDouble(0.78, 1.12),
    germinationDays: RangeInt(4, 7),
    emergenceDays: RangeInt(7, 10),
    vegEarlyDays: RangeInt(10, 26),
  ),
  kMzg07: MaizeProfile(
    id: kMzg07,
    label: 'MZG-07 · Grano intermedio corto invernal',
    useType: 'Grano',
    maizeUseType: MaizeUseType.grain,
    r1Days: RangeInt(70, 78),
    endWindowDays: RangeInt(118, 128),
    endActionLabel: 'Cosecha',
    plantHeightM: RangeDouble(1.85, 2.45),
    earHeightM: RangeDouble(0.75, 1.08),
    germinationDays: RangeInt(5, 8),
    emergenceDays: RangeInt(8, 11),
    vegEarlyDays: RangeInt(11, 27),
  ),
  kMzg08: MaizeProfile(
    id: kMzg08,
    label: 'MZG-08 · Grano tardío extendido',
    useType: 'Grano',
    maizeUseType: MaizeUseType.grain,
    r1Days: RangeInt(85, 95),
    endWindowDays: RangeInt(145, 160),
    endActionLabel: 'Cosecha',
    plantHeightM: RangeDouble(2.25, 2.95),
    earHeightM: RangeDouble(0.95, 1.32),
    germinationDays: RangeInt(4, 7),
    emergenceDays: RangeInt(7, 12),
    vegEarlyDays: RangeInt(12, 31),
  ),
  kMzg09: MaizeProfile(
    id: kMzg09,
    label: 'MZG-09 · Grano largo de riego',
    useType: 'Grano',
    maizeUseType: MaizeUseType.grain,
    r1Days: RangeInt(90, 100),
    endWindowDays: RangeInt(155, 170),
    endActionLabel: 'Cosecha',
    plantHeightM: RangeDouble(2.35, 3.05),
    earHeightM: RangeDouble(1.00, 1.38),
    germinationDays: RangeInt(4, 7),
    emergenceDays: RangeInt(7, 12),
    vegEarlyDays: RangeInt(12, 32),
  ),

  // ── Elote ────────────────────────────────────────────────────────────────
  kMze00: MaizeProfile(
    id: kMze00,
    label: 'MZE-00 · Elote intermedio',
    useType: 'Elote',
    maizeUseType: MaizeUseType.elote,
    r1Days: RangeInt(58, 68),
    endWindowDays: RangeInt(78, 92),
    endActionLabel: 'Cosecha elote',
    plantHeightM: RangeDouble(1.80, 2.40),
    earHeightM: RangeDouble(0.70, 1.08),
    germinationDays: RangeInt(4, 7),
    emergenceDays: RangeInt(7, 10),
    vegEarlyDays: RangeInt(10, 25),
  ),

  // ── Genéricos ────────────────────────────────────────────────────────────
  kMzgGenB: MaizeProfile(
    id: kMzgGenB,
    label: 'MZG-GEN-B · Blanco / intermedio conservador',
    useType: 'Grano',
    maizeUseType: MaizeUseType.grain,
    r1Days: RangeInt(72, 80),
    endWindowDays: RangeInt(125, 138),
    endActionLabel: 'Cosecha',
    plantHeightM: RangeDouble(2.00, 2.60),
    earHeightM: RangeDouble(0.82, 1.15),
    germinationDays: RangeInt(4, 7),
    emergenceDays: RangeInt(7, 11),
    vegEarlyDays: RangeInt(11, 27),
  ),
  kMzgGenA: MaizeProfile(
    id: kMzgGenA,
    label: 'MZG-GEN-A · Amarillo / intermedio conservador',
    useType: 'Grano',
    maizeUseType: MaizeUseType.grain,
    r1Days: RangeInt(70, 78),
    endWindowDays: RangeInt(120, 134),
    endActionLabel: 'Cosecha',
    plantHeightM: RangeDouble(1.95, 2.55),
    earHeightM: RangeDouble(0.80, 1.12),
    germinationDays: RangeInt(4, 7),
    emergenceDays: RangeInt(7, 11),
    vegEarlyDays: RangeInt(11, 27),
  ),
  kMzfGen: MaizeProfile(
    id: kMzfGen,
    label: 'MZF-GEN · Forrajero conservador',
    useType: 'Forraje',
    maizeUseType: MaizeUseType.forage,
    r1Days: RangeInt(66, 74),
    endWindowDays: RangeInt(100, 115),
    endActionLabel: 'Corte',
    plantHeightM: RangeDouble(2.05, 2.70),
    earHeightM: RangeDouble(0.88, 1.20),
    germinationDays: RangeInt(4, 7),
    emergenceDays: RangeInt(7, 11),
    vegEarlyDays: RangeInt(11, 27),
  ),
  kMzeGen: MaizeProfile(
    id: kMzeGen,
    label: 'MZE-GEN · Elote conservador',
    useType: 'Elote',
    maizeUseType: MaizeUseType.elote,
    r1Days: RangeInt(58, 66),
    endWindowDays: RangeInt(78, 90),
    endActionLabel: 'Cosecha elote',
    plantHeightM: RangeDouble(1.80, 2.35),
    earHeightM: RangeDouble(0.72, 1.05),
    germinationDays: RangeInt(4, 7),
    emergenceDays: RangeInt(7, 10),
    vegEarlyDays: RangeInt(10, 25),
  ),
  kMaizeGenericProfileId: MaizeProfile(
    id: kMaizeGenericProfileId,
    label: 'MZG-GEN · Legacy',
    useType: 'Grano',
    maizeUseType: MaizeUseType.grain,
    r1Days: RangeInt(72, 80),
    endWindowDays: RangeInt(125, 138),
    endActionLabel: 'Cosecha',
    plantHeightM: RangeDouble(2.00, 2.60),
    earHeightM: RangeDouble(0.82, 1.15),
    germinationDays: RangeInt(4, 7),
    emergenceDays: RangeInt(7, 11),
    vegEarlyDays: RangeInt(11, 27),
  ),
};

final Map<String, String> _maizeProfileAliasToCanonical = {
  // IDs directos y variantes.
  ..._aliasSet(kMzf00, [kMzf00, 'mzf-00', 'forrajero precoz', 'maiz forrajero precoz', 'maíz forrajero precoz']),
  ..._aliasSet(kMzf01, [kMzf01, 'mzf-01', 'forrajero intermedio temprano', 'maiz forrajero intermedio temprano', 'maíz forrajero intermedio temprano']),
  ..._aliasSet(kMzf02, [kMzf02, 'mzf-02', 'forrajero intermedio', 'maiz forrajero intermedio', 'maíz forrajero intermedio']),
  ..._aliasSet(kMzf03, [kMzf03, 'mzf-03', 'forrajero intermedio tardio', 'forrajero intermedio tardío', 'maiz forrajero intermedio tardio', 'maíz forrajero intermedio tardío']),
  ..._aliasSet(kMzf04, [kMzf04, 'mzf-04', 'forrajero tardio', 'forrajero tardío', 'maiz forrajero tardio', 'maíz forrajero tardío']),
  ..._aliasSet(kMzf05, [kMzf05, 'mzf-05', 'forrajero intermedio calido', 'forrajero intermedio cálido', 'maiz forrajero calido', 'maíz forrajero cálido']),
  ..._aliasSet(kMzf06, [kMzf06, 'mzf-06', 'forrajero super precoz', 'forrajero súper precoz', 'maiz forrajero super precoz', 'maíz forrajero súper precoz']),

  ..._aliasSet(kMzg00, [kMzg00, 'mzg-00', 'grano precoz extremo', 'maiz grano precoz extremo', 'maíz grano precoz extremo']),
  ..._aliasSet(kMzg01, [kMzg01, 'mzg-01', 'grano precoz', 'maiz grano precoz', 'maíz grano precoz']),
  ..._aliasSet(kMzg02, [kMzg02, 'mzg-02', 'grano intermedio precoz', 'maiz grano intermedio precoz', 'maíz grano intermedio precoz']),
  ..._aliasSet(kMzg03, [kMzg03, 'mzg-03', 'grano intermedio estandar', 'grano intermedio estándar', 'maiz grano intermedio', 'maíz grano intermedio', 'intermedio estandar', 'intermedio estándar']),
  ..._aliasSet(kMzg04, [kMzg04, 'mzg-04', 'grano intermedio tardio', 'grano intermedio tardío', 'maiz grano intermedio tardio', 'maíz grano intermedio tardío']),
  ..._aliasSet(kMzg05, [kMzg05, 'mzg-05', 'grano intermedio tardio calido', 'grano intermedio tardío cálido', 'maiz grano calido', 'maíz grano cálido']),
  ..._aliasSet(kMzg06, [kMzg06, 'mzg-06', 'grano intermedio corto tropical', 'maiz tropical corto', 'maíz tropical corto']),
  ..._aliasSet(kMzg07, [kMzg07, 'mzg-07', 'grano intermedio corto invernal', 'maiz invernal corto', 'maíz invernal corto']),
  ..._aliasSet(kMzg08, [kMzg08, 'mzg-08', 'grano tardio extendido', 'grano tardío extendido', 'maiz grano tardio', 'maíz grano tardío']),
  ..._aliasSet(kMzg09, [kMzg09, 'mzg-09', 'grano largo de riego', 'maiz largo de riego', 'maíz largo de riego']),

  ..._aliasSet(kMze00, [kMze00, 'mze-00', 'elote intermedio', 'maiz elotero', 'maíz elotero']),

  ..._aliasSet(kMzgGenB, [kMzgGenB, 'mzg-gen-b', 'generico blanco', 'genérico blanco', 'generico blanco grano', 'genérico blanco/grano', 'generic white grain', 'maize white generic', 'maiz blanco', 'maíz blanco']),
  ..._aliasSet(kMzgGenA, [kMzgGenA, 'mzg-gen-a', 'generico amarillo', 'genérico amarillo', 'generico amarillo grano', 'genérico amarillo/grano', 'generic yellow grain', 'maize yellow generic', 'maiz amarillo', 'maíz amarillo']),
  ..._aliasSet(kMzfGen, [kMzfGen, 'mzf-gen', 'generico forrajero', 'genérico forrajero', 'generic forage', 'maize forage generic', 'maiz forrajero', 'maíz forrajero']),
  ..._aliasSet(kMzeGen, [kMzeGen, 'mze-gen', 'generico elote', 'genérico elote', 'generic elote', 'maize elote generic', 'elote generico', 'elote genérico']),
  ..._aliasSet(kMaizeGenericProfileId, [kMaizeGenericProfileId, 'generic', 'generic maize', 'generic corn', 'perfil generico', 'perfil genérico', 'maize generic']),
};

Map<String, String> _aliasSet(String canonical, List<String> aliases) {
  return {
    for (final alias in aliases) _normalizeMaizeProfileRaw(alias): canonical,
  };
}

String? resolveCanonicalMaizeProfileId(String raw) {
  final normalized = _normalizeMaizeProfileRaw(raw);
  if (normalized.isEmpty) return null;
  return _maizeProfileAliasToCanonical[normalized];
}

String _normalizeMaizeProfileRaw(String raw) {
  var value = raw.trim().toLowerCase();
  const replacements = {
    'á': 'a',
    'é': 'e',
    'í': 'i',
    'ó': 'o',
    'ú': 'u',
    'ü': 'u',
    'ñ': 'n',
  };
  replacements.forEach((from, to) {
    value = value.replaceAll(from, to);
  });
  value = value.replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
  return value;
}
