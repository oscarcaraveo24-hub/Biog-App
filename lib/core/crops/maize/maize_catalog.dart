// lib/core/crops/maize/maize_catalog.dart
//
// Catálogo oficial Bio-G de variedades de maíz.
// Organizado por: Tipo (marketTypeId) → Marca (brandId) → Variedad
//
// IDs de variedad: {brand}_{name_normalized}_{useType}[_{qualifier}]
// Ej: dekalb_dk2069_grain | dekalb_dk2069_forage
//
// Nota: algunas variedades físicas tienen MÚLTIPLES entradas cuando su uso
// más frecuente difiere (forraje vs grano, corto vs largo). El subtitle
// resuelve la ambigüedad en la UI del wizard.

import 'package:bio_g/core/crops/catalog/crop_catalog_models.dart';
import 'package:bio_g/widgets/seeds/maize_profiles.dart';

// ─── IDs de marca ────────────────────────────────────────────────────────────
const String kBrandAsgrow   = 'asgrow';
const String kBrandPioneer  = 'pioneer';
const String kBrandDekalb   = 'dekalb';
const String kBrandSyngenta = 'syngenta';

// ─── IDs de tipo de mercado ──────────────────────────────────────────────────
const String kMarketWhite  = 'white';   // Maíz blanco
const String kMarketYellow = 'yellow';  // Maíz amarillo
const String kMarketSweet  = 'sweet';   // Elotero

// ─── IDs de uso ──────────────────────────────────────────────────────────────
const String kUseGrain  = 'grain';   // Grano
const String kUseForage = 'forage';  // Forraje/ensilaje
const String kUseElote  = 'elote';   // Elote

// ─── cropId ──────────────────────────────────────────────────────────────────
const String kCropMaize = 'maize';

// ═════════════════════════════════════════════════════════════════════════════
// MARCAS
// ═════════════════════════════════════════════════════════════════════════════

const List<CropBrandEntry> maizeBrands = [
  CropBrandEntry(id: kBrandAsgrow,   label: 'Asgrow',   cropId: kCropMaize),
  CropBrandEntry(id: kBrandPioneer,  label: 'Pioneer',  cropId: kCropMaize),
  CropBrandEntry(id: kBrandDekalb,   label: 'Dekalb',   cropId: kCropMaize),
  CropBrandEntry(id: kBrandSyngenta, label: 'Syngenta', cropId: kCropMaize),
];

// ═════════════════════════════════════════════════════════════════════════════
// VARIEDADES
// Convención de subtitle: 'Marca · Tipo · Perfil'
// ═════════════════════════════════════════════════════════════════════════════

