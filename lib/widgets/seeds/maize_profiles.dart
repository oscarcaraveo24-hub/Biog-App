// lib/widgets/seeds/maize_profiles.dart
//
// Tabla Maestra Completa Bio-G v1 — Perfiles de Maíz
// ─────────────────────────────────────────────────────
// MZF-00..06  Forrajeros   (7 perfiles)
// MZG-00..09  Grano        (10 perfiles)
// MZE-00      Elote        (1 perfil)
// MZG-GEN-B   Genérico blanco/grano
// MZG-GEN-A   Genérico amarillo/grano
// MZF-GEN     Genérico forrajero
// MZE-GEN     Genérico elote
// maize_generic  Legacy ID (= MZG-07, backward compat)

import 'package:bio_g/widgets/seeds/maize_models.dart';

// ─── IDs canónicos ───────────────────────────────────────────────────────────

// Forrajeros
const String kMzf00 = 'mzf_00';
const String kMzf01 = 'mzf_01';
const String kMzf02 = 'mzf_02';
const String kMzf03 = 'mzf_03';
const String kMzf04 = 'mzf_04';
const String kMzf05 = 'mzf_05';
const String kMzf06 = 'mzf_06';

// Grano
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

// Elote
const String kMze00 = 'mze_00';

// Genéricos
const String kMzgGenB = 'mzg_gen_b'; // blanco/grano genérico
const String kMzgGenA = 'mzg_gen_a'; // amarillo/grano genérico
const String kMzfGen  = 'mzf_gen';   // forrajero genérico
const String kMzeGen  = 'mze_gen';   // elote genérico

// Legacy — IDs que pueden estar en SharedPrefs de usuarios anteriores
const String kMaizeGenericProfileId       = 'maize_generic';
const String kMaizeLegacyGenericProfileId = 'MZG-07';

// ─── Mapa principal ──────────────────────────────────────────────────────────

