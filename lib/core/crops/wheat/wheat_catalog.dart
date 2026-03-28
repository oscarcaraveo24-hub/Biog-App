// lib/core/crops/wheat/wheat_catalog.dart
//
// Catálogo v1 de trigo para Bio-G.
// Perfiles, variedades, y constantes usadas por CropCatalog.
//
// Fuentes: fichas técnicas Bio-G, INIFAP trigo,
//          CIMMYT variedades liberadas.

import 'package:bio_g/core/crops/catalog/crop_catalog_models.dart';
import 'package:bio_g/widgets/seeds/wheat_profiles.dart';

const String kCropWheat = 'wheat';
const String kWheatDefaultCalendarId = 'wheat_default';

// ─── Profile entries (validación catálogo) ──────────────────────────────────

const List<CropProfileEntry> wheatProfileEntries = [
  CropProfileEntry(
    id: kTr01,
    label: 'TR-01 · Precoz',
    cropId: kCropWheat,
    subtitle: 'Temporal corto / escape a calor',
    aliases: ['TR-01', 'TR01', 'Precoz'],
  ),
  CropProfileEntry(
    id: kTr02,
    label: 'TR-02 · Intermedio / Harinero',
    cropId: kCropWheat,
    subtitle: 'Estándar nacional — harinero / panificable',
    aliases: ['TR-02', 'TR02', 'Intermedio', 'Harinero'],
  ),
  CropProfileEntry(
    id: kTr03,
    label: 'TR-03 · Largo / Cristalino',
    cropId: kCropWheat,
    subtitle: 'Durum / alto potencial bajo riego',
    aliases: ['TR-03', 'TR03', 'Largo', 'Cristalino', 'Durum'],
  ),
  CropProfileEntry(
    id: kTrFor,
    label: 'TR-FOR · Forrajero',
    cropId: kCropWheat,
    subtitle: 'Corte temprano / pastoreo',
    aliases: ['TR-FOR', 'TRFOR', 'Forrajero'],
  ),
  CropProfileEntry(
    id: kTrGen,
    label: 'TR-GEN · Intermedio Conservador',
    cropId: kCropWheat,
    subtitle: 'Perfil conservador (SKIP)',
    aliases: ['TR-GEN', 'TRGEN', 'Genérico', 'Generico'],
  ),
];

// ─── Variedades ─────────────────────────────────────────────────────────────

