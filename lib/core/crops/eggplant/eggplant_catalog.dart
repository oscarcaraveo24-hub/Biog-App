import 'package:bio_g/core/crops/catalog/crop_catalog_models.dart';
import 'package:bio_g/widgets/seeds/eggplant_profiles.dart';

const String kCropEggplant = 'eggplant';
const String kEggplantDefaultCalendarId = 'eggplant_default';

const List<CropProfileEntry> eggplantProfileEntries = [
  CropProfileEntry(
    id: kBeGen,
    label: 'BE-GEN - Berenjena genérica',
    cropId: kCropEggplant,
    subtitle:
        'Perfil de berenjena conservador y migrable: precisa el tipo más '
        'adelante sin perder tu historial',
    aliases: [
      'BE-GEN',
      'BEGEN',
      'Generica',
      'Genérica',
      'Generico',
      'Genérico',
      'Generic',
      'No se',
      'No sé',
      'Otra berenjena',
      'Berenjena generica',
      'Berenjena genérica',
    ],
  ),
  CropProfileEntry(
    id: kBe01,
    label: 'BE-01 - Berenjena larga / semilarga morada',
    cropId: kCropEggplant,
    subtitle:
        'Berenjena morada alargada, el tipo más sembrado, se va cortando '
        'conforme el fruto llega',
    aliases: [
      'BE-01',
      'BE01',
      'Larga',
      'Semilarga',
      'Morada larga',
      'Larga morada',
      'Berenjena larga',
      'Berenjena semilarga',
      'Semilarga morada',
      'Oriental',
      'China',
      'Berenjena china',
      'Barcelona',
      'Dark Night',
      'Orestia',
      'Napoli',
      'Nápoli',
    ],
  ),
  CropProfileEntry(
    id: kBe02,
    label: 'BE-02 - Berenjena oval / bola morada',
    cropId: kCropEggplant,
    subtitle:
        'Berenjena morada de fruto ovalado o de bola, donde se cuida el tamaño '
        'parejo para el mercado',
    aliases: [
      'BE-02',
      'BE02',
      'Oval',
      'Bola',
      'Bola morada',
      'Oval morada',
      'Berenjena bola',
      'Berenjena oval',
      'Americana',
      'Morada grande',
      'Italiana',
      'Berenjena italiana',
      'Berenjena italiana / clasica morada',
      'Berenjena italiana / clásica morada',
      'Clasica',
      'Clásica',
      'Clasica morada',
      'Clásica morada',
      'Morada clasica',
      'Morada clásica',
      'Black Beauty',
      'Night Shadow',
      'Emma F1',
      'eggplant_italian_purple',
      'eggplant_italian_black',
      'eggplant_oval_round',
    ],
  ),
  CropProfileEntry(
    id: kBe03,
    label: 'BE-03 - Berenjena rayada / listada',
    cropId: kCropEggplant,
    subtitle:
        'Berenjena con rayas moradas y blancas para mercado gourmet, pide más '
        'cuidado en la presentación',
    aliases: [
      'BE-03',
      'BE03',
      'Rayada',
      'Listada',
      'Jaspeada',
      'Berenjena rayada',
      'Berenjena listada',
      'Graffiti',
      'Grafiti',
    ],
  ),
  CropProfileEntry(
    id: kBe04,
    label: 'BE-04 - Berenjena blanca',
    cropId: kCropEggplant,
    subtitle:
        'Berenjena de piel blanca para mercado de nicho, se marca fácil y '
        'exige cuidado al cortarla',
    aliases: [
      'BE-04',
      'BE04',
      'Blanca',
      'Berenjena blanca',
      'White Egg',
      'Blanca F1',
      'Otra blanca',
    ],
  ),
];

const List<CropVarietyEntry> eggplantVarieties = [
  CropVarietyEntry(
    id: 'eggplant_long_purple',
    label: 'Berenjena larga / semilarga morada',
    cropId: kCropEggplant,
    subtitle:
        'Berenjena morada de fruto largo y delgado, la más común en fresco '
        '(Barcelona, Dark Night, Orestia)',
    defaultProfileId: kBe01,
    aliases: [
      'Barcelona',
      'Dark Night',
      'Orestia',
      'Napoli',
      'Nápoli',
      'Morada larga',
      'Larga morada',
      'Berenjena larga',
      'Berenjena semilarga',
      'Semilarga morada',
      'Oriental',
      'China',
      'Berenjena china',
      'Otra variedad larga',
      'BE-01',
      'BE01',
    ],
  ),
  CropVarietyEntry(
    id: 'eggplant_italian_purple',
    label: 'Berenjena italiana / clásica morada',
    cropId: kCropEggplant,
    subtitle:
        'Berenjena clásica italiana, morada oscura y de fruto ovalado y '
        'grueso, buena para rebanar y asar',
    defaultProfileId: kBe02,
    aliases: [
      'Italiana',
      'Berenjena italiana',
      'Berenjena italiana / clasica morada',
      'Berenjena italiana / clásica morada',
      'Italiana clasica morada',
      'Italiana clásica morada',
      'Italian',
      'Clasica',
      'Clásica',
      'Clasica morada',
      'Clásica morada',
      'Morada clasica',
      'Morada clásica',
      'Black Beauty',
      'eggplant_italian_black',
      'BE-02',
      'BE02',
    ],
  ),
  CropVarietyEntry(
    id: 'eggplant_oval_round',
    label: 'Berenjena oval / bola morada',
    cropId: kCropEggplant,
    subtitle:
        'Berenjena morada de fruto oval o de bola, tipo americana, se pide de '
        'tamaño parejo (Emma F1)',
    defaultProfileId: kBe02,
    aliases: [
      'Night Shadow',
      'Emma F1',
      'Berenjena bola',
      'Berenjena oval',
      'Oval',
      'Bola',
      'Bola morada',
      'Oval morada',
      'Americana',
      'Morada grande',
      'Otra variedad oval',
      'BE-02',
      'BE02',
    ],
  ),
  CropVarietyEntry(
    id: 'eggplant_striped',
    label: 'Berenjena rayada / listada',
    cropId: kCropEggplant,
    subtitle:
        'Berenjena rayada de morado con blanco, tipo graffiti, de nicho '
        'gourmet y buena presentación',
    defaultProfileId: kBe03,
    aliases: [
      'Berenjena rayada',
      'Berenjena listada',
      'Rayada',
      'Listada',
      'Jaspeada',
      'Graffiti',
      'Grafiti',
      'Otra variedad rayada',
      'BE-03',
      'BE03',
    ],
  ),
  CropVarietyEntry(
    id: 'eggplant_white',
    label: 'Berenjena blanca',
    cropId: kCropEggplant,
    subtitle:
        'Berenjena de piel blanca lisa, de mercado de nicho, se mancha fácil '
        'al cortarla y empacarla',
    defaultProfileId: kBe04,
    aliases: [
      'Berenjena blanca',
      'Blanca',
      'White Egg',
      'Blanca F1',
      'Otra variedad blanca',
      'BE-04',
      'BE04',
    ],
  ),
  CropVarietyEntry(
    id: 'eggplant_generic',
    label: 'No sé / Otra berenjena',
    cropId: kCropEggplant,
    subtitle:
        'Perfil general y migrable de berenjena: eliges el tipo más adelante '
        'sin perder tu historial',
    defaultProfileId: kBeGen,
    aliases: [
      'Generica',
      'Genérica',
      'Berenjena generica',
      'Berenjena genérica',
      'Otra berenjena',
      'No se',
      'No sé',
      'BE-GEN',
      'BEGEN',
    ],
    isGeneric: true,
  ),
];
