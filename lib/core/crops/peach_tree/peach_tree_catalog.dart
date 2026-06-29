import 'package:bio_g/core/crops/catalog/crop_catalog_models.dart';

/// Catalogo base del Durazno / Duraznero (Prunus persica).
///
/// Solo contiene metadata de catalogo: ids de perfil, etiquetas humanas y
/// aliases. La agronomia vive en `peach_tree_universal_profile.dart` y
/// `peach_tree_yield_reference.dart`.
const String kCropPeachTree = 'crop_peach_tree';

/// Id legacy del durazno. Conservado solo como alias de compatibilidad.
const String kCropPeachTreeLegacy = 'peach_tree';

const String kDzSkip = 'dz_skip';
const String kDz01CriolloRegional = 'dz_01_criollo_regional';
const String kDz02TempranoBajoFrio = 'dz_02_temprano_bajo_frio';
const String kDz03AmarilloComercial = 'dz_03_amarillo_comercial';
const String kDz04BlancoDulce = 'dz_04_blanco_dulce';
const String kDz05TardioIndustria = 'dz_05_tardio_industria';

const List<CropProfileEntry> peachTreeProfileEntries = [
  CropProfileEntry(
    id: kDz01CriolloRegional,
    label: 'Criollo / Regional',
    cropId: kCropPeachTree,
    subtitle: 'Durazno criollo, regional o tradicional para mercado local',
    aliases: [
      'DZ-01',
      'DZ01',
      'Criollo',
      'Regional',
      'Criollo / regional',
      'Criollo / Regional',
      'Tradicional',
      'Durazno criollo',
      'Durazno de rancho',
      'Durazno amarillo criollo',
      'Durazno local',
      'Variedad regional',
      'Otra variedad criolla',
      'Prisco',
      'Oro Azteca',
      'Diamante',
      'San Juan',
      'Regio',
      'Otra criolla',
    ],
  ),
  CropProfileEntry(
    id: kDz02TempranoBajoFrio,
    label: 'Temprano / bajo frío',
    cropId: kCropPeachTree,
    subtitle: 'Durazno temprano o de bajo requerimiento de frio',
    aliases: [
      'DZ-02',
      'DZ02',
      'Bajo frio',
      'Bajo frío',
      'Temprano / bajo frío',
      'Temprano / Bajo frio',
      'Temprano',
      'Muy temprano',
      'Precoz',
      'Flordaprince',
      'Anna',
      'Fred',
      'Victoria Temprano',
      'June Gold',
      'Durazno temprano',
      'Otra variedad de bajo frio',
    ],
  ),
  CropProfileEntry(
    id: kDz03AmarilloComercial,
    label: 'Amarillo comercial',
    cropId: kCropPeachTree,
    subtitle: 'Durazno amarillo comercial de mercado fresco',
    aliases: [
      'DZ-03',
      'DZ03',
      'Amarillo',
      'Comercial',
      'Amarillo comercial',
      'Durazno amarillo',
      'Redhaven',
      'Suncrest',
      "O'Henry",
      'OHenry',
      'Oro',
      'Mercado nacional',
      'Otra variedad amarilla',
    ],
  ),
  CropProfileEntry(
    id: kDz04BlancoDulce,
    label: 'Blanco / Dulce',
    cropId: kCropPeachTree,
    subtitle: 'Durazno de carne blanca o especialidad dulce / premium',
    aliases: [
      'DZ-04',
      'DZ04',
      'Blanco',
      'Durazno blanco',
      'Dulce',
      'Blanco / dulce',
      'Blanco / Dulce',
      'Especialidad',
      'Premium',
      'Donut',
      'Saturn',
      'Chato',
      'Paraguayo',
      'Otra variedad blanca',
    ],
  ),
  CropProfileEntry(
    id: kDz05TardioIndustria,
    label: 'Tardío / industria',
    cropId: kCropPeachTree,
    subtitle: 'Durazno tardio, de industria, proceso o mercado tardio',
    aliases: [
      'DZ-05',
      'DZ05',
      'Tardio',
      'Tardío',
      'Tardío / industria',
      'Tardío / Industria',
      'Industria',
      'Proceso',
      'Processing peach',
      'Conserva',
      'Almibar',
      'Almíbar',
      'Durazno para industria',
      'Mercado tardio',
      'Cling',
      'Otra variedad tardia',
    ],
  ),
  CropProfileEntry(
    id: kDzSkip,
    label: 'No sé / Durazno general',
    cropId: kCropPeachTree,
    subtitle:
        'Perfil general y migrable del durazno: puedes precisar la variedad '
        'despues sin perder historial. No es descanso del suelo.',
    aliases: [
      'DZ-SKIP',
      'DZ_SKIP',
      'DZSKIP',
      'Durazno',
      'Duraznero',
      'Melocoton',
      'Melocotón',
      'Melocotonero',
      'Durazno general',
      'No sé',
      'No se',
      'Peach',
      'Peach tree',
      'Nectarina',
      'Nectarine',
      'Pelon',
      'Pelón',
      'Pavia',
      'Pavía',
      'Durazno sin pelusa',
    ],
  ),
];
