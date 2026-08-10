import 'package:bio_g/core/crops/catalog/crop_catalog_models.dart';
import 'package:bio_g/widgets/seeds/tomato_profiles.dart';

const String kCropTomato = 'tomato';
const String kTomatoDefaultCalendarId = 'tomato_default';

/// Perfiles oficiales del tomate (TM-01..TM-05 + TM-GEN).
///
/// TM-GEN es la opción SKIP obligatoria (filosofía BIO-G): el usuario
/// siempre puede no elegir tipo y quedarse en genérico, migrable a un
/// perfil oficial sin perder historia.
const List<CropProfileEntry> tomatoProfileEntries = [
  CropProfileEntry(
    id: kTm01,
    label: 'TM-01 · Saladette campo abierto',
    cropId: kCropTomato,
    subtitle:
        'Jitomate saladette o Roma a campo abierto, de mata baja que para '
        'sola, ciclo corto a medio',
    aliases: ['TM-01', 'TM01', 'Saladette campo abierto', 'Roma', 'Pera'],
  ),
  CropProfileEntry(
    id: kTm02,
    label: 'TM-02 · Saladette protegido',
    cropId: kCropTomato,
    subtitle:
        'Perfil de jitomate saladette sembrado en suelo bajo malla sombra o '
        'invernadero, no a cielo abierto',
    aliases: ['TM-02', 'TM02', 'Saladette protegido'],
  ),
  CropProfileEntry(
    id: kTm03,
    label: 'TM-03 · Bola',
    cropId: kCropTomato,
    subtitle:
        'Jitomate bola, redondo y grande, de planta que sigue creciendo y da '
        'cosecha por más tiempo',
    aliases: ['TM-03', 'TM03', 'Bola', 'Redondo', 'Beef'],
  ),
  CropProfileEntry(
    id: kTm04,
    label: 'TM-04 · Cherry / uva',
    cropId: kCropTomato,
    subtitle:
        'Jitomate chico cherry o uva, de planta que no deja de crecer, en '
        'suelo bajo malla o invernadero',
    aliases: ['TM-04', 'TM04', 'Cherry', 'Uva', 'Grape'],
  ),
  CropProfileEntry(
    id: kTm05,
    label: 'TM-05 · TOV (racimo)',
    cropId: kCropTomato,
    subtitle:
        'Jitomate que se corta y se vende en racimo, con la rama pegada al '
        'fruto, para anaquel',
    aliases: ['TM-05', 'TM05', 'TOV', 'Racimo'],
  ),
  CropProfileEntry(
    id: kTmGen,
    label: 'TM-GEN · Genérico',
    cropId: kCropTomato,
    subtitle:
        'Perfil general y migrable de jitomate: puedes precisar el tipo '
        'después sin perder tu historial',
    aliases: ['TM-GEN', 'TMGEN', 'Genérico', 'Generico', 'Generic'],
  ),
];

/// Variedades de tomate.
///
/// En v1 usamos variedades-tipo visibles por UX que apuntan al perfil
/// oficial correspondiente. No hay marca comercial (el marketing de
/// semilleros en tomate es muy fragmentado y no aporta al reloj
/// biológico v1).
const List<CropVarietyEntry> tomatoVarieties = [
  CropVarietyEntry(
    id: 'tomato_saladette_ca',
    label: 'Saladette campo abierto',
    cropId: kCropTomato,
    subtitle:
        'Jitomate alargado tipo saladette sembrado a campo abierto, para salsa '
        'y venta diaria (Roma, pera)',
    defaultProfileId: kTm01,
    aliases: [
      'Saladette',
      'Saladette campo abierto',
      'Saladette CA',
      'Roma',
      'Pera',
      'Tomate Roma',
      'Tomate pera',
      'TM-01',
      'TM01',
    ],
  ),
  CropVarietyEntry(
    id: 'tomato_saladette_protegido',
    label: 'Saladette protegido',
    cropId: kCropTomato,
    subtitle:
        'Jitomate alargado tipo saladette cultivado en suelo bajo malla sombra '
        'o invernadero',
    defaultProfileId: kTm02,
    aliases: [
      'Saladette protegido',
      'Saladette malla',
      'Saladette invernadero',
      'TM-02',
      'TM02',
    ],
  ),
  CropVarietyEntry(
    id: 'tomato_bola',
    label: 'Bola',
    cropId: kCropTomato,
    subtitle:
        'Jitomate bola, redondo y grande, bueno para rebanar en tortas y '
        'hamburguesas (beef, beefsteak)',
    defaultProfileId: kTm03,
    aliases: [
      'Bola',
      'Tomate bola',
      'Redondo',
      'Beef',
      'Beefsteak',
      'TM-03',
      'TM03',
    ],
  ),
  CropVarietyEntry(
    id: 'tomato_cherry',
    label: 'Cherry / uva',
    cropId: kCropTomato,
    subtitle:
        'Jitomate chico y dulce que da en racimos, redondo cherry o alargado '
        'tipo uva, para ensalada',
    defaultProfileId: kTm04,
    aliases: [
      'Cherry',
      'Tomate cherry',
      'Uva',
      'Tomate uva',
      'Grape',
      'TM-04',
      'TM04',
    ],
  ),
  CropVarietyEntry(
    id: 'tomato_tov',
    label: 'TOV (racimo)',
    cropId: kCropTomato,
    subtitle:
        'Jitomate que se corta y se vende en racimo, con todo y rama, conocido '
        'como tomate en racimo',
    defaultProfileId: kTm05,
    aliases: [
      'TOV',
      'Tomate TOV',
      'Racimo',
      'Truss on the Vine',
      'Truss',
      'TM-05',
      'TM05',
    ],
  ),
  CropVarietyEntry(
    id: 'tomato_generic',
    label: 'Tomate genérico',
    cropId: kCropTomato,
    subtitle:
        'Perfil general y migrable de jitomate: eliges el tipo más adelante '
        'sin perder tu historial',
    defaultProfileId: kTmGen,
    aliases: [
      'Genérico',
      'Generico',
      'Tomate genérico',
      'Tomate generico',
      'TM-GEN',
      'TMGEN',
    ],
    isGeneric: true,
  ),
];
