// lib/core/crops/barley/barley_catalog.dart
//
// Catálogo v1 de cebada para Bio-G.
// Perfiles, variedades, y constantes usadas por CropCatalog.
//
// Fuentes: fichas técnicas Bio-G, INIFAP cebada maltera,
//          catálogos RAGT, Syngenta, LG Seeds, KWS.

import 'package:bio_g/core/crops/catalog/crop_catalog_models.dart';
import 'package:bio_g/widgets/seeds/barley_profiles.dart';

const String kCropBarley = 'barley';
const String kBarleyDefaultCalendarId = 'barley_default';

// ─── Profile entries (validación catálogo) ──────────────────────────────────

const List<CropProfileEntry> barleyProfileEntries = [
  CropProfileEntry(
    id: kCb01,
    label: 'CB-01 · Precoz',
    cropId: kCropBarley,
    subtitle: 'Grano / forraje temprano',
    aliases: ['CB-01', 'CB01', 'Precoz', 'Temprana'],
  ),
  CropProfileEntry(
    id: kCb02,
    label: 'CB-02 · Intermedio / Maltera',
    cropId: kCropBarley,
    subtitle: 'Grano maltero / industrial — dominante MX',
    aliases: ['CB-02', 'CB02', 'Intermedio', 'Maltera'],
  ),
  CropProfileEntry(
    id: kCb03,
    label: 'CB-03 · Largo / Riego',
    cropId: kCropBarley,
    subtitle: 'Alto potencial bajo riego',
    aliases: ['CB-03', 'CB03', 'Largo', 'Riego'],
  ),
  CropProfileEntry(
    id: kCb04,
    label: 'CB-04 · Forrajera',
    cropId: kCropBarley,
    subtitle: 'Corte temprano',
    aliases: ['CB-04', 'CB04', 'Forrajera'],
  ),
  CropProfileEntry(
    id: kCbGen,
    label: 'CB-GEN · Intermedio Conservador',
    cropId: kCropBarley,
    subtitle: 'Perfil conservador (SKIP)',
    aliases: ['CB-GEN', 'CBGEN', 'Genérico', 'Generico'],
  ),
];

// ─── Variedades ─────────────────────────────────────────────────────────────

