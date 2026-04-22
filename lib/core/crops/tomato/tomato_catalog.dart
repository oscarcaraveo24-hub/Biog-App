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
    subtitle: 'Roma / pera · determinado · ciclo corto-medio',
    aliases: ['TM-01', 'TM01', 'Saladette campo abierto', 'Roma', 'Pera'],
  ),
  CropProfileEntry(
    id: kTm02,
    label: 'TM-02 · Saladette protegido',
    cropId: kCropTomato,
    subtitle: 'Saladette bajo malla o invernadero en suelo',
    aliases: ['TM-02', 'TM02', 'Saladette protegido'],
  ),
  CropProfileEntry(
    id: kTm03,
    label: 'TM-03 · Bola',
    cropId: kCropTomato,
    subtitle: 'Redondo grande · indeterminado · ciclo largo',
    aliases: ['TM-03', 'TM03', 'Bola', 'Redondo', 'Beef'],
  ),
  CropProfileEntry(
    id: kTm04,
    label: 'TM-04 · Cherry / uva',
    cropId: kCropTomato,
    subtitle: 'Cherry o uva · indeterminado · protegido en suelo',
    aliases: ['TM-04', 'TM04', 'Cherry', 'Uva', 'Grape'],
  ),
  CropProfileEntry(
    id: kTm05,
    label: 'TM-05 · TOV (racimo)',
    cropId: kCropTomato,
    subtitle: 'Truss on the Vine · racimo comercial',
    aliases: ['TM-05', 'TM05', 'TOV', 'Racimo'],
  ),
  CropProfileEntry(
    id: kTmGen,
    label: 'TM-GEN · Genérico',
    cropId: kCropTomato,
    subtitle: 'Perfil genérico (skip obligatorio)',
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
    subtitle: 'Tipo · Saladette / Roma',
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
    subtitle: 'Tipo · Saladette bajo malla o invernadero',
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
    subtitle: 'Tipo · Redondo grande',
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
    subtitle: 'Tipo · Cherry o uva',
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
    subtitle: 'Tipo · Truss on the Vine',
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
    subtitle: 'Sin tipo definido (TM-GEN)',
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
