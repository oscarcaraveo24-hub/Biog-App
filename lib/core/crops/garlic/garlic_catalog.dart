import 'package:bio_g/core/crops/catalog/crop_catalog_models.dart';
import 'package:bio_g/widgets/seeds/garlic_profiles.dart';

const String kCropGarlic = 'garlic';
const String kGarlicDefaultCalendarId = 'garlic_default';

const List<CropProfileEntry> garlicProfileEntries = [
  CropProfileEntry(
    id: kAgGen,
    label: 'AG-GEN - No se / Otro ajo',
    cropId: kCropGarlic,
    subtitle:
        'Perfil general de ajo, conservador y migrable — cambias el tipo '
        'después sin perder tu historial',
    aliases: [
      'AG-GEN',
      'AGGEN',
      'AG_GEN',
      'Ajo',
      'Ajo generico',
      'Otro ajo',
      'Otra variedad',
      'No se',
      'Garlic',
    ],
  ),
  CropProfileEntry(
    id: kAg01,
    label: 'AG-01 - Ajo blanco / Perla',
    cropId: kCropGarlic,
    subtitle:
        'Ajo de túnica blanca y bulbo parejo, se cura para calibre comercial y '
        'venta en fresco (perla)',
    aliases: [
      'AG-01',
      'AG01',
      'Ajo blanco',
      'Perla',
      'Orion',
      'San Marqueno',
      'Diamante',
      'Blanco de Egipto',
    ],
  ),
  CropProfileEntry(
    id: kAg02,
    label: 'AG-02 - Ajo jaspeado / Calera / rayado',
    cropId: kCropGarlic,
    subtitle:
        'Ajo de túnica rayada con vetas moradas, de alto potencial donde hay '
        'frío y buena sanidad (Calera)',
    aliases: [
      'AG-02',
      'AG02',
      'Ajo jaspeado',
      'Calera',
      'Rayado',
      'CEZAC 06',
      'Jaspeado Calera',
      'Barretero',
      'Inifap 94',
      'Tacatzcuaro',
      'Tinguindin',
    ],
  ),
  CropProfileEntry(
    id: kAg03,
    label: 'AG-03 - Ajo morado',
    cropId: kCropGarlic,
    subtitle:
        'Ajo de túnica morada, donde el color, el frío y el buen curado pesan '
        'fuerte a la hora de vender',
    aliases: ['AG-03', 'AG03', 'Ajo morado', 'Morado'],
  ),
  CropProfileEntry(
    id: kAg04,
    label: 'AG-04 - Ajo criollo / regional',
    cropId: kCropGarlic,
    subtitle:
        'Ajo criollo adaptado a tu zona, cuida la calidad del diente-semilla y '
        'la sanidad local',
    aliases: ['AG-04', 'AG04', 'Ajo criollo', 'Criollo Regional', 'Regional'],
  ),
  CropProfileEntry(
    id: kAg05,
    label: 'AG-05 - Ajo chino / coreano',
    cropId: kCropGarlic,
    subtitle:
        'Ajo tipo chino o coreano de bulbo blanco y grande, revisa su '
        'trazabilidad y su adaptación a tu zona',
    aliases: [
      'AG-05',
      'AG05',
      'Ajo chino',
      'Ajo coreano',
      'Chino Calera',
      'Chino CEDEL',
      'Coreano',
    ],
  ),
];

const List<CropVarietyEntry> garlicVarieties = [
  CropVarietyEntry(
    id: 'garlic_generic',
    label: 'No se / Otro ajo',
    cropId: kCropGarlic,
    subtitle:
        'Perfil general de ajo, seguro y migrable — lo ajustas después sin '
        'reiniciar tu historial',
    defaultProfileId: kAgGen,
    aliases: [
      'Ajo',
      'Ajo generico',
      'Otro ajo',
      'Otra variedad',
      'No se',
      'Garlic',
      'AG-GEN',
      'AGGEN',
    ],
    isGeneric: true,
  ),
  CropVarietyEntry(
    id: 'garlic_white_pearl',
    label: 'Blanco / Perla',
    cropId: kCropGarlic,
    subtitle:
        'Tipo de túnica blanca o perla, bulbo parejo y ya curado para venta '
        'comercial en fresco',
    defaultProfileId: kAg01,
    aliases: [
      'Ajo blanco',
      'Perla',
      'Orion',
      'San Marqueno',
      'Diamante',
      'Blanco de Egipto',
      'garlic_orion',
      'garlic_san_marqueno',
      'AG-01',
      'AG01',
    ],
  ),
  CropVarietyEntry(
    id: 'garlic_jaspeado_calera',
    label: 'Jaspeado / Calera / rayado',
    cropId: kCropGarlic,
    subtitle:
        'Tipo de túnica rayada con vetas moradas y dientes grandes, pocos por '
        'bulbo (Calera, rayado)',
    defaultProfileId: kAg02,
    aliases: [
      'Ajo jaspeado',
      'Calera',
      'Rayado',
      'CEZAC 06',
      'Jaspeado Calera',
      'Barretero',
      'Inifap 94',
      'Tacatzcuaro',
      'Tinguindin',
      'garlic_cezac_06',
      'garlic_barretero',
      'AG-02',
      'AG02',
    ],
  ),
  CropVarietyEntry(
    id: 'garlic_purple',
    label: 'Morado',
    cropId: kCropGarlic,
    subtitle:
        'Tipo de túnica morada, se vende por su color intenso en mercados '
        'regionales y locales',
    defaultProfileId: kAg03,
    aliases: ['Ajo morado', 'Morado', 'AG-03', 'AG03'],
  ),
  CropVarietyEntry(
    id: 'garlic_criollo_regional',
    label: 'Criollo / Regional',
    cropId: kCropGarlic,
    subtitle:
        'Tipo criollo o regional, de semilla propia del productor y bulbo '
        'adaptado a tu zona',
    defaultProfileId: kAg04,
    aliases: ['Ajo criollo', 'Criollo Regional', 'Regional', 'AG-04', 'AG04'],
  ),
  CropVarietyEntry(
    id: 'garlic_chinese_korean',
    label: 'Chino / Coreano',
    cropId: kCropGarlic,
    subtitle:
        'Tipo chino o coreano de bulbo blanco y grande, revisa la trazabilidad '
        'de la semilla que compras',
    defaultProfileId: kAg05,
    aliases: [
      'Ajo chino',
      'Ajo coreano',
      'Chino Calera',
      'Chino CEDEL',
      'Coreano',
      'AG-05',
      'AG05',
    ],
  ),
];
