import 'package:bio_g/core/crops/catalog/crop_catalog_models.dart';

/// Catalogo base del Naranjo / Naranja dulce (Citrus sinensis (L.) Osbeck).
///
/// Solo contiene metadata de catalogo: ids de perfil, etiquetas humanas y
/// aliases. La agronomia vive en `orange_tree_universal_profile.dart` y
/// `orange_tree_yield_reference.dart` (docs 01-05 del paquete Naranjo).
///
/// Regla citrica central (doc 01 §0.3): el naranjo es un arbol perenne
/// SIEMPREVERDE. No usa sowingDate como eje ni trata `dormancy` como arbol
/// caducifolio pelon: el eje es estado del arbol + etapa visible + ancla +
/// memoria.
const String kCropOrangeTree = 'crop_orange_tree';

/// Id legacy del naranjo. Conservado solo como alias de compatibilidad
/// (doc 01 §0.1, §2).
const String kCropOrangeTreeLegacy = 'orange_tree';

const String kOrSkip = 'or_skip';
const String kOr01Valencia = 'or_01_valencia';
const String kOr02Navel = 'or_02_navel';
const String kOr03Temprano = 'or_03_temprano';
const String kOr04CriolloRegional = 'or_04_criollo_regional';
const String kOr05TropicalCalido = 'or_05_tropical_calido';

const List<CropProfileEntry> orangeTreeProfileEntries = [
  CropProfileEntry(
    id: kOr01Valencia,
    label: 'Valencia / tardía / jugo',
    cropId: kCropOrangeTree,
    subtitle:
        'Naranja tardía para jugo e industria, aguanta más tiempo colgada en '
        'el árbol (Valencia)',
    aliases: [
      'OR-01',
      'OR01',
      'Valencia',
      'Valencia Late',
      'Valencia tardia',
      'Valencia tardía',
      'Valencia comun',
      'Valencia común',
      'Valencia de industria',
      'naranja para jugo',
      'naranja de jugo',
      'jugo',
      'tardia',
      'tardía',
      // Migracion: ids previos de los docs 01/03 conservados como alias.
      'or_01_valencia_tardia',
      'or_01_valencia_late',
      'or_01_tardia',
    ],
  ),
  CropProfileEntry(
    id: kOr02Navel,
    label: 'Navel / ombligo / mesa',
    cropId: kCropOrangeTree,
    subtitle:
        'Naranja de mesa u ombligona, donde pesan más el calibre, el color y '
        'la calidad externa (Navel)',
    aliases: [
      'OR-02',
      'OR02',
      'Navel',
      'Washington Navel',
      'Navelina',
      'naranja de ombligo',
      'ombligona',
      'ombligo',
      'mesa',
      'naranja de mesa',
      'Cara Cara',
      'or_02_navel_mesa',
      'or_02_ombligo',
      'or_02_washington_navel',
    ],
  ),
  CropProfileEntry(
    id: kOr03Temprano,
    label: 'Temprano / Hamlin-Pineapple',
    cropId: kCropOrangeTree,
    subtitle:
        'Naranja del grupo temprano que adelanta la cosecha (Hamlin, Pineapple '
        'o Parson Brown)',
    aliases: [
      'OR-03',
      'OR03',
      'Hamlin',
      'Pineapple',
      'Parson Brown',
      'temprana',
      'temprano',
      'naranja temprana',
      'naranja de corte temprano',
      'corte temprano',
      'or_03_temprano_hamlin_pineapple',
      'or_03_hamlin',
      'or_03_pineapple',
    ],
  ),
  CropProfileEntry(
    id: kOr04CriolloRegional,
    label: 'Criollo / regional / huerto viejo',
    cropId: kCropOrangeTree,
    subtitle:
        'Naranja criolla de huerto viejo o mezcla de árboles, con la variedad '
        'no bien conocida',
    aliases: [
      'OR-04',
      'OR04',
      'Criolla',
      'criollo',
      'regional',
      'comun',
      'común',
      'naranja del rancho',
      'huerto viejo',
      'naranja local',
      'naranja dulce regional',
      'or_04_criolla',
      'or_04_regional',
    ],
  ),
  CropProfileEntry(
    id: kOr05TropicalCalido,
    label: 'Tropical / clima cálido / floración múltiple',
    cropId: kCropOrangeTree,
    subtitle:
        'Naranja de zona cálida y húmeda, que puede traer flor, fruto y brote '
        'al mismo tiempo',
    aliases: [
      'OR-05',
      'OR05',
      'Tropical',
      'naranja de clima calido',
      'naranja de clima cálido',
      'naranja de calor',
      'clima calido',
      'clima cálido',
      'floracion multiple',
      'floración múltiple',
      'huasteca tropical',
      'region calida',
      'región cálida',
      'or_05_tropical',
      'or_05_clima_calido',
    ],
  ),
  CropProfileEntry(
    id: kOrSkip,
    label: 'No sé / Naranjo general',
    cropId: kCropOrangeTree,
    subtitle:
        'Perfil general y migrable del naranjo, precisa la variedad después '
        'sin perder historial; no es descanso del suelo',
    aliases: [
      'OR-SKIP',
      'OR_SKIP',
      'ORSKIP',
      'Naranjo',
      'Naranja',
      'Naranjo general',
      'Naranja comun',
      'Naranja común',
      'naranja dulce',
      'arbol de naranja',
      'árbol de naranja',
      'orange',
      'orange tree',
      'sweet orange',
      'No sé',
      'No se',
      'No sé qué variedad',
      'No sé la variedad',
    ],
  ),
];
