import 'package:bio_g/core/crops/catalog/crop_catalog_models.dart';
import 'package:bio_g/widgets/seeds/chili_profiles.dart';

const String kCropChili = 'chili';
const String kChiliDefaultCalendarId = 'chili_default';

const List<CropProfileEntry> chiliProfileEntries = [
  CropProfileEntry(
    id: kChGen,
    label: 'CH-GEN - Chile generico',
    cropId: kCropChili,
    subtitle:
        'Perfil de chile conservador y migrable: puedes precisar el tipo '
        'después sin perder tu historial',
    aliases: ['CH-GEN', 'CHGEN', 'Generico', 'Generic', 'No se', 'Otro chile'],
  ),
  CropProfileEntry(
    id: kCh01,
    label: 'CH-01 - Jalapeno',
    cropId: kCropChili,
    subtitle:
        'Chile jalapeño de ciclo intermedio, para venta en fresco, encurtido o '
        'secado como chipotle',
    aliases: ['CH-01', 'CH01', 'Jalapeno', 'Chipotle'],
  ),
  CropProfileEntry(
    id: kCh02,
    label: 'CH-02 - Serrano',
    cropId: kCropChili,
    subtitle:
        'Chile serrano de ciclo intermedio, con mucha carga de fruto y corte '
        'continuo para salsa verde',
    aliases: ['CH-02', 'CH02', 'Serrano'],
  ),
  CropProfileEntry(
    id: kCh03,
    label: 'CH-03 - Poblano / Ancho',
    cropId: kCropChili,
    subtitle:
        'Chile grande de ciclo intermedio largo para relleno, en fresco es '
        'poblano y ya seco es ancho',
    aliases: ['CH-03', 'CH03', 'Poblano', 'Ancho', 'Mulato'],
  ),
  CropProfileEntry(
    id: kCh04,
    label: 'CH-04 - Chilaca / Pasilla',
    cropId: kCropChili,
    subtitle:
        'Chile de fruto largo y oscuro, chilaca en fresco y pasilla cuando se '
        'seca, para mole y salsa',
    aliases: ['CH-04', 'CH04', 'Chilaca', 'Pasilla'],
  ),
  CropProfileEntry(
    id: kCh05,
    label: 'CH-05 - Mirasol / Guajillo',
    cropId: kCropChili,
    subtitle:
        'Chile mirasol de ciclo intermedio largo que se vende sobre todo seco, '
        'ya como guajillo',
    aliases: ['CH-05', 'CH05', 'Mirasol', 'Guajillo'],
  ),
  CropProfileEntry(
    id: kCh06,
    label: 'CH-06 - De arbol / Puya',
    cropId: kCropChili,
    subtitle:
        'Chile de fruto chico y delgado, se siembra bien tupido y se vende '
        'seco para salsa picante',
    aliases: [
      'CH-06',
      'CH06',
      'De arbol',
      'Arbol',
      'Puya',
      'De arbol fresco',
      'Chile de arbol fresco',
      'Puya seco',
    ],
  ),
  CropProfileEntry(
    id: kCh07,
    label: 'CH-07 - Habanero',
    cropId: kCropChili,
    subtitle:
        'Chile habanero, especie aparte que pide más calor y es más delicada '
        'de llevar en campo',
    aliases: ['CH-07', 'CH07', 'Habanero', 'Capsicum chinense'],
  ),
  CropProfileEntry(
    id: kCh08,
    label: 'CH-08 - Pimiento morron / Chile gordo',
    cropId: kCropChili,
    subtitle:
        'Pimiento morrón de fruto grande, carnoso y sin picor, también '
        'conocido como chile gordo',
    aliases: ['CH-08', 'CH08', 'Pimiento', 'Morron', 'Chile gordo'],
  ),
];

