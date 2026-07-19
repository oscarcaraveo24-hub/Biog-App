import 'package:bio_g/core/crops/catalog/crop_catalog_models.dart';

/// Catálogo base de la Sábila / Aloe ornamental (tercera ornamental oficial de
/// BIO-G, modo `establishment_maintenance`).
///
/// Solo contiene metadata de catálogo: ids de perfil, etiquetas humanas y
/// aliases. La agronomía vive en `aloe_universal_profile.dart`, el ciclo en
/// `aloe_lifecycle.dart` y los riesgos en `aloe_risk_catalog.dart`
/// (Documentos A/B/C del paquete Sábila SA v1.0).
///
/// Identidad congelada (Doc A §0.2): `cropId = crop_aloe`, `CropKey = aloe`,
/// prefijo de perfil `SA`, nombre visible "Sábila". Sin fecha de siembra ni
/// cosecha; el eje es etapa (instalación → raíz → crecimiento → mantenimiento
/// abierto). El HARDWARE es la fuente de verdad para humedad, NPK, EC y
/// temperatura.
const String kCropAloe = 'crop_aloe';

/// Id legacy/cropKey esperado de la sábila. Se conserva como alias de
/// compatibilidad (Doc A §0.2).
const String kAloeLegacy = 'aloe';

const String kSaSkip = 'sa_skip';
const String kAloeProfilePrefix = 'SA';
const String kSa01BroadleafRosette = 'sa_01_broadleaf_rosette';
const String kSa02SmallClumping = 'sa_02_small_clumping';
const String kSa03ShrubbyBranching = 'sa_03_shrubby_branching';
const String kSa04SpottedLandscape = 'sa_04_spotted_landscape';

/// Perfiles de la sábila, en el ORDEN EN QUE SE MUESTRAN AL USUARIO
/// (Doc A §3: orden visible obligatorio).
///
/// Primero los cuatro tipos concretos (SA-01 … SA-04) y **al final** la salida
/// "No sé / sábila general". El general es la red de seguridad, no la primera
/// opción.
///
/// El perfil general (`sa_skip`) sigue siendo el `defaultProfileId` del cultivo:
/// si el usuario no elige, cae aquí. NUNCA se le muestra la palabra "SKIP" ni el
/// profileId (Doc A §0.2 #18, §8).
const List<CropProfileEntry> aloeProfileEntries = <CropProfileEntry>[
  CropProfileEntry(
    id: kSa01BroadleafRosette,
    label: 'Sábila de hoja ancha',
    cropId: kCropAloe,
    subtitle:
        'La común: roseta desde el centro, hoja gruesa con gel. Exige sustrato '
        'muy drenante; el agua estancada daña el cuello.',
    aliases: <String>[
      'SA-01',
      'SA01',
      'sa_01',
      'sábila',
      'sabila',
      'zábila',
      'zabila',
      'aloe',
      'aloe vera',
      'aloe barbadensis',
      'aloe barbadensis miller',
      'barbadensis miller',
      'sábila medicinal',
      'sábila comestible',
      'sábila de hoja ancha',
      'sábila gigante',
      'planta de sábila',
      'planta de la quemadura',
      'aloe de barbados',
      'true aloe',
      'medicine plant',
    ],
  ),
  CropProfileEntry(
    id: kSa02SmallClumping,
    label: 'Sábila pequeña de maceta',
    cropId: kCropAloe,
    subtitle:
        'Roseta chica que hace matita; aguanta luz clara sin sol fuerte. Poco '
        'volumen de raíz: una maceta grande seca lento y el cuello se queda '
        'húmedo.',
    aliases: <String>[
      'SA-02',
      'SA02',
      'sa_02',
      'aloe pequeño',
      'aloe enano',
      'sábila enana',
      'sábila de maceta',
      'mini aloe',
      'aloe brevifolia',
      'aloe humilis',
      'aloe juvenna',
      'aloe descoingsii',
      'aloe haworthioides',
      'aloe bakeri',
      'aloe albiflora',
      'aloe rauhii',
      'aloe parvula',
      'aloe aristata',
      'aristaloe aristata',
      'lace aloe',
      'aloe encaje',
      'aloe variegata',
      'gonialoe variegata',
      'partridge breast',
    ],
  ),
  CropProfileEntry(
    id: kSa03ShrubbyBranching,
    label: 'Sábila arbustiva o de candelabro',
    cropId: kCropAloe,
    subtitle:
        'Hace tronco y ramas; parece un arbusto de varios brazos. Con el porte '
        'ganan importancia el anclaje y la estabilidad; el drenaje sigue '
        'mandando.',
    aliases: <String>[
      'SA-03',
      'SA03',
      'sa_03',
      'aloe arborescens',
      'sábila pulpo',
      'aloe pulpo',
      'aloe candelabro',
      'sábila de candelabro',
      'sábila arbustiva',
      'aloe arborescente',
      'sábila de árbol',
      'krantz aloe',
      'torch aloe',
      'candelabra aloe',
    ],
  ),
  CropProfileEntry(
    id: kSa04SpottedLandscape,
    label: 'Sábila moteada de jardín',
    cropId: kCropAloe,
    subtitle:
        'Hoja ancha con manchas; se llena de hijos y forma mata. Uso de '
        'paisaje; forma colonias densas más rápido que la de hoja ancha.',
    aliases: <String>[
      'SA-04',
      'SA04',
      'sa_04',
      'aloe maculata',
      'aloe saponaria',
      'sábila jabonera',
      'aloe jabonero',
      'soap aloe',
      'sábila moteada',
      'aloe moteado',
      'sábila cebra',
      'aloe cebra',
      'tiger aloe',
      'sábila de jardín',
      'sábila manchada',
    ],
  ),
  // ── SIEMPRE AL FINAL ──────────────────────────────────────────────────────
  // La salida "no sé" va hasta abajo, después de los tipos concretos. Sigue
  // siendo el defaultProfileId: si el usuario no elige, cae aquí.
  CropProfileEntry(
    id: kSaSkip,
    label: 'No sé / sábila general',
    cropId: kCropAloe,
    subtitle:
        'Perfil general y migrable: usaremos un manejo prudente y podrás elegir '
        'su forma después sin perder la fecha ni el historial.',
    aliases: <String>[
      'SA-SKIP',
      'SA_SKIP',
      'SASKIP',
      'sábila',
      'sabila',
      'zábila',
      'zabila',
      'aloe',
      'sábila general',
      'otra sábila',
      'no se que sábila es',
      'no sé qué sábila es',
      'sábila sin identificar',
      'me la vendieron como sábila',
      'me la vendieron como aloe',
      'aloe sp.',
      'aloe hybrid',
      'aloe species',
    ],
  ),
];