const List<CropVarietyEntry> maizeVarieties = [

  // ──────────────────────────────────────────────────────────────────────────
  // ASGROW — Maíz Blanco
  // ──────────────────────────────────────────────────────────────────────────

  CropVarietyEntry(
    id: 'asgrow_antilope_forage',
    label: 'ANTÍLOPE',
    cropId: kCropMaize,
    subtitle: 'Asgrow · Blanco · Forraje intermedio temprano',
    brandId: kBrandAsgrow, marketTypeId: kMarketWhite, useTypeId: kUseForage,
    defaultProfileId: kMzf01,
    aliases: ['ANTILOPE', 'ANTÍLOPE FORRAJE'],
  ),
  CropVarietyEntry(
    id: 'asgrow_antilope_grain',
    label: 'ANTÍLOPE',
    cropId: kCropMaize,
    subtitle: 'Asgrow · Blanco · Grano intermedio tardío',
    brandId: kBrandAsgrow, marketTypeId: kMarketWhite, useTypeId: kUseGrain,
    defaultProfileId: kMzg04,
    aliases: ['ANTILOPE GRANO'],
  ),
  CropVarietyEntry(
    id: 'asgrow_antilope_grain_long',
    label: 'ANTÍLOPE',
    cropId: kCropMaize,
    subtitle: 'Asgrow · Blanco · Grano tardío extendido',
    brandId: kBrandAsgrow, marketTypeId: kMarketWhite, useTypeId: kUseGrain,
    defaultProfileId: kMzg08,
    aliases: ['ANTILOPE LARGO'],
  ),
  CropVarietyEntry(
    id: 'asgrow_armadillo_forage',
    label: 'ARMADILLO',
    cropId: kCropMaize,
    subtitle: 'Asgrow · Blanco · Forraje intermedio temprano',
    brandId: kBrandAsgrow, marketTypeId: kMarketWhite, useTypeId: kUseForage,
    defaultProfileId: kMzf01,
  ),
  CropVarietyEntry(
    id: 'asgrow_hipopotamo_forage',
    label: 'HIPOPÓTAMO',
    cropId: kCropMaize,
    subtitle: 'Asgrow · Blanco · Forraje intermedio temprano',
    brandId: kBrandAsgrow, marketTypeId: kMarketWhite, useTypeId: kUseForage,
    defaultProfileId: kMzf01,
    aliases: ['HIPOPOTAMO'],
  ),
  CropVarietyEntry(
    id: 'asgrow_rinoceronte_forage',
    label: 'RINOCERONTE',
    cropId: kCropMaize,
    subtitle: 'Asgrow · Blanco · Forraje intermedio temprano',
    brandId: kBrandAsgrow, marketTypeId: kMarketWhite, useTypeId: kUseForage,
    defaultProfileId: kMzf01,
  ),
  CropVarietyEntry(
    id: 'asgrow_rinoceronte_grain_long',
    label: 'RINOCERONTE',
    cropId: kCropMaize,
    subtitle: 'Asgrow · Blanco · Grano tardío extendido',
    brandId: kBrandAsgrow, marketTypeId: kMarketWhite, useTypeId: kUseGrain,
    defaultProfileId: kMzg08,
    aliases: ['RINOCERONTE GRANO'],
  ),
  CropVarietyEntry(
    id: 'asgrow_berrendo_forage',
    label: 'BERRENDO',
    cropId: kCropMaize,
    subtitle: 'Asgrow · Blanco · Forraje intermedio temprano',
    brandId: kBrandAsgrow, marketTypeId: kMarketWhite, useTypeId: kUseForage,
    defaultProfileId: kMzf01,
  ),
  CropVarietyEntry(
    id: 'asgrow_berrendo_grain_long',
    label: 'BERRENDO',
    cropId: kCropMaize,
    subtitle: 'Asgrow · Blanco · Grano tardío extendido',
    brandId: kBrandAsgrow, marketTypeId: kMarketWhite, useTypeId: kUseGrain,
    defaultProfileId: kMzg08,
    aliases: ['BERRENDO GRANO'],
  ),
  CropVarietyEntry(
    id: 'asgrow_cimarron_grain_long',
    label: 'CIMARRÓN',
    cropId: kCropMaize,
    subtitle: 'Asgrow · Blanco · Grano tardío extendido',
    brandId: kBrandAsgrow, marketTypeId: kMarketWhite, useTypeId: kUseGrain,
    defaultProfileId: kMzg08,
    aliases: ['CIMARRON'],
  ),
  CropVarietyEntry(
    id: 'asgrow_ocelote_grain',
    label: 'OCELOTE',
    cropId: kCropMaize,
    subtitle: 'Asgrow · Blanco · Grano precoz extremo',
    brandId: kBrandAsgrow, marketTypeId: kMarketWhite, useTypeId: kUseGrain,
    defaultProfileId: kMzg00,
  ),
  CropVarietyEntry(
    id: 'asgrow_tigrillo_grain',
    label: 'TIGRILLO',
    cropId: kCropMaize,
    subtitle: 'Asgrow · Blanco · Grano precoz',
    brandId: kBrandAsgrow, marketTypeId: kMarketWhite, useTypeId: kUseGrain,
    defaultProfileId: kMzg01,
  ),
  CropVarietyEntry(
    id: 'asgrow_salamandra_grain_short',
    label: 'SALAMANDRA',
    cropId: kCropMaize,
    subtitle: 'Asgrow · Blanco · Grano intermedio estándar',
    brandId: kBrandAsgrow, marketTypeId: kMarketWhite, useTypeId: kUseGrain,
    defaultProfileId: kMzg03,
    aliases: ['SALAMANDRA CORTO'],
  ),
  CropVarietyEntry(
    id: 'asgrow_salamandra_grain_long',
    label: 'SALAMANDRA',
    cropId: kCropMaize,
    subtitle: 'Asgrow · Blanco · Grano intermedio tardío',
    brandId: kBrandAsgrow, marketTypeId: kMarketWhite, useTypeId: kUseGrain,
    defaultProfileId: kMzg04,
    aliases: ['SALAMANDRA LARGO'],
  ),
  CropVarietyEntry(
    id: 'asgrow_az60_grain_long',
    label: 'AZ60',
    cropId: kCropMaize,
    subtitle: 'Asgrow · Blanco · Grano largo de riego',
    brandId: kBrandAsgrow, marketTypeId: kMarketWhite, useTypeId: kUseGrain,
    defaultProfileId: kMzg09,
  ),
  CropVarietyEntry(
    id: 'asgrow_faisan_grain_long',
    label: 'FAISÁN',
    cropId: kCropMaize,
    subtitle: 'Asgrow · Blanco · Grano largo de riego',
    brandId: kBrandAsgrow, marketTypeId: kMarketWhite, useTypeId: kUseGrain,
    defaultProfileId: kMzg09,
    aliases: ['FAISAN'],
  ),
  CropVarietyEntry(
    id: 'asgrow_albatros_grain_long',
    label: 'ALBATROS',
    cropId: kCropMaize,
    subtitle: 'Asgrow · Blanco · Grano largo de riego',
    brandId: kBrandAsgrow, marketTypeId: kMarketWhite, useTypeId: kUseGrain,
    defaultProfileId: kMzg09,
  ),

  // ──────────────────────────────────────────────────────────────────────────
  // ASGROW — Maíz Amarillo
  // ──────────────────────────────────────────────────────────────────────────

  CropVarietyEntry(
    id: 'asgrow_antilope_y_grain_long',
    label: 'ANTÍLOPE Y',
    cropId: kCropMaize,
    subtitle: 'Asgrow · Amarillo · Grano tardío extendido',
    brandId: kBrandAsgrow, marketTypeId: kMarketYellow, useTypeId: kUseGrain,
    defaultProfileId: kMzg08,
    aliases: ['ANTILOPE Y', 'ANTILOPEY'],
  ),
  CropVarietyEntry(
    id: 'asgrow_rx715_grain',
    label: 'RX-715',
    cropId: kCropMaize,
    subtitle: 'Asgrow · Amarillo · Grano intermedio estándar',
    brandId: kBrandAsgrow, marketTypeId: kMarketYellow, useTypeId: kUseGrain,
    defaultProfileId: kMzg03,
    aliases: ['RX715'],
  ),
  CropVarietyEntry(
    id: 'asgrow_rx717_grain_tropical',
    label: 'RX-717',
    cropId: kCropMaize,
    subtitle: 'Asgrow · Amarillo · Grano corto tropical',
    brandId: kBrandAsgrow, marketTypeId: kMarketYellow, useTypeId: kUseGrain,
    defaultProfileId: kMzg06,
    aliases: ['RX717'],
  ),
  CropVarietyEntry(
    id: 'asgrow_rx840_grain',
    label: 'RX-840',
    cropId: kCropMaize,
    subtitle: 'Asgrow · Amarillo · Grano intermedio estándar',
    brandId: kBrandAsgrow, marketTypeId: kMarketYellow, useTypeId: kUseGrain,
    defaultProfileId: kMzg03,
    aliases: ['RX840'],
  ),
  CropVarietyEntry(
    id: 'asgrow_rx860_forage_precoz',
    label: 'RX-860',
    cropId: kCropMaize,
    subtitle: 'Asgrow · Amarillo · Forraje precoz',
    brandId: kBrandAsgrow, marketTypeId: kMarketYellow, useTypeId: kUseForage,
    defaultProfileId: kMzf00,
    aliases: ['RX860'],
  ),
  CropVarietyEntry(
    id: 'asgrow_rx860_forage_super',
    label: 'RX-860',
    cropId: kCropMaize,
    subtitle: 'Asgrow · Amarillo · Forraje súper precoz',
    brandId: kBrandAsgrow, marketTypeId: kMarketYellow, useTypeId: kUseForage,
    defaultProfileId: kMzf06,
    aliases: ['RX860 SUPER'],
  ),

  // ──────────────────────────────────────────────────────────────────────────
  // ASGROW — Elotero
  // ──────────────────────────────────────────────────────────────────────────

  CropVarietyEntry(
    id: 'asgrow_a7573_elote',
    label: 'A 7573',
    cropId: kCropMaize,
    subtitle: 'Asgrow · Elotero · Elote intermedio',
    brandId: kBrandAsgrow, marketTypeId: kMarketSweet, useTypeId: kUseElote,
    defaultProfileId: kMze00,
    aliases: ['A7573', 'A-7573'],
  ),
  CropVarietyEntry(
    id: 'asgrow_a7573_grain',
    label: 'A 7573',
    cropId: kCropMaize,
    subtitle: 'Asgrow · Blanco · Grano intermedio estándar',
    brandId: kBrandAsgrow, marketTypeId: kMarketWhite, useTypeId: kUseGrain,
    defaultProfileId: kMzg03,
    aliases: ['A7573 GRANO'],
  ),
  CropVarietyEntry(
    id: 'asgrow_garanon_elote',
    label: 'GARAÑÓN',
    cropId: kCropMaize,
    subtitle: 'Asgrow · Elotero · Elote intermedio',
    brandId: kBrandAsgrow, marketTypeId: kMarketSweet, useTypeId: kUseElote,
    defaultProfileId: kMze00,
    aliases: ['GARANON'],
  ),

  // ──────────────────────────────────────────────────────────────────────────
  // PIONEER — Maíz Blanco (terminan en W)
  // ──────────────────────────────────────────────────────────────────────────

  CropVarietyEntry(
    id: 'pioneer_p2327w_forage',
    label: 'P2327W',
    cropId: kCropMaize,
    subtitle: 'Pioneer · Blanco · Forraje precoz',
    brandId: kBrandPioneer, marketTypeId: kMarketWhite, useTypeId: kUseForage,
    defaultProfileId: kMzf00,
  ),
  CropVarietyEntry(
    id: 'pioneer_p32208w_forage',
    label: 'P32208W',
    cropId: kCropMaize,
    subtitle: 'Pioneer · Blanco · Forraje intermedio',
    brandId: kBrandPioneer, marketTypeId: kMarketWhite, useTypeId: kUseForage,
    defaultProfileId: kMzf02,
  ),
  CropVarietyEntry(
    id: 'pioneer_p3274w_forage',
    label: 'P3274W',
    cropId: kCropMaize,
    subtitle: 'Pioneer · Blanco · Forraje intermedio',
    brandId: kBrandPioneer, marketTypeId: kMarketWhite, useTypeId: kUseForage,
    defaultProfileId: kMzf02,
  ),
  CropVarietyEntry(
    id: 'pioneer_p3274w_grain_oi',
    label: 'P3274W',
    cropId: kCropMaize,
    subtitle: 'Pioneer · Blanco · Grano tardío cálido OI',
    brandId: kBrandPioneer, marketTypeId: kMarketWhite, useTypeId: kUseGrain,
    defaultProfileId: kMzg05,
    aliases: ['P3274W GRANO'],
  ),
  CropVarietyEntry(
    id: 'pioneer_p39177w_forage',
    label: 'P39177W',
    cropId: kCropMaize,
    subtitle: 'Pioneer · Blanco · Forraje intermedio tardío',
    brandId: kBrandPioneer, marketTypeId: kMarketWhite, useTypeId: kUseForage,
    defaultProfileId: kMzf03,
  ),
  CropVarietyEntry(
    id: 'pioneer_p39177w_grain_tropical',
    label: 'P39177W',
    cropId: kCropMaize,
    subtitle: 'Pioneer · Blanco · Grano corto tropical',
    brandId: kBrandPioneer, marketTypeId: kMarketWhite, useTypeId: kUseGrain,
    defaultProfileId: kMzg06,
    aliases: ['P39177W TROPICAL'],
  ),
  CropVarietyEntry(
    id: 'pioneer_p3966w_forage',
    label: 'P3966W',
    cropId: kCropMaize,
    subtitle: 'Pioneer · Blanco · Forraje intermedio tardío',
    brandId: kBrandPioneer, marketTypeId: kMarketWhite, useTypeId: kUseForage,
    defaultProfileId: kMzf03,
  ),
  CropVarietyEntry(
    id: 'pioneer_p3966w_grain_tropical',
    label: 'P3966W',
    cropId: kCropMaize,
    subtitle: 'Pioneer · Blanco · Grano corto tropical',
    brandId: kBrandPioneer, marketTypeId: kMarketWhite, useTypeId: kUseGrain,
    defaultProfileId: kMzg06,
    aliases: ['P3966W TROPICAL'],
  ),
  CropVarietyEntry(
    id: 'pioneer_p4082w_forage',
    label: 'P4082W',
    cropId: kCropMaize,
    subtitle: 'Pioneer · Blanco · Forraje tardío',
    brandId: kBrandPioneer, marketTypeId: kMarketWhite, useTypeId: kUseForage,
    defaultProfileId: kMzf04,
  ),
  CropVarietyEntry(
    id: 'pioneer_p4082w_grain_tropical',
    label: 'P4082W',
    cropId: kCropMaize,
    subtitle: 'Pioneer · Blanco · Grano corto tropical',
    brandId: kBrandPioneer, marketTypeId: kMarketWhite, useTypeId: kUseGrain,
    defaultProfileId: kMzg06,
    aliases: ['P4082W TROPICAL'],
  ),
  CropVarietyEntry(
    id: 'pioneer_p3260w_grain',
    label: 'P3260W',
    cropId: kCropMaize,
    subtitle: 'Pioneer · Blanco · Grano intermedio precoz',
    brandId: kBrandPioneer, marketTypeId: kMarketWhite, useTypeId: kUseGrain,
    defaultProfileId: kMzg02,
  ),
  CropVarietyEntry(
    id: 'pioneer_p3057w_grain_invernal',
    label: 'P3057W',
    cropId: kCropMaize,
    subtitle: 'Pioneer · Blanco · Grano intermedio corto invernal',
    brandId: kBrandPioneer, marketTypeId: kMarketWhite, useTypeId: kUseGrain,
    defaultProfileId: kMzg07,
  ),
  CropVarietyEntry(
    id: 'pioneer_p3051w_grain',
    label: 'P3051W',
    cropId: kCropMaize,
    subtitle: 'Pioneer · Blanco · Grano intermedio precoz',
    brandId: kBrandPioneer, marketTypeId: kMarketWhite, useTypeId: kUseGrain,
    defaultProfileId: kMzg02,
  ),
  CropVarietyEntry(
    id: 'pioneer_p3011w_grain',
    label: 'P3011W',
    cropId: kCropMaize,
    subtitle: 'Pioneer · Blanco · Grano intermedio precoz',
    brandId: kBrandPioneer, marketTypeId: kMarketWhite, useTypeId: kUseGrain,
    defaultProfileId: kMzg02,
  ),
  CropVarietyEntry(
    id: 'pioneer_p30064w_grain_oi',
    label: 'P30064W',
    cropId: kCropMaize,
    subtitle: 'Pioneer · Blanco · Grano tardío cálido OI',
    brandId: kBrandPioneer, marketTypeId: kMarketWhite, useTypeId: kUseGrain,
    defaultProfileId: kMzg05,
  ),
  CropVarietyEntry(
    id: 'pioneer_p40007w_grain_tropical',
    label: 'P40007W',
    cropId: kCropMaize,
    subtitle: 'Pioneer · Blanco · Grano corto tropical',
    brandId: kBrandPioneer, marketTypeId: kMarketWhite, useTypeId: kUseGrain,
    defaultProfileId: kMzg06,
  ),
  CropVarietyEntry(
    id: 'pioneer_p39092w_grain_tropical',
    label: 'P39092W',
    cropId: kCropMaize,
    subtitle: 'Pioneer · Blanco · Grano corto tropical',
    brandId: kBrandPioneer, marketTypeId: kMarketWhite, useTypeId: kUseGrain,
    defaultProfileId: kMzg06,
  ),

  // ──────────────────────────────────────────────────────────────────────────
  // PIONEER — Maíz Amarillo (sin W)
  // ──────────────────────────────────────────────────────────────────────────

  CropVarietyEntry(
    id: 'pioneer_p1382_grain',
    label: 'P1382',
    cropId: kCropMaize,
    subtitle: 'Pioneer · Amarillo · Grano intermedio precoz',
    brandId: kBrandPioneer, marketTypeId: kMarketYellow, useTypeId: kUseGrain,
    defaultProfileId: kMzg02,
  ),
  CropVarietyEntry(
    id: 'pioneer_p1445_grain',
    label: 'P1445',
    cropId: kCropMaize,
    subtitle: 'Pioneer · Amarillo · Grano intermedio precoz',
    brandId: kBrandPioneer, marketTypeId: kMarketYellow, useTypeId: kUseGrain,
    defaultProfileId: kMzg02,
  ),
  CropVarietyEntry(
    id: 'pioneer_p2807_grain_oi',
    label: 'P2807',
    cropId: kCropMaize,
    subtitle: 'Pioneer · Amarillo · Grano tardío cálido OI',
    brandId: kBrandPioneer, marketTypeId: kMarketYellow, useTypeId: kUseGrain,
    defaultProfileId: kMzg05,
  ),
  CropVarietyEntry(
    id: 'pioneer_p3076_grain_invernal',
    label: 'P3076',
    cropId: kCropMaize,
    subtitle: 'Pioneer · Amarillo · Grano intermedio corto invernal',
    brandId: kBrandPioneer, marketTypeId: kMarketYellow, useTypeId: kUseGrain,
    defaultProfileId: kMzg07,
  ),
  CropVarietyEntry(
    id: 'pioneer_p3092_grain_invernal',
    label: 'P3092',
    cropId: kCropMaize,
    subtitle: 'Pioneer · Amarillo · Grano intermedio corto invernal',
    brandId: kBrandPioneer, marketTypeId: kMarketYellow, useTypeId: kUseGrain,
    defaultProfileId: kMzg07,
  ),
  CropVarietyEntry(
    id: 'pioneer_p3097_grain_invernal',
    label: 'P3097',
    cropId: kCropMaize,
    subtitle: 'Pioneer · Amarillo · Grano intermedio corto invernal',
    brandId: kBrandPioneer, marketTypeId: kMarketYellow, useTypeId: kUseGrain,
    defaultProfileId: kMzg07,
  ),
  CropVarietyEntry(
    id: 'pioneer_b3715_forage_calido',
    label: 'B3715',
    cropId: kCropMaize,
    subtitle: 'Pioneer · Amarillo · Forraje intermedio cálido',
    brandId: kBrandPioneer, marketTypeId: kMarketYellow, useTypeId: kUseForage,
    defaultProfileId: kMzf05,
  ),
  CropVarietyEntry(
    id: 'pioneer_b3799_grain_oi',
    label: 'B3799',
    cropId: kCropMaize,
    subtitle: 'Pioneer · Amarillo · Grano tardío cálido OI',
    brandId: kBrandPioneer, marketTypeId: kMarketYellow, useTypeId: kUseGrain,
    defaultProfileId: kMzg05,
  ),
  CropVarietyEntry(
    id: 'pioneer_p3898_grain_tropical',
    label: 'P3898',
    cropId: kCropMaize,
    subtitle: 'Pioneer · Amarillo · Grano corto tropical',
    brandId: kBrandPioneer, marketTypeId: kMarketYellow, useTypeId: kUseGrain,
    defaultProfileId: kMzg06,
  ),
  CropVarietyEntry(
    id: 'pioneer_p35136_grain_tropical',
    label: 'P35136',
    cropId: kCropMaize,
    subtitle: 'Pioneer · Amarillo · Grano corto tropical',
    brandId: kBrandPioneer, marketTypeId: kMarketYellow, useTypeId: kUseGrain,
    defaultProfileId: kMzg06,
  ),
  CropVarietyEntry(
    id: 'pioneer_p4039_grain_tropical',
    label: 'P4039',
    cropId: kCropMaize,
    subtitle: 'Pioneer · Amarillo · Grano corto tropical',
    brandId: kBrandPioneer, marketTypeId: kMarketYellow, useTypeId: kUseGrain,
    defaultProfileId: kMzg06,
  ),

  // ──────────────────────────────────────────────────────────────────────────
  // DEKALB — Maíz Blanco
  // ──────────────────────────────────────────────────────────────────────────

  CropVarietyEntry(
    id: 'dekalb_dk2037_grain',
    label: 'DK-2037',
    cropId: kCropMaize,
    subtitle: 'Dekalb · Blanco · Grano precoz extremo',
    brandId: kBrandDekalb, marketTypeId: kMarketWhite, useTypeId: kUseGrain,
    defaultProfileId: kMzg00,
    aliases: ['DK2037'],
  ),
  CropVarietyEntry(
    id: 'dekalb_dk1050_grain',
    label: 'DK-1050',
    cropId: kCropMaize,
    subtitle: 'Dekalb · Blanco · Grano precoz',
    brandId: kBrandDekalb, marketTypeId: kMarketWhite, useTypeId: kUseGrain,
    defaultProfileId: kMzg01,
    aliases: ['DK1050'],
  ),
  CropVarietyEntry(
    id: 'dekalb_dk2061_forage',
    label: 'DK-2061',
    cropId: kCropMaize,
    subtitle: 'Dekalb · Blanco · Forraje intermedio',
    brandId: kBrandDekalb, marketTypeId: kMarketWhite, useTypeId: kUseForage,
    defaultProfileId: kMzf02,
    aliases: ['DK2061'],
  ),
  // DK-2069: doble entrada (forraje tardío / grano invernal)
  CropVarietyEntry(
    id: 'dekalb_dk2069_forage',
    label: 'DK-2069',
    cropId: kCropMaize,
    subtitle: 'Dekalb · Blanco · Forraje tardío',
    brandId: kBrandDekalb, marketTypeId: kMarketWhite, useTypeId: kUseForage,
    defaultProfileId: kMzf04,
    aliases: ['DK2069 FORRAJE'],
  ),
  CropVarietyEntry(
    id: 'dekalb_dk2069_grain',
    label: 'DK-2069',
    cropId: kCropMaize,
    subtitle: 'Dekalb · Blanco · Grano intermedio corto invernal',
    brandId: kBrandDekalb, marketTypeId: kMarketWhite, useTypeId: kUseGrain,
    defaultProfileId: kMzg07,
    // Aliases legacy para backward compat
    aliases: ['DK-2069', 'DK2069', 'DK2069 GRANO'],
  ),
  // DK-2048: forage cálido / grano largo
  CropVarietyEntry(
    id: 'dekalb_dk2048_forage',
    label: 'DK-2048',
    cropId: kCropMaize,
    subtitle: 'Dekalb · Blanco · Forraje intermedio cálido',
    brandId: kBrandDekalb, marketTypeId: kMarketWhite, useTypeId: kUseForage,
    defaultProfileId: kMzf05,
    aliases: ['DK2048 FORRAJE'],
  ),
  CropVarietyEntry(
    id: 'dekalb_dk2048_grain_long',
    label: 'DK-2048',
    cropId: kCropMaize,
    subtitle: 'Dekalb · Blanco · Grano tardío extendido',
    brandId: kBrandDekalb, marketTypeId: kMarketWhite, useTypeId: kUseGrain,
    defaultProfileId: kMzg08,
    aliases: ['DK2048', 'DK2048 GRANO'],
  ),
  // DK-4018: forage tardío / grano estándar
  CropVarietyEntry(
    id: 'dekalb_dk4018_forage',
    label: 'DK-4018',
    cropId: kCropMaize,
    subtitle: 'Dekalb · Blanco · Forraje intermedio tardío',
    brandId: kBrandDekalb, marketTypeId: kMarketWhite, useTypeId: kUseForage,
    defaultProfileId: kMzf03,
    aliases: ['DK4018 FORRAJE'],
  ),
  CropVarietyEntry(
    id: 'dekalb_dk4018_grain',
    label: 'DK-4018',
    cropId: kCropMaize,
    subtitle: 'Dekalb · Blanco · Grano intermedio estándar',
    brandId: kBrandDekalb, marketTypeId: kMarketWhite, useTypeId: kUseGrain,
    defaultProfileId: kMzg03,
    aliases: ['DK4018', 'DK4018 GRANO'],
  ),
  CropVarietyEntry(
    id: 'dekalb_dk4021_grain',
    label: 'DK-4021',
    cropId: kCropMaize,
    subtitle: 'Dekalb · Blanco · Grano intermedio precoz',
    brandId: kBrandDekalb, marketTypeId: kMarketWhite, useTypeId: kUseGrain,
    defaultProfileId: kMzg02,
    aliases: ['DK4021'],
  ),
  CropVarietyEntry(
    id: 'dekalb_dk4050_grain_oi',
    label: 'DK-4050',
    cropId: kCropMaize,
    subtitle: 'Dekalb · Blanco · Grano tardío cálido OI',
    brandId: kBrandDekalb, marketTypeId: kMarketWhite, useTypeId: kUseGrain,
    defaultProfileId: kMzg05,
    aliases: ['DK4050'],
  ),
  CropVarietyEntry(
    id: 'dekalb_dk357_forage',
    label: 'DK-357',
    cropId: kCropMaize,
    subtitle: 'Dekalb · Blanco · Forraje precoz',
    brandId: kBrandDekalb, marketTypeId: kMarketWhite, useTypeId: kUseForage,
    defaultProfileId: kMzf00,
    aliases: ['DK357'],
  ),
  CropVarietyEntry(
    id: 'dekalb_dk390_grain_tropical',
    label: 'DK-390',
    cropId: kCropMaize,
    subtitle: 'Dekalb · Blanco · Grano corto tropical',
    brandId: kBrandDekalb, marketTypeId: kMarketWhite, useTypeId: kUseGrain,
    defaultProfileId: kMzg06,
    aliases: ['DK390'],
  ),
  CropVarietyEntry(
    id: 'dekalb_dk7088_forage',
    label: 'DK-7088',
    cropId: kCropMaize,
    subtitle: 'Dekalb · Blanco · Forraje intermedio temprano',
    brandId: kBrandDekalb, marketTypeId: kMarketWhite, useTypeId: kUseForage,
    defaultProfileId: kMzf01,
    aliases: ['DK7088'],
  ),
  CropVarietyEntry(
    id: 'dekalb_dk7500_forage',
    label: 'DK-7500',
    cropId: kCropMaize,
    subtitle: 'Dekalb · Blanco · Forraje intermedio temprano',
    brandId: kBrandDekalb, marketTypeId: kMarketWhite, useTypeId: kUseForage,
    defaultProfileId: kMzf01,
    aliases: ['DK7500'],
  ),

  // ──────────────────────────────────────────────────────────────────────────
  // DEKALB — Maíz Amarillo
  // ──────────────────────────────────────────────────────────────────────────

  CropVarietyEntry(
    id: 'dekalb_dk4020y_grain_tardio',
    label: 'DK-4020Y',
    cropId: kCropMaize,
    subtitle: 'Dekalb · Amarillo · Grano intermedio tardío',
    brandId: kBrandDekalb, marketTypeId: kMarketYellow, useTypeId: kUseGrain,
    defaultProfileId: kMzg04,
    aliases: ['DK4020Y', 'DK-4020'],
  ),

  // ──────────────────────────────────────────────────────────────────────────
  // SYNGENTA — Maíz Blanco
  // ──────────────────────────────────────────────────────────────────────────

  CropVarietyEntry(
    id: 'syngenta_sorento_grain',
    label: 'SORENTO',
    cropId: kCropMaize,
    subtitle: 'Syngenta · Blanco · Grano precoz extremo',
    brandId: kBrandSyngenta, marketTypeId: kMarketWhite, useTypeId: kUseGrain,
    defaultProfileId: kMzg00,
  ),
  CropVarietyEntry(
    id: 'syngenta_lucino_grain',
    label: 'LUCINO',
    cropId: kCropMaize,
    subtitle: 'Syngenta · Blanco · Grano intermedio estándar',
    brandId: kBrandSyngenta, marketTypeId: kMarketWhite, useTypeId: kUseGrain,
    defaultProfileId: kMzg03,
  ),
  CropVarietyEntry(
    id: 'syngenta_nmi078_grain_tardio',
    label: 'NMI078',
    cropId: kCropMaize,
    subtitle: 'Syngenta · Blanco · Grano intermedio tardío',
    brandId: kBrandSyngenta, marketTypeId: kMarketWhite, useTypeId: kUseGrain,
    defaultProfileId: kMzg04,
  ),
  CropVarietyEntry(
    id: 'syngenta_6018w_grain',
    label: '6018W',
    cropId: kCropMaize,
    subtitle: 'Syngenta · Blanco · Grano intermedio precoz',
    brandId: kBrandSyngenta, marketTypeId: kMarketWhite, useTypeId: kUseGrain,
    defaultProfileId: kMzg02,
  ),
  CropVarietyEntry(
    id: 'syngenta_tiburon_grain_long',
    label: 'TIBURÓN',
    cropId: kCropMaize,
    subtitle: 'Syngenta · Blanco · Grano tardío extendido',
    brandId: kBrandSyngenta, marketTypeId: kMarketWhite, useTypeId: kUseGrain,
    defaultProfileId: kMzg08,
    aliases: ['TIBURON'],
  ),
  CropVarietyEntry(
    id: 'syngenta_sy600_forage',
    label: 'SY-600',
    cropId: kCropMaize,
    subtitle: 'Syngenta · Blanco · Forraje intermedio',
    brandId: kBrandSyngenta, marketTypeId: kMarketWhite, useTypeId: kUseForage,
    defaultProfileId: kMzf02,
    aliases: ['SY600'],
  ),
  CropVarietyEntry(
    id: 'syngenta_sy700_grain',
    label: 'SY-700',
    cropId: kCropMaize,
    subtitle: 'Syngenta · Blanco · Grano intermedio estándar',
    brandId: kBrandSyngenta, marketTypeId: kMarketWhite, useTypeId: kUseGrain,
    defaultProfileId: kMzg03,
    aliases: ['SY700'],
  ),
  CropVarietyEntry(
    id: 'syngenta_sy800_forage_calido',
    label: 'SY-800',
    cropId: kCropMaize,
    subtitle: 'Syngenta · Blanco · Forraje intermedio cálido',
    brandId: kBrandSyngenta, marketTypeId: kMarketWhite, useTypeId: kUseForage,
    defaultProfileId: kMzf05,
    aliases: ['SY800'],
  ),

  // ──────────────────────────────────────────────────────────────────────────
  // SYNGENTA — Maíz Amarillo
  // ──────────────────────────────────────────────────────────────────────────

  CropVarietyEntry(
    id: 'syngenta_impacto_grain',
    label: 'IMPACTO',
    cropId: kCropMaize,
    subtitle: 'Syngenta · Amarillo · Grano precoz extremo',
    brandId: kBrandSyngenta, marketTypeId: kMarketYellow, useTypeId: kUseGrain,
    defaultProfileId: kMzg00,
  ),
  CropVarietyEntry(
    id: 'syngenta_8246_grain',
    label: '8246',
    cropId: kCropMaize,
    subtitle: 'Syngenta · Amarillo · Grano intermedio precoz',
    brandId: kBrandSyngenta, marketTypeId: kMarketYellow, useTypeId: kUseGrain,
    defaultProfileId: kMzg02,
  ),
  CropVarietyEntry(
    id: 'syngenta_n83n5_grain_tardio',
    label: 'N83N5',
    cropId: kCropMaize,
    subtitle: 'Syngenta · Amarillo · Grano intermedio tardío',
    brandId: kBrandSyngenta, marketTypeId: kMarketYellow, useTypeId: kUseGrain,
    defaultProfileId: kMzg04,
  ),
  CropVarietyEntry(
    id: 'syngenta_9166_grain',
    label: '9166',
    cropId: kCropMaize,
    subtitle: 'Syngenta · Amarillo · Grano intermedio estándar',
    brandId: kBrandSyngenta, marketTypeId: kMarketYellow, useTypeId: kUseGrain,
    defaultProfileId: kMzg03,
  ),
  CropVarietyEntry(
    id: 'syngenta_9703_grain_oi',
    label: '9703',
    cropId: kCropMaize,
    subtitle: 'Syngenta · Amarillo · Grano tardío cálido OI',
    brandId: kBrandSyngenta, marketTypeId: kMarketYellow, useTypeId: kUseGrain,
    defaultProfileId: kMzg05,
  ),
  CropVarietyEntry(
    id: 'syngenta_tundra_grain_tropical',
    label: 'TUNDRA',
    cropId: kCropMaize,
    subtitle: 'Syngenta · Amarillo · Grano corto tropical',
    brandId: kBrandSyngenta, marketTypeId: kMarketYellow, useTypeId: kUseGrain,
    defaultProfileId: kMzg06,
  ),

  // ──────────────────────────────────────────────────────────────────────────
  // GENÉRICOS — "No conozco mi semilla"
  // ──────────────────────────────────────────────────────────────────────────

  CropVarietyEntry(
    id: 'generic_maize_white_grain',
    label: 'Maíz blanco (no sé la variedad)',
    cropId: kCropMaize,
    subtitle: 'Genérico · Blanco · Grano',
    brandId: null, marketTypeId: kMarketWhite, useTypeId: kUseGrain,
    defaultProfileId: kMzgGenB,
    isGeneric: true,
    aliases: ['GENERIC_WHITE_GRAIN', 'MAIZE_WHITE_GENERIC'],
  ),
  CropVarietyEntry(
    id: 'generic_maize_yellow_grain',
    label: 'Maíz amarillo (no sé la variedad)',
    cropId: kCropMaize,
    subtitle: 'Genérico · Amarillo · Grano',
    brandId: null, marketTypeId: kMarketYellow, useTypeId: kUseGrain,
    defaultProfileId: kMzgGenA,
    isGeneric: true,
    aliases: ['GENERIC_YELLOW_GRAIN', 'MAIZE_YELLOW_GENERIC'],
  ),
  CropVarietyEntry(
    id: 'generic_maize_forage',
    label: 'Maíz forrajero (no sé la variedad)',
    cropId: kCropMaize,
    subtitle: 'Genérico · Forraje',
    brandId: null, marketTypeId: null, useTypeId: kUseForage,
    defaultProfileId: kMzfGen,
    isGeneric: true,
    aliases: ['GENERIC_FORAGE', 'MAIZE_FORAGE_GENERIC'],
  ),
  CropVarietyEntry(
    id: 'generic_maize_elote',
    label: 'Elote (no sé la variedad)',
    cropId: kCropMaize,
    subtitle: 'Genérico · Elote',
    brandId: null, marketTypeId: kMarketSweet, useTypeId: kUseElote,
    defaultProfileId: kMzeGen,
    isGeneric: true,
    aliases: ['GENERIC_ELOTE', 'MAIZE_ELOTE_GENERIC'],
  ),
];

