// lib/core/crops/oat/oat_catalog.dart
//
// Catálogo v1 de avena para Bio-G.
// Perfiles, variedades, y constantes usadas por CropCatalog.
//
// Fuentes: INIFAP variedades de avena, fichas técnicas Bio-G,
//          Semillas Berentsen catálogo comercial.

import 'package:bio_g/core/crops/catalog/crop_catalog_models.dart';
import 'package:bio_g/widgets/seeds/oat_profiles.dart';

const String kCropOat = 'oat';
const String kOatDefaultCalendarId = 'oat_default';

// ─── Marcas (Avena) ─────────────────────────────────────────────────────────
// Avena no sobrecarga marcas como maíz. Solo INIFAP y Berentsen en v1.

const List<CropBrandEntry> oatBrands = [
  CropBrandEntry(id: 'inifap_oat', label: 'INIFAP', cropId: kCropOat),
  CropBrandEntry(id: 'berentsen_oat', label: 'Semillas Berentsen', cropId: kCropOat),
];

// ─── Profile entries (validación catálogo) ──────────────────────────────────

const List<CropProfileEntry> oatProfileEntries = [
  CropProfileEntry(
    id: kAvf01,
    label: 'AVF-01 · Forrajera Precoz',
    cropId: kCropOat,
    subtitle: 'Ciclo corto, corte temprano',
    aliases: ['AVF-01', 'AVF01', 'Forrajera Precoz'],
  ),
  CropProfileEntry(
    id: kAvf02,
    label: 'AVF-02 · Forrajera Intermedia',
    cropId: kCropOat,
    subtitle: 'Estándar nacional de forraje',
    aliases: ['AVF-02', 'AVF02', 'Forrajera Intermedia', 'Forrajera'],
  ),
  CropProfileEntry(
    id: kAvg01,
    label: 'AVG-01 · Grano',
    cropId: kCropOat,
    subtitle: 'Cosecha de grano',
    aliases: ['AVG-01', 'AVG01', 'Grano'],
  ),
  CropProfileEntry(
    id: kAvd01,
    label: 'AVD-01 · Doble Propósito',
    cropId: kCropOat,
    subtitle: 'Forraje + grano',
    aliases: ['AVD-01', 'AVD01', 'Doble Propósito', 'Doble Proposito'],
  ),
  CropProfileEntry(
    id: kAvGen,
    label: 'AV-GEN · General',
    cropId: kCropOat,
    subtitle: 'Perfil conservador (SKIP)',
    aliases: ['AV-GEN', 'AVGEN', 'Genérico', 'Generico', 'General'],
  ),
];

// ─── Variedades ─────────────────────────────────────────────────────────────

const List<CropVarietyEntry> oatVarieties = [
  // ── Forrajeras INIFAP ────────────────────────────────────────────────────
  CropVarietyEntry(
    id: 'oat_chihuahua',
    label: 'Avena Chihuahua',
    cropId: kCropOat,
    subtitle: 'Forrajera · INIFAP',
    defaultProfileId: kAvf01,
    brandId: 'inifap_oat',
    aliases: ['Chihuahua', 'Avena Chihuahua INIFAP'],
  ),
  CropVarietyEntry(
    id: 'oat_cuauhtemoc',
    label: 'Avena Cuauhtémoc',
    cropId: kCropOat,
    subtitle: 'Forrajera / Doble propósito · INIFAP',
    defaultProfileId: kAvf02,
    brandId: 'inifap_oat',
    aliases: ['Cuauhtémoc', 'Cuauhtemoc', 'Avena Cuauhtémoc INIFAP'],
  ),
  CropVarietyEntry(
    id: 'oat_menonita',
    label: 'Avena Menonita',
    cropId: kCropOat,
    subtitle: 'Forrajera · INIFAP',
    defaultProfileId: kAvf02,
    brandId: 'inifap_oat',
    aliases: ['Menonita', 'Avena Menonita INIFAP', 'Avena menonita'],
  ),
  CropVarietyEntry(
    id: 'oat_obispo',
    label: 'Avena Obispo',
    cropId: kCropOat,
    subtitle: 'Forrajera · INIFAP',
    defaultProfileId: kAvf02,
    brandId: 'inifap_oat',
    aliases: ['Obispo', 'Avena Obispo INIFAP'],
  ),

  // ── Forrajeras Berentsen ─────────────────────────────────────────────────
  CropVarietyEntry(
    id: 'oat_turquesa',
    label: 'Avena Turquesa',
    cropId: kCropOat,
    subtitle: 'Forrajera · Berentsen',
    defaultProfileId: kAvf02,
    brandId: 'berentsen_oat',
    aliases: ['Turquesa', 'Avena Turquesa Berentsen'],
  ),

  // ── Grano INIFAP ─────────────────────────────────────────────────────────
  CropVarietyEntry(
    id: 'oat_karma',
    label: 'Avena Karma',
    cropId: kCropOat,
    subtitle: 'Grano / Doble propósito · INIFAP',
    defaultProfileId: kAvg01,
    brandId: 'inifap_oat',
    aliases: ['Karma', 'Avena Karma INIFAP', 'Avena Karma Berentsen'],
  ),
  CropVarietyEntry(
    id: 'oat_agata',
    label: 'Avena Ágata',
    cropId: kCropOat,
    subtitle: 'Grano · INIFAP',
    defaultProfileId: kAvg01,
    brandId: 'inifap_oat',
    aliases: ['Ágata', 'Agata', 'Avena Ágata INIFAP'],
  ),

  // ── Genérica ─────────────────────────────────────────────────────────────
  CropVarietyEntry(
    id: 'oat_generic',
    label: 'Avena genérica',
    cropId: kCropOat,
    subtitle: 'Usar perfil general',
    defaultProfileId: kAvGen,
    aliases: [
      'Genérica',
      'Generica',
      'Avena genérica',
      'Avena generica',
      'Avena criolla',
      'Avena regional',
      'Avena de temporal',
      'Avena de costal',
      'AV-GEN',
      'AVGEN',
    ],
    isGeneric: true,
  ),
];
