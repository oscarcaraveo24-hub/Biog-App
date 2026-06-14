import 'package:bio_g/core/crops/catalog/crop_catalog_models.dart';

/// Catálogo base de Manzano (Malus domestica) — Fase 1.
///
/// Solo metadata de catálogo: ids de perfil, etiquetas y alias. No contiene
/// lógica agronómica (sin GDD, horas frío, VPD, fenología ni rendimiento);
/// esa lógica llega en la Fase 2 del runtime perenne.
///
/// AP-SKIP es el perfil general/seguro de manzano ("No sé / Manzano general").
/// IMPORTANTE: AP-SKIP NO significa descanso/fallow del suelo. En árboles la
/// variedad/perfil es opcional y migrable: cambiar de AP-SKIP a AP-01..AP-05
/// no debe reiniciar la memoria del cultivo.
///
/// cropId canónico OFICIAL: `crop_apple_tree` (alineado con los documentos del
/// estándar BIO-G de árboles perennes). El id legacy `apple_tree` (usado en una
/// integración previa y en datos ya persistidos) sigue resolviendo a Manzano
/// como ALIAS vía [CropCatalog.canonicalCropKey] / [CropCatalog.cropById]; no
/// se duplica el cultivo ni se rompen datos existentes.
const String kCropAppleTree = 'crop_apple_tree';

/// Id legacy del manzano. Conservado solo como alias de compatibilidad para
/// datos persistidos y comparaciones por string previas a `crop_apple_tree`.
const String kCropAppleTreeLegacy = 'apple_tree';

const String kApSkip = 'ap_skip';
const String kAp01Golden = 'ap_01_golden';
const String kAp02Red = 'ap_02_red';
const String kAp03CriollaRayada = 'ap_03_criolla_rayada';
const String kAp04Gala = 'ap_04_gala';
const String kAp05LowChill = 'ap_05_low_chill';

const List<CropProfileEntry> appleTreeProfileEntries = [
  CropProfileEntry(
    id: kApSkip,
    label: 'AP-SKIP - No sé / Manzano general',
    cropId: kCropAppleTree,
    subtitle:
        'Perfil general y migrable del manzano: puedes precisar la variedad '
        'después sin perder historial. No es descanso del suelo.',
    aliases: [
      'AP-SKIP',
      'AP_SKIP',
      'APSKIP',
      'Manzano',
      'Manzano general',
      'No sé',
      'No se',
      'Apple',
      'Apple tree',
      // Legacy onboarding: 'apple_generic'/'apple_verde' (manzana verde sin
      // perfil claro) se normalizan al perfil general, no a uno inventado.
      'apple_generic',
      'apple_verde',
    ],
  ),
  CropProfileEntry(
    id: kAp01Golden,
    label: 'AP-01 - Golden',
    cropId: kCropAppleTree,
    subtitle: 'Manzana Golden / amarilla',
    aliases: [
      'AP-01',
      'AP01',
      'Golden',
      'Golden Delicious',
      'Golden Reinders',
      'Smoothee Golden',
      'manzana amarilla',
      'amarilla',
    ],
  ),
  CropProfileEntry(
    id: kAp02Red,
    label: 'AP-02 - Red',
    cropId: kCropAppleTree,
    subtitle: 'Manzana roja / Red Delicious',
    // 'apple_rojo' es el id legacy del onboarding viejo para manzana roja.
    aliases: [
      'AP-02',
      'AP02',
      'Red',
      'Red Delicious',
      'Top Red',
      'Starking',
      'Starkrimson',
      'Red Chief',
      'Roja',
      'manzana roja',
      'apple_rojo',
    ],
  ),
  CropProfileEntry(
    id: kAp03CriollaRayada,
    label: 'AP-03 - Criolla / Rayada',
    cropId: kCropAppleTree,
    subtitle: 'Manzana criolla o rayada (regional)',
    aliases: [
      'AP-03',
      'AP03',
      'Criolla',
      'Rayada',
      'Criolla Rayada',
      'Regional',
      'Manzano local',
    ],
  ),
  CropProfileEntry(
    id: kAp04Gala,
    label: 'AP-04 - Gala',
    cropId: kCropAppleTree,
    subtitle: 'Manzana Gala',
    aliases: ['AP-04', 'AP04', 'Gala', 'Royal Gala', 'Gala sport'],
  ),
  CropProfileEntry(
    id: kAp05LowChill,
    label: 'AP-05 - Bajo requerimiento de frío',
    cropId: kCropAppleTree,
    subtitle: 'Variedades de bajo requerimiento de horas frío (low-chill)',
    aliases: [
      'AP-05',
      'AP05',
      'Bajo frío',
      'Bajo requerimiento de frío',
      'Low chill',
      'Anna',
      // Dorsett Golden / Golden Dorsett contienen "Golden" pero DEBEN pesar
      // bajo frío, no Golden: por eso viven en AP-05. La resolución por alias es
      // por igualdad exacta, así que nunca caen en AP-01.
      'Dorsett',
      'Dorsett Golden',
      'Golden Dorsett',
      'Ein Shemer',
      'Tropic Sweet',
      'Tropical',
      'Manzano tropical',
    ],
  ),
];