const List<CropVarietyEntry> wheatVarieties = [
  // ── Precoz ───────────────────────────────────────────────────────────────
  CropVarietyEntry(
    id: 'wheat_kentana_48',
    label: 'Kentana 48',
    cropId: kCropWheat,
    subtitle: 'Precoz · INIFAP/CIMMYT',
    defaultProfileId: kTr01,
    aliases: ['Kentana 48', 'Kentana'],
  ),
  CropVarietyEntry(
    id: 'wheat_chapingo_53',
    label: 'Chapingo 53',
    cropId: kCropWheat,
    subtitle: 'Precoz',
    defaultProfileId: kTr01,
    aliases: ['Chapingo 53', 'Chapingo'],
  ),
  CropVarietyEntry(
    id: 'wheat_bajio_53',
    label: 'Bajío 53',
    cropId: kCropWheat,
    subtitle: 'Precoz',
    defaultProfileId: kTr01,
    aliases: ['Bajío 53', 'Bajio 53', 'Bajío', 'Bajio'],
  ),
  CropVarietyEntry(
    id: 'wheat_mexe_53',
    label: 'Mexe 53',
    cropId: kCropWheat,
    subtitle: 'Precoz',
    defaultProfileId: kTr01,
    aliases: ['Mexe 53', 'Mexe'],
  ),
  CropVarietyEntry(
    id: 'wheat_tobari_f66',
    label: 'Tobari F66',
    cropId: kCropWheat,
    subtitle: 'Precoz',
    defaultProfileId: kTr01,
    aliases: ['Tobari F66', 'Tobari'],
  ),

  // ── Intermedio / Harinero ────────────────────────────────────────────────
  CropVarietyEntry(
    id: 'wheat_roelfs_f2007',
    label: 'Roelfs F2007',
    cropId: kCropWheat,
    subtitle: 'Harinero · INIFAP/CIMMYT',
    defaultProfileId: kTr02,
    aliases: ['Roelfs F2007', 'Roelfs'],
  ),
  CropVarietyEntry(
    id: 'wheat_tacupeto_f2001',
    label: 'Tacupeto F2001',
    cropId: kCropWheat,
    subtitle: 'Harinero · INIFAP/CIMMYT',
    defaultProfileId: kTr02,
    aliases: ['Tacupeto F2001', 'Tacupeto'],
  ),
  CropVarietyEntry(
    id: 'wheat_bacanora_t88',
    label: 'Bacanora T88',
    cropId: kCropWheat,
    subtitle: 'Harinero · INIFAP/CIMMYT',
    defaultProfileId: kTr02,
    aliases: ['Bacanora T88', 'Bacanora'],
  ),
  CropVarietyEntry(
    id: 'wheat_opata_m85',
    label: 'Ópata M85',
    cropId: kCropWheat,
    subtitle: 'Harinero · INIFAP/CIMMYT',
    defaultProfileId: kTr02,
    aliases: ['Ópata M85', 'Opata M85', 'Ópata', 'Opata'],
  ),
  CropVarietyEntry(
    id: 'wheat_kronstad_f2004',
    label: 'Kronstad F2004',
    cropId: kCropWheat,
    subtitle: 'Harinero · INIFAP/CIMMYT',
    defaultProfileId: kTr02,
    aliases: ['Kronstad F2004', 'Kronstad'],
  ),
  CropVarietyEntry(
    id: 'wheat_onavas_f2009',
    label: 'Ónavas F2009',
    cropId: kCropWheat,
    subtitle: 'Harinero · INIFAP/CIMMYT',
    defaultProfileId: kTr02,
    aliases: ['Ónavas F2009', 'Onavas F2009', 'Ónavas', 'Onavas'],
  ),
  CropVarietyEntry(
    id: 'wheat_borlaug_m95',
    label: 'Borlaug M95',
    cropId: kCropWheat,
    subtitle: 'Harinero · INIFAP/CIMMYT',
    defaultProfileId: kTr02,
    aliases: ['Borlaug M95', 'Borlaug'],
  ),

  // ── Largo / Cristalino ───────────────────────────────────────────────────
  CropVarietyEntry(
    id: 'wheat_cirno_c2008',
    label: 'CIRNO C2008',
    cropId: kCropWheat,
    subtitle: 'Cristalino · INIFAP/CIMMYT',
    defaultProfileId: kTr03,
    aliases: ['CIRNO C2008', 'CIRNO', 'Cirno'],
  ),
  CropVarietyEntry(
    id: 'wheat_borlaug_100_f2014',
    label: 'Borlaug 100 F2014',
    cropId: kCropWheat,
    subtitle: 'Cristalino · INIFAP/CIMMYT',
    defaultProfileId: kTr03,
    aliases: ['Borlaug 100 F2014', 'Borlaug 100'],
  ),
  CropVarietyEntry(
    id: 'wheat_conatrigo_f2015',
    label: 'Conatrigo F2015',
    cropId: kCropWheat,
    subtitle: 'Cristalino · INIFAP/CIMMYT',
    defaultProfileId: kTr03,
    aliases: ['Conatrigo F2015', 'Conatrigo'],
  ),
  CropVarietyEntry(
    id: 'wheat_bacorehuis_f2015',
    label: 'Bacorehuis F2015',
    cropId: kCropWheat,
    subtitle: 'Cristalino · INIFAP/CIMMYT',
    defaultProfileId: kTr03,
    aliases: ['Bacorehuis F2015', 'Bacorehuis'],
  ),
  CropVarietyEntry(
    id: 'wheat_seri_m82',
    label: 'Seri M82',
    cropId: kCropWheat,
    subtitle: 'Cristalino · INIFAP/CIMMYT',
    defaultProfileId: kTr03,
    aliases: ['Seri M82', 'Seri'],
  ),

  // ── Durum modernos noroeste (Sonora, Baja California) ────────────────────
  CropVarietyEntry(
    id: 'wheat_huatabampo_durum_c2017',
    label: 'Huatabampo Durum C2017',
    cropId: kCropWheat,
    subtitle: 'Cristalino · INIFAP/CIMMYT',
    defaultProfileId: kTr03,
    aliases: ['Huatabampo Durum C2017', 'Huatabampo Durum', 'Huatabampo'],
  ),
  CropVarietyEntry(
    id: 'wheat_quetchehueca_oro_c2013',
    label: 'Quetchehueca Oro C2013',
    cropId: kCropWheat,
    subtitle: 'Cristalino · INIFAP/CIMMYT',
    defaultProfileId: kTr03,
    aliases: ['Quetchehueca Oro C2013', 'Quetchehueca Oro', 'Quetchehueca'],
  ),
  CropVarietyEntry(
    id: 'wheat_movas_c2015',
    label: 'Movas C2015',
    cropId: kCropWheat,
    subtitle: 'Cristalino · INIFAP/CIMMYT',
    defaultProfileId: kTr03,
    aliases: ['Movas C2015', 'Movas'],
  ),

  // ── Forrajero ──────────────────────────────────────────────────────────
  CropVarietyEntry(
    id: 'wheat_forrajero',
    label: 'Trigo forrajero',
    cropId: kCropWheat,
    subtitle: 'Corte temprano',
    defaultProfileId: kTrFor,
    aliases: [
      'Trigo forrajero',
      'Trigo forraje',
      'Trigo corte',
      'TR-FOR',
      'TRFOR',
    ],
  ),

  // ── Genérica ─────────────────────────────────────────────────────────────
  CropVarietyEntry(
    id: 'wheat_generic',
    label: 'Trigo genérico',
    cropId: kCropWheat,
    subtitle: 'Usar perfil general',
    defaultProfileId: kTrGen,
    aliases: [
      'Genérico',
      'Generico',
      'Trigo genérico',
      'Trigo generico',
      'TR-GEN',
      'TRGEN',
    ],
    isGeneric: true,
  ),
];
