import 'package:bio_g/core/crops/catalog/crop_catalog_models.dart';

/// Catálogo base de Pera / Peral (Pyrus communis) — segundo árbol perenne real
/// después del Manzano.
///
/// Solo metadata de catálogo: ids de perfil, etiquetas y alias. No contiene
/// lógica agronómica (sin GDD, horas frío, fenología ni rendimiento); esa lógica
/// vive en `pear_tree_universal_profile.dart` y `pear_tree_yield_reference.dart`.
///
/// PR-SKIP es el perfil general/seguro de pera ("No sé / Pera general").
/// IMPORTANTE: PR-SKIP NO significa descanso/fallow del suelo. En árboles el
/// perfil/variedad es opcional y migrable: cambiar de PR-SKIP a PR-01..PR-05 NO
/// debe reiniciar la memoria del cultivo (doc 01 §13).
///
/// cropId canónico OFICIAL: `crop_pear_tree`. El id legacy `pear_tree` resuelve
/// a Pera como ALIAS vía [CropCatalog.canonicalCropKey]; no se duplica el
/// cultivo. NO se hardcodea ni se reutiliza apple_tree para pera (doc 01 §17).
const String kCropPearTree = 'crop_pear_tree';

/// Id legacy de pera. Conservado solo como alias de compatibilidad.
const String kCropPearTreeLegacy = 'pear_tree';

const String kPrSkip = 'pr_skip';
const String kPr01BartlettWilliams = 'pr_01_bartlett_williams';
const String kPr02Anjou = 'pr_02_anjou';
const String kPr03Bosc = 'pr_03_bosc';
const String kPr04SeckelComice = 'pr_04_seckel_comice';
const String kPr05KiefferRustic = 'pr_05_kieffer_rustic';

const List<CropProfileEntry> pearTreeProfileEntries = [
  CropProfileEntry(
    id: kPrSkip,
    label: 'PR-SKIP - No sé / Pera general',
    cropId: kCropPearTree,
    subtitle:
        'Perfil general y migrable de la pera: puedes precisar la variedad '
        'después sin perder historial. No es descanso del suelo.',
    aliases: [
      'PR-SKIP',
      'PR_SKIP',
      'PRSKIP',
      'Pera',
      'Peral',
      'Pera general',
      'No sé',
      'No se',
      'Pear',
      'Pear tree',
      // Pera asiática / nashi: en v1 NO se inventa PR-06. Cae al perfil general
      // con confianza baja (doc 01 §2 nota, §13 y doc 04 §6 futuro PR-06).
      'Pera asiatica',
      'Pera asiática',
      'Nashi',
      'Pera manzana',
      'Asian pear',
    ],
  ),
  CropProfileEntry(
    id: kPr01BartlettWilliams,
    label: 'PR-01 - Bartlett / Williams',
    cropId: kCropPearTree,
    subtitle: 'Pera europea clásica verde-amarilla, jugosa (Bartlett/Williams)',
    aliases: [
      'PR-01',
      'PR01',
      'Bartlett',
      'Williams',
      'Williams Bon Chretien',
      'Bon Chretien',
      'Pera Bartlett',
      'Pera Williams',
      'Pera de agua',
      'Pera amarilla',
      'Amarilla',
      'Verano',
      'Otra Bartlett',
      'Otra Williams',
    ],
  ),
  CropProfileEntry(
    id: kPr02Anjou,
    label: "PR-02 - D'Anjou / Anjou",
    cropId: kCropPearTree,
    subtitle: 'Pera europea de invierno / alta conservación y almacenaje',
    aliases: [
      'PR-02',
      'PR02',
      "D'Anjou",
      'Danjou',
      'Anjou',
      'Anjou verde',
      'Anjou roja',
      'Red Anjou',
      'Green Anjou',
      'Pera Anjou',
      'Pera de invierno',
      'Alta conservacion',
      'Otra Anjou',
    ],
  ),
  CropProfileEntry(
    id: kPr03Bosc,
    label: 'PR-03 - Bosc',
    cropId: kCropPearTree,
    subtitle: 'Pera firme de piel café/russet (Bosc / Mantecosa Bosc)',
    aliases: [
      'PR-03',
      'PR03',
      'Bosc',
      'Beurre Bosc',
      'Beurré Bosc',
      'Mantecosa Bosc',
      'Pera Bosc',
      'Café',
      'Marron',
      'Russet',
      'Otra Bosc',
    ],
  ),
  CropProfileEntry(
    id: kPr04SeckelComice,
    label: 'PR-04 - Seckel / Comice',
    cropId: kCropPearTree,
    subtitle: 'Peras dulces premium de mesa (Seckel / Comice)',
    aliases: [
      'PR-04',
      'PR04',
      'Seckel',
      'Comice',
      'Doyenne du Comice',
      'Doyenné du Comice',
      'Pera Comice',
      'Pera Seckel',
      'Dulce',
      'Premium',
      'Pera de mesa premium',
      'Otra dulce',
      'Otra premium',
    ],
  ),
  CropProfileEntry(
    id: kPr05KiefferRustic,
    label: 'PR-05 - Kieffer / Rústicas',
    cropId: kCropPearTree,
    subtitle: 'Peras híbridas/rústicas/regionales para proceso o mercado local',
    aliases: [
      'PR-05',
      'PR05',
      'Kieffer',
      'Kieffer hibrida',
      'Pera Kieffer',
      'Rustica',
      'Rústica',
      'Regional rustica',
      'Para proceso',
      'Industria',
      'Conserva',
      'Pera dura',
      'Otra rustica',
      'Otra rústica',
    ],
  ),
];
