import 'package:bio_g/core/crops/catalog/crop_catalog_models.dart';

/// Catalogo base del Mango / Arbol de mango (Mangifera indica L.,
/// Anacardiaceae).
///
/// Solo contiene metadata de catalogo: ids de perfil, etiquetas humanas y
/// aliases. La agronomia vive en `mango_tree_universal_profile.dart` y
/// `mango_tree_yield_reference.dart` (docs 01-05 del paquete Mango).
///
/// Regla fisiologica central (doc 01 §0.4, §2): el mango es un arbol perenne
/// tropical/subtropical siempreverde de produccion EPISODICA. NO florece
/// automaticamente cada ano: la ausencia de floracion es un estado valido. No
/// usa sowingDate como eje ni trata `dormancy` como arbol pelon caducifolio: el
/// eje es estado del arbol + etapa visible + ancla del evento + memoria. El
/// mango NO es limon, NO es naranjo y NO es manzano (doc 04 §0).
const String kCropMangoTree = 'crop_mango_tree';

/// Id legacy/cropKey esperado del mango. Conservado como alias de
/// compatibilidad (doc 01 §0.1, §1).
const String kMangoTreeLegacy = 'mango_tree';

const String kMgSkip = 'mg_skip';
const String kMg01AtaulfoManila = 'mg_01_ataulfo_manila';
const String kMg02TommyAtkins = 'mg_02_tommy_atkins';
const String kMg03Kent = 'mg_03_kent';
const String kMg04Keitt = 'mg_04_keitt';
const String kMg05CriolloRegional = 'mg_05_criollo_regional';

const List<CropProfileEntry> mangoTreeProfileEntries = [
  CropProfileEntry(
    id: kMg01AtaulfoManila,
    label: 'Ataulfo / Manila / miel',
    cropId: kCropMangoTree,
    subtitle:
        'Mango amarillo, pequeño-mediano, pulpa cremosa/poca fibra, temprano y '
        'premium. Sensible a HR/lluvia en floración, aborto floral, cuajado, '
        'alternancia y calidad de piel/pulpa. Premium no significa más toneladas.',
    aliases: [
      'MG-01',
      'MG01',
      'Ataulfo',
      'Ataúlfo',
      'Manila',
      'Mango miel',
      'miel',
      'Honey',
      'Champagne',
      'Soconusco',
      'amarillo',
      'premium',
      // Migracion: id corto del doc 01 §9.1 conservado como alias.
      'mg_01_ataulfo',
      'mg_01_manila',
      'mg_01_mango_miel',
      'mg_01_champagne',
      'mg_01_premium',
    ],
  ),
  CropProfileEntry(
    id: kMg02TommyAtkins,
    label: 'Tommy Atkins',
    cropId: kCropMangoTree,
    subtitle:
        'Mango de volumen/exportación, fruto grande rojo/verde de buena '
        'resistencia de transporte. Vigilar déficit hídrico prolongado, exceso '
        'vegetativo por N, alternancia y antracnosis/cenicilla en flor.',
    aliases: [
      'MG-02',
      'MG02',
      'Tommy',
      'Tommy Atkins',
      'Exportación',
      'exportacion',
      'volumen',
      'Mango rojo',
      'rojo',
      'mg_02_tommy',
      'mg_02_tommy_atkins',
      'mg_02_exportacion',
      'mg_02_volumen',
    ],
  ),
  CropProfileEntry(
    id: kMg03Kent,
    label: 'Kent',
    cropId: kCropMangoTree,
    subtitle:
        'Mango intermedio-tardío de exportación, buena calidad interna y '
        'llenado largo. Sensible a estrés hídrico en llenado, HR en floración, '
        'alternancia moderada y madurez de corte.',
    aliases: [
      'MG-03',
      'MG03',
      'Kent',
      'tardío',
      'tardio',
      'exportación tardía',
      'exportacion tardia',
      'calidad interna',
      'mg_03_kent',
      'mg_03_exportacion_tardia',
      'mg_03_calidad_interna',
    ],
  ),
  CropProfileEntry(
    id: kMg04Keitt,
    label: 'Keitt',
    cropId: kCropMangoTree,
    subtitle:
        'Mango tardío/muy tardío, fruto grande, ventana extendida. Llenado muy '
        'largo: mayor exposición a estrés hídrico acumulado, alternancia fuerte, '
        'reservas de postcosecha, calibre y madurez.',
    aliases: [
      'MG-04',
      'MG04',
      'Keitt',
      'muy tardío',
      'muy tardio',
      'ventana extendida',
      'mg_04_keitt',
      'mg_04_tardio',
      'mg_04_muy_tardio',
      'mg_04_ventana_extendida',
    ],
  ),
  CropProfileEntry(
    id: kMg05CriolloRegional,
    label: 'Criollo / regional',
    cropId: kCropMangoTree,
    subtitle:
        'Mango de patio/huerto tradicional, mercado local/regional, mucha '
        'variabilidad genética y de calidad. No asumir rendimiento alto por '
        'árbol grande viejo: poda, alternancia y calidad son irregulares.',
    aliases: [
      'MG-05',
      'MG05',
      'Criollo',
      'criollo',
      'Regional',
      'regional',
      'Local',
      'local',
      'patio',
      'huerto viejo',
      'Manila local',
      'mg_05_criollo',
      'mg_05_regional',
      'mg_05_local',
      'mg_05_huerto_viejo',
    ],
  ),
  CropProfileEntry(
    id: kMgSkip,
    label: 'No sé / Mango general',
    cropId: kCropMangoTree,
    subtitle:
        'Perfil general y migrable del mango: puedes precisar Ataulfo/Manila, '
        'Tommy Atkins, Kent, Keitt o Criollo después sin perder historial. No '
        'es descanso del suelo ni promete floración cada año.',
    aliases: [
      'MG-SKIP',
      'MG_SKIP',
      'MGSKIP',
      'Mango',
      'mango',
      'Mango general',
      'mango común',
      'mango comun',
      'árbol de mango',
      'arbol de mango',
      'arbol_mango',
      'árbol_mango',
      'mangos',
      'crop_mango',
      'mangifera',
      'mangifera_indica',
      'No sé',
      'No se',
      'No sé qué tipo de mango',
      'No sé la variedad',
    ],
  ),
];
