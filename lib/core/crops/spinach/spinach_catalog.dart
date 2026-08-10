import 'package:bio_g/core/crops/catalog/crop_catalog_models.dart';
import 'package:bio_g/widgets/seeds/spinach_profiles.dart';

const String kCropSpinach = 'spinach';
const String kSpinachDefaultCalendarId = 'spinach_default';

const List<CropProfileEntry> spinachProfileEntries = [
  CropProfileEntry(
    id: kSpGen,
    label: 'SP-GEN - Espinaca generica / no se todavia',
    cropId: kCropSpinach,
    subtitle:
        'Perfil general de espinaca, conservador y migrable — cambias el tipo '
        'después sin perder historial',
    aliases: [
      'SP-GEN',
      'SPGEN',
      'SP_GEN',
      'Espinaca',
      'Espinaca generica',
      'Otra espinaca',
      'Otra variedad',
      'No se',
      'No se todavia',
      'Spinach',
    ],
  ),
  CropProfileEntry(
    id: kSp01,
    label: 'SP-01 - Saboya / semi-saboya verano-calor',
    cropId: kCropSpinach,
    subtitle:
        'Hoja rizada o semirrizada con tolerancia relativa al calor, para '
        'siembras de verano',
    aliases: [
      'SP-01',
      'SP01',
      'Saboya verano',
      'Semi-saboya verano',
      'Verano calor',
      'Savoy summer',
      'Semi savoy summer',
    ],
  ),
  CropProfileEntry(
    id: kSp02,
    label: 'SP-02 - Saboya / semi-saboya invierno',
    cropId: kCropSpinach,
    subtitle:
        'Hoja rizada o semirrizada para clima fresco y días cortos, propia de '
        'siembras de invierno',
    aliases: [
      'SP-02',
      'SP02',
      'Saboya invierno',
      'Semi-saboya invierno',
      'Dias cortos',
      'Savoy winter',
      'Winter savoy',
    ],
  ),
  CropProfileEntry(
    id: kSp03,
    label: 'SP-03 - Lisa / baby leaf / premium',
    cropId: kCropSpinach,
    subtitle:
        'Hoja lisa y tierna que se corta chica para baby leaf y bolsa de '
        'mercado premium',
    aliases: [
      'SP-03',
      'SP03',
      'Lisa',
      'Baby leaf',
      'Baby spinach',
      'Premium',
      'Smooth baby',
    ],
  ),
  CropProfileEntry(
    id: kSp04,
    label: 'SP-04 - Oriental / manojo erecta',
    cropId: kCropSpinach,
    subtitle:
        'Hoja erecta y de tallo largo, fácil de amarrar para venta en manojo y '
        'corte en fresco',
    aliases: [
      'SP-04',
      'SP04',
      'Oriental',
      'Manojo',
      'Bunching',
      'Oriental bunch',
      'Erecta',
    ],
  ),
  CropProfileEntry(
    id: kSp05,
    label: 'SP-05 - Proceso / industria',
    cropId: kCropSpinach,
    subtitle:
        'Planta pareja y de buena biomasa, cortada para proceso e industria '
        'más que para fresco',
    aliases: [
      'SP-05',
      'SP05',
      'Proceso',
      'Industria',
      'Industrial',
      'Processing',
    ],
  ),
];

const List<CropVarietyEntry> spinachVarieties = [
  CropVarietyEntry(
    id: 'spinach_generic',
    label: 'No se / Otra espinaca',
    cropId: kCropSpinach,
    subtitle:
        'Perfil general de espinaca, seguro y migrable — lo ajustas después '
        'sin reiniciar tu historial',
    defaultProfileId: kSpGen,
    aliases: [
      'Espinaca',
      'Espinaca generica',
      'Otra espinaca',
      'Otra variedad',
      'No se',
      'No se todavia',
      'Spinach',
      'SP-GEN',
      'SPGEN',
    ],
    isGeneric: true,
  ),
  CropVarietyEntry(
    id: 'spinach_savoy_summer',
    label: 'Saboya / semi-saboya verano-calor',
    cropId: kCropSpinach,
    subtitle:
        'Tipo de hoja rizada o semirrizada, pensada para siembras en clima con '
        'más calor',
    defaultProfileId: kSp01,
    aliases: [
      'Saboya verano',
      'Semi-saboya verano',
      'Verano calor',
      'Savoy summer',
      'Semi savoy summer',
      'SP-01',
      'SP01',
    ],
  ),
  CropVarietyEntry(
    id: 'spinach_savoy_winter',
    label: 'Saboya / semi-saboya invierno',
    cropId: kCropSpinach,
    subtitle:
        'Tipo de hoja rizada o semirrizada para clima fresco y días cortos de '
        'invierno',
    defaultProfileId: kSp02,
    aliases: [
      'Saboya invierno',
      'Semi-saboya invierno',
      'Invierno',
      'Dias cortos',
      'Savoy winter',
      'SP-02',
      'SP02',
    ],
  ),
  CropVarietyEntry(
    id: 'spinach_smooth_baby',
    label: 'Lisa / baby leaf / premium',
    cropId: kCropSpinach,
    subtitle:
        'Tipo de hoja lisa, tierna y muy vistosa, para corte chico de baby '
        'leaf y bolsa premium',
    defaultProfileId: kSp03,
    aliases: [
      'Lisa',
      'Espinaca lisa',
      'Baby leaf',
      'Baby spinach',
      'Premium',
      'Smooth baby',
      'SP-03',
      'SP03',
    ],
  ),
  CropVarietyEntry(
    id: 'spinach_oriental_bunching',
    label: 'Oriental / manojo erecta',
    cropId: kCropSpinach,
    subtitle:
        'Tipo de hoja erecta y tallo largo, fácil de amarrar para venderse en '
        'manojo',
    defaultProfileId: kSp04,
    aliases: [
      'Oriental',
      'Espinaca oriental',
      'Manojo',
      'Bunching',
      'Oriental bunch',
      'Erecta',
      'SP-04',
      'SP04',
    ],
  ),
  CropVarietyEntry(
    id: 'spinach_processing',
    label: 'Proceso / industria',
    cropId: kCropSpinach,
    subtitle:
        'Tipo de planta pareja y de buena biomasa, cortada para proceso e '
        'industria',
    defaultProfileId: kSp05,
    aliases: [
      'Proceso',
      'Industria',
      'Industrial',
      'Processing',
      'Process spinach',
      'SP-05',
      'SP05',
    ],
  ),
];
