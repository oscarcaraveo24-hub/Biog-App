import 'package:bio_g/core/crops/catalog/crop_catalog_models.dart';
import 'package:bio_g/widgets/seeds/lettuce_profiles.dart';

const String kCropLettuce = 'lettuce';
const String kLettuceDefaultCalendarId = 'lettuce_default';

/// Perfiles UX visibles en el wizard de configuración de semilla.
///
/// El usuario nunca debe ver "SKIP": LE-GEN se etiqueta como "Lechuga
/// genérica / no sé todavía" y queda como entrada por defecto si no
/// conoce el tipo. La memoria del cultivo no se pierde al migrar.
const List<CropProfileEntry> lettuceProfileEntries = [
  CropProfileEntry(
    id: kLeGen,
    label: 'LE-GEN - Lechuga genérica / no sé todavía',
    cropId: kCropLettuce,
    subtitle:
        'Perfil general de lechuga, conservador y migrable — cambias el tipo '
        'después sin perder historial',
    aliases: [
      'LE-GEN',
      'LEGEN',
      'LE_GEN',
      'Lechuga',
      'Lechuga generica',
      'Lechuga genérica',
      'Otra lechuga',
      'Otra variedad',
      'No se',
      'No sé',
      'No sé todavía',
      'Lettuce',
    ],
  ),
  CropProfileEntry(
    id: kLe01,
    label: 'LE-01 - Lechuga romana / cos',
    cropId: kCropLettuce,
    subtitle:
        'Cabeza alargada de hoja firme y nervadura marcada, se cosecha en 1 '
        'corte (romana, cos)',
    aliases: [
      'LE-01',
      'LE01',
      'Romana',
      'Cos',
      'Oreja larga',
      'Romaine',
      'Valmaine',
      'Parris Island',
      'Little Caesar',
    ],
  ),
  CropProfileEntry(
    id: kLe02,
    label: 'LE-02 - Mini romana / corazones / Little Gem',
    cropId: kCropLettuce,
    subtitle:
        'Cabeza chica y compacta que se vende como corazones, se cosecha en 1 '
        'corte (Little Gem)',
    aliases: [
      'LE-02',
      'LE02',
      'Mini romana',
      'Corazones',
      'Little Gem',
      'Gem',
      'Mini cos',
    ],
  ),
  CropProfileEntry(
    id: kLe03,
    label: 'LE-03 - Lechuga bola / iceberg',
    cropId: kCropLettuce,
    subtitle:
        'Cabeza redonda, apretada y de hoja crujiente, se cosecha entera en 1 '
        'corte (iceberg, bola)',
    aliases: [
      'LE-03',
      'LE03',
      'Bola',
      'Iceberg',
      'Crisphead',
      'Great Lakes',
      'Salinas',
      'Sure Shot',
    ],
  ),
  CropProfileEntry(
    id: kLe04,
    label: 'LE-04 - Lechuga mantequilla / butterhead',
    cropId: kCropLettuce,
    subtitle:
        'Cabeza suave y poco apretada, de hojas tiernas al tacto, se cosecha '
        'en 1 corte (Bibb, Boston)',
    aliases: [
      'LE-04',
      'LE04',
      'Mantequilla',
      'Butterhead',
      'Bibb',
      'Boston',
      'Fairly',
      'Cuervo',
    ],
  ),
  CropProfileEntry(
    id: kLe05,
    label: 'LE-05 - Lechuga hoja suelta / orejona / baby leaf',
    cropId: kCropLettuce,
    subtitle:
        'Roseta abierta de hojas sueltas que no cabecea, va a 1 corte o '
        'multicorte (orejona, baby leaf)',
    aliases: [
      'LE-05',
      'LE05',
      'Hoja suelta',
      'Orejona',
      'Looseleaf',
      'Leaf lettuce',
      'Baby leaf',
      'Green leaf',
      'Red leaf',
      'Lolla',
      'Oak leaf',
    ],
  ),
];

