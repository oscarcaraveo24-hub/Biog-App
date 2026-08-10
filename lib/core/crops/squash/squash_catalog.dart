import 'package:bio_g/core/crops/catalog/crop_catalog_models.dart';
import 'package:bio_g/widgets/seeds/squash_profiles.dart';

const String kCropSquash = 'squash';
const String kSquashDefaultCalendarId = 'squash_default';

/// Perfiles UX visibles en el wizard de configuración de semilla.
///
/// El usuario nunca debe ver "SKIP": CA-GEN se etiqueta como
/// "Calabaza genérica" y queda como entrada por defecto si no sabe.
const List<CropProfileEntry> squashProfileEntries = [
  CropProfileEntry(
    id: kCaGen,
    label: 'CA-GEN - Calabaza genérica',
    cropId: kCropSquash,
    subtitle:
        'Perfil conservador y migrable de calabaza: afinas el tipo después sin '
        'perder tu historial',
    aliases: [
      'CA-GEN',
      'CAGEN',
      'CA_GEN',
      'Calabaza',
      'Calabaza generica',
      'Calabaza genérica',
      'Otra calabaza',
      'No se',
      'No sé',
      'Squash',
      'Pumpkin',
      'Zapallo',
      'Ayote',
      'Auyama',
    ],
  ),
  CropProfileEntry(
    id: kCa01,
    label: 'CA-01 - Calabacita italiana / zucchini',
    cropId: kCropSquash,
    subtitle:
        'Calabacita tierna de planta de mata, se corta chica y seguido para '
        'consumo inmediato (zucchini)',
    aliases: [
      'CA-01',
      'CA01',
      'Calabacita',
      'Calabacita italiana',
      'Italiana',
      'Zucchini',
      'Zuccini',
      'Calabacin',
      'Calabacín',
      'Italiana larga',
      'Grey zucchini',
      'Squash italiano',
    ],
  ),
  CropProfileEntry(
    id: kCa02,
    label: 'CA-02 - Calabacita criolla / huicha / milpa',
    cropId: kCropSquash,
    subtitle:
        'Calabacita criolla de guía, sembrada en milpa y de temporal, se come '
        'tierna (huicha)',
    aliases: [
      'CA-02',
      'CA02',
      'Criolla',
      'Calabacita criolla',
      'Calabaza criolla',
      'Huicha',
      'Güicha',
      'Guicha',
      'Milpa',
      'Calabaza de milpa',
      'Calabaza de temporal',
      'Temporal',
    ],
  ),
  CropProfileEntry(
    id: kCa03,
    label: 'CA-03 - Calabacita de bola / redonda',
    cropId: kCropSquash,
    subtitle:
        'Calabacita tierna y redonda de planta de mata, se corta chica para '
        'consumo inmediato (de bola)',
    aliases: [
      'CA-03',
      'CA03',
      'Bola',
      'Redonda',
      'Calabacita de bola',
      'Calabacita redonda',
      'Round zucchini',
      'Eight ball',
    ],
  ),
  CropProfileEntry(
    id: kCa04,
    label: 'CA-04 - Calabaza de Castilla',
    cropId: kCropSquash,
    subtitle:
        'Calabaza de guía de cáscara dura y pulpa dulce, se cosecha madura y '
        'aguanta guardada (de altar)',
    aliases: [
      'CA-04',
      'CA04',
      'Castilla',
      'Calabaza de Castilla',
      'Calabaza para dulce',
      'Calabaza de altar',
      'Calabaza madura',
      'Pumpkin mexicano',
      'Winter squash',
    ],
  ),
  CropProfileEntry(
    id: kCa05,
    label: 'CA-05 - Butternut / buchona / mantequilla',
    cropId: kCropSquash,
    subtitle:
        'Calabaza de cuello largo y cáscara dura, de pulpa anaranjada dulce y '
        'guarda larga (buchona)',
    aliases: [
      'CA-05',
      'CA05',
      'Butternut',
      'Buchona',
      'Mantequilla',
      'Cacahuate',
      'Violin',
      'Violín',
      'Squash mantequilla',
    ],
  ),
  CropProfileEntry(
    id: kCa06,
    label: 'CA-06 - Chilacayote',
    cropId: kCropSquash,
    subtitle:
        'Calabaza de guía muy vigorosa y ciclo largo, de cáscara dura y fruto '
        'maduro para dulce',
    aliases: [
      'CA-06',
      'CA06',
      'Chilacayote',
      'Chilacayota',
      'Alcayota',
    ],
  ),
  CropProfileEntry(
    id: kCa07,
    label: 'CA-07 - Pipián / pipiana / pepita',
    cropId: kCropSquash,
    subtitle:
        'Calabaza sembrada para pepita: se cosecha la semilla seca y no la '
        'pulpa (pipiana, chihua)',
    aliases: [
      'CA-07',
      'CA07',
      'Pipian',
      'Pipián',
      'Pipiana',
      'Pepita',
      'Calabaza pipiana',
      'Calabaza para semilla',
      'Chihua',
      'Cushaw',
      'Arota',
    ],
  ),
];