// ═════════════════════════════════════════════════════════════════════════════
// HELPERS DEL CATÁLOGO
// ═════════════════════════════════════════════════════════════════════════════

/// Todas las variedades de una marca.
List<CropVarietyEntry> maizeVarietiesByBrand(String brandId) =>
    maizeVarieties.where((v) => v.brandId == brandId).toList();

/// Variedades filtradas por marca + tipo de mercado.
List<CropVarietyEntry> maizeVarietiesByBrandAndMarket(
  String brandId,
  String marketTypeId,
) =>
    maizeVarieties
        .where((v) => v.brandId == brandId && v.marketTypeId == marketTypeId)
        .toList();

/// Variedades filtradas por tipo de uso (grain/forage/elote).
List<CropVarietyEntry> maizeVarietiesByUse(String useTypeId) =>
    maizeVarieties.where((v) => v.useTypeId == useTypeId).toList();

/// Busca una variedad por su ID canónico.
CropVarietyEntry? maizeVarietyById(String id) {
  for (final v in maizeVarieties) {
    if (v.id == id) return v;
  }
  return null;
}

/// Busca una variedad por label visible + marca + uso (para resolución en wizard).
CropVarietyEntry? maizeVarietyByLabelAndContext({
  required String label,
  String? brandId,
  String? useTypeId,
}) {
  final normalized = label.trim().toUpperCase();
  for (final v in maizeVarieties) {
    final labelMatch = v.label.toUpperCase() == normalized;
    if (!labelMatch) continue;
    if (brandId != null && v.brandId != brandId) continue;
    if (useTypeId != null && v.useTypeId != useTypeId) continue;
    return v;
  }
  return null;
}

