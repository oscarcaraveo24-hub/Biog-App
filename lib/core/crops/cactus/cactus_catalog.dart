import 'package:bio_g/core/crops/catalog/crop_catalog_models.dart';

/// Catálogo base del Cactus ornamental (primera ornamental oficial de BIO-G).
///
/// Solo contiene metadata de catálogo: ids de perfil, etiquetas humanas y
/// aliases. La agronomía vive en `cactus_universal_profile.dart`, el ciclo en
/// `cactus_lifecycle.dart` y los riesgos en `cactus_risk_catalog.dart`
/// (docs 01-05 del paquete Cactus CA v1.1).
///
/// Regla ornamental central (doc 01 §0.1): el cactus es una planta perenne en
/// modo `establishment_maintenance`. No usa fecha de siembra ni cosecha; el eje
/// es etapa ornamental + microciclo hídrico + ancla + memoria. El HARDWARE es la
/// fuente de verdad para humedad, NPK, EC y temperatura.
const String kCropCactus = 'crop_cactus';

/// Id legacy/cropKey esperado del cactus. Conservado como alias de
/// compatibilidad (doc 01 §0.4, §1).
const String kCactusLegacy = 'cactus';

const String kCaSkip = 'ca_skip';
const String kCactusProfilePrefix = 'CA';
const String kCa01DesertContainer = 'ca_01_desert_container';
const String kCa02BarrelBiznaga = 'ca_02_barrel_biznaga';
const String kCa03ColumnarLandscape = 'ca_03_columnar_landscape';
const String kCa04ClusteredDesert = 'ca_04_clustered_desert';

/// Perfiles del cactus, en el ORDEN EN QUE SE MUESTRAN AL USUARIO.
///
/// El orden importa: primero los tipos concretos (CA-01 a CA-04, el orden
/// canónico del doc 01) y **al final** la salida "No sé / cactus general".
/// Un menú que abre con "No sé" invita a no elegir; el genérico es la red de
/// seguridad, no la primera opción.
///
/// El perfil general/SKIP va SIEMPRE disponible y NUNCA muestra al usuario la
/// palabra "SKIP" ni el profileId (doc 02 §0). Sigue siendo el
/// `defaultProfileId` del cultivo: si el usuario no elige, cae aquí.
///
/// Aliases de compatibilidad: los ids provisionales previos del wizard
/// (`cactus_generic`, `cactus_mini`, `cactus_columnar`) se conservan como alias
/// hacia los nuevos perfiles CA, pero la salida canónica usa siempre los nuevos
/// ids (requerimiento COMPATIBILIDAD).
const List<CropProfileEntry> cactusProfileEntries = <CropProfileEntry>[
  CropProfileEntry(
    id: kCa01DesertContainer,
    label: 'Cactus de maceta',
    cropId: kCropCactus,
    subtitle:
        'Cactus desértico de contenedor. Raíz confinada, secado más rápido y '
        'mayor riesgo de sales; la luz interior insuficiente es un riesgo común.',
    aliases: <String>[
      'CA-01',
      'CA01',
      'ca_01',
      'cactus mini',
      'cactus de escritorio',
      'cactus de maceta',
      'cactus de coleccion',
      'cactus de colección',
      'cactus pequeno',
      'cactus pequeño',
      // Compatibilidad: ids provisionales previos del wizard.
      'cactus_mini',
      'cactus mini legacy',
    ],
  ),
  CropProfileEntry(
    id: kCa02BarrelBiznaga,
    label: 'Biznaga o cactus barril',
    cropId: kCropCactus,
    subtitle:
        'Cactus globoso / barril / biznaga. Crecimiento muy lento, gran reserva '
        'en el tallo y alta sensibilidad al agua retenida junto al cuello.',
    aliases: <String>[
      'CA-02',
      'CA02',
      'ca_02',
      'biznaga',
      'cactus barril',
      'barril de oro',
      'bola de oro',
      'asiento de suegra',
      'ferocactus',
      'echinocactus',
      'otro cactus globoso',
    ],
  ),
  CropProfileEntry(
    id: kCa03ColumnarLandscape,
    label: 'Cactus columna u órgano',
    cropId: kCropCactus,
    subtitle:
        'Cactus columnar de paisaje (ejemplar mediano o grande). '
        'Establecimiento radicular más prolongado; una sola sonda representa '
        'solo parte de la zona radicular.',
    aliases: <String>[
      'CA-03',
      'CA03',
      'ca_03',
      'cactus organo',
      'cactus órgano',
      'organo',
      'órgano',
      'cactus columna',
      'cardon ornamental',
      'cardón ornamental',
      'cactus castillo',
      'cereus ornamental',
      'stenocereus ornamental',
      'echinopsis columnar',
      'trichocereus columnar',
      'otro cactus columnar',
      // Compatibilidad: id provisional previo del wizard.
      'cactus_columnar',
    ],
  ),
  CropProfileEntry(
    id: kCa04ClusteredDesert,
    label: 'Cactus agrupado o de varios tallos',
    cropId: kCropCactus,
    subtitle:
        'Cactus desértico agrupado, cespitoso o ramificado. Múltiples tallos o '
        'hijuelos; puede coexistir tejido sano con daño localizado.',
    aliases: <String>[
      'CA-04',
      'CA04',
      'ca_04',
      'cactus agrupado',
      'cactus de hijuelos',
      'cactus cespitoso',
      'cactus ramificado',
      'mammillaria agrupada',
      'echinopsis agrupada',
      'otro cactus desertico de varios tallos',
      'otro cactus desértico de varios tallos',
    ],
  ),
  // ── SIEMPRE AL FINAL ──────────────────────────────────────────────────────
  // La salida "no sé" va hasta abajo, después de los tipos concretos. Sigue
  // siendo el defaultProfileId: si el usuario no elige, cae aquí.
  CropProfileEntry(
    id: kCaSkip,
    label: 'No sé / cactus general',
    cropId: kCropCactus,
    subtitle:
        'Perfil general y migrable del cactus: puedes precisar maceta, biznaga, '
        'columnar o agrupado después sin perder historial.',
    aliases: <String>[
      'CA-SKIP',
      'CA_SKIP',
      'CASKIP',
      'cactus',
      'cactus general',
      'no se que cactus es',
      'no sé qué cactus es',
      'otro cactus',
      'cactus desconocido',
      'cactus sin identificar',
      'no se',
      'no sé',
      // Compatibilidad de entrada: id provisional previo del wizard.
      'cactus_generic',
    ],
  ),
];

