// lib/widgets/seeds/barley_profiles.dart
//
// Tabla Maestra Bio-G v1 — Perfiles de Cebada
// ─────────────────────────────────────────────
// CB-01   Precoz / Temprana
// CB-02   Intermedio / Maltera  (dominante en México)
// CB-03   Largo / Riego
// CB-04   Forrajera
// CB-GEN  Genérico / General
//
// Fuentes: fichas técnicas Bio-G, INIFAP cebada,
//          catálogos RAGT, Syngenta, LG Seeds, KWS.

import 'package:bio_g/widgets/seeds/barley_models.dart';
import 'package:bio_g/widgets/seeds/maize_models.dart';

// ─── IDs canónicos ──────────────────────────────────────────────────────────

const String kCb01 = 'cb_01';
const String kCb02 = 'cb_02';
const String kCb03 = 'cb_03';
const String kCb04 = 'cb_04';
const String kCbGen = 'cb_gen';

// ─── Perfiles ───────────────────────────────────────────────────────────────

const Map<String, BarleyProfile> barleyProfiles = {
  // ── CB-01 Precoz / Temprana ──────────────────────────────────────────────
  kCb01: BarleyProfile(
    id: kCb01,
    label: 'CB-01 · Precoz',
    useType: 'Grano',
    barleyUseType: BarleyUseType.grain,
    floweringDays: RangeInt(55, 70),
    endWindowDays: RangeInt(105, 125),
    endActionLabel: 'Cosecha',
    plantHeightM: RangeDouble(0.60, 0.85),
    spikeHeightM: RangeDouble(0.40, 0.60),
    germinationDays: RangeInt(4, 7),
    emergenceDays: RangeInt(7, 10),
    vegEarlyDays: RangeInt(10, 20),
  ),

  // ── CB-02 Intermedio / Maltera ───────────────────────────────────────────
  // La más conocida y sembrada en México. Grano maltero / industrial.
  kCb02: BarleyProfile(
    id: kCb02,
    label: 'CB-02 · Intermedio / Maltera',
    useType: 'Grano maltero',
    barleyUseType: BarleyUseType.malt,
    floweringDays: RangeInt(70, 90),
    endWindowDays: RangeInt(125, 155),
    endActionLabel: 'Cosecha',
    plantHeightM: RangeDouble(0.80, 1.10),
    spikeHeightM: RangeDouble(0.55, 0.75),
    germinationDays: RangeInt(4, 7),
    emergenceDays: RangeInt(7, 11),
    vegEarlyDays: RangeInt(10, 25),
  ),

  // ── CB-03 Largo / Riego ──────────────────────────────────────────────────
  kCb03: BarleyProfile(
    id: kCb03,
    label: 'CB-03 · Largo / Riego',
    useType: 'Grano',
    barleyUseType: BarleyUseType.grain,
    floweringDays: RangeInt(85, 105),
    endWindowDays: RangeInt(150, 180),
    endActionLabel: 'Cosecha',
    plantHeightM: RangeDouble(1.00, 1.30),
    spikeHeightM: RangeDouble(0.65, 0.85),
    germinationDays: RangeInt(4, 7),
    emergenceDays: RangeInt(7, 12),
    vegEarlyDays: RangeInt(12, 28),
  ),

  // ── CB-04 Forrajera ──────────────────────────────────────────────────────
  // Mantén la ventana final después de floración para que el adapter no rompa
  // el orden fenológico (grainFill → madurez → corte/cosecha).
  kCb04: BarleyProfile(
    id: kCb04,
    label: 'CB-04 · Forrajera',
    useType: 'Forraje',
    barleyUseType: BarleyUseType.forage,
    floweringDays: RangeInt(65, 90),
    endWindowDays: RangeInt(95, 115),
    endActionLabel: 'Corte',
    plantHeightM: RangeDouble(0.70, 1.20),
    spikeHeightM: RangeDouble(0.45, 0.75),
    germinationDays: RangeInt(4, 7),
    emergenceDays: RangeInt(7, 10),
    vegEarlyDays: RangeInt(10, 22),
  ),

  // ── CB-GEN Genérico / General ────────────────────────────────────────────
  // Perfil conservador activado por SKIP. Intermedio conservador.
  // No asume calidad maltera alta para no sobre-prometer.
  kCbGen: BarleyProfile(
    id: kCbGen,
    label: 'CB-GEN · Intermedio Conservador',
    useType: 'Grano',
    barleyUseType: BarleyUseType.grain,
    floweringDays: RangeInt(75, 95),
    endWindowDays: RangeInt(130, 160),
    endActionLabel: 'Cosecha',
    plantHeightM: RangeDouble(0.80, 1.10),
    spikeHeightM: RangeDouble(0.55, 0.75),
    germinationDays: RangeInt(4, 7),
    emergenceDays: RangeInt(7, 11),
    vegEarlyDays: RangeInt(10, 25),
  ),
};

// ─── Alias → ID canónico ────────────────────────────────────────────────────

const Map<String, String> _barleyProfileAliasToCanonical = {
  // CB-01 Precoz
  'cb-01': kCb01,
  'cb01': kCb01,
  'precoz': kCb01,
  'temprana': kCb01,
  'cebada temprana': kCb01,
  'cebada precoz': kCb01,
  'cebada corta': kCb01,

  // CB-02 Intermedio / Maltera
  'cb-02': kCb02,
  'cb02': kCb02,
  'intermedio': kCb02,
  'maltera': kCb02,
  'cebada maltera': kCb02,
  'cebada intermedia': kCb02,
  'grano maltero': kCb02,

  // CB-03 Largo / Riego
  'cb-03': kCb03,
  'cb03': kCb03,
  'largo': kCb03,
  'riego': kCb03,
  'cebada de riego': kCb03,
  'cebada larga': kCb03,
  'alto potencial': kCb03,

  // CB-04 Forrajera
  'cb-04': kCb04,
  'cb04': kCb04,
  'forrajera': kCb04,
  'cebada forrajera': kCb04,
  'forraje': kCb04,

  // CB-GEN Genérico
  'cb-gen': kCbGen,
  'cbgen': kCbGen,
  'cb_gen': kCbGen,
  'generico': kCbGen,
  'genérico': kCbGen,
  'cebada generica': kCbGen,
  'cebada genérica': kCbGen,
  'intermedio conservador': kCbGen,
};

/// Resuelve el ID canónico del perfil de cebada a partir de texto libre.
String? resolveCanonicalBarleyProfileId(String raw) {
  final normalized = raw.trim().toLowerCase();
  if (normalized.isEmpty) return null;
  if (barleyProfiles.containsKey(normalized)) return normalized;
  return _barleyProfileAliasToCanonical[normalized];
}