/// Aliases de ENTRADA que NO deben mapear silenciosamente a un perfil SA: son
/// cultivos que BIO-G modela (o modelará) por separado (Doc A §1.4, §4.4).
const List<String> aloeAgaveRedirectAliases = <String>[
  'maguey',
  'agave',
  'agave americana',
  'pita',
  'henequén',
  'henequen',
];

const List<String> aloeNopalRedirectAliases = <String>[
  'nopal',
  'opuntia',
];

const List<String> aloeCactusRedirectAliases = <String>[
  'cactus',
  'cactacea',
  'cactácea',
  'cactaceae',
];

const List<String> aloeSucculentRedirectAliases = <String>[
  'suculenta',
  'crasa',
  'haworthia',
  'haworthiopsis',
  'gasteria',
  'tulista',
];

/// Grupos diferidos / ambiguos: NO se resuelven por nombre a un perfil SA
/// (Doc A §4.3, §4.4). Requieren identificación por forma o quedan fuera de v1.
const List<String> aloeDeferredGroupAliases = <String>[
  'lithops',
  'planta cebra',
  'lengua de suegra',
  'sansevieria',
  'rosa del desierto',
  'euphorbia',
  'yuca',
  'izote',
  'piña',
  'aloidendron barberae',
  'aloidendron dichotoma',
  'aloiampelos ciliaris',
  'aloe trepador',
];

bool _matchesAlias(String? raw, List<String> aliases) {
  final v = raw?.trim().toLowerCase();
  if (v == null || v.isEmpty) return false;
  return aliases.contains(v);
}

/// True si el alias corresponde a maguey/Agave (redirige a `crop_agave`).
bool isAloeAgaveAlias(String? raw) =>
    _matchesAlias(raw, aloeAgaveRedirectAliases);

/// True si el alias corresponde a nopal/Opuntia (redirige a `crop_nopal`).
bool isAloeNopalAlias(String? raw) =>
    _matchesAlias(raw, aloeNopalRedirectAliases);

/// True si el alias corresponde a un cactus (redirige a `crop_cactus`).
bool isAloeCactusAlias(String? raw) =>
    _matchesAlias(raw, aloeCactusRedirectAliases);

/// True si el alias corresponde a una suculenta no aloe (redirige a
/// `crop_succulent`).
bool isAloeSucculentAlias(String? raw) =>
    _matchesAlias(raw, aloeSucculentRedirectAliases);

/// True si el alias pertenece a un grupo diferido o ambiguo (Lithops, "planta
/// cebra", Sansevieria, aloes arbóreos…). No se le asigna un perfil SA en
/// silencio.
bool isAloeDeferredGroupAlias(String? raw) =>
    _matchesAlias(raw, aloeDeferredGroupAliases);

/// True si el alias debe redirigirse a OTRO cultivo de BIO-G.
bool isAloeRedirectAlias(String? raw) =>
    isAloeAgaveAlias(raw) ||
    isAloeNopalAlias(raw) ||
    isAloeCactusAlias(raw) ||
    isAloeSucculentAlias(raw);
