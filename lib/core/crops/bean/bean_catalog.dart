import 'package:bio_g/core/crops/catalog/crop_catalog_models.dart';
import 'package:bio_g/widgets/seeds/bean_profiles.dart';

const String kCropBean = 'bean';
const String kBeanDefaultCalendarId = 'bean_default';

const List<CropProfileEntry> beanProfileEntries = [
  CropProfileEntry(
    id: kFj01,
    label: 'FJ-01 · Precoz',
    cropId: kCropBean,
    subtitle:
        'Perfil de frijol negro de ciclo corto, el primero que se levanta de '
        'la parcela',
    aliases: ['FJ-01', 'FJ01', 'Precoz'],
  ),
  CropProfileEntry(
    id: kFj02,
    label: 'FJ-02 · Intermedio',
    cropId: kCropBean,
    subtitle:
        'Perfil de ciclo intermedio para frijol negro, bayo, azufrado o blanco '
        'de grano claro',
    aliases: ['FJ-02', 'FJ02', 'Intermedio'],
  ),
  CropProfileEntry(
    id: kFj03,
    label: 'FJ-03 · Intermedio largo',
    cropId: kCropBean,
    subtitle:
        'Perfil de ciclo intermedio largo para frijol pinto moteado y Flor de '
        'Mayo o Flor de Junio',
    aliases: ['FJ-03', 'FJ03', 'Intermedio largo'],
  ),
  CropProfileEntry(
    id: kFj04,
    label: 'FJ-04 · Temporal largo',
    cropId: kCropBean,
    subtitle:
        'Perfil de temporal largo para frijol de grano amarillo, de los que '
        'más tardan en madurar',
    aliases: ['FJ-04', 'FJ04', 'Temporal largo'],
  ),
  CropProfileEntry(
    id: kFjGen,
    label: 'FJ-GEN · Intermedio conservador',
    cropId: kCropBean,
    subtitle:
        'Perfil general y migrable de frijol: puedes precisar la variedad '
        'después sin perder tu historial',
    aliases: ['FJ-GEN', 'FJGEN', 'Genérico', 'Generico'],
  ),
];

const List<CropVarietyEntry> beanVarieties = [
  CropVarietyEntry(
    id: 'bean_negro_temprano',
    label: 'Frijol negro temprano',
    cropId: kCropBean,
    subtitle:
        'Frijol de grano negro y ciclo corto, para caldo o refrito (Verdín, '
        'Frailescano, Sangre Maya)',
    defaultProfileId: kFj01,
    aliases: [
      'Negro temprano',
      'Verdín',
      'Verdin',
      'Frailescano',
      'Sangre Maya',
      'FJ-01',
      'FJ01',
    ],
  ),
  CropVarietyEntry(
    id: 'bean_negro',
    label: 'Frijol negro',
    cropId: kCropBean,
    subtitle:
        'Frijol de grano negro chico que suelta caldo oscuro y espeso, de '
        'ciclo intermedio (Jamapa)',
    defaultProfileId: kFj02,
    aliases: [
      'Negro',
      'Negro Jamapa',
      'Negro INIFAP',
      'Negro Comapa',
      'Negro Veracruz',
      'Negro San Luis',
      'Negro Tacaná',
      'Negro Tacana',
      'Negro Huasteco',
      'FJ-02',
      'FJ02',
    ],
  ),
  CropVarietyEntry(
    id: 'bean_pinto',
    label: 'Frijol pinto',
    cropId: kCropBean,
    subtitle:
        'Frijol de grano café claro con motas, de ciclo intermedio largo y '
        'zona de temporal (Pinto Saltillo)',
    defaultProfileId: kFj03,
    aliases: [
      'Pinto',
      'Pinto Saltillo',
      'Pinto Durango',
      'Pinto Centenario',
      'Pinto Mestizo',
      'Pinto Libertad',
      'FJ-03',
      'FJ03',
    ],
  ),
  CropVarietyEntry(
    id: 'bean_flor_mayo_junio',
    label: 'Frijol Flor de Mayo / Flor de Junio',
    cropId: kCropBean,
    subtitle:
        'Frijol de grano rosado con veteado morado, muy pedido en el centro '
        'del país (Flor de Mayo)',
    defaultProfileId: kFj03,
    aliases: [
      'Flor de Mayo',
      'Flor de Junio',
      'Flor de Mayo / Flor de Junio',
      'Flor de Mayo Dolores',
      'Flor de Junio León',
      'Flor de Junio Leon',
      'Junio León',
      'Junio Leon',
      'Dalia',
      'FJ-03',
      'FJ03',
    ],
  ),
  CropVarietyEntry(
    id: 'bean_bayo_azufrado_blanco',
    label: 'Frijol bayo / azufrado / blanco',
    cropId: kCropBean,
    subtitle:
        'Frijol de grano claro, café beige, amarillo pálido o blanco, de ciclo '
        'intermedio (bayo, azufrado)',
    defaultProfileId: kFj02,
    aliases: [
      'Bayo',
      'Azufrado',
      'Blanco',
      'Bayo Azteca',
      'Azufrado Higuera',
      'Azufrasin',
      'Aluyori',
      'FJ-02',
      'FJ02',
    ],
  ),
  CropVarietyEntry(
    id: 'bean_peruano',
    label: 'Frijol peruano',
    cropId: kCropBean,
    subtitle:
        'Frijol de grano amarillo claro, gordo y de cáscara delgada, de '
        'temporal largo (peruano bola)',
    defaultProfileId: kFj04,
    aliases: [
      'Peruano',
      'Frijol peruano',
      'Peruano Bola',
    ],
  ),
  CropVarietyEntry(
    id: 'bean_canario',
    label: 'Frijol canario',
    cropId: kCropBean,
    subtitle:
        'Frijol de grano amarillo ovalado y parejo, de temporal largo, muy '
        'buscado en el mercado (Mayocoba)',
    defaultProfileId: kFj04,
    aliases: [
      'Canario',
      'Frijol canario',
      'Mayocoba',
      'Frijol Mayocoba',
    ],
  ),
  CropVarietyEntry(
    id: 'bean_generic',
    label: 'Frijol genérico',
    cropId: kCropBean,
    subtitle:
        'Perfil general y migrable de frijol: elige tu variedad más adelante '
        'sin perder tu historial',
    defaultProfileId: kFjGen,
    aliases: [
      'Genérico',
      'Generico',
      'Frijol genérico',
      'Frijol generico',
      'FJ-GEN',
      'FJGEN',
    ],
    isGeneric: true,
  ),
];