/// Variedades visibles en el wizard (los "tipos comerciales" de lechuga).
///
/// Cada variedad apunta a un perfil canónico LE-XX como `defaultProfileId`
/// y arrastra alias amplios para que la búsqueda reconozca nombres
/// regionales. Siempre se mantiene la entrada genérica migrable.
const List<CropVarietyEntry> lettuceVarieties = [
  CropVarietyEntry(
    id: 'lettuce_generic',
    label: 'No sé / Otra lechuga',
    cropId: kCropLettuce,
    subtitle:
        'Perfil general de lechuga, seguro y migrable — lo ajustas después sin '
        'reiniciar tu historial',
    defaultProfileId: kLeGen,
    aliases: [
      'Lechuga',
      'Lechuga generica',
      'Lechuga genérica',
      'Otra lechuga',
      'Otra variedad',
      'No se',
      'No sé',
      'No sé todavía',
      'Lettuce',
      'LE-GEN',
      'LEGEN',
    ],
    isGeneric: true,
  ),
  CropVarietyEntry(
    id: 'lettuce_romaine',
    label: 'Lechuga romana / cos',
    cropId: kCropLettuce,
    subtitle:
        'Tipo de cabeza alargada, con hoja firme y nervadura marcada al centro '
        '(romana, cos)',
    defaultProfileId: kLe01,
    aliases: [
      'Romana',
      'Lechuga romana',
      'Cos',
      'Oreja larga',
      'Romaine',
      'Valmaine',
      'Parris Island',
      'Little Caesar',
      'Otra variedad romana',
      'LE-01',
      'LE01',
    ],
  ),
  CropVarietyEntry(
    id: 'lettuce_mini_romaine',
    label: 'Mini romana / corazones / Little Gem',
    cropId: kCropLettuce,
    subtitle:
        'Tipo de cabeza chica y compacta que se corta y se vende como '
        'corazones (Little Gem, mini cos)',
    defaultProfileId: kLe02,
    aliases: [
      'Mini romana',
      'Corazones',
      'Corazón',
      'Little Gem',
      'Gem',
      'Mini cos',
      'Otra variedad mini romana',
      'LE-02',
      'LE02',
    ],
  ),
  CropVarietyEntry(
    id: 'lettuce_iceberg',
    label: 'Lechuga bola / iceberg',
    cropId: kCropLettuce,
    subtitle:
        'Tipo de cabeza redonda y apretada, de hoja crujiente que se corta '
        'entera (iceberg, crisphead)',
    defaultProfileId: kLe03,
    aliases: [
      'Bola',
      'Iceberg',
      'Lechuga bola',
      'Crisphead',
      'Great Lakes',
      'Salinas',
      'Sure Shot',
      'Otra variedad iceberg',
      'LE-03',
      'LE03',
    ],
  ),
  CropVarietyEntry(
    id: 'lettuce_butterhead',
    label: 'Lechuga mantequilla / butterhead',
    cropId: kCropLettuce,
    subtitle:
        'Tipo de cabeza suave y poco apretada, de hojas tiernas y delicadas al '
        'manejo (Bibb, Boston)',
    defaultProfileId: kLe04,
    aliases: [
      'Mantequilla',
      'Lechuga mantequilla',
      'Butterhead',
      'Bibb',
      'Boston',
      'Fairly',
      'Cuervo',
      'Otra variedad mantequilla',
      'LE-04',
      'LE04',
    ],
  ),
  CropVarietyEntry(
    id: 'lettuce_looseleaf',
    label: 'Lechuga hoja suelta / orejona / baby leaf',
    cropId: kCropLettuce,
    subtitle:
        'Tipo de roseta abierta que no forma cabeza, se corta por hoja o '
        'completa (orejona, baby leaf)',
    defaultProfileId: kLe05,
    aliases: [
      'Hoja suelta',
      'Orejona',
      'Looseleaf',
      'Leaf lettuce',
      'Baby leaf',
      'Green leaf',
      'Red leaf',
      'Lolla',
      'Oak leaf',
      'Otra variedad hoja suelta',
      'LE-05',
      'LE05',
    ],
  ),
];
