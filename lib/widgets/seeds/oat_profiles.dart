// lib/widgets/seeds/oat_profiles.dart
//
// Tabla Maestra Bio-G v1 — Perfiles de Avena
// ────────────────────────────────────────────
// AVF-01   Forrajera Precoz
// AVF-02   Forrajera Intermedia
// AVG-01   Grano
// AVD-01   Doble Propósito
// AV-GEN   Genérico / General
//
// Fuentes: fichas técnicas Bio-G, INIFAP variedades de avena,
//          Semillas Berentsen catálogo comercial.

import 'package:bio_g/widgets/seeds/maize_models.dart';
import 'package:bio_g/widgets/seeds/oat_models.dart';

// ─── IDs canónicos ──────────────────────────────────────────────────────────

const String kAvf01 = 'avf_01';
const String kAvf02 = 'avf_02';
const String kAvg01 = 'avg_01';
const String kAvd01 = 'avd_01';
const String kAvGen = 'av_gen';

// ─── Perfiles ───────────────────────────────────────────────────────────────

const Map<String, OatProfile> oatProfiles = {
  // ── Forrajera Precoz ─────────────────────────────────────────────────────
  kAvf01: OatProfile(
    id: kAvf01,
    label: 'AVF-01 · Forrajera Precoz',
    useType: 'Forraje',
    oatUseType: OatUseType.forage,
    floweringDays: RangeInt(55, 65),
    endWindowDays: RangeInt(68, 82),
    endActionLabel: 'Corte',
    plantHeightM: RangeDouble(0.90, 1.20),
    germinationDays: RangeInt(4, 7),
    emergenceDays: RangeInt(7, 10),
    vegEarlyDays: RangeInt(10, 20),
  ),

  // ── Forrajera Intermedia ─────────────────────────────────────────────────
  kAvf02: OatProfile(
    id: kAvf02,
    label: 'AVF-02 · Forrajera Intermedia',
    useType: 'Forraje',
    oatUseType: OatUseType.forage,
    floweringDays: RangeInt(65, 80),
    endWindowDays: RangeInt(83, 98),
    endActionLabel: 'Corte',
    plantHeightM: RangeDouble(1.10, 1.40),
    germinationDays: RangeInt(4, 7),
    emergenceDays: RangeInt(7, 10),
    vegEarlyDays: RangeInt(10, 25),
  ),

  // ── Grano ────────────────────────────────────────────────────────────────
  kAvg01: OatProfile(
    id: kAvg01,
    label: 'AVG-01 · Grano',
    useType: 'Grano',
    oatUseType: OatUseType.grain,
    floweringDays: RangeInt(65, 80),
    endWindowDays: RangeInt(120, 145),
    endActionLabel: 'Cosecha',
    plantHeightM: RangeDouble(0.90, 1.20),
    germinationDays: RangeInt(4, 7),
    emergenceDays: RangeInt(7, 10),
    vegEarlyDays: RangeInt(10, 25),
  ),

  // ── Doble Propósito ──────────────────────────────────────────────────────
  kAvd01: OatProfile(
    id: kAvd01,
    label: 'AVD-01 · Doble Propósito',
    useType: 'Doble propósito',
    oatUseType: OatUseType.dualPurpose,
    floweringDays: RangeInt(65, 80),
    endWindowDays: RangeInt(135, 155),
    endActionLabel: 'Corte / Cosecha',
    plantHeightM: RangeDouble(1.10, 1.40),
    germinationDays: RangeInt(4, 7),
    emergenceDays: RangeInt(7, 10),
    vegEarlyDays: RangeInt(10, 25),
  ),

  // ── Genérico / General ───────────────────────────────────────────────────
  // Perfil conservador activado por SKIP. Cubre avena criolla, regional,
  // INIFAP sin identificar, temporal. ~80-90 % de casos reales.
  kAvGen: OatProfile(
    id: kAvGen,
    label: 'AV-GEN · General',
    useType: 'Forraje',
    oatUseType: OatUseType.forage,
    floweringDays: RangeInt(70, 80),
    endWindowDays: RangeInt(82, 96),
    endActionLabel: 'Corte',
    plantHeightM: RangeDouble(1.20, 1.40),
    germinationDays: RangeInt(4, 7),
    emergenceDays: RangeInt(7, 10),
    vegEarlyDays: RangeInt(10, 25),
  ),
};

// ─── Alias → ID canónico ────────────────────────────────────────────────────

const Map<String, String> _oatProfileAliasToCanonical = {
  // AVF-01 Forrajera Precoz
  'avf-01': kAvf01,
  'avf01': kAvf01,
  'forrajera precoz': kAvf01,
  'avena precoz': kAvf01,

  // AVF-02 Forrajera Intermedia
  'avf-02': kAvf02,
  'avf02': kAvf02,
  'forrajera intermedia': kAvf02,
  'forrajera': kAvf02,
  'avena forrajera': kAvf02,

  // AVG-01 Grano
  'avg-01': kAvg01,
  'avg01': kAvg01,
  'grano': kAvg01,
  'avena grano': kAvg01,

  // AVD-01 Doble Propósito
  'avd-01': kAvd01,
  'avd01': kAvd01,
  'doble proposito': kAvd01,
  'doble propósito': kAvd01,
  'avena doble proposito': kAvd01,
  'avena doble propósito': kAvd01,

  // AV-GEN Genérico
  'av-gen': kAvGen,
  'avgen': kAvGen,
  'av_gen': kAvGen,
  'generico': kAvGen,
  'genérico': kAvGen,
  'avena generica': kAvGen,
  'avena genérica': kAvGen,
  'general': kAvGen,
  'avena general': kAvGen,
};

/// Resuelve el ID canónico del perfil de avena a partir de texto libre.
String? resolveCanonicalOatProfileId(String raw) {
  final normalized = raw.trim().toLowerCase();
  if (normalized.isEmpty) return null;
  if (oatProfiles.containsKey(normalized)) return normalized;
  return _oatProfileAliasToCanonical[normalized];
}
