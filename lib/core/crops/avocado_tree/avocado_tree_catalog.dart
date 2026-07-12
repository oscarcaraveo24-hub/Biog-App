import 'package:bio_g/core/crops/catalog/crop_catalog_models.dart';

/// Catalogo base del Aguacate / Arbol de aguacate (Persea americana Mill.,
/// Lauraceae).
///
/// Solo contiene metadata de catalogo: ids de perfil, etiquetas humanas y
/// aliases. La agronomia vive en `avocado_tree_universal_profile.dart` y
/// `avocado_tree_yield_reference.dart` (docs 01-05 del paquete Aguacate).
///
/// Regla fisiologica central (doc 01 §0.1, §0.4): el aguacate es un arbol
/// perenne subtropical/tropical SIEMPREVERDE, sin dormancia verdadera, con
/// floracion tipo A/B, cuajado FRAGIL (menos de 1% de flor llega a fruto),
/// raiz superficial/fina muy sensible a asfixia, salinidad y Phytophthora,
/// alternancia productiva marcada y memoria multianual. NO usa sowingDate como
/// eje ni trata `dormancy` como arbol pelon caducifolio: `dormancy` es reposo
/// funcional / preparacion / posible induccion floral. El eje es estado del
/// arbol + etapa visible + ancla del evento + memoria. El aguacate NO es mango,
/// NO es citrico, NO es manzano ni cultivo anual (doc 01 §0.1, §3.1, §12).
const String kCropAvocadoTree = 'crop_avocado_tree';

/// Id legacy/cropKey esperado del aguacate. Conservado como alias de
/// compatibilidad (doc 01 §0.1, §0.2).
const String kAvocadoTreeLegacy = 'avocado_tree';

const String kAgSkip = 'ag_skip';
const String kAg01Hass = 'ag_01_hass';
const String kAg02MendezCarmen = 'ag_02_mendez_carmen';
const String kAg03CriolloMexicano = 'ag_03_criollo_mexicano';
const String kAg04FuertePielVerde = 'ag_04_fuerte_piel_verde';
const String kAg05AntillanoTropical = 'ag_05_antillano_tropical';
const String kAg06TardioLambReed = 'ag_06_tardio_lamb_reed';