const Map<String, MaizeProfile> maizeProfiles = {

  // ══════════════════════════════════════════════════════════════════════════
  // FORRAJEROS
  // ══════════════════════════════════════════════════════════════════════════

  /// MZF-00 — Forrajero precoz  (R1: 60–65 d · Corte: 110–115 d)
  kMzf00: MaizeProfile(
    id: kMzf00,
    label: 'Forrajero precoz',
    useType: 'Forraje',
    maizeUseType: MaizeUseType.forage,
    r1Days: RangeInt(60, 65),
    endWindowDays: RangeInt(110, 115),
    endActionLabel: 'Corte',
    plantHeightM: RangeDouble(2.80, 3.00),
    earHeightM: RangeDouble(1.45, 1.60),
    germinationDays: RangeInt(3, 7),
    emergenceDays: RangeInt(5, 10),
    vegEarlyDays: RangeInt(10, 25),
  ),

  /// MZF-01 — Forrajero intermedio temprano  (R1: 65–70 d · Corte: 100–115 d)
  kMzf01: MaizeProfile(
    id: kMzf01,
    label: 'Forrajero intermedio temprano',
    useType: 'Forraje',
    maizeUseType: MaizeUseType.forage,
    r1Days: RangeInt(65, 70),
    endWindowDays: RangeInt(100, 115),
    endActionLabel: 'Corte',
    plantHeightM: RangeDouble(2.70, 3.10),
    earHeightM: RangeDouble(1.40, 1.45),
    germinationDays: RangeInt(3, 7),
    emergenceDays: RangeInt(5, 10),
    vegEarlyDays: RangeInt(10, 25),
  ),

  /// MZF-02 — Forrajero intermedio  (R1: 68–75 d · Corte: 110–120 d)
  kMzf02: MaizeProfile(
    id: kMzf02,
    label: 'Forrajero intermedio',
    useType: 'Forraje',
    maizeUseType: MaizeUseType.forage,
    r1Days: RangeInt(68, 75),
    endWindowDays: RangeInt(110, 120),
    endActionLabel: 'Corte',
    plantHeightM: RangeDouble(2.70, 3.10),
    earHeightM: RangeDouble(1.45, 1.55),
    germinationDays: RangeInt(3, 7),
    emergenceDays: RangeInt(5, 10),
    vegEarlyDays: RangeInt(10, 25),
  ),

  /// MZF-03 — Forrajero intermedio tardío  (R1: 75–80 d · Corte: 115–130 d)
  kMzf03: MaizeProfile(
    id: kMzf03,
    label: 'Forrajero intermedio tardío',
    useType: 'Forraje',
    maizeUseType: MaizeUseType.forage,
    r1Days: RangeInt(75, 80),
    endWindowDays: RangeInt(115, 130),
    endActionLabel: 'Corte',
    plantHeightM: RangeDouble(2.80, 3.20),
    earHeightM: RangeDouble(1.50, 1.65),
    germinationDays: RangeInt(3, 7),
    emergenceDays: RangeInt(5, 10),
    vegEarlyDays: RangeInt(10, 28),
  ),

  /// MZF-04 — Forrajero tardío  (R1: 80–85 d · Corte: 115–130 d)
  kMzf04: MaizeProfile(
    id: kMzf04,
    label: 'Forrajero tardío',
    useType: 'Forraje',
    maizeUseType: MaizeUseType.forage,
    r1Days: RangeInt(80, 85),
    endWindowDays: RangeInt(115, 130),
    endActionLabel: 'Corte',
    plantHeightM: RangeDouble(2.70, 3.20),
    earHeightM: RangeDouble(1.60, 1.65),
    germinationDays: RangeInt(3, 7),
    emergenceDays: RangeInt(5, 10),
    vegEarlyDays: RangeInt(10, 30),
  ),

  /// MZF-05 — Forrajero intermedio cálido  (R1: 58–75 d · Corte: 120–135 d)
  kMzf05: MaizeProfile(
    id: kMzf05,
    label: 'Forrajero intermedio cálido',
    useType: 'Forraje',
    maizeUseType: MaizeUseType.forage,
    r1Days: RangeInt(58, 75),
    endWindowDays: RangeInt(120, 135),
    endActionLabel: 'Corte',
    plantHeightM: RangeDouble(2.90, 3.15),
    earHeightM: RangeDouble(1.50, 1.70),
    germinationDays: RangeInt(3, 7),
    emergenceDays: RangeInt(5, 10),
    vegEarlyDays: RangeInt(10, 25),
  ),

  /// MZF-06 — Forrajero súper precoz  (R1: 60–66 d · Corte: 90–98 d)
  kMzf06: MaizeProfile(
    id: kMzf06,
    label: 'Forrajero súper precoz',
    useType: 'Forraje',
    maizeUseType: MaizeUseType.forage,
    r1Days: RangeInt(60, 66),
    endWindowDays: RangeInt(90, 98),
    endActionLabel: 'Corte',
    plantHeightM: RangeDouble(2.30, 2.65),
    earHeightM: RangeDouble(0.90, 1.10),
    germinationDays: RangeInt(3, 7),
    emergenceDays: RangeInt(5, 10),
    vegEarlyDays: RangeInt(10, 22),
  ),

  // ══════════════════════════════════════════════════════════════════════════
  // GRANO
  // ══════════════════════════════════════════════════════════════════════════

  /// MZG-00 — Precoz extremo  (R1: 58–63 d · Cosecha: 160–165 d)
  kMzg00: MaizeProfile(
    id: kMzg00,
    label: 'Grano precoz extremo',
    useType: 'Grano',
    maizeUseType: MaizeUseType.grain,
    r1Days: RangeInt(58, 63),
    endWindowDays: RangeInt(160, 165),
    endActionLabel: 'Cosecha',
    plantHeightM: RangeDouble(2.90, 3.00),
    earHeightM: RangeDouble(1.50, 1.60),
    germinationDays: RangeInt(3, 7),
    emergenceDays: RangeInt(5, 10),
    vegEarlyDays: RangeInt(10, 22),
  ),

  /// MZG-01 — Precoz  (R1: 60–65 d · Cosecha: 170–175 d)
  kMzg01: MaizeProfile(
    id: kMzg01,
    label: 'Grano precoz',
    useType: 'Grano',
    maizeUseType: MaizeUseType.grain,
    r1Days: RangeInt(60, 65),
    endWindowDays: RangeInt(170, 175),
    endActionLabel: 'Cosecha',
    plantHeightM: RangeDouble(2.90, 3.00),
    earHeightM: RangeDouble(1.50, 1.60),
    germinationDays: RangeInt(3, 7),
    emergenceDays: RangeInt(5, 10),
    vegEarlyDays: RangeInt(10, 25),
  ),

  /// MZG-02 — Intermedio precoz  (R1: 74–81 d · Cosecha: 170–180 d)
  kMzg02: MaizeProfile(
    id: kMzg02,
    label: 'Grano intermedio precoz',
    useType: 'Grano',
    maizeUseType: MaizeUseType.grain,
    r1Days: RangeInt(74, 81),
    endWindowDays: RangeInt(170, 180),
    endActionLabel: 'Cosecha',
    plantHeightM: RangeDouble(2.18, 2.61),
    earHeightM: RangeDouble(0.97, 1.24),
    germinationDays: RangeInt(3, 7),
    emergenceDays: RangeInt(5, 10),
    vegEarlyDays: RangeInt(10, 28),
  ),

  /// MZG-03 — Intermedio estándar  (R1: 65–83 d · Cosecha: 175–185 d)
  kMzg03: MaizeProfile(
    id: kMzg03,
    label: 'Grano intermedio estándar',
    useType: 'Grano',
    maizeUseType: MaizeUseType.grain,
    r1Days: RangeInt(65, 83),
    endWindowDays: RangeInt(175, 185),
    endActionLabel: 'Cosecha',
    plantHeightM: RangeDouble(2.16, 2.53),
    earHeightM: RangeDouble(0.90, 1.12),
    germinationDays: RangeInt(3, 7),
    emergenceDays: RangeInt(5, 10),
    vegEarlyDays: RangeInt(10, 30),
  ),

  /// MZG-04 — Intermedio tardío  (R1: 76–85 d · Cosecha: 185–190 d)
  kMzg04: MaizeProfile(
    id: kMzg04,
    label: 'Grano intermedio tardío',
    useType: 'Grano',
    maizeUseType: MaizeUseType.grain,
    r1Days: RangeInt(76, 85),
    endWindowDays: RangeInt(185, 190),
    endActionLabel: 'Cosecha',
    plantHeightM: RangeDouble(2.46, 3.30),
    earHeightM: RangeDouble(1.04, 1.70),
    germinationDays: RangeInt(3, 7),
    emergenceDays: RangeInt(5, 10),
    vegEarlyDays: RangeInt(10, 30),
  ),

  /// MZG-05 — Intermedio tardío cálido OI  (R1: 80–95 d · Cosecha: 180–190 d)
  kMzg05: MaizeProfile(
    id: kMzg05,
    label: 'Grano intermedio tardío cálido',
    useType: 'Grano',
    maizeUseType: MaizeUseType.grain,
    r1Days: RangeInt(80, 95),
    endWindowDays: RangeInt(180, 190),
    endActionLabel: 'Cosecha',
    plantHeightM: RangeDouble(2.80, 3.10),
    earHeightM: RangeDouble(1.60, 1.65),
    germinationDays: RangeInt(3, 7),
    emergenceDays: RangeInt(5, 10),
    vegEarlyDays: RangeInt(10, 32),
  ),

  /// MZG-06 — Intermedio corto tropical  (R1: 53–75 d · Cosecha: 145–160 d)
  kMzg06: MaizeProfile(
    id: kMzg06,
    label: 'Grano intermedio corto tropical',
    useType: 'Grano',
    maizeUseType: MaizeUseType.grain,
    r1Days: RangeInt(53, 75),
    endWindowDays: RangeInt(145, 160),
    endActionLabel: 'Cosecha',
    plantHeightM: RangeDouble(2.35, 2.95),
    earHeightM: RangeDouble(1.22, 1.63),
    germinationDays: RangeInt(3, 7),
    emergenceDays: RangeInt(5, 10),
    vegEarlyDays: RangeInt(10, 25),
  ),

  /// MZG-07 — Intermedio corto invernal  (R1: 73–80 d · Cosecha: 135–150 d)
  /// Mismo dato que el legacy 'maize_generic'. Se conserva como perfil propio.
  kMzg07: MaizeProfile(
    id: kMzg07,
    label: 'Grano intermedio corto invernal',
    useType: 'Grano',
    maizeUseType: MaizeUseType.grain,
    r1Days: RangeInt(73, 80),
    endWindowDays: RangeInt(135, 150),
    endActionLabel: 'Cosecha',
    plantHeightM: RangeDouble(1.90, 2.12),
    earHeightM: RangeDouble(0.80, 1.10),
    germinationDays: RangeInt(3, 7),
    emergenceDays: RangeInt(5, 12),
    vegEarlyDays: RangeInt(12, 30),
  ),

  /// MZG-08 — Intermedio tardío extendido  (R1: 85–95 d · Cosecha: 190–205 d)
  kMzg08: MaizeProfile(
    id: kMzg08,
    label: 'Grano intermedio tardío extendido',
    useType: 'Grano',
    maizeUseType: MaizeUseType.grain,
    r1Days: RangeInt(85, 95),
    endWindowDays: RangeInt(190, 205),
    endActionLabel: 'Cosecha',
    plantHeightM: RangeDouble(2.20, 3.00),
    earHeightM: RangeDouble(1.10, 1.60),
    germinationDays: RangeInt(3, 7),
    emergenceDays: RangeInt(5, 10),
    vegEarlyDays: RangeInt(10, 32),
  ),

  /// MZG-09 — Largo de riego  (R1: 85–100 d · Cosecha: 215–240 d)
  kMzg09: MaizeProfile(
    id: kMzg09,
    label: 'Grano largo de riego',
    useType: 'Grano',
    maizeUseType: MaizeUseType.grain,
    r1Days: RangeInt(85, 100),
    endWindowDays: RangeInt(215, 240),
    endActionLabel: 'Cosecha',
    plantHeightM: RangeDouble(2.25, 2.65),
    earHeightM: RangeDouble(1.00, 1.30),
    germinationDays: RangeInt(3, 7),
    emergenceDays: RangeInt(5, 10),
    vegEarlyDays: RangeInt(10, 35),
  ),

  // ══════════════════════════════════════════════════════════════════════════
  // ELOTE
  // ══════════════════════════════════════════════════════════════════════════

  /// MZE-00 — Elote intermedio  (R1: 65–75 d · Cosecha: 95–120 d)
  kMze00: MaizeProfile(
    id: kMze00,
    label: 'Elote intermedio',
    useType: 'Elote',
    maizeUseType: MaizeUseType.elote,
    r1Days: RangeInt(65, 75),
    endWindowDays: RangeInt(95, 120),
    endActionLabel: 'Cosecha elote',
    plantHeightM: RangeDouble(2.10, 2.80),
    earHeightM: RangeDouble(1.10, 1.40),
    germinationDays: RangeInt(3, 7),
    emergenceDays: RangeInt(5, 10),
    vegEarlyDays: RangeInt(10, 25),
  ),

  // ══════════════════════════════════════════════════════════════════════════
  // GENÉRICOS — "No sé mi semilla"
  // ══════════════════════════════════════════════════════════════════════════

  /// Blanco/grano genérico — rango amplio basado en MZG-03
  kMzgGenB: MaizeProfile(
    id: kMzgGenB,
    label: 'Maíz blanco genérico',
    useType: 'Grano',
    maizeUseType: MaizeUseType.grain,
    r1Days: RangeInt(65, 83),
    endWindowDays: RangeInt(170, 185),
    endActionLabel: 'Cosecha',
    plantHeightM: RangeDouble(2.16, 2.90),
    earHeightM: RangeDouble(0.90, 1.40),
    germinationDays: RangeInt(3, 7),
    emergenceDays: RangeInt(5, 10),
    vegEarlyDays: RangeInt(10, 30),
  ),

  /// Amarillo/grano genérico — promedio MZG-03/MZG-04
  kMzgGenA: MaizeProfile(
    id: kMzgGenA,
    label: 'Maíz amarillo genérico',
    useType: 'Grano',
    maizeUseType: MaizeUseType.grain,
    r1Days: RangeInt(65, 85),
    endWindowDays: RangeInt(170, 190),
    endActionLabel: 'Cosecha',
    plantHeightM: RangeDouble(2.20, 3.00),
    earHeightM: RangeDouble(0.90, 1.50),
    germinationDays: RangeInt(3, 7),
    emergenceDays: RangeInt(5, 10),
    vegEarlyDays: RangeInt(10, 30),
  ),

  /// Forrajero genérico — basado en MZF-02 (más común en México)
  kMzfGen: MaizeProfile(
    id: kMzfGen,
    label: 'Maíz forrajero genérico',
    useType: 'Forraje',
    maizeUseType: MaizeUseType.forage,
    r1Days: RangeInt(65, 75),
    endWindowDays: RangeInt(105, 125),
    endActionLabel: 'Corte',
    plantHeightM: RangeDouble(2.70, 3.10),
    earHeightM: RangeDouble(1.40, 1.60),
    germinationDays: RangeInt(3, 7),
    emergenceDays: RangeInt(5, 10),
    vegEarlyDays: RangeInt(10, 25),
  ),

  /// Elote genérico
  kMzeGen: MaizeProfile(
    id: kMzeGen,
    label: 'Elote genérico',
    useType: 'Elote',
    maizeUseType: MaizeUseType.elote,
    r1Days: RangeInt(65, 75),
    endWindowDays: RangeInt(95, 120),
    endActionLabel: 'Cosecha elote',
    plantHeightM: RangeDouble(2.10, 2.80),
    earHeightM: RangeDouble(1.10, 1.40),
    germinationDays: RangeInt(3, 7),
    emergenceDays: RangeInt(5, 10),
    vegEarlyDays: RangeInt(10, 25),
  ),

  // ══════════════════════════════════════════════════════════════════════════
  // LEGACY — no remover (backward compat SharedPrefs)
  // 'maize_generic' es el ID que pueden tener usuarios con versión anterior.
  // Apunta a los mismos datos que MZG-07.
  // ══════════════════════════════════════════════════════════════════════════
  kMaizeGenericProfileId: MaizeProfile(
    id: kMaizeGenericProfileId,
    label: 'Intermedio corto invernal',
    useType: 'Grano',
    maizeUseType: MaizeUseType.grain,
    r1Days: RangeInt(73, 80),
    endWindowDays: RangeInt(135, 150),
    endActionLabel: 'Cosecha',
    plantHeightM: RangeDouble(1.90, 2.12),
    earHeightM: RangeDouble(0.80, 1.10),
    germinationDays: RangeInt(3, 7),
    emergenceDays: RangeInt(5, 12),
    vegEarlyDays: RangeInt(12, 30),
  ),
};