/// Aliases de ENTRADA que NO deben mapear silenciosamente a un perfil desértico
/// CA: epífitos/tropicales y nopal/Opuntia (doc 01 §0.3, doc 02 §12). El nopal
/// se reserva para `crop_nopal`; los epífitos requieren un perfil futuro.
const List<String> cactusEpiphyticRedirectAliases = <String>[
  'cactus de navidad',
  'schlumbergera',
  'rhipsalis',
  'epiphyllum',
  'disocactus',
  'cactus colgante',
  'cactus de selva',
];

const List<String> cactusOpuntiaRedirectAliases = <String>[
  'nopal',
  'opuntia',
  'orejas de conejo',
];

const List<String> cactusProductiveExclusionAliases = <String>[
  'pitahaya',
  'pitaya',
  'dragon fruit',
];

/// True si el alias corresponde a un cactus epífito/tropical (no CA v1).
bool isCactusEpiphyticAlias(String? raw) {
  final v = raw?.trim().toLowerCase();
  if (v == null || v.isEmpty) return false;
  return cactusEpiphyticRedirectAliases.contains(v);
}

/// True si el alias corresponde a nopal/Opuntia (redirige a crop_nopal).
bool isCactusOpuntiaAlias(String? raw) {
  final v = raw?.trim().toLowerCase();
  if (v == null || v.isEmpty) return false;
  return cactusOpuntiaRedirectAliases.contains(v);
}

bool isCactusProductiveExclusionAlias(String? raw) {
  final v = raw?.trim().toLowerCase();
  if (v == null || v.isEmpty) return false;
  return cactusProductiveExclusionAliases.contains(v);
}
