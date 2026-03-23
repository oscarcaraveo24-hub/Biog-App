// lib/widgets/seeds/wheat_profiles.dart
//
// Tabla Maestra Bio-G v1 — Perfiles de Trigo
// ────────────────────────────────────────────
// TR-01   Precoz (temporal corto / escape a calor)
// TR-02   Intermedio / Harinero  (estándar nacional MX)
// TR-03   Largo / Cristalino (riego / alto potencial)
// TR-GEN  Genérico / General
//
// Fuentes: fichas técnicas Bio-G, INIFAP trigo,
//          CIMMYT variedades liberadas.

import 'package:bio_g/widgets/seeds/maize_models.dart';
import 'package:bio_g/widgets/seeds/wheat_models.dart';

// ─── IDs canónicos ──────────────────────────────────────────────────────────

const String kTr01  = 'tr_01';
const String kTr02  = 'tr_02';
const String kTr03  = 'tr_03';
const String kTrGen = 'tr_gen';

// ─── Perfiles ───────────────────────────────────────────────────────────────

const Map<String, WheatProfile> wheatProfiles = {
  // ── TR-01 Precoz ─────────────────────────────────────────────────────────
  // Temporal corto / escape a calor. Harinero o forrajero temprano.
  kTr01: WheatProfile(
    id: kTr01,
    label: 'TR-01 · Precoz',
    useType: 'Grano',
    wheatUseType: WheatUseType.bread,
    floweringDays: RangeInt(60, 75),
    endWindowDays: RangeInt(110, 130),
    endActionLabel: 'Cosecha',
    plantHeightM: RangeDouble(0.60, 0.85),
    spikeHeightM: RangeDouble(0.40, 0.60),
    germinationDays: RangeInt(4, 7),
    emergenceDays: RangeInt(7, 10),
    vegEarlyDays: RangeInt(10, 20),
  ),

  // ── TR-02 Intermedio / Harinero ──────────────────────────────────────────
  // El más usado en México. Grano harinero / panificable.
  kTr02: WheatProfile(
    id: kTr02,
    label: 'TR-02 · Intermedio / Harinero',
    useType: 'Grano harinero',
    wheatUseType: WheatUseType.bread,
    floweringDays: RangeInt(75, 95),
    endWindowDays: RangeInt(130, 155),
    endActionLabel: 'Cosecha',
    plantHeightM: RangeDouble(0.80, 1.10),
    spikeHeightM: RangeDouble(0.55, 0.75),
    germinationDays: RangeInt(4, 7),
    emergenceDays: RangeInt(7, 11),
    vegEarlyDays: RangeInt(11, 25),
  ),

  // ── TR-03 Largo / Cristalino ─────────────────────────────────────────────
  // Grano cristalino (durum) / harinero de alto potencial bajo riego.
  kTr03: WheatProfile(
    id: kTr03,
    label: 'TR-03 · Largo / Cristalino',
    useType: 'Grano cristalino',
    wheatUseType: WheatUseType.durum,
    floweringDays: RangeInt(95, 115),
    endWindowDays: RangeInt(155, 180),
    endActionLabel: 'Cosecha',
    plantHeightM: RangeDouble(1.00, 1.30),
    spikeHeightM: RangeDouble(0.70, 0.90),
    germinationDays: RangeInt(4, 7),
    emergenceDays: RangeInt(7, 12),
    vegEarlyDays: RangeInt(12, 30),
  ),

  // ── TR-GEN Genérico / General ────────────────────────────────────────────
  // Perfil conservador activado por SKIP.
  // Supuesto base: trigo harinero intermedio, manejo estándar, sin extremos.
  kTrGen: WheatProfile(
    id: kTrGen,
    label: 'TR-GEN · Intermedio Conservador',
    useType: 'Grano',
    wheatUseType: WheatUseType.bread,
    floweringDays: RangeInt(80, 90),
    endWindowDays: RangeInt(140, 155),
    endActionLabel: 'Cosecha',
    plantHeightM: RangeDouble(0.90, 1.05),
    spikeHeightM: RangeDouble(0.60, 0.75),
    germinationDays: RangeInt(4, 7),
    emergenceDays: RangeInt(7, 11),
    vegEarlyDays: RangeInt(11, 25),
  ),
};

// ─── Alias → ID canónico ────────────────────────────────────────────────────

const Map<String, String> _wheatProfileAliasToCanonical = {
  // TR-01 Precoz
  'tr-01': kTr01,
  'tr01': kTr01,
  'precoz': kTr01,
  'trigo precoz': kTr01,
  'temporal corto': kTr01,

  // TR-02 Intermedio / Harinero
  'tr-02': kTr02,
  'tr02': kTr02,
  'intermedio': kTr02,
  'harinero': kTr02,
  'trigo harinero': kTr02,
  'trigo intermedio': kTr02,
  'panificable': kTr02,
  'trigo panificable': kTr02,

  // TR-03 Largo / Cristalino
  'tr-03': kTr03,
  'tr03': kTr03,
  'largo': kTr03,
  'cristalino': kTr03,
  'durum': kTr03,
  'trigo cristalino': kTr03,
  'trigo durum': kTr03,
  'trigo largo': kTr03,
  'alto potencial': kTr03,

  // TR-GEN Genérico
  'tr-gen': kTrGen,
  'trgen': kTrGen,
  'tr_gen': kTrGen,
  'generico': kTrGen,
  'genérico': kTrGen,
  'trigo generico': kTrGen,
  'trigo genérico': kTrGen,
  'intermedio conservador': kTrGen,
};

/// Resuelve el ID canónico del perfil de trigo a partir de texto libre.
String? resolveCanonicalWheatProfileId(String raw) {
  final normalized = raw.trim().toLowerCase();
  if (normalized.isEmpty) return null;
  if (wheatProfiles.containsKey(normalized)) return normalized;
  return _wheatProfileAliasToCanonical[normalized];
}