/// Variedades visibles en el wizard. Cada variedad apunta a un perfil
/// canónico CA-XX como `defaultProfileId` y arrastra alias amplios para
/// que la búsqueda en el wizard reconozca nombres regionales.
const List<CropVarietyEntry> squashVarieties = [
  CropVarietyEntry(
    id: 'squash_generic',
    label: 'No sé / Otra calabaza',
    cropId: kCropSquash,
    subtitle:
        'Perfil seguro y migrable de calabaza, ajustas el tipo después sin '
        'reiniciar tu historial',
    defaultProfileId: kCaGen,
    aliases: [
      'Calabaza',
      'Calabaza generica',
      'Calabaza genérica',
      'Otra calabaza',
      'No se',
      'No sé',
      'Pumpkin',
      'Squash',
      'Zapallo',
      'Ayote',
      'Auyama',
      'CA-GEN',
      'CAGEN',
    ],
    isGeneric: true,
  ),
  CropVarietyEntry(
    id: 'squash_zucchini',
    label: 'Calabacita italiana / zucchini',
    cropId: kCropSquash,
    subtitle:
        'Tipo de mata con fruto tierno de corte continuo, para consumo '
        'inmediato (italiana, zucchini)',
    defaultProfileId: kCa01,
    aliases: [
      'Calabacita italiana',
      'Italiana',
      'Zucchini',
      'Zuccini',
      'Calabacin',
      'Calabacín',
      'Grey zucchini',
      'Italiana larga',
      'Squash italiano',
      'CA-01',
      'CA01',
    ],
  ),
  CropVarietyEntry(
    id: 'squash_criolla',
    label: 'Calabacita criolla / huicha / milpa',
    cropId: kCropSquash,
    subtitle:
        'Tipo de guía para milpa y temporal, de fruto tierno y consumo '
        'inmediato (criolla, huicha)',
    defaultProfileId: kCa02,
    aliases: [
      'Criolla',
      'Calabacita criolla',
      'Calabaza criolla',
      'Huicha',
      'Güicha',
      'Guicha',
      'Milpa',
      'Calabaza de milpa',
      'Calabaza de temporal',
      'CA-02',
      'CA02',
    ],
  ),
  CropVarietyEntry(
    id: 'squash_round',
    label: 'Calabacita de bola / redonda',
    cropId: kCropSquash,
    subtitle:
        'Tipo de mata con fruto tierno y redondo, se corta chico y se come '
        'pronto (bola, redonda)',
    defaultProfileId: kCa03,
    aliases: [
      'Bola',
      'Redonda',
      'Calabacita de bola',
      'Calabacita redonda',
      'Round zucchini',
      'Eight ball',
      'CA-03',
      'CA03',
    ],
  ),
  CropVarietyEntry(
    id: 'squash_castilla',
    label: 'Calabaza de Castilla',
    cropId: kCropSquash,
    subtitle:
        'Tipo de guía con fruto maduro de cáscara dura, dulce y de guarda '
        'larga (calabaza de altar)',
    defaultProfileId: kCa04,
    aliases: [
      'Castilla',
      'Calabaza de Castilla',
      'Calabaza para dulce',
      'Calabaza de altar',
      'Calabaza madura',
      'Pumpkin mexicano',
      'Winter squash',
      'CA-04',
      'CA04',
    ],
  ),
  CropVarietyEntry(
    id: 'squash_butternut',
    label: 'Butternut / buchona / mantequilla',
    cropId: kCropSquash,
    subtitle:
        'Tipo de fruto maduro con cuello largo y cáscara dura, aguanta bien '
        'guardado (mantequilla)',
    defaultProfileId: kCa05,
    aliases: [
      'Butternut',
      'Buchona',
      'Mantequilla',
      'Cacahuate',
      'Violin',
      'Violín',
      'Squash mantequilla',
      'CA-05',
      'CA05',
    ],
  ),
  CropVarietyEntry(
    id: 'squash_chilacayote',
    label: 'Chilacayote',
    cropId: kCropSquash,
    subtitle:
        'Tipo de guía de ciclo muy largo, con fruto maduro de cáscara dura que '
        'se usa para dulce',
    defaultProfileId: kCa06,
    aliases: [
      'Chilacayote',
      'Chilacayota',
      'Alcayota',
      'CA-06',
      'CA06',
    ],
  ),
  CropVarietyEntry(
    id: 'squash_pipian',
    label: 'Pipián / pipiana / pepita',
    cropId: kCropSquash,
    subtitle:
        'Tipo sembrado para semilla seca, se cosecha la pepita y no la pulpa '
        '(pipiana, chihua)',
    defaultProfileId: kCa07,
    aliases: [
      'Pipian',
      'Pipián',
      'Pipiana',
      'Pepita',
      'Calabaza pipiana',
      'Calabaza para semilla',
      'Chihua',
      'Cushaw',
      'Arota',
      'CA-07',
      'CA07',
    ],
  ),
];
