import 'package:bio_g/core/crops/catalog/crop_catalog_models.dart';

/// Catalogo base del Pistache / Pistacho (Pistacia vera L.).
///
/// Solo contiene metadata de catalogo: ids de perfil, etiquetas humanas y
/// aliases. La agronomia vive en `pistachio_tree_universal_profile.dart` y
/// `pistachio_tree_yield_reference.dart` (docs 01-05 del paquete Pistache).
const String kCropPistachioTree = 'crop_pistachio_tree';

/// Id legacy del pistache. Conservado solo como alias de compatibilidad
/// (doc 01 §0.1, §2).
const String kCropPistachioTreeLegacy = 'pistachio_tree';

const String kPsSkip = 'ps_skip';
const String kPs01KermanPeters = 'ps_01_kerman_peters';
const String kPs02GoldenHillsRandy = 'ps_02_golden_hills_randy';
const String kPs03LostHillsRandy = 'ps_03_lost_hills_randy';
const String kPs04SiroraCompatible = 'ps_04_sirora_compatible';
const String kPs05LarnakaMateurLowChill = 'ps_05_larnaka_mateur_low_chill';

const List<CropProfileEntry> pistachioTreeProfileEntries = [
  CropProfileEntry(
    id: kPs01KermanPeters,
    label: 'Kerman / Peters',
    cropId: kCropPistachioTree,
    subtitle:
        'Pistache tradicional de cosecha tardía, con Peters como macho '
        'polinizador (Kerman)',
    aliases: [
      'PS-01',
      'PS01',
      'Kerman',
      'Kerman tradicional',
      'Peters',
      'Kerman/Peters',
      'Kerman Peters',
      'pistache americano',
      'tradicional',
      'California',
      'tardio',
      // Migracion: id previo conservado como alias (no romper historial).
      'ps_01_kerman',
    ],
  ),
  CropProfileEntry(
    id: kPs02GoldenHillsRandy,
    label: 'Golden Hills / Randy',
    cropId: kCropPistachioTree,
    subtitle:
        'Pistache moderno más temprano que el Kerman, con Randy como macho '
        'polinizador (Golden Hills)',
    aliases: [
      'PS-02',
      'PS02',
      'Golden Hills',
      'Golden Hills temprano',
      'GH',
      'Golden',
      'Golden/Randy',
      'Randy',
      'temprano',
      'ps_02_golden_hills',
      'ps_02_golden',
    ],
  ),
  CropProfileEntry(
    id: kPs03LostHillsRandy,
    label: 'Lost Hills / Randy',
    cropId: kCropPistachioTree,
    subtitle:
        'Pistache moderno de nuez grande, con Randy como macho polinizador '
        '(Lost Hills)',
    aliases: [
      'PS-03',
      'PS03',
      'Lost Hills',
      'Lost Hills calibre grande',
      'LH',
      'Lost',
      'Lost/Randy',
      'calibre grande',
      'ps_03_lost_hills',
      'ps_03_lost',
    ],
  ),
  CropProfileEntry(
    id: kPs04SiroraCompatible,
    label: 'Sirora / compatible',
    cropId: kCropPistachioTree,
    subtitle:
        'Pistache intermedio y adaptable, sin macho polinizador definido '
        '(Sirora)',
    aliases: [
      'PS-04',
      'PS04',
      'Sirora',
      'Sirora intermedio',
      'pistache australiano',
      'intermedio',
      'adaptable',
      'otra variedad intermedia',
      'ps_04_sirora',
    ],
  ),
  CropProfileEntry(
    id: kPs05LarnakaMateurLowChill,
    label: 'Larnaka / Mateur (bajo-frio relativo)',
    cropId: kCropPistachioTree,
    subtitle:
        'Pistache mediterráneo temprano, pide menos frío pero no cero frío '
        '(Larnaka o Mateur)',
    aliases: [
      'PS-05',
      'PS05',
      'Larnaka',
      'Mateur',
      'mediterraneo',
      'mediterraneo bajo-frio',
      'bajo frio',
      'bajo-frio',
      'temprano mediterraneo',
      'otra variedad temprana',
      'ps_05_larnaka_mateur',
      'ps_05_low_chill',
      'ps_05_mediterraneo',
    ],
  ),
  CropProfileEntry(
    id: kPsSkip,
    label: 'No sé / Pistache general',
    cropId: kCropPistachioTree,
    subtitle:
        'Perfil general y migrable del pistache, precisa variedad y macho '
        'después sin perder historial; no es descanso del suelo',
    aliases: [
      'PS-SKIP',
      'PS_SKIP',
      'PSSKIP',
      'Pistache',
      'Pistacho',
      'Pistache general',
      'Pistachero',
      'alfoncigo',
      'alfóncigo',
      'arbol de pistache',
      'pistachio',
      'pistachio tree',
      'No sé',
      'No se',
      'No sé qué variedad',
      'No sé la variedad',
    ],
  ),
];
