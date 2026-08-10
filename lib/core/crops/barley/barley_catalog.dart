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
    subtitle:
        'Cebada de ciclo corto que puedes llevar a grano o cortar temprano '
        'como forraje',
    aliases: ['CB-01', 'CB01', 'Precoz', 'Temprana'],
  ),
  CropProfileEntry(
    id: kCb02,
    label: 'CB-02 · Intermedio / Maltera',
    cropId: kCropBarley,
    subtitle:
        'Cebada de ciclo intermedio para grano maltero e industrial, la más '
        'sembrada en México',
    aliases: ['CB-02', 'CB02', 'Intermedio', 'Maltera'],
  ),
  CropProfileEntry(
    id: kCb03,
    label: 'CB-03 · Largo / Riego',
    cropId: kCropBarley,
    subtitle:
        'Cebada de ciclo largo para siembra bajo riego, con alto potencial de '
        'grano',
    aliases: ['CB-03', 'CB03', 'Largo', 'Riego'],
  ),
  CropProfileEntry(
    id: kCb04,
    label: 'CB-04 · Forrajera',
    cropId: kCropBarley,
    subtitle:
        'Cebada sembrada para forraje, con corte temprano de planta verde para '
        'el ganado',
    aliases: ['CB-04', 'CB04', 'Forrajera'],
  ),
  CropProfileEntry(
    id: kCbGen,
    label: 'CB-GEN · Intermedio Conservador',
    cropId: kCropBarley,
    subtitle:
        'Perfil general y migrable de cebada: puedes precisar la variedad '
        'después sin perder tu historial',
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
    subtitle:
        'Cebada maltera de ciclo temprano liberada por el INIFAP, se cosecha '
        'en grano para la industria',
    defaultProfileId: kCb01,
    aliases: ['Esperanza', 'Cebada Esperanza'],
  ),
  CropVarietyEntry(
    id: 'barley_maravilla',
    label: 'Maravilla',
    cropId: kCropBarley,
    subtitle:
        'Cebada de ciclo temprano del INIFAP, su grano se destina a malta y a '
        'la industria cervecera',
    defaultProfileId: kCb01,
    aliases: ['Maravilla', 'Cebada Maravilla'],
  ),
  CropVarietyEntry(
    id: 'barley_cucapah_87',
    label: 'Cucapah 87',
    cropId: kCropBarley,
    subtitle:
        'Cebada de ciclo temprano para siembra bajo riego en el noroeste, se '
        'lleva hasta grano seco',
    defaultProfileId: kCb01,
    aliases: ['Cucapah 87', 'Cucapah', 'Cebada Cucapah'],
  ),
  CropVarietyEntry(
    id: 'barley_lg_diablo',
    label: 'LG Diablo',
    cropId: kCropBarley,
    subtitle:
        'Cebada maltera de primavera de origen europeo, grano de ciclo '
        'temprano para malta y cerveza',
    defaultProfileId: kCb01,
    aliases: ['LG Diablo', 'Diablo'],
  ),
  CropVarietyEntry(
    id: 'barley_kws_fantex',
    label: 'KWS Fantex',
    cropId: kCropBarley,
    subtitle:
        'Cebada maltera de primavera de mejoramiento europeo, ciclo temprano y '
        'cosecha en grano',
    defaultProfileId: kCb01,
    aliases: ['KWS Fantex', 'Fantex'],
  ),

  // ── Maltera / Intermedia ─────────────────────────────────────────────────
  CropVarietyEntry(
    id: 'barley_esmeralda',
    label: 'Esmeralda',
    cropId: kCropBarley,
    subtitle:
        'Cebada maltera de ciclo intermedio liberada por el INIFAP, grano para '
        'malta y cervecería',
    defaultProfileId: kCb02,
    aliases: ['Esmeralda', 'Cebada Esmeralda'],
  ),
  CropVarietyEntry(
    id: 'barley_adabella',
    label: 'Adabella',
    cropId: kCropBarley,
    subtitle:
        'Cebada maltera del INIFAP para siembra de temporal, grano que compra '
        'la industria cervecera',
    defaultProfileId: kCb02,
    aliases: ['Adabella', 'Cebada Adabella'],
  ),
  CropVarietyEntry(
    id: 'barley_armida',
    label: 'Armida',
    cropId: kCropBarley,
    subtitle:
        'Cebada maltera liberada por el INIFAP, su grano se entrega a maltería '
        'y no a forraje',
    defaultProfileId: kCb02,
    aliases: ['Armida', 'Cebada Armida'],
  ),
  CropVarietyEntry(
    id: 'barley_alina',
    label: 'Alina',
    cropId: kCropBarley,
    subtitle:
        'Cebada maltera del INIFAP para cosecha de grano, la que se siembra '
        'por contrato con la industria',
    defaultProfileId: kCb02,
    aliases: ['Alina', 'Cebada Alina'],
  ),
  CropVarietyEntry(
    id: 'barley_dona_josefa',
    label: 'Doña Josefa',
    cropId: kCropBarley,
    subtitle:
        'Cebada maltera del INIFAP, grano de temporal destinado a malta y a la '
        'industria cervecera',
    defaultProfileId: kCb02,
    aliases: ['Doña Josefa', 'Dona Josefa', 'Cebada Doña Josefa'],
  ),
  CropVarietyEntry(
    id: 'barley_rgt_planet',
    label: 'RGT Planet',
    cropId: kCropBarley,
    subtitle:
        'Cebada maltera de primavera de origen europeo, muy usada para grano '
        'con destino a malta',
    defaultProfileId: kCb02,
    aliases: ['RGT Planet', 'Planet'],
  ),
  CropVarietyEntry(
    id: 'barley_rgt_asteroid',
    label: 'RGT Asteroid',
    cropId: kCropBarley,
    subtitle:
        'Cebada maltera de primavera de mejoramiento europeo, se cosecha en '
        'grano para maltería',
    defaultProfileId: kCb02,
    aliases: ['RGT Asteroid', 'Asteroid'],
  ),
  CropVarietyEntry(
    id: 'barley_sy_tungsten',
    label: 'SY Tungsten',
    cropId: kCropBarley,
    subtitle:
        'Cebada maltera de primavera de origen europeo, grano para malta y '
        'cerveza, no para corte',
    defaultProfileId: kCb02,
    aliases: ['SY Tungsten', 'Tungsten'],
  ),
  CropVarietyEntry(
    id: 'barley_sy_odyssey',
    label: 'SY Odyssey',
    cropId: kCropBarley,
    subtitle:
        'Cebada maltera de primavera de origen europeo, su grano se vende a la '
        'industria de malta',
    defaultProfileId: kCb02,
    aliases: ['SY Odyssey', 'Odyssey'],
  ),
  CropVarietyEntry(
    id: 'barley_lg_zebra',
    label: 'LG Zebra',
    cropId: kCropBarley,
    subtitle:
        'Cebada maltera de primavera de origen europeo, cosecha de grano con '
        'destino cervecero',
    defaultProfileId: kCb02,
    aliases: ['LG Zebra', 'Zebra'],
  ),
  CropVarietyEntry(
    id: 'barley_lg_esterel',
    label: 'LG Esterel',
    cropId: kCropBarley,
    subtitle:
        'Cebada maltera de mejoramiento europeo, grano que se coloca en '
        'malterías y cervecerías',
    defaultProfileId: kCb02,
    aliases: ['LG Esterel', 'Esterel'],
  ),
  CropVarietyEntry(
    id: 'barley_kws_orbit',
    label: 'KWS Orbit',
    cropId: kCropBarley,
    subtitle:
        'Cebada maltera de primavera de origen europeo, se lleva hasta grano '
        'seco para maltería',
    defaultProfileId: kCb02,
    aliases: ['KWS Orbit', 'Orbit'],
  ),

  // ── Largo / Riego ────────────────────────────────────────────────────────
  CropVarietyEntry(
    id: 'barley_estelar_oh',
    label: 'Estelar-OH',
    cropId: kCropBarley,
    subtitle:
        'Cebada de ciclo largo pensada para siembra bajo riego, se lleva hasta '
        'cosecha de grano seco',
    defaultProfileId: kCb03,
    aliases: ['Estelar-OH', 'Estelar OH', 'Estelar'],
  ),

  // ── Forrajera ─────────────────────────────────────────────────────────────
  CropVarietyEntry(
    id: 'barley_forrajera_inifap',
    label: 'Cebada forrajera INIFAP',
    cropId: kCropBarley,
    subtitle:
        'Cebada de uso forrajero liberada por el INIFAP, se corta en verde o '
        'se ensila para el ganado',
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
    subtitle:
        'Cebada forrajera del INIFAP, se aprovecha en corte verde, henificada '
        'o en ensilado',
    defaultProfileId: kCb04,
    aliases: ['Cerro Prieto', 'Cebada Cerro Prieto'],
  ),
  CropVarietyEntry(
    id: 'barley_puebla',
    label: 'Puebla',
    cropId: kCropBarley,
    subtitle:
        'Cebada de uso forrajero, se siembra para corte de planta verde y '
        'alimento del ganado',
    defaultProfileId: kCb04,
    aliases: ['Puebla', 'Cebada Puebla'],
  ),

  // ── Genérica ─────────────────────────────────────────────────────────────
  CropVarietyEntry(
    id: 'barley_generic',
    label: 'Cebada genérica',
    cropId: kCropBarley,
    subtitle:
        'Perfil general y migrable para cebada a granel: puedes precisar la '
        'variedad después sin perder historial',
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
