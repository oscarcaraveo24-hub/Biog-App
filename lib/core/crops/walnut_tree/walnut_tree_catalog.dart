import 'package:bio_g/core/crops/catalog/crop_catalog_models.dart';

/// Catalogo base del Nogal pecanero / Nuez pecana (Carya illinoinensis).
///
/// Solo contiene metadata de catalogo: ids de perfil, etiquetas humanas y
/// aliases. La agronomia vive en `walnut_tree_universal_profile.dart` y
/// `walnut_tree_yield_reference.dart` (docs 01-05 del paquete Nogal).
const String kCropWalnutTree = 'crop_walnut_tree';

/// Id legacy del nogal. Conservado solo como alias de compatibilidad (doc 01 §2).
const String kCropWalnutTreeLegacy = 'walnut_tree';

const String kNgSkip = 'ng_skip';
const String kNg01Western = 'ng_01_western';
const String kNg02Wichita = 'ng_02_wichita';
const String kNg03WesternWichita = 'ng_03_western_wichita';
const String kNg04CriolloRegional = 'ng_04_criollo_regional';

/// NG-05 canónico hacia adelante. Aliases de migración conservan el historial de
/// ids previos (`ng_05_temprano_nuevo`, `ng_05_temprano`).
const String kNg05TempranoPawneeKanza = 'ng_05_temprano_pawnee_kanza';

const List<CropProfileEntry> walnutTreeProfileEntries = [
  CropProfileEntry(
    id: kNg01Western,
    label: 'Western / Western Schley',
    cropId: kCropWalnutTree,
    subtitle: 'Backbone del oeste/norte; vigoroso y confiable, puede sobrecargar',
    aliases: [
      'NG-01',
      'NG01',
      'Western',
      'Western Schley',
      'Western Chihuahua',
      'Occidental',
      'Nuez Western',
      'Otra variedad Western',
    ],
  ),
  CropProfileEntry(
    id: kNg02Wichita,
    label: 'Wichita',
    cropId: kCropWalnutTree,
    subtitle: 'Precoz y prolifica; polinizadora comun de Western, sensible a zinc',
    aliases: [
      'NG-02',
      'NG02',
      'Wichita',
      'Grande',
      'Exportacion',
      'Exportación',
      'Nuez grande',
    ],
  ),
  CropProfileEntry(
    id: kNg03WesternWichita,
    label: 'Bloque Western / Wichita',
    cropId: kCropWalnutTree,
    subtitle: 'Huerto mixto comercial: paquete de polinizacion regional',
    aliases: [
      'NG-03',
      'NG03',
      'Western/Wichita',
      'Western Wichita',
      'Bloque Western/Wichita',
      'Paquete Chihuahua',
      'Bloque norte',
      'Bloque comercial',
    ],
  ),
  CropProfileEntry(
    id: kNg04CriolloRegional,
    label: 'Criollo / Regional',
    cropId: kCropWalnutTree,
    subtitle: 'Criollo, nativo o huerto viejo de genetica variable',
    aliases: [
      'NG-04',
      'NG04',
      'Criollo',
      'Nativo',
      'Regional',
      'Criollo / regional',
      'Huerto viejo',
      'Nogal criollo',
      'Nogal nativo',
      'Nogal regional',
    ],
  ),
  CropProfileEntry(
    id: kNg05TempranoPawneeKanza,
    label: 'Temprano / Pawnee-Kanza',
    cropId: kCropWalnutTree,
    subtitle: 'Grupo temprano o nuevas variedades; adelantan ventana de cosecha',
    aliases: [
      'NG-05',
      'NG05',
      // Migración: ids previos conservados como alias (no romper historial).
      'ng_05_temprano_nuevo',
      'ng_05_temprano',
      'Temprano',
      'Tempranas',
      'Pawnee',
      'Kanza',
      'Cheyenne',
      'Nuevas',
      'Variedad temprana',
      'Otra temprana',
    ],
  ),
  CropProfileEntry(
    id: kNgSkip,
    label: 'No sé / Nogal general',
    cropId: kCropWalnutTree,
    subtitle:
        'Perfil general y migrable del nogal: puedes precisar la variedad '
        'despues sin perder historial. No es descanso del suelo.',
    aliases: [
      'NG-SKIP',
      'NG_SKIP',
      'NGSKIP',
      'Nogal',
      'Nogal general',
      'Nogal pecanero',
      'Nuez',
      'Nuez pecana',
      'Pecana',
      'Pecanero',
      'Pecan',
      'Pecan tree',
      'Walnut',
      'Walnut tree',
      'No sé',
      'No se',
      'No sé la variedad',
    ],
  ),
];
