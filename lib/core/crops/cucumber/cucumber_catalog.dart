import 'package:bio_g/core/crops/catalog/crop_catalog_models.dart';
import 'package:bio_g/widgets/seeds/cucumber_profiles.dart';

const String kCropCucumber = 'cucumber';
const String kCucumberDefaultCalendarId = 'cucumber_default';

/// Perfiles oficiales del pepino (PE-01..PE-04 + PE-GEN).
///
/// PE-GEN es la opción SKIP obligatoria (filosofía BIO-G): el usuario
/// siempre puede no elegir tipo y quedarse en genérico, migrable a un
/// perfil oficial sin perder historia.
const List<CropProfileEntry> cucumberProfileEntries = [
  CropProfileEntry(
    id: kPe01,
    label: 'PE-01 · Slicer campo abierto',
    cropId: kCropCucumber,
    subtitle:
        'Pepino americano de rebanada, de cáscara gruesa y con espinas, para '
        'campo abierto (criollo)',
    aliases: [
      'PE-01',
      'PE01',
      'Slicer',
      'Slicer campo abierto',
      'Americano',
      'Criollo',
    ],
  ),
  CropProfileEntry(
    id: kPe02,
    label: 'PE-02 · Europeo / inglés protegido',
    cropId: kCropCucumber,
    subtitle:
        'Pepino largo de cáscara lisa y delgada, sin espinas, para cultivo '
        'bajo cubierta (inglés o europeo)',
    aliases: [
      'PE-02',
      'PE02',
      'Europeo',
      'Europeo protegido',
      'Inglés',
      'Inglés protegido',
    ],
  ),
  CropProfileEntry(
    id: kPe03,
    label: 'PE-03 · Persa / mini / Beit-Alfa',
    cropId: kCropCucumber,
    subtitle:
        'Pepino chico de cáscara lisa y casi sin semilla, se da bajo cubierta '
        '(persa, mini, Beit-Alfa)',
    aliases: [
      'PE-03',
      'PE03',
      'Persian',
      'Persa',
      'Mini',
      'Beit-alpha',
      'Beit alpha',
      'Partenocárpico',
    ],
  ),
  CropProfileEntry(
    id: kPe04,
    label: 'PE-04 · Pickler campo abierto',
    cropId: kCropCucumber,
    subtitle:
        'Pepino chico y firme que se corta tierno para encurtir, se siembra '
        'denso (pepinillo, cornichón)',
    aliases: [
      'PE-04',
      'PE04',
      'Pickler',
      'Cornichón',
      'Encurtido',
      'Pepinillo',
    ],
  ),
  CropProfileEntry(
    id: kPeGen,
    label: 'PE-GEN · Genérico',
    cropId: kCropCucumber,
    subtitle:
        'Perfil general del pepino, migrable: defines el tipo después sin '
        'perder tu historial',
    aliases: ['PE-GEN', 'PEGEN', 'Genérico', 'Generico', 'Generic'],
  ),
];

/// Variedades-tipo de pepino visibles en UX (apuntan al perfil oficial).
///
/// En v1 no se modela marca comercial: el mercado de cucurbitáceas en MX
/// está fragmentado y la marca no añade información al reloj biológico.
const List<CropVarietyEntry> cucumberVarieties = [
  CropVarietyEntry(
    id: 'cucumber_slicer_ca',
    label: 'Slicer campo abierto',
    cropId: kCropCucumber,
    subtitle:
        'Tipo de rebanada para campo abierto, de cáscara gruesa y con espinas '
        '(americano, criollo)',
    defaultProfileId: kPe01,
    aliases: [
      'Slicer',
      'Slicer campo abierto',
      'Americano',
      'Pepino criollo',
      'Criollo',
      'PE-01',
      'PE01',
    ],
  ),
  CropVarietyEntry(
    id: 'cucumber_european_protected',
    label: 'Europeo / inglés protegido',
    cropId: kCropCucumber,
    subtitle:
        'Pepino largo europeo de piel lisa y delgada, sin espinas, para '
        'cultivo bajo cubierta',
    defaultProfileId: kPe02,
    aliases: [
      'Europeo',
      'Europeo protegido',
      'Inglés',
      'Ingles',
      'Inglés protegido',
      'Ingles protegido',
      'Pepino inglés',
      'Pepino ingles',
      'PE-02',
      'PE02',
    ],
  ),
  CropVarietyEntry(
    id: 'cucumber_persian',
    label: 'Persa / mini / Beit-Alfa',
    cropId: kCropCucumber,
    subtitle:
        'Pepino mini de piel lisa y casi sin semilla, se cultiva bajo cubierta '
        '(persa, Beit-Alfa)',
    defaultProfileId: kPe03,
    aliases: [
      'Persian',
      'Persa',
      'Beit-alpha',
      'Beit alpha',
      'Pepino persa',
      'Mini',
      'Partenocárpico',
      'Partenocarpico',
      'Sin semilla',
      'Snack',
      'PE-03',
      'PE03',
    ],
  ),
  CropVarietyEntry(
    id: 'cucumber_pickler',
    label: 'Pickler (encurtido)',
    cropId: kCropCucumber,
    subtitle:
        'Pepino chico y firme que se cosecha tierno para encurtir (pepinillo, '
        'cornichón)',
    defaultProfileId: kPe04,
    aliases: [
      'Pickler',
      'Cornichón',
      'Cornichon',
      'Encurtido',
      'Pepinillo',
      'Pepino encurtido',
      'PE-04',
      'PE04',
    ],
  ),
  CropVarietyEntry(
    id: 'cucumber_generic',
    label: 'Pepino genérico',
    cropId: kCropCucumber,
    subtitle:
        'Pepino sin tipo definido, perfil migrable: afinas el tipo después sin '
        'perder historial',
    defaultProfileId: kPeGen,
    aliases: [
      'Genérico',
      'Generico',
      'Pepino genérico',
      'Pepino generico',
      'PE-GEN',
      'PEGEN',
    ],
    isGeneric: true,
  ),
];