const List<CropVarietyEntry> barleyVarieties = [
  // ── Temprana / Precoz ────────────────────────────────────────────────────
  CropVarietyEntry(
    id: 'barley_esperanza',
    label: 'Esperanza',
    cropId: kCropBarley,
    subtitle: 'Temprana · INIFAP',
    defaultProfileId: kCb01,
    aliases: ['Esperanza', 'Cebada Esperanza'],
  ),
  CropVarietyEntry(
    id: 'barley_maravilla',
    label: 'Maravilla',
    cropId: kCropBarley,
    subtitle: 'Temprana · INIFAP',
    defaultProfileId: kCb01,
    aliases: ['Maravilla', 'Cebada Maravilla'],
  ),
  CropVarietyEntry(
    id: 'barley_cucapah_87',
    label: 'Cucapah 87',
    cropId: kCropBarley,
    subtitle: 'Temprana',
    defaultProfileId: kCb01,
    aliases: ['Cucapah 87', 'Cucapah', 'Cebada Cucapah'],
  ),
  CropVarietyEntry(
    id: 'barley_lg_diablo',
    label: 'LG Diablo',
    cropId: kCropBarley,
    subtitle: 'Temprana · LG Seeds',
    defaultProfileId: kCb01,
    aliases: ['LG Diablo', 'Diablo'],
  ),
  CropVarietyEntry(
    id: 'barley_kws_fantex',
    label: 'KWS Fantex',
    cropId: kCropBarley,
    subtitle: 'Temprana · KWS',
    defaultProfileId: kCb01,
    aliases: ['KWS Fantex', 'Fantex'],
  ),

  // ── Maltera / Intermedia ─────────────────────────────────────────────────
  CropVarietyEntry(
    id: 'barley_esmeralda',
    label: 'Esmeralda',
    cropId: kCropBarley,
    subtitle: 'Maltera · INIFAP',
    defaultProfileId: kCb02,
    aliases: ['Esmeralda', 'Cebada Esmeralda'],
  ),
  CropVarietyEntry(
    id: 'barley_adabella',
    label: 'Adabella',
    cropId: kCropBarley,
    subtitle: 'Maltera · INIFAP',
    defaultProfileId: kCb02,
    aliases: ['Adabella', 'Cebada Adabella'],
  ),
  CropVarietyEntry(
    id: 'barley_armida',
    label: 'Armida',
    cropId: kCropBarley,
    subtitle: 'Maltera · INIFAP',
    defaultProfileId: kCb02,
    aliases: ['Armida', 'Cebada Armida'],
  ),
  CropVarietyEntry(
    id: 'barley_alina',
    label: 'Alina',
    cropId: kCropBarley,
    subtitle: 'Maltera · INIFAP',
    defaultProfileId: kCb02,
    aliases: ['Alina', 'Cebada Alina'],
  ),
  CropVarietyEntry(
    id: 'barley_dona_josefa',
    label: 'Doña Josefa',
    cropId: kCropBarley,
    subtitle: 'Maltera · INIFAP',
    defaultProfileId: kCb02,
    aliases: ['Doña Josefa', 'Dona Josefa', 'Cebada Doña Josefa'],
  ),
  CropVarietyEntry(
    id: 'barley_rgt_planet',
    label: 'RGT Planet',
    cropId: kCropBarley,
    subtitle: 'Maltera · RAGT',
    defaultProfileId: kCb02,
    aliases: ['RGT Planet', 'Planet'],
  ),
  CropVarietyEntry(
    id: 'barley_rgt_asteroid',
    label: 'RGT Asteroid',
    cropId: kCropBarley,
    subtitle: 'Maltera · RAGT',
    defaultProfileId: kCb02,
    aliases: ['RGT Asteroid', 'Asteroid'],
  ),
  CropVarietyEntry(
    id: 'barley_sy_tungsten',
    label: 'SY Tungsten',
    cropId: kCropBarley,
    subtitle: 'Maltera · Syngenta',
    defaultProfileId: kCb02,
    aliases: ['SY Tungsten', 'Tungsten'],
  ),
  CropVarietyEntry(
    id: 'barley_sy_odyssey',
    label: 'SY Odyssey',
    cropId: kCropBarley,
    subtitle: 'Maltera · Syngenta',
    defaultProfileId: kCb02,
    aliases: ['SY Odyssey', 'Odyssey'],
  ),
  CropVarietyEntry(
    id: 'barley_lg_zebra',
    label: 'LG Zebra',
    cropId: kCropBarley,
    subtitle: 'Maltera · LG Seeds',
    defaultProfileId: kCb02,
    aliases: ['LG Zebra', 'Zebra'],
  ),
  CropVarietyEntry(
    id: 'barley_lg_esterel',
    label: 'LG Esterel',
    cropId: kCropBarley,
    subtitle: 'Maltera · LG Seeds',
    defaultProfileId: kCb02,
    aliases: ['LG Esterel', 'Esterel'],
  ),
  CropVarietyEntry(
    id: 'barley_kws_orbit',
    label: 'KWS Orbit',
    cropId: kCropBarley,
    subtitle: 'Maltera · KWS',
    defaultProfileId: kCb02,
    aliases: ['KWS Orbit', 'Orbit'],
  ),

  // ── Largo / Riego ────────────────────────────────────────────────────────
  CropVarietyEntry(
    id: 'barley_estelar_oh',
    label: 'Estelar-OH',
    cropId: kCropBarley,
    subtitle: 'Largo / Riego',
    defaultProfileId: kCb03,
    aliases: ['Estelar-OH', 'Estelar OH', 'Estelar'],
  ),

  // ── Forrajera ─────────────────────────────────────────────────────────────
  CropVarietyEntry(
    id: 'barley_forrajera_inifap',
    label: 'Cebada forrajera INIFAP',
    cropId: kCropBarley,
    subtitle: 'Forrajera · INIFAP',
    defaultProfileId: kCb04,
    aliases: [
      'Cebada forrajera',
      'Cebada forraje',
      'Cebada corte',
      'Forrajera INIFAP',
    ],
  ),
  CropVarietyEntry(
    id: 'barley_cerro_prieto',
    label: 'Cerro Prieto',
    cropId: kCropBarley,
    subtitle: 'Forrajera · INIFAP',
    defaultProfileId: kCb04,
    aliases: ['Cerro Prieto', 'Cebada Cerro Prieto'],
  ),
  CropVarietyEntry(
    id: 'barley_puebla',
    label: 'Puebla',
    cropId: kCropBarley,
    subtitle: 'Forrajera',
    defaultProfileId: kCb04,
    aliases: ['Puebla', 'Cebada Puebla'],
  ),

  // ── Genérica ─────────────────────────────────────────────────────────────
  CropVarietyEntry(
    id: 'barley_generic',
    label: 'Cebada genérica',
    cropId: kCropBarley,
    subtitle: 'Usar perfil general',
    defaultProfileId: kCbGen,
    aliases: [
      'Genérica',
      'Generica',
      'Cebada genérica',
      'Cebada generica',
      'Cebada a granel',
      'CB-GEN',
      'CBGEN',
    ],
    isGeneric: true,
  ),
];