const List<CropProfileEntry> avocadoTreeProfileEntries = [
  CropProfileEntry(
    id: kAg01Hass,
    label: 'Hass',
    cropId: kCropAvocadoTree,
    subtitle:
        'Aguacate de exportación dominante, piel rugosa verde que oscurece a '
        'negro/morado al madurar, tipo floral A. Vigilar alternancia marcada, '
        'cuajado, salinidad/cloruros, Phytophthora y fruta colgando durante '
        'nueva floración. Exportación es calidad, no garantía de toneladas.',
    aliases: [
      'AG-01',
      'AG01',
      'Hass',
      'Hass mexicano',
      'Hass exportación',
      'aguacate negro',
      'hass normal',
      'hass tradicional',
      'Hass tipo A',
      'negro',
      'exportacion',
      'ag_01',
      'ag_01_hass',
    ],
  ),
  CropProfileEntry(
    id: kAg02MendezCarmen,
    label: 'Méndez / Carmen / Hass temprano',
    cropId: kCropAvocadoTree,
    subtitle:
        'Tipo Hass temprano o con floración/cosecha fuera de temporada '
        '(«flor loca»), tipo floral A. Ventana temprana de alto valor, pero la '
        'floración desfasada no garantiza cosecha: puede tirar fruta si clima, '
        'agua o raíz fallan. No copiar el manejo de Hass al 100%.',
    aliases: [
      'AG-02',
      'AG02',
      'Méndez',
      'Mendez',
      'Carmen',
      'Hass-Méndez',
      'Hass Mendez',
      'Hass-Mendez',
      'Carmen Hass',
      'flor loca',
      'Hass temprano',
      'Hass mejorado',
      'ag_02',
      'ag_02_mendez',
      'ag_02_carmen',
      'ag_02_mendez_carmen',
    ],
  ),
  CropProfileEntry(
    id: kAg03CriolloMexicano,
    label: 'Criollo / mexicano / regional',
    cropId: kCropAvocadoTree,
    subtitle:
        'Aguacate de patio/regional, semilla o injerto, mucha variabilidad de '
        'piel, calibre, calidad y ventana. No asumir exportación ni rendimiento '
        'alto por árbol grande viejo: tipo floral desconocido, alternancia y '
        'calidad irregulares. SKIP/criollo debe ser conservador.',
    aliases: [
      'AG-03',
      'AG03',
      'Criollo',
      'criollo',
      'Mexicano',
      'mexicano',
      'Nacional',
      'nacional',
      'Regional',
      'regional',
      'aguacate de patio',
      'aguacate de semilla',
      'criollo negro',
      'criollo verde',
      'palta criolla',
      'ag_03',
      'ag_03_criollo',
      'ag_03_criollo_mexicano',
    ],
  ),
  CropProfileEntry(
    id: kAg04FuertePielVerde,
    label: 'Fuerte / piel verde',
    cropId: kCropAvocadoTree,
    subtitle:
        'Clásico de piel verde (no oscurece), tipo floral B y posible '
        'polinizador de Hass si coincide la floración. Puede alternar o ser '
        'inconsistente; la piel verde confunde la madurez visual. No tratarlo '
        'como Hass negro de exportación.',
    aliases: [
      'AG-04',
      'AG04',
      'Fuerte',
      'fuerte',
      'piel verde',
      'aguacate verde',
      'clásico',
      'clasico',
      'tipo B',
      'polinizador',
      'Fuerte mexicano',
      'green_skin',
      'ag_04',
      'ag_04_fuerte',
      'ag_04_fuerte_piel_verde',
    ],
  ),
  CropProfileEntry(
    id: kAg05AntillanoTropical,
    label: 'Antillano / tropical',
    cropId: kCropAvocadoTree,
    subtitle:
        'Grupo antillano/tropical de costa y clima cálido: fruta grande, piel '
        'más lisa y verde, menor aceite en algunos materiales. Fruto grande '
        'puede subir kg/árbol, pero no equivale a Hass exportación. Sensible a '
        'exceso de humedad, antracnosis/roña y calidad externa/poscosecha.',
    aliases: [
      'AG-05',
      'AG05',
      'Antillano',
      'antillano',
      'tropical',
      'costa',
      'calor',
      'aguacate grande',
      'aguacate verde grande',
      'palta tropical',
      'west_indian',
      'ag_05',
      'ag_05_antillano',
      'ag_05_antillano_tropical',
    ],
  ),
  CropProfileEntry(
    id: kAg06TardioLambReed,
    label: 'Tardío / Lamb Hass / Reed',
    cropId: kCropAvocadoTree,
    subtitle:
        'Tardíos y especialidad: Lamb Hass (Hass-like más grande/tardío) y '
        'Reed (verde, redondo, grande, puede permanecer en árbol), tipo floral '
        'A. Ventana extendida y buen potencial, pero acumula estrés y carga '
        'sostenida; no marcar inmaduro solo porque sigue verde.',
    aliases: [
      'AG-06',
      'AG06',
      'Tardío',
      'tardio',
      'Lamb Hass',
      'Lamb',
      'Reed',
      'especialidad',
      'verano',
      'ventana extendida',
      'aguacate redondo verde',
      'ag_06',
      'ag_06_lamb_reed',
      'ag_06_tardio',
      'ag_06_tardio_lamb_reed',
    ],
  ),
  CropProfileEntry(
    id: kAgSkip,
    label: 'No sé / Aguacate general',
    cropId: kCropAvocadoTree,
    subtitle:
        'Perfil general y migrable del aguacate: puedes precisar Hass, '
        'Méndez/Carmen, Criollo, Fuerte, Antillano o Tardío después sin perder '
        'historial. No asume tipo floral A/B, portainjerto ni destino. No es '
        'descanso del suelo ni promete floración ni cuajado.',
    aliases: [
      'AG-SKIP',
      'AG_SKIP',
      'AGSKIP',
      'Aguacate',
      'aguacate',
      'aguacates',
      'Aguacate general',
      'aguacate común',
      'aguacate comun',
      'árbol de aguacate',
      'arbol de aguacate',
      'arbol_aguacate',
      'árbol_aguacate',
      'avocado',
      'avocados',
      'crop_avocado',
      'palta',
      'palto',
      'persea',
      'persea_americana',
      'aguacatero',
      'No sé',
      'No se',
      'No sé qué tipo de aguacate',
      'No sé la variedad',
    ],
  ),
];
