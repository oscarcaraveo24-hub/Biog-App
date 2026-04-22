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
    subtitle: 'Americano / criollo de rebanada · ciclo corto-medio',
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
    subtitle: 'Pepino largo protegido en suelo · inglés / europeo',
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
    subtitle: 'Partenocárpico sin semilla · mini protegido en suelo',
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
    subtitle: 'Encurtido / cornichón · ciclo corto · alta densidad',
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
    subtitle: 'Perfil genérico (skip obligatorio)',
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
    subtitle: 'Tipo · Americano / criollo de rebanada',
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
    subtitle: 'Tipo · Pepino largo europeo bajo cubierta',
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
    subtitle: 'Tipo · Mini partenocárpico protegido',
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
    subtitle: 'Tipo · Cornichón / pepinillo',
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
    subtitle: 'Sin tipo definido (PE-GEN)',
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