// ─── Alias: string corto / legacy → profileId canónico ──────────────────────
//
// Prioridad de resolución (wizard + resolver):
//   1. varietyEntry.defaultProfileId  (viene del catálogo, la más confiable)
//   2. maizeVarietyAliasToProfile[normalized]  (aliases explícitos)
//   3. Fallback → kMzgGenB

const Map<String, String> maizeVarietyAliasToProfile = {
  // ── Legacy ──────────────────────────────────────────────────────────────
  'MZG-07':        kMaizeGenericProfileId,
  'MAIZE_GENERIC': kMaizeGenericProfileId,
  // DK-2069: en versiones anteriores se resolvía como genérico; ahora → MZG-07
  'DK2069':        kMzg07,
  'DK-2069':       kMzg07,

  // ── IDs cortos de perfil (para resolver desde un string tipo "MZF-02") ──
  'MZF-00': kMzf00, 'MZF-01': kMzf01, 'MZF-02': kMzf02,
  'MZF-03': kMzf03, 'MZF-04': kMzf04, 'MZF-05': kMzf05, 'MZF-06': kMzf06,
  'MZG-00': kMzg00, 'MZG-01': kMzg01, 'MZG-02': kMzg02, 'MZG-03': kMzg03,
  'MZG-04': kMzg04, 'MZG-05': kMzg05, 'MZG-06': kMzg06,
  'MZG-08': kMzg08, 'MZG-09': kMzg09,
  'MZE-00': kMze00,
  'MZG-GEN-B': kMzgGenB, 'MZG-GEN-A': kMzgGenA,
  'MZF-GEN': kMzfGen,    'MZE-GEN': kMzeGen,
};