/// Busca por alias (legacy DK-2069, etc.).
CropVarietyEntry? maizeVarietyByAlias(String alias) {
  final normalized = alias.trim().toUpperCase();
  for (final v in maizeVarieties) {
    for (final a in v.aliases) {
      if (a.toUpperCase() == normalized) return v;
    }
  }
  return null;
}

/// Genéricos solamente.
List<CropVarietyEntry> get maizeGenericVarieties =>
    maizeVarieties.where((v) => v.isGeneric).toList();

// ═════════════════════════════════════════════════════════════════════════════
// ENTRADAS DE PERFIL — para CropCatalogEntry.profiles
// Permite que CropCatalog.resolveProfileId() valide IDs de los 21 perfiles.
// ═════════════════════════════════════════════════════════════════════════════

const List<CropProfileEntry> maizeProfileEntries = [

  // Forrajeros
  CropProfileEntry(id: kMzf00, label: 'Forrajero precoz',              cropId: kCropMaize),
  CropProfileEntry(id: kMzf01, label: 'Forrajero intermedio temprano', cropId: kCropMaize),
  CropProfileEntry(id: kMzf02, label: 'Forrajero intermedio',          cropId: kCropMaize),
  CropProfileEntry(id: kMzf03, label: 'Forrajero intermedio tardío',   cropId: kCropMaize),
  CropProfileEntry(id: kMzf04, label: 'Forrajero tardío',              cropId: kCropMaize),
  CropProfileEntry(id: kMzf05, label: 'Forrajero intermedio cálido',   cropId: kCropMaize),
  CropProfileEntry(id: kMzf06, label: 'Forrajero súper precoz',        cropId: kCropMaize),

  // Grano
  CropProfileEntry(id: kMzg00, label: 'Grano precoz extremo',               cropId: kCropMaize),
  CropProfileEntry(id: kMzg01, label: 'Grano precoz',                       cropId: kCropMaize),
  CropProfileEntry(id: kMzg02, label: 'Grano intermedio precoz',            cropId: kCropMaize),
  CropProfileEntry(id: kMzg03, label: 'Grano intermedio estándar',          cropId: kCropMaize),
  CropProfileEntry(id: kMzg04, label: 'Grano intermedio tardío',            cropId: kCropMaize),
  CropProfileEntry(id: kMzg05, label: 'Grano intermedio tardío cálido',     cropId: kCropMaize),
  CropProfileEntry(id: kMzg06, label: 'Grano intermedio corto tropical',    cropId: kCropMaize),
  CropProfileEntry(
    id: kMzg07,
    label: 'Grano intermedio corto invernal',
    cropId: kCropMaize,
    aliases: <String>['MZG-07'],
  ),
  CropProfileEntry(id: kMzg08, label: 'Grano tardío extendido',             cropId: kCropMaize),
  CropProfileEntry(id: kMzg09, label: 'Grano largo de riego',               cropId: kCropMaize),

  // Elote
  CropProfileEntry(id: kMze00, label: 'Elote intermedio', cropId: kCropMaize),

  // Genéricos
  CropProfileEntry(
    id: kMzgGenB,
    label: 'Genérico blanco/grano',
    cropId: kCropMaize,
    aliases: <String>['GENERIC_WHITE_GRAIN'],
  ),
  CropProfileEntry(
    id: kMzgGenA,
    label: 'Genérico amarillo/grano',
    cropId: kCropMaize,
    aliases: <String>['GENERIC_YELLOW_GRAIN'],
  ),
  CropProfileEntry(id: kMzfGen, label: 'Genérico forrajero', cropId: kCropMaize),
  CropProfileEntry(id: kMzeGen, label: 'Genérico elote',     cropId: kCropMaize),

  // Legacy ID — backward compat para usuarios con 'maize_generic' en prefs
  CropProfileEntry(
    id: kMaizeGenericProfileId,
    label: 'Genérico (legacy)',
    cropId: kCropMaize,
    aliases: <String>['MAIZE_GENERIC'],
  ),
];
