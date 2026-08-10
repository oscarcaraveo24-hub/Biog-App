import 'package:bio_g/core/crops/catalog/crop_catalog_models.dart';

/// Catalogo base del Limon / Limonero (grupo comercial Citrus: C. latifolia,
/// C. aurantiifolia y C. limon segun perfil).
///
/// Solo contiene metadata de catalogo: ids de perfil, etiquetas humanas y
/// aliases. La agronomia vive en `lemon_tree_universal_profile.dart` y
/// `lemon_tree_yield_reference.dart` (docs 01-05 del paquete Limon).
///
/// Regla citrica central (doc 01 §0.4): el limonero es un arbol perenne
/// SIEMPREVERDE de produccion frecuente. Puede tener brote, flor, frutito y
/// fruto de corte al mismo tiempo. No usa sowingDate como eje ni trata
/// `dormancy` como arbol caducifolio pelon: el eje es estado del arbol + etapa
/// visible + ancla + memoria. NO es un naranjo pequeno.
const String kCropLemonTree = 'crop_lemon_tree';

/// Id legacy/cropKey esperado del limon. Conservado como alias de
/// compatibilidad (doc 01 §0.1, §1).
const String kLemonTreeLegacy = 'lemon_tree';

/// Aliases botanicos lime del PDF base: los perfiles LM no cambian aunque
/// internamente se acepte lime/lemon (doc 01 §0.2, doc 03 §0.2).
const String kLimeTreeLegacy = 'lime_tree';
const String kCropLimeTreeLegacy = 'crop_lime_tree';

const String kLmSkip = 'lm_skip';
const String kLm01PersaTahiti = 'lm_01_persa_tahiti';
const String kLm02MexicanoColima = 'lm_02_mexicano_colima';
const String kLm03AmarilloEurekaLisbon = 'lm_03_amarillo_eureka_lisbon';
const String kLm04TropicalContinuo = 'lm_04_tropical_continuo';
const String kLm05DesfaseInducido = 'lm_05_desfase_inducido';

const List<CropProfileEntry> lemonTreeProfileEntries = [
  CropProfileEntry(
    id: kLm01PersaTahiti,
    label: 'Persa / Tahití / sin semilla',
    cropId: kCropLemonTree,
    subtitle:
        'Limón grande y verde, casi siempre sin semilla, para fresco y '
        'exportación (persa o Tahití)',
    aliases: [
      'LM-01',
      'LM01',
      'Persa',
      'Tahití',
      'Tahiti',
      'Persian lime',
      'limón persa',
      'limon persa',
      'limón sin semilla',
      'limon sin semilla',
      'sin semilla',
      // Migracion: ids previos de los docs 01/03 conservados como alias.
      'lm_01_persa',
      'lm_01_tahiti',
      'lm_01_persian_lime',
      'lm_01_sin_semilla',
    ],
  ),
  CropProfileEntry(
    id: kLm02MexicanoColima,
    label: 'Mexicano / Colima / con semilla',
    cropId: kCropLemonTree,
    subtitle:
        'Limón chico y muy ácido, con semilla y cortes frecuentes (mexicano, '
        'criollo o de Colima)',
    aliases: [
      'LM-02',
      'LM02',
      'Mexicano',
      'Colima',
      'Criollo',
      'criollo agrio',
      'limón mexicano',
      'limon mexicano',
      'limón agrio',
      'limon agrio',
      'Key lime',
      'key lime',
      'con semilla',
      'limón verde mexicano',
      'limon verde mexicano',
      'lm_02_mexicano',
      'lm_02_colima',
      'lm_02_criollo',
      'lm_02_key_lime',
      'lm_02_agrio',
    ],
  ),
  CropProfileEntry(
    id: kLm03AmarilloEurekaLisbon,
    label: 'Amarillo / Eureka / Lisbon',
    cropId: kCropLemonTree,
    subtitle:
        'Limón amarillo verdadero, poco común en México (Eureka, Lisbon o '
        'italiano)',
    aliases: [
      'LM-03',
      'LM03',
      'Amarillo',
      'Italiano',
      'italiano',
      'Eureka',
      'Lisbon',
      'Lisboa',
      'limón amarillo',
      'limon amarillo',
      'limón italiano',
      'limon italiano',
      'lm_03_amarillo',
      'lm_03_italiano',
      'lm_03_eureka',
      'lm_03_lisbon',
      'lm_03_lisboa',
    ],
  ),
  CropProfileEntry(
    id: kLm04TropicalContinuo,
    label: 'Tropical / producción continua',
    cropId: kCropLemonTree,
    subtitle:
        'Limón de zona cálida con flor, fruto y brote al mismo tiempo y cortes '
        'repetidos',
    aliases: [
      'LM-04',
      'LM04',
      'Tropical',
      'tropical continuo',
      'producción continua',
      'produccion continua',
      'de calor',
      'limón tropical',
      'limon tropical',
      'lm_04_tropical',
      'lm_04_continuo',
      'lm_04_de_calor',
    ],
  ),
  CropProfileEntry(
    id: kLm05DesfaseInducido,
    label: 'Desfase / producción programada',
    cropId: kCropLemonTree,
    subtitle:
        'Manejo de riego, estrés y poda para mover la cosecha a meses de mejor '
        'precio, no es una variedad',
    aliases: [
      'LM-05',
      'LM05',
      'Desfase',
      'desfase',
      'Inducido',
      'inducido',
      'producción de invierno',
      'produccion de invierno',
      'meses caros',
      'programado',
      'producción programada',
      'produccion programada',
      'lm_05_desfase',
      'lm_05_inducido',
      'lm_05_invierno',
      'lm_05_programado',
    ],
  ),
  CropProfileEntry(
    id: kLmSkip,
    label: 'No sé / Limón general',
    cropId: kCropLemonTree,
    subtitle:
        'Perfil general y migrable del limón, precisa la variedad después sin '
        'perder historial; no es descanso del suelo',
    aliases: [
      'LM-SKIP',
      'LM_SKIP',
      'LMSKIP',
      'Limón',
      'Limon',
      'Limonero',
      'limonero',
      'Limón general',
      'limón común',
      'limon comun',
      'limón verde',
      'limon verde',
      'lima',
      'lemon',
      'lime',
      'lemon tree',
      'lime tree',
      'árbol de limón',
      'arbol de limon',
      'No sé',
      'No se',
      'No sé qué tipo de limón',
      'No sé la variedad',
    ],
  ),
];