// ─── Helpers ─────────────────────────────────────────────────────────────────

/// Resuelve un string crudo (profileId corto, alias legacy, etc.) al ID
/// canónico de [maizeProfiles]. Devuelve null si no hay match.
String? resolveCanonicalMaizeProfileId(String raw) {
  final normalized = _normalizeAlias(raw);
  if (normalized.isEmpty) return null;

  // 1. Match directo como clave del mapa (snake_case)
  if (maizeProfiles.containsKey(raw)) return raw;
  if (maizeProfiles.containsKey(raw.toLowerCase())) return raw.toLowerCase();

  // 2. Lookup en alias (upper-case normalizado)
  return maizeVarietyAliasToProfile[normalized];
}

MaizeProfile? resolveMaizeProfileFromAlias(String alias) {
  final id = resolveCanonicalMaizeProfileId(alias);
  if (id == null) return null;
  return maizeProfiles[id];
}

/// Resuelve o devuelve el genérico blanco como fallback seguro.
MaizeProfile resolveOrDefaultMaizeProfile(String alias) {
  return resolveMaizeProfileFromAlias(alias) ??
      maizeProfiles[kMzgGenB] ??
      maizeProfiles[kMaizeGenericProfileId] ??
      maizeProfiles.values.first;
}

String _normalizeAlias(String raw) => raw.trim().toUpperCase();