const List<CropVarietyEntry> chiliVarieties = [
  CropVarietyEntry(
    id: 'chili_jalapeno',
    label: 'Jalapeno',
    cropId: kCropChili,
    subtitle:
        'Chile verde grueso de punta redondeada, se come fresco, en escabeche '
        'o seco como chipotle',
    defaultProfileId: kCh01,
    aliases: ['Jalapeno', 'Chipotle', 'CH-01', 'CH01'],
  ),
  CropVarietyEntry(
    id: 'chili_serrano',
    label: 'Serrano',
    cropId: kCropChili,
    subtitle:
        'Chile verde chico y delgado, de corte continuo, muy usado en salsa '
        'verde y pico de gallo',
    defaultProfileId: kCh02,
    aliases: ['Serrano', 'CH-02', 'CH02'],
  ),
  CropVarietyEntry(
    id: 'chili_poblano_ancho',
    label: 'Poblano / Ancho',
    cropId: kCropChili,
    subtitle:
        'Chile grande de pared gruesa para relleno en fresco, ya seco se '
        'conoce como ancho o mulato',
    defaultProfileId: kCh03,
    aliases: ['Poblano', 'Ancho', 'Mulato', 'CH-03', 'CH03'],
  ),
  CropVarietyEntry(
    id: 'chili_chilaca_pasilla',
    label: 'Chilaca / Pasilla',
    cropId: kCropChili,
    subtitle:
        'Chile largo, delgado y oscuro, chilaca en fresco y pasilla ya seco, '
        'base de moles y salsas',
    defaultProfileId: kCh04,
    aliases: ['Chilaca', 'Pasilla', 'CH-04', 'CH04'],
  ),
  CropVarietyEntry(
    id: 'chili_guajillo_mirasol',
    label: 'Guajillo / Mirasol',
    cropId: kCropChili,
    subtitle:
        'Chile mirasol que se cosecha para secar y venderse como guajillo en '
        'adobos, salsas y moles',
    defaultProfileId: kCh05,
    aliases: ['Guajillo', 'Mirasol', 'CH-05', 'CH05'],
  ),
  CropVarietyEntry(
    id: 'chili_arbol_puya',
    label: 'De arbol / Puya',
    cropId: kCropChili,
    subtitle:
        'Chile chico, delgado y picoso, se siembra tupido y se vende seco como '
        'de árbol o puya',
    defaultProfileId: kCh06,
    aliases: [
      'De arbol',
      'Arbol',
      'Puya',
      'De arbol fresco',
      'Chile de arbol fresco',
      'Puya seco',
      'CH-06',
      'CH06',
    ],
  ),
  CropVarietyEntry(
    id: 'chili_habanero',
    label: 'Habanero',
    cropId: kCropChili,
    subtitle:
        'Chile de fruto chico y arrugado, muy picoso, especie aparte que pide '
        'más calor y cuidado',
    defaultProfileId: kCh07,
    aliases: ['Habanero', 'Capsicum chinense', 'CH-07', 'CH07'],
  ),
  CropVarietyEntry(
    id: 'chili_bell_pepper',
    label: 'Pimiento morron / Chile gordo',
    cropId: kCropChili,
    subtitle:
        'Pimiento morrón de fruto grande, cuadrado y carnoso, sin picor, le '
        'dicen también chile gordo',
    defaultProfileId: kCh08,
    aliases: [
      'Pimiento',
      'Pimiento morron',
      'Morron',
      'Chile gordo',
      'Bell pepper',
      'CH-08',
      'CH08',
    ],
  ),
  CropVarietyEntry(
    id: 'chili_generic',
    label: 'No se / Otro chile',
    cropId: kCropChili,
    subtitle:
        'Perfil general y migrable de chile: puedes precisar el tipo después '
        'sin perder tu historial',
    defaultProfileId: kChGen,
    aliases: [
      'Generico',
      'Chile generico',
      'Otro chile',
      'No se',
      'CH-GEN',
      'CHGEN',
    ],
    isGeneric: true,
  ),
];
